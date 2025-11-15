import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../models/file_model.dart';
import '../services/file_service.dart';
import '../services/auth_service.dart';
import '../config/theme_config.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen>
    with TickerProviderStateMixin {
  final FileService _fileService = FileService();
  final AuthService _authService = AuthService();

  List<FileModel> _files = [];
  List<String> _departments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _selectedDepartment;
  FileTypeFilter _selectedFileType = FileTypeFilter.all;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _files.clear();
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = null;
      });
      _loadFiles();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadDepartments(),
        _loadFiles(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _fileService.getDepartments();
      final userProfile = await _authService.getUserProfile();

      setState(() {
        _departments = departments;
        // Only set selected department if it exists in the departments list
        _selectedDepartment = departments.contains(userProfile?.department)
            ? userProfile?.department
            : null;
      });
      // Use departments for debugging
      print('Loaded ${_departments.length} departments');
    } catch (e) {
      print('Failed to load departments: $e');
      // Set empty departments list and no selection on error
      setState(() {
        _departments = [];
        _selectedDepartment = null;
      });
    }
  }

  Future<void> _loadFiles({bool isRefresh = false}) async {
    if (_isLoadingMore || (!_hasMore && !isRefresh)) return;

    setState(() {
      if (isRefresh) {
        _currentPage = 1;
        _hasMore = true;
        _files.clear();
      }
      _isLoadingMore = true;
      _errorMessage = null;
    });

    try {
      String? departmentFilter;
      String? fileTypeFilter;

      // Apply filters based on selected tab
      switch (_tabController.index) {
        case 0: // All Files
          // No additional filters
          break;
        case 1: // My Department
          departmentFilter = _selectedDepartment;
          break;
        case 2: // My Uploads
          // Filter by current user ID
          final currentUser = _authService.currentUser;
          if (currentUser != null) {
            // We'll filter client-side since API doesn't have uploader filter
            // First get all files then filter by uploader
          }
          break;
      }

      // Apply file type filter
      if (_selectedFileType != FileTypeFilter.all) {
        fileTypeFilter = _selectedFileType.apiValue;
      }

      final response = await _fileService.getFiles(
        page: _currentPage,
        pageSize: 20,
        department: departmentFilter,
        fileType: fileTypeFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      // Apply client-side filtering for "My Uploads" tab
      List<FileModel> filteredFiles = response.files;
      if (_tabController.index == 2) {
        // My Uploads - filter by current user
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          filteredFiles = response.files
              .where((file) => file.uploadedBy.toString() == currentUser.id)
              .toList();
        }
      }

      setState(() {
        if (isRefresh) {
          _files = filteredFiles;
        } else {
          _files.addAll(filteredFiles);
        }
        _currentPage++;
        _hasMore = response.files.length >= 20;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load files: $e';
      });
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> uploadFile() async {
    // Show upload options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Upload Image'),
              subtitle: const Text('Select from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.orange),
              title: const Text('Upload Document'),
              subtitle: const Text('PDF, Word, Excel, PowerPoint'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: const Text('Browse Files'),
              subtitle: const Text('Any file type'),
              onTap: () {
                Navigator.pop(context);
                _pickAnyFile();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
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

        // Show upload dialog with description input
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

  // Pick document files (PDF, Word, Excel, PowerPoint)
  Future<void> _pickDocument() async {
    try {
      // Try to pick files directly - FilePicker handles permissions internally
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Show upload dialog with description input
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

  // Pick any file type
  Future<void> _pickAnyFile() async {
    try {
      // Try to pick files directly - FilePicker handles permissions internally
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Show upload dialog with description input
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
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload File'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _getFileIcon(fileName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _formatFileSize(file.lengthSync()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description input
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add a description for this file...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isUploading,
                ),

                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text(
                    'Uploading file...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      setDialogState(() {
                        isUploading = true;
                      });

                      try {
                        final result = await _fileService.uploadFile(
                          file,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );

                        if (result != null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File uploaded successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refresh files list
                          _loadFiles(isRefresh: true);
                        }
                      } catch (e) {
                        setDialogState(() {
                          isUploading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Upload failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return const Icon(Icons.image, color: Colors.purple, size: 32);

      // Documents
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
      case 'doc':
      case 'docx':
        return Icon(Icons.description, color: AppTheme.primaryColor, size: 32);
      case 'xls':
      case 'xlsx':
        return const Icon(Icons.table_chart, color: Colors.green, size: 32);
      case 'ppt':
      case 'pptx':
        return const Icon(Icons.slideshow, color: Colors.orange, size: 32);

      // Videos
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
        return const Icon(Icons.video_file, color: Colors.red, size: 32);

      // Audio
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return const Icon(Icons.audio_file, color: Colors.pink, size: 32);

      // Archives
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return const Icon(Icons.archive, color: Colors.brown, size: 32);

      // Text
      case 'txt':
      case 'rtf':
        return const Icon(Icons.text_snippet, color: Colors.grey, size: 32);

      // Default
      default:
        return Icon(Icons.insert_drive_file,
            color: AppTheme.primaryColor, size: 32);
    }
  }

  Future<void> _downloadFile(FileModel file) async {
    try {
      // Check storage permissions on Android
      if (Platform.isAndroid) {
        var permission = await Permission.storage.status;

        // For Android 13+, we might need to check different permissions
        if (permission.isDenied) {
          // Show explanation dialog before requesting permission
          final shouldRequest = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Storage Permission Required'),
                content: const Text(
                  'This app needs storage permission to save downloaded files to your device. '
                  'Files will be saved to your Downloads folder where you can easily access them.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Allow'),
                  ),
                ],
              );
            },
          );

          if (shouldRequest == true) {
            final result = await Permission.storage.request();
            if (result.isDenied) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Storage permission is required to download files'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            } else if (result.isPermanentlyDenied) {
              // Show dialog explaining they need to enable from settings
              if (mounted) {
                final goToSettings = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Permission Required'),
                      content: const Text(
                        'Storage permission has been permanently denied. '
                        'Please enable it in app settings to download files.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Open Settings'),
                        ),
                      ],
                    );
                  },
                );

                if (goToSettings == true) {
                  await openAppSettings();
                }
              }
              return;
            }
          } else {
            return; // User cancelled
          }
        } else if (permission.isPermanentlyDenied) {
          // Permission was permanently denied previously
          if (mounted) {
            final goToSettings = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Permission Required'),
                  content: const Text(
                    'Storage permission is required to download files. '
                    'Please enable it in app settings.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Open Settings'),
                    ),
                  ],
                );
              },
            );

            if (goToSettings == true) {
              await openAppSettings();
            }
          }
          return;
        }
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Downloading ${file.originalFilename}...'),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Download file using proper authentication
      final response = await _fileService.downloadFile(file.id);

      Directory? directory;
      String downloadsPath = '';

      if (Platform.isAndroid) {
        // For Android, try multiple approaches based on Android version and permissions
        try {
          // First try the public Downloads directory (works on most devices)
          directory = Directory('/storage/emulated/0/Download');
          if (await directory.exists()) {
            downloadsPath = directory.path;
          } else {
            // Second approach: try getDownloadsDirectory from path_provider
            directory = await getDownloadsDirectory();
            if (directory != null && await directory.exists()) {
              downloadsPath = directory.path;
            } else {
              // Third approach: create Downloads folder in external storage
              directory = await getExternalStorageDirectory();
              if (directory != null) {
                downloadsPath = path.join(directory.path, 'Download');
                await Directory(downloadsPath).create(recursive: true);
              } else {
                // Final fallback: use app documents directory
                directory = await getApplicationDocumentsDirectory();
                downloadsPath = directory.path;
              }
            }
          }
        } catch (e) {
          // If all else fails, use app documents directory
          directory = await getApplicationDocumentsDirectory();
          downloadsPath = directory.path;
        }
      } else if (Platform.isIOS) {
        // For iOS, use the app documents directory
        directory = await getApplicationDocumentsDirectory();
        downloadsPath = directory.path;
      } else {
        // For other platforms, try downloads directory first
        directory = await getDownloadsDirectory();
        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        }
        downloadsPath = directory.path;
      }

      // Create file path with original filename
      final fileName = file.originalFilename;
      final filePath = path.join(downloadsPath, fileName);
      final downloadedFile = File(filePath);

      // Write file data
      await downloadedFile.writeAsBytes(response.bodyBytes);

      // Show success message with better path display
      final displayPath = Platform.isAndroid &&
              downloadsPath.contains('/storage/emulated/0/Download')
          ? 'Downloads/${fileName}'
          : downloadedFile.path;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to: $displayPath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              final uri = Uri.file(downloadedFile.path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _deleteFile(FileModel file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content:
            Text('Are you sure you want to delete "${file.originalFilename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _fileService.deleteFile(file.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFiles(isRefresh: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFileTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter by File Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...FileTypeFilter.values.map((filter) => ListTile(
                  title: Text(filter.displayName),
                  leading: Radio<FileTypeFilter>(
                    value: filter,
                    groupValue: _selectedFileType,
                    onChanged: (value) {
                      setState(() {
                        _selectedFileType = value!;
                      });
                      Navigator.pop(context);
                      _loadFiles(isRefresh: true);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadFiles(isRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Files',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Access and share your documents',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: AppTheme.primaryColor),
                    onPressed: _showFileTypeFilter,
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
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
                tabs: const [
                  Tab(text: 'All Files', height: 40),
                  Tab(text: 'Department', height: 40),
                  Tab(text: 'My Uploads', height: 40),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: 16),

            // Files List
            Expanded(
              child: _buildFilesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadFiles(isRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No files found'),
            const SizedBox(height: 8),
            const Text('Upload your first file to get started!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFiles(isRefresh: true),
      child: ListView.builder(
        padding:
            const EdgeInsets.only(bottom: 180), // Space for nav bar and FAB
        itemCount: _files.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _files.length) {
            // Load more indicator
            if (!_isLoadingMore) {
              _loadFiles();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final file = _files[index];
          return _buildFileCard(file);
        },
      ),
    );
  }

  Widget _buildFileCard(FileModel file) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _getFileIcon(file.fileType),
        title: Text(
          file.originalFilename,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${file.fileSizeFormatted} • ${file.uploaderName}'),
            Text('${file.department} • ${file.timeAgo}'),
            if (file.description != null && file.description!.isNotEmpty)
              Text(
                file.description!,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
                dense: true,
              ),
            ),
            if (file.uploadedBy.toString() == _authService.currentUser?.id)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'download':
                _downloadFile(file);
                break;
              case 'delete':
                _deleteFile(file);
                break;
            }
          },
        ),
        onTap: () => _downloadFile(file),
      ),
    );
  }
}
