import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '_expandable_post_content.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme_config.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/ai_service.dart';
import '../services/alert_service.dart';
import '../services/news_service.dart';
import '../services/file_service.dart';
import '../services/reward_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/ai_models.dart';
import '../models/api_exception.dart';
import '../models/news_model.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'file_upload_screen.dart';
import 'notification_screen.dart';
import 'user_profile_screen.dart';
import 'create_post_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final AiService _aiService = AiService();
  final AlertService _alertService = AlertService();
  final NewsService _newsService = NewsService();
  final FileService _fileService = FileService();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final PageController _bannerPageController = PageController();
  late TabController _filterTabController;
  int _currentIndex = 0;
  int _currentBannerIndex = 0;
  Timer? _bannerAutoScrollTimer;

  List<Post> _posts = [];
  List<NewsArticle> _newsArticles = [];
  bool _isLoadingPosts = false;
  bool _isLoadingNews = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _newsErrorMessage;
  int _skip = 0;
  final int _limit = 10;
  bool _hasMore = true;

  // Filter state
  int _selectedTabIndex = 0;
  final List<String> _filterTabs = ['All', 'My Dept', 'Events', 'Announce'];

  // Cache user profile to avoid repeated API calls
  UserProfile? _cachedUserProfile;

  // Debounce timer for scroll events
  Timer? _scrollDebounceTimer;

  // AI Chat state
  List<ChatMessage> _chatMessages = [];
  bool _isLoadingAIResponse = false;

  // Notification state
  int _unreadNotificationCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: 4, vsync: this);
    _filterTabController.addListener(_onTabChanged);
    _loadPosts();
    _loadNews();
    _loadUnreadNotificationCount();
    _scrollController.addListener(_onScroll);
    _startNotificationPolling();
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _filterTabController.dispose();
    _scrollController.dispose();
    _chatScrollController.dispose();
    _messageController.dispose();
    _bannerPageController.dispose();
    _scrollDebounceTimer?.cancel();
    _notificationTimer?.cancel();
    _bannerAutoScrollTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_filterTabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _filterTabController.index;
      });
      _loadPosts(); // Reload posts with new filter
    }
  }

  void _onScroll() {
    // Debounce scroll events to prevent excessive calls
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      // Check if user has scrolled to the bottom
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent -
                  200 && // Start loading 200px before the end
          !_isLoadingMore &&
          _hasMore) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _loadPosts() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingPosts) return;

    setState(() {
      _isLoadingPosts = true;
      _errorMessage = null;
      _skip = 0;
      _hasMore = true;
    });

    try {
      List<Post> posts;

      switch (_selectedTabIndex) {
        case 0: // All
          posts = await _postService.getPosts(skip: 0, limit: _limit);
          break;
        case 1: // My Dept
          posts = await _loadPostsByDepartment(skip: 0, limit: _limit);
          break;
        case 2: // Events
          try {
            posts = await _postService.getPostsByType('EVENTS',
                skip: 0, limit: _limit);
          } catch (e) {
            print('No events posts found, showing empty list');
            posts = [];
          }
          break;
        case 3: // Announcements
          try {
            posts = await _postService.getPostsByType('ANNOUNCEMENT',
                skip: 0, limit: _limit);
          } catch (e) {
            print('No announcement posts found, showing empty list');
            posts = [];
          }
          break;
        default:
          posts = await _postService.getPosts(skip: 0, limit: _limit);
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _skip = posts.length;
          _hasMore = posts.length >= _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load posts: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<List<Post>> _loadPostsByDepartment(
      {int skip = 0, int limit = 50}) async {
    // Cache user profile to avoid repeated API calls
    _cachedUserProfile ??= await _authService.getUserProfile();

    if (_cachedUserProfile?.department == null) {
      // If no department, just return all posts
      return await _postService.getPosts(skip: skip, limit: limit);
    }

    // Get all posts first
    final allPosts = await _postService.getPosts(
        skip: skip, limit: limit * 2); // Get more to filter

    // Filter by user's department
    final filteredPosts = allPosts
        .where((post) => post.authorDepartment
            .toLowerCase()
            .contains(_cachedUserProfile!.department.toLowerCase()))
        .toList();

    // Return only the requested amount
    return filteredPosts.take(limit).toList();
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      List<Post> newPosts;

      switch (_selectedTabIndex) {
        case 0: // All
          newPosts = await _postService.getPosts(skip: _skip, limit: _limit);
          break;
        case 1: // My Dept
          newPosts = await _loadPostsByDepartment(skip: _skip, limit: _limit);
          break;
        case 2: // Events
          try {
            newPosts = await _postService.getPostsByType('EVENTS',
                skip: _skip, limit: _limit);
          } catch (e) {
            print('No more events posts found');
            newPosts = [];
          }
          break;
        case 3: // Announcements
          try {
            newPosts = await _postService.getPostsByType('ANNOUNCEMENT',
                skip: _skip, limit: _limit);
          } catch (e) {
            print('No more announcement posts found');
            newPosts = [];
          }
          break;
        default:
          newPosts = await _postService.getPosts(skip: _skip, limit: _limit);
      }

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _skip += newPosts.length;
          _hasMore = newPosts.length >= _limit;
        });
      }
    } catch (e) {
      print('Error loading more posts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPostType = 'GENERAL';
    bool isCreating = false;
    File? selectedImage;
    String? uploadedImageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                // Image picker section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.image, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Image (optional)',
                                style: TextStyle(fontSize: 16)),
                          ),
                          TextButton.icon(
                            onPressed: isCreating
                                ? null
                                : () async {
                                    try {
                                      await _pickImageForPost(setDialogState,
                                          (image, imageUrl) {
                                        selectedImage = image;
                                        uploadedImageUrl = imageUrl;
                                        print(
                                            'Image callback called: image=${image?.path}, url=$imageUrl');
                                      });
                                    } catch (e) {
                                      print(
                                          'Error in image picker callback: $e');
                                    }
                                  },
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Choose Image'),
                          ),
                        ],
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              uploadedImageUrl != null
                                  ? 'Image uploaded'
                                  : 'Image selected',
                              style: const TextStyle(
                                  color: Colors.green, fontSize: 12),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: isCreating
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        selectedImage = null;
                                        uploadedImageUrl = null;
                                      });
                                    },
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPostType,
                  decoration: const InputDecoration(
                    labelText: 'Post Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                    DropdownMenuItem(
                        value: 'ANNOUNCEMENT', child: Text('Announcement')),
                    DropdownMenuItem(value: 'INFO', child: Text('Info')),
                    DropdownMenuItem(
                        value: 'IMPORTANT', child: Text('Important')),
                    DropdownMenuItem(value: 'EVENTS', child: Text('Events')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPostType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty ||
                          contentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in title and content'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isCreating = true;
                      });

                      try {
                        final post = await _postService.createPost(
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          imageUrl: uploadedImageUrl,
                          postType: selectedPostType,
                        );

                        if (post != null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Post created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Reload posts to show the new post
                          _loadPosts();
                        }
                      } catch (e) {
                        setDialogState(() {
                          isCreating = false;
                        });

                        if (e is InappropriateContentException) {
                          // Close the create post dialog first
                          Navigator.pop(context);
                          // Show warning dialog for inappropriate content
                          _showInappropriateContentWarning(e.message);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Failed to create post: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _alertService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
      // Don't show error to user for notification count failures
    }
  }

  void _startNotificationPolling() {
    // Poll for notification updates every 30 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _authService.isAuthenticated) {
        _loadUnreadNotificationCount();
      }
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    ).then((_) {
      // Refresh notification count when returning from notification screen
      _loadUnreadNotificationCount();
    });
  }

  void _navigateToAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminScreen()),
    );
  }

  Future<void> _loadNews() async {
    if (_isLoadingNews) return;

    setState(() {
      _isLoadingNews = true;
      _newsErrorMessage = null;
    });

    try {
      final newsResponse = await _newsService.fetchTechHeadlines();
      if (mounted) {
        setState(() {
          _newsArticles = newsResponse.articles;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newsErrorMessage = 'Failed to load news: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
      }
    }
  }

  void _startBannerAutoScroll() {
    _bannerAutoScrollTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_newsArticles.isNotEmpty && _bannerPageController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _newsArticles.length;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onBannerPageChanged(int index) {
    setState(() {
      _currentBannerIndex = index;
    });
  }

  Future<void> _openNewsUrl(String url) async {
    print('Attempting to open URL: $url');
    try {
      final uri = Uri.parse(url);
      print('Parsed URI: $uri');

      // Try different launch modes
      try {
        // First try external application
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('External app launch result: $result');
        return;
      } catch (e) {
        print('External app launch failed: $e');
      }

      try {
        // Try platform default
        final result = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        print('Platform default launch result: $result');
        return;
      } catch (e) {
        print('Platform default launch failed: $e');
      }

      // Last resort - try with canLaunchUrl check
      final canLaunch = await canLaunchUrl(uri);
      print('Can launch URL: $canLaunch');

      if (canLaunch) {
        final result = await launchUrl(uri);
        print('Basic launch result: $result');
      } else {
        throw Exception('Could not launch $url - no app available');
      }
    } catch (e) {
      print('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open article: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshHomeData() async {
    await Future.wait([
      _loadPosts(),
      _loadNews(),
    ]);
  }

  void _navigateToUserProfile(int userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );

    // If post was created successfully, refresh the home screen
    if (result == true) {
      _loadPosts();
    }
  }

  Future<void> _pickImageForPost(StateSetter setDialogState,
      Function(File?, String?) onImageSelected) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Request permissions first
      await Permission.camera.request();
      await Permission.photos.request();

      // Show bottom sheet to choose camera or gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        print('Image source selected: $source');
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          print('Image picked: ${image.path}');
          final file = File(image.path);

          // Update dialog state first with the selected image
          setDialogState(() {
            onImageSelected(file, null);
          });

          // Upload the image in the background
          try {
            print('🔄 Starting image upload...');
            final imageUrl = await _fileService.uploadPostImage(file);
            print('🔄 Upload result - imageUrl: $imageUrl');
            if (imageUrl != null) {
              print('✅ Image uploaded successfully: $imageUrl');
              setDialogState(() {
                print('🔄 Calling onImageSelected with imageUrl: $imageUrl');
                onImageSelected(file, imageUrl);
              });
            } else {
              print('❌ imageUrl is null after upload');
            }
          } catch (e) {
            print('Error uploading image: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload image: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          print('No image selected');
        }
      } else {
        print('No image source selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInappropriateContentWarning(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Content Warning',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.report_outlined,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Repeated violations will be reported to administrators and may result in account suspension.',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please review and revise your content to comply with our community guidelines.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text('I Understand'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Reopen the create post dialog
              _showCreatePostDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Revise Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _buildCurrentPage(),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: _buildFloatingActionButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: AnimatedBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Hide FAB when keyboard is visible
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardVisible) {
      return null;
    }

    Widget? fab;

    switch (_currentIndex) {
      case 0: // Home - Create Post
        fab = Container(
          key: const ValueKey('fab_home'),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _navigateToCreatePost,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        );
        break;
      case 1: // AI Search - New Conversation
        fab = Container(
          key: const ValueKey('fab_ai'),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              _startNewAIConversation();
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child:
                const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
          ),
        );
        break;
      case 3: // Files - Upload
        fab = Container(
          key: const ValueKey('fab_files'),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              // Trigger file upload
              _showFileUploadOptions();
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child:
                const Icon(Icons.upload_rounded, color: Colors.white, size: 26),
          ),
        );
        break;
      case 4: // Rewards - Give Reward (Admin only)
        // Check if user is admin
        final authService = AuthService();
        final userRoles = authService.currentUser?.roles ?? [];
        final isAdmin = userRoles.contains('admin');

        fab = Container(
          key: const ValueKey('fab_rewards'),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isAdmin
                  ? [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ]
                  : [
                      Colors.grey.shade400,
                      Colors.grey.shade300,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: isAdmin
                ? () {
                    // Show give reward dialog for admins
                    _showGiveRewardBottomSheet();
                  }
                : null, // Disabled for students
            backgroundColor: Colors.transparent,
            elevation: 0,
            disabledElevation: 0,
            child: Icon(
              Icons.card_giftcard,
              color: isAdmin ? Colors.white : Colors.grey.shade500,
              size: 26,
            ),
          ),
        );
        break;
      default:
        fab = null;
    }

    if (fab == null) return null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: RotationTransition(
            turns: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: fab,
    );
  }

  void _showGiveRewardBottomSheet() async {
    final rewardService = RewardService();
    final authService = AuthService();

    // Load reward types and users
    List<String> rewardTypes = [];
    List<Map<String, dynamic>> users = [];

    try {
      final results = await Future.wait([
        rewardService.getRewardTypes(),
        rewardService.getUsers(),
      ]);

      rewardTypes = results[0] as List<String>;
      users = results[1] as List<Map<String, dynamic>>;

      // Filter out the current user from the list
      final currentUserId = authService.currentUser?.id;
      if (currentUserId != null) {
        users = users
            .where((user) => user['id'].toString() != currentUserId)
            .toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController(text: '10');

    String selectedRewardType =
        rewardTypes.isNotEmpty ? rewardTypes.first : 'OTHER';
    Map<String, dynamic>? selectedUser;
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Give Reward',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedUser,
                  decoration: const InputDecoration(
                    labelText: 'Select User',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  menuMaxHeight: 300, // Add max height for scrollable dropdown
                  items: users.map((user) {
                    return DropdownMenuItem(
                      value: user,
                      child: Text(
                        user['full_name']?.toString() ?? 'Unknown',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedUser = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRewardType,
                  decoration: const InputDecoration(
                    labelText: 'Reward Type',
                    border: OutlineInputBorder(),
                  ),
                  items: rewardTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRewardType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isCreating ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isCreating
                            ? null
                            : () async {
                                if (selectedUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a user'),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isCreating = true;
                                });

                                try {
                                  await rewardService.createReward(
                                    receiverId: selectedUser!['id'],
                                    title: titleController.text,
                                    description: descriptionController.text,
                                    rewardType: selectedRewardType,
                                    points:
                                        int.tryParse(pointsController.text) ??
                                            10,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Reward given successfully!'),
                                      ),
                                    );
                                    // Refresh the rewards page if we're on it
                                    if (_currentIndex == 4) {
                                      setState(() {});
                                    }
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isCreating = false;
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to give reward: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Give Reward'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFileUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upload File',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Upload Image'),
              subtitle: const Text('Select from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageForUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImageForUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.orange),
              title: const Text('Upload Document'),
              subtitle: const Text('PDF, Word, Excel, PowerPoint'),
              onTap: () {
                Navigator.pop(context);
                _pickDocumentForUpload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: const Text('Browse Files'),
              subtitle: const Text('Any file type'),
              onTap: () {
                Navigator.pop(context);
                _pickAnyFileForUpload();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageForUpload(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileName = image.name;
        _showUploadDialog(file, fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDocumentForUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        _showUploadDialog(file, fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAnyFileForUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        _showUploadDialog(file, fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadDialog(File file, String fileName) {
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $fileName'),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _uploadFileToServer(
                file,
                fileName,
                descriptionController.text,
                categoryController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFileToServer(
    File file,
    String fileName,
    String description,
    String category,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading file...')),
      );

      // Get the current folder path from FileUploadScreen if we're on the Files tab
      String folderPath = '/'; // Default to root
      if (_currentIndex == 3) {
        // We're on the Files tab - get the current folder path
        folderPath = FileUploadScreen.currentFolderPath;
      }

      print('📤 Home screen uploading to folder: $folderPath');

      await _fileService.uploadFile(
        file,
        description: description.isNotEmpty ? description : null,
        folderPath: folderPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh if on files page
        if (_currentIndex == 3) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildAISearchPage();
      case 2:
        // Post - this won't be shown as we navigate away
        return _buildHomePage();
      case 3:
        return const FileUploadScreen();
      case 4:
        return const RewardsScreen();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final user = _authService.currentUser;

    return RefreshIndicator(
      onRefresh: _refreshHomeData,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header with user info and notifications
                _buildHeader(user),
                const SizedBox(height: 24),

                // Main banner card
                _buildMainBanner(),
              ]),
            ),
          ),

          // Category tabs with integrated design
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _buildCategoryTabs(),
            ),
          ),

          // Posts list
          if (_isLoadingPosts)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_posts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No posts yet'),
              ),
            )
          else ...[
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      key: ValueKey(_posts[index].id),
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildPostCard(_posts[index]),
                    );
                  },
                  childCount: _posts.length,
                ),
              ),
            ),

            // Loading indicator and status messages
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Loading indicator when fetching more posts
                  if (_isLoadingMore)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              'Loading more posts...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Swipe indicator when more posts are available
                  if (_hasMore && !_isLoadingMore && _posts.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.grey.shade400,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Swipe up to load more',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // End of posts indicator
                  if (!_hasMore && _posts.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green.shade400,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'re all caught up! 🎉',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ]),
              ),
            ),

            // Final bottom spacing for navigation bar
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 180),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Row(
      children: [
        // User avatar and info
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // User details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? 'User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              Text(
                '3rd yr, Computer Science Engineering',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Notification icon
        GestureDetector(
          onTap: _navigateToNotifications,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none,
                    color: Colors.black54,
                  ),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotificationCount > 99
                              ? '99+'
                              : _unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Admin wrench icon - only visible for admin users
        if (user?.roles.contains('admin') == true) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _navigateToAdminPanel,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade600,
                    Colors.orange.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainBanner() {
    if (_isLoadingNews) {
      return Container(
        width: double.infinity,
        height: 240,
        decoration: AppTheme.gradientCardDecoration,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (_newsErrorMessage != null || _newsArticles.isEmpty) {
      // Fallback to a default banner when news fails to load
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: AppTheme.gradientCardDecoration,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Campus Updates',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _newsErrorMessage ??
                        'Stay connected with your campus community.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.newspaper,
                size: 40,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerPageController,
            onPageChanged: _onBannerPageChanged,
            itemCount: _newsArticles.length,
            itemBuilder: (context, index) {
              final article = _newsArticles[index];
              return GestureDetector(
                onTap: () => _openNewsUrl(article.url),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      // Background image if available
                      if (article.image != null && article.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.black26,
                            ),
                            child: Image.network(
                              article.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                article.source,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              article.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              article.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    print(
                                        'Read More tapped for: ${article.title}');
                                    print('Article URL: ${article.url}');
                                    _openNewsUrl(article.url);
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'Read More',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Page indicators
          if (_newsArticles.length > 1)
            Positioned(
              bottom: 16,
              left: 20,
              child: Row(
                children: List.generate(
                  _newsArticles.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: index == _currentBannerIndex ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentBannerIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _filterTabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(4),
        tabs: _filterTabs.map((category) {
          return Tab(
            text: category,
            height: 40,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clickable avatar
              GestureDetector(
                onTap: () =>
                    _navigateToUserProfile(post.authorId, post.authorName),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      post.authorInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _navigateToUserProfile(post.authorId, post.authorName),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.authorDepartment,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPostTypeColor(post.postType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.postType,
                      style: TextStyle(
                        color: _getPostTypeColor(post.postType),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.more_horiz,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Post title
          if (post.title.isNotEmpty) ...[
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Post content with truncation and 'Show more' option
          ExpandablePostContent(content: post.content),

          // Post image
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Post actions (like, comment, share)
          Row(
            children: [
              _buildActionButton(
                icon: Icons.favorite_border,
                label: post.likes.toString(),
                onTap: () => _handleLike(post),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: post.comments.toString(),
                onTap: () => _showCommentsDialog(post),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: post.shares.toString(),
                onTap: () => _handleShare(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPostTypeColor(String postType) {
    switch (postType.toUpperCase()) {
      case 'ANNOUNCEMENT':
        return AppTheme.accentColor;
      case 'IMPORTANT':
        return Colors.orange;
      case 'INFO':
        return AppTheme.primaryColor;
      case 'EVENTS':
        return AppTheme.secondaryColor;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleLike(Post post) async {
    if (!mounted) return;

    // Optimistically update UI
    final originalPost = post;
    final postIndex = _posts.indexWhere((p) => p.id == post.id);
    if (postIndex == -1) return;

    setState(() {
      final updatedMetadata = Map<String, dynamic>.from(post.postMetadata);
      updatedMetadata['likes'] = post.likes + 1;

      _posts[postIndex] = Post(
        id: post.id,
        title: post.title,
        content: post.content,
        imageUrl: post.imageUrl,
        postType: post.postType,
        authorId: post.authorId,
        collegeId: post.collegeId,
        postMetadata: updatedMetadata,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        authorName: post.authorName,
        authorDepartment: post.authorDepartment,
        timeAgo: post.timeAgo,
      );
    });

    // Call the like API endpoint without blocking UI
    _postService.likePost(post.id).then((success) {
      if (!mounted) return;

      if (!success) {
        // Revert on failure
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = originalPost;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to like post')),
        );
      }
    }).catchError((e) {
      if (!mounted) return;

      // Revert on error
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = originalPost;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $e')),
      );
    });
  }

  void _showCommentsDialog(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  Widget _buildAISearchPage() {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16.0),
          child: SafeArea(
            bottom: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.psychology,
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus AI Assistant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Ask me about college content, files, and posts',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Chat Messages
        Expanded(
          child: _chatMessages.isEmpty
              ? _buildEmptyChat()
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _chatMessages.length + (_isLoadingAIResponse ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatMessages.length && _isLoadingAIResponse) {
                      return _buildTypingIndicator();
                    }
                    return _buildChatBubble(_chatMessages[index]);
                  },
                ),
        ),

        // Message Input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ask me anything about your college content, files, posts, or get help with your studies!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestedQuestion('What files are available?'),
              _buildSuggestedQuestion('Show me recent posts'),
              _buildSuggestedQuestion('Help with assignments'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestion(String question) {
    return GestureDetector(
      onTap: () => _sendMessage(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          question,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.blue.shade600
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (message.sources != null &&
                      message.sources!.isNotEmpty &&
                      _hasValidSources(message.sources!)) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Sources:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...message.sources!
                        .where((source) =>
                            source['doc_id'] != null &&
                            source['doc_id'].toString() != 'null')
                        .map((source) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '• ${source['metadata']?['title'] ?? 'Source ${source['doc_id']}'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            )),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  _authService.currentUser?.initials ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI is typing...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = keyboardHeight > 0 ? 16.0 : 80.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text.trim());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final message = _messageController.text.trim();
                if (message.isNotEmpty) {
                  _sendMessage(message);
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty || _isLoadingAIResponse) return;

    // Clear the input
    _messageController.clear();

    // Add user message
    setState(() {
      _chatMessages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoadingAIResponse = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      // Send request to AI service
      final response = await _aiService.askAI(message);

      setState(() {
        _chatMessages.add(ChatMessage(
          content: response.answer,
          isUser: false,
          timestamp: DateTime.now(),
          sources: response.sources,
        ));
        _isLoadingAIResponse = false;
      });

      // Scroll to bottom to show new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          content: 'Sorry, I encountered an error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoadingAIResponse = false;
      });

      // Scroll to bottom to show error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startNewAIConversation() {
    setState(() {
      _chatMessages.clear();
      _isLoadingAIResponse = false;
    });
    _messageController.clear();
  }

  bool _hasValidSources(List<Map<String, dynamic>> sources) {
    return sources.any((source) =>
        source['doc_id'] != null &&
        source['doc_id'].toString().trim().isNotEmpty &&
        source['doc_id'].toString() != 'null');
  }

  Widget _buildAppsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),

          // New Post Button
          InkWell(
            onTap: _showCreatePostDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Post',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Share something with your campus',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Placeholder for more apps
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'More apps coming soon',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
