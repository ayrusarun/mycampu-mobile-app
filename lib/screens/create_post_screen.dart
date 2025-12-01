import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme_config.dart';
import '../models/academic_models.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/file_service.dart';
import '../services/ai_service.dart';
import '../services/academic_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final FileService _fileService = FileService();
  final AiService _aiService = AiService();
  final AcademicService _academicService = AcademicService();

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String _selectedPostType = 'General';
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isCreating = false;
  bool _isRewriting = false;

  // NEW: Academic targeting
  List<Program> _programs = [];
  List<Cohort> _cohorts = [];
  List<Class> _classes = [];
  Program? _selectedProgram;
  Cohort? _selectedCohort;
  Class? _selectedClass;
  bool _isLoadingPrograms = false;
  bool _isLoadingCohorts = false;
  bool _isLoadingClasses = false;
  bool _isAcademicTargeting = false; // Toggle for academic targeting
  int? _userProgramId; // Store user's program ID
  String? _userProgramName; // Store user's program name

  // Post type options
  final List<PostTypeOption> _postTypes = [
    PostTypeOption(
      type: 'General',
      icon: Icons.text_fields,
      color: Colors.blue,
      enabled: true,
    ),
    PostTypeOption(
      type: 'Events',
      icon: Icons.event,
      color: Colors.green,
      enabled: true,
    ),
    PostTypeOption(
      type: 'Announcement',
      icon: Icons.campaign,
      color: Colors.orange,
      enabled: true,
    ),
    PostTypeOption(
      type: 'Important',
      icon: Icons.priority_high,
      color: Colors.red,
      enabled: true,
    ),
  ];

  // Add to post options
  final List<AddToPostOption> _addToPostOptions = [
    AddToPostOption(
      title: 'Photo/Video',
      subtitle: 'Take or select photos',
      icon: Icons.photo_library,
      color: Colors.blue,
      enabled: true,
    ),
    AddToPostOption(
      title: 'Gif',
      subtitle: 'Add animated GIFs',
      icon: Icons.gif,
      color: Colors.green,
      enabled: false,
    ),
    AddToPostOption(
      title: 'Poll',
      subtitle: 'Create a poll',
      icon: Icons.poll,
      color: Colors.purple,
      enabled: false,
    ),
    AddToPostOption(
      title: 'Event',
      subtitle: 'Create an event',
      icon: Icons.event,
      color: Colors.orange,
      enabled: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        // Trigger rebuild to update AI rewrite button state and description
      });
    });
    _titleController.addListener(() {
      setState(() {
        // Trigger rebuild to update post button state
      });
    });
    _loadDepartments();
    _loadUserDepartment();
  }

  Future<void> _loadUserDepartment() async {
    try {
      final userProfile = await _authService.getUserProfile();
      if (userProfile != null) {
        setState(() {
          _userDepartmentId = userProfile.departmentId;
          _userDepartmentName = userProfile.departmentName;
        });
      }
    } catch (e) {
      print('❌ Failed to load user department: $e');
    }
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      final departments = await _departmentService.getDepartments();
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
      print('✅ Loaded ${departments.length} departments for post targeting');
    } catch (e) {
      print('❌ Failed to load departments: $e');
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _canPost() ? _createPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section (moved to top)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    (user?.name?.split(' ').map((e) => e[0]).take(2).join('') ??
                            'U')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedPostType,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Post Type section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Post Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _postTypes.map((postType) {
                        final isSelected = _selectedPostType == postType.type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: postType.enabled
                                ? () {
                                    setState(() {
                                      _selectedPostType = postType.type;
                                    });
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? postType.color : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: postType.enabled
                                      ? (isSelected
                                          ? postType.color
                                          : Colors.grey.shade300)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    postType.icon,
                                    size: 14,
                                    color: postType.enabled
                                        ? (isSelected
                                            ? Colors.white
                                            : postType.color)
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    postType.type,
                                    style: TextStyle(
                                      color: postType.enabled
                                          ? (isSelected
                                              ? Colors.white
                                              : postType.color)
                                          : Colors.grey.shade400,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Department Targeting (Conditional based on role)
            Builder(
              builder: (context) {
                final user = _authService.currentUser;
                final isAdmin = user?.roles.contains('admin') ?? false;

                if (isAdmin) {
                  // Admin: Show dropdown with all departments
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Target Department (Optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDepartment == null
                              ? 'Visible to all departments'
                              : 'Only visible to ${_selectedDepartment!.name}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingDepartments)
                          const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          DropdownButtonFormField<Department>(
                            value: _selectedDepartment,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade200),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            hint: Text(
                              'Select a department',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blue.shade700,
                            ),
                            isExpanded: true,
                            items: [
                              // "All Departments" option (null value)
                              DropdownMenuItem<Department>(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'All Departments',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ..._departments.map((dept) {
                                return DropdownMenuItem<Department>(
                                  value: dept,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.school,
                                        size: 16,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dept.displayName,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (Department? newValue) {
                              setState(() {
                                _selectedDepartment = newValue;
                              });
                            },
                          ),
                      ],
                    ),
                  );
                } else {
                  // Non-admin: Show checkbox for their own department
                  if (_userDepartmentId == null) {
                    return const SizedBox
                        .shrink(); // Don't show if user has no department
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isDepartmentSpecific,
                          onChanged: (bool? value) {
                            setState(() {
                              _isDepartmentSpecific = value ?? false;
                            });
                          },
                          activeColor: Colors.blue.shade700,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Department Specific Post',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isDepartmentSpecific
                                    ? 'Only visible to ${_userDepartmentName ?? "your department"}'
                                    : 'Visible to all departments',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Title input (reduced size)
            TextField(
              controller: _titleController,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Add a title (optional)',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 8),

            // Content input (reduced size)
            TextField(
              controller: _contentController,
              maxLines: 5,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'What do you want to talk about?',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Selected image display
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _uploadedImageUrl != null
                        ? Icons.check_circle
                        : Icons.upload,
                    color: _uploadedImageUrl != null
                        ? Colors.green
                        : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _uploadedImageUrl != null
                        ? 'Image uploaded'
                        : 'Uploading...',
                    style: TextStyle(
                      color: _uploadedImageUrl != null
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _uploadedImageUrl = null;
                      });
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // AI Rewrite section (reduced size)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rewrite with AI',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          (_titleController.text.trim().isEmpty &&
                                  _contentController.text.trim().isEmpty)
                              ? 'Write a title or content first to enable AI rewrite'
                              : _isRewriting
                                  ? 'AI is rewriting your post...'
                                  : 'Improve your post with AI',
                          style: TextStyle(
                            color: (_titleController.text.trim().isEmpty &&
                                    _contentController.text.trim().isEmpty)
                                ? Colors.orange.shade600
                                : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (_titleController.text.trim().isNotEmpty ||
                                _contentController.text.trim().isNotEmpty) &&
                            !_isRewriting
                        ? _rewriteWithAI
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (_titleController.text.trim().isNotEmpty ||
                                  _contentController.text.trim().isNotEmpty)
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                      foregroundColor:
                          (_titleController.text.trim().isNotEmpty ||
                                  _contentController.text.trim().isNotEmpty)
                              ? Colors.white
                              : Colors.grey.shade500,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: _isRewriting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Rewrite',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Add to post section (reduced size)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add to your post',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _addToPostOptions.length,
                    itemBuilder: (context, index) {
                      final option = _addToPostOptions[index];
                      return _buildAddToPostOption(option);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToPostOption(AddToPostOption option) {
    return GestureDetector(
      onTap: option.enabled ? () => _handleAddToPostOption(option) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: option.enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: option.enabled ? AppTheme.borderColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: option.enabled ? option.color : Colors.grey.shade400,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: option.enabled
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (option.enabled)
              Icon(
                Icons.add,
                color: option.color,
                size: 16,
              )
            else
              Icon(
                Icons.lock,
                color: Colors.grey.shade400,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  void _handleAddToPostOption(AddToPostOption option) {
    switch (option.title) {
      case 'Photo/Video':
        _pickImage();
        break;
      case 'Gif':
        // TODO: Implement GIF picker
        _showComingSoonSnackbar('GIF picker');
        break;
      case 'Poll':
        // TODO: Implement poll creation
        _showComingSoonSnackbar('Poll creation');
        break;
      case 'Event':
        // TODO: Implement event creation
        _showComingSoonSnackbar('Event creation');
        break;
    }
  }

  Future<void> _pickImage() async {
    try {
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
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          final file = File(image.path);

          setState(() {
            _selectedImage = file;
            _uploadedImageUrl = null;
          });

          // Upload image in background
          try {
            final imageUrl = await _fileService.uploadPostImage(file);
            if (imageUrl != null) {
              setState(() {
                _uploadedImageUrl = imageUrl;
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload image: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
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

  Future<void> _rewriteWithAI() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

    setState(() {
      _isRewriting = true;
    });

    try {
      // Combine title and content for rewriting
      String textToRewrite = '';
      if (title.isNotEmpty && content.isNotEmpty) {
        textToRewrite = '$title\n\n$content';
      } else if (title.isNotEmpty) {
        textToRewrite = title;
      } else {
        textToRewrite = content;
      }

      final rewrittenText = await _aiService.rewriteContent(textToRewrite);

      // Split the rewritten text back into title and content if it has multiple lines
      final lines = rewrittenText.split('\n');
      if (lines.length > 2 && title.isNotEmpty) {
        // If we had a title and the rewritten text has multiple paragraphs
        final rewrittenTitle = lines.first.trim();
        final rewrittenContent = lines
            .skip(1)
            .where((line) => line.trim().isNotEmpty)
            .join('\n')
            .trim();

        setState(() {
          _titleController.text = rewrittenTitle;
          _contentController.text = rewrittenContent;
        });
      } else {
        // If we only had content or the rewrite didn't create multiple paragraphs
        setState(() {
          if (title.isNotEmpty && content.isEmpty) {
            _titleController.text = rewrittenText;
          } else {
            _contentController.text = rewrittenText;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rewrite content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRewriting = false;
      });
    }
  }

  bool _canPost() {
    return (_titleController.text.trim().isNotEmpty ||
            _contentController.text.trim().isNotEmpty) &&
        !_isCreating;
  }

  Future<void> _createPost() async {
    if (!_canPost()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Smart title generation
      String finalTitle;
      if (_titleController.text.trim().isNotEmpty) {
        finalTitle = _titleController.text.trim();
      } else {
        // Generate crisp title from content
        final content = _contentController.text.trim();
        final firstLine = content.split('\n').first;
        // Limit to 60 characters for crispness
        if (firstLine.length > 60) {
          finalTitle = '${firstLine.substring(0, 57)}...';
        } else {
          finalTitle = firstLine;
        }
      }

      // Determine target department ID based on user role
      int? targetDepartmentId;
      final user = _authService.currentUser;
      final isAdmin = user?.roles.contains('admin') ?? false;

      if (isAdmin) {
        // Admin: Use selected department from dropdown
        targetDepartmentId = _selectedDepartment?.id;
      } else {
        // Regular user: Use their department if checkbox is checked
        targetDepartmentId = _isDepartmentSpecific ? _userDepartmentId : null;
      }

      await _postService.createPost(
        title: finalTitle,
        content: _contentController.text.trim(),
        postType: _selectedPostType.toUpperCase(),
        imageUrl: _uploadedImageUrl,
        targetDepartmentId: targetDepartmentId,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class PostTypeOption {
  final String type;
  final IconData icon;
  final Color color;
  final bool enabled;

  PostTypeOption({
    required this.type,
    required this.icon,
    required this.color,
    required this.enabled,
  });
}

class AddToPostOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;

  AddToPostOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
  });
}
