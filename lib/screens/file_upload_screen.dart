import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/file_model.dart';
import '../models/folder_model.dart';
import '../services/file_service.dart';
import '../services/folder_service.dart';
import '../services/auth_service.dart';
import '../config/theme_config.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();

  // Public static getter to access current folder path
  static String get currentFolderPath =>
      _FileUploadScreenState.currentFolderPath;
}

class _FileUploadScreenState extends State<FileUploadScreen>
    with TickerProviderStateMixin {
  final FileService _fileService = FileService();
  final FolderService _folderService = FolderService();
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

  // Folder navigation
  String _currentFolderPath = '/';
  FolderContentsResponse? _folderContents;
  bool _isLoadingFolder = false;

  // Static reference to current instance for accessing folder path from parent
  static _FileUploadScreenState? _instance;

  // Static getter for current folder path
  static String get currentFolderPath => _instance?._currentFolderPath ?? '/';

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _instance = this; // Set static instance
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
    _loadFolderContents(); // Load initial folder contents
  }

  @override
  void dispose() {
    _instance = null; // Clear static instance
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

  // Load folder contents
  Future<void> _loadFolderContents({String? folderPath}) async {
    setState(() {
      _isLoadingFolder = true;
      _errorMessage = null;
    });

    try {
      final pathToLoad = folderPath ?? _currentFolderPath;
      print('📁 Loading folder contents for: $pathToLoad');

      final contents = await _folderService.browseFolderContents(
        folderPath: pathToLoad,
      );

      print('📁 Browse returned currentPath: ${contents.currentPath}');
      print('📁 Before update _currentFolderPath was: $_currentFolderPath');

      setState(() {
        _folderContents = contents;
        // Only update _currentFolderPath if the API returns a valid path
        // This ensures we keep the correct path even if API returns inconsistent data
        if (contents.currentPath.isNotEmpty) {
          _currentFolderPath = contents.currentPath;
        }
      });

      print('📁 After update _currentFolderPath is now: $_currentFolderPath');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load folder: $e';
      });
    } finally {
      setState(() {
        _isLoadingFolder = false;
      });
    }
  }

  // Navigate to folder
  void _navigateToFolder(String folderPath) {
    print('📁 Navigating to folder: $folderPath');
    setState(() {
      _currentFolderPath = folderPath;
    });
    print('📁 Current folder path set to: $_currentFolderPath');
    _loadFolderContents(folderPath: folderPath);
  }

  // Go back to parent folder
  void _goToParentFolder() {
    if (_folderContents?.parentPath != null) {
      _navigateToFolder(_folderContents!.parentPath!);
    }
  }

  // Create new folder
  Future<void> _showCreateFolderDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'Enter folder name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter folder description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        await _folderService.createFolder(
          FolderCreate(
            name: nameController.text,
            parentPath: _currentFolderPath,
            description: descriptionController.text.isEmpty
                ? null
                : descriptionController.text,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload folder contents
        _loadFolderContents();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete folder dialog
  Future<void> _showDeleteFolderDialog(FolderItem folder) async {
    final hasItems = (folder.fileCount ?? 0) > 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${folder.name}"?'),
            if (hasItems) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This folder contains ${folder.fileCount} item(s). All contents will be deleted.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        setState(() {
          _isLoadingFolder = true;
        });

        await _folderService.deleteFolder(
          folderPath: folder.path,
          recursive: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder "${folder.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload folder contents
        _loadFolderContents();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoadingFolder = false;
        });
      }
    }
  }

  // Delete file dialog
  Future<void> _showDeleteFileDialog(FolderItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && item.id != null) {
      try {
        setState(() {
          _isLoadingFolder = true;
        });

        final success = await _fileService.deleteFile(item.id!);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "${item.name}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Reload folder contents
          _loadFolderContents();
        } else {
          throw Exception('Failed to delete file');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoadingFolder = false;
        });
      }
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

        print(
            '📤 About to show upload dialog. Current folder: $_currentFolderPath');
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

    print('📤 Upload dialog opened. Current folder: $_currentFolderPath');

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

                      print(
                          '📤 Starting upload to folder: $_currentFolderPath');

                      try {
                        final result = await _fileService.uploadFile(
                          file,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          folderPath: _currentFolderPath,
                        );

                        print('📤 Upload result: ${result?.toJson()}');

                        if (result != null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File uploaded successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refresh files list and folder contents
                          _loadFiles(isRefresh: true);
                          _loadFolderContents();
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
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Downloading ${file.originalFilename}...'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Download file using proper authentication
      final response = await _fileService.downloadFile(file.id);

      final fileName = file.originalFilename;
      String? savedPath;

      if (Platform.isAndroid) {
        // For Android: Use direct path to public Downloads folder
        // This works on all Android versions without permissions because:
        // - Android 9 and below: Direct file access allowed
        // - Android 10+: App can write to Downloads without permission for own files
        try {
          // Standard Android Downloads path
          final downloadsDir = Directory('/storage/emulated/0/Download');

          if (!await downloadsDir.exists()) {
            // Try alternative path
            final altDir = Directory('/storage/emulated/0/Downloads');
            if (await altDir.exists()) {
              final filePath = path.join(altDir.path, fileName);
              final downloadedFile = File(filePath);
              await downloadedFile.writeAsBytes(response.bodyBytes);
              savedPath = filePath;
            } else {
              throw Exception('Downloads folder not found');
            }
          } else {
            final filePath = path.join(downloadsDir.path, fileName);
            final downloadedFile = File(filePath);
            await downloadedFile.writeAsBytes(response.bodyBytes);
            savedPath = filePath;
          }
        } catch (e) {
          // Fallback: Use app-specific external storage
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final downloadsDir =
                Directory(path.join(externalDir.path, 'Downloads'));
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            final filePath = path.join(downloadsDir.path, fileName);
            final downloadedFile = File(filePath);
            await downloadedFile.writeAsBytes(response.bodyBytes);
            savedPath = filePath;
          } else {
            throw Exception('Could not access storage');
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, use the app documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = path.join(directory.path, fileName);
        final downloadedFile = File(filePath);
        await downloadedFile.writeAsBytes(response.bodyBytes);
        savedPath = filePath;
      } else {
        // For other platforms
        final directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final filePath = path.join(directory.path, fileName);
        final downloadedFile = File(filePath);
        await downloadedFile.writeAsBytes(response.bodyBytes);
        savedPath = filePath;
      }

      if (savedPath == null) {
        throw Exception('Failed to save file');
      }

      // Show success message
      String displayMessage = 'File downloaded successfully!';
      String displayPath = '';

      if (Platform.isAndroid) {
        if (savedPath.contains('/storage/emulated/0/Download')) {
          displayMessage = 'Downloaded to Downloads folder';
          displayPath = fileName;
        } else {
          displayMessage = 'Downloaded to app storage';
          displayPath =
              'File Manager → Android → data → MyCampus → files → Downloads';
        }
      } else if (Platform.isIOS) {
        displayMessage = 'Downloaded to Files';
        displayPath = 'Files app → On My iPhone → MyCampus';
      } else {
        displayPath = savedPath;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayMessage,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (displayPath.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  displayPath,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
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

            // Breadcrumb Navigation
            if (_folderContents != null) _buildBreadcrumbs(),

            // Action Buttons (Create Folder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCreateFolderDialog,
                    icon: const Icon(Icons.create_new_folder, size: 18),
                    label: const Text('New Folder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_folderContents != null)
                    Text(
                      '${_folderContents!.totalItems} items',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            // Files List
            Expanded(
              child: _buildFilesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    if (_folderContents == null || _folderContents!.breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.folder, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 8),
            for (int i = 0; i < _folderContents!.breadcrumbs.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              GestureDetector(
                onTap: () => _navigateToFolder(
                  _folderContents!.breadcrumbs[i].path,
                ),
                child: Text(
                  _folderContents!.breadcrumbs[i].name,
                  style: TextStyle(
                    color: i == _folderContents!.breadcrumbs.length - 1
                        ? AppTheme.primaryColor
                        : Colors.grey.shade700,
                    fontWeight: i == _folderContents!.breadcrumbs.length - 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    if (_isLoading || _isLoadingFolder) {
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
                onPressed: () {
                  _loadFiles(isRefresh: true);
                  _loadFolderContents();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Combine folders and files
    final folders = _folderContents?.folders ?? [];
    final files = _folderContents?.files ?? [];
    final totalItems = folders.length + files.length;

    if (totalItems == 0 && _files.isEmpty) {
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
      onRefresh: () async {
        await _loadFiles(isRefresh: true);
        await _loadFolderContents();
      },
      child: ListView.builder(
        padding:
            const EdgeInsets.only(bottom: 180), // Space for nav bar and FAB
        itemCount: folders.length + files.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show folders first
          if (index < folders.length) {
            return _buildFolderCard(folders[index]);
          }

          // Then show files
          final fileIndex = index - folders.length;
          if (fileIndex < files.length) {
            return _buildFolderItemCard(files[fileIndex]);
          }

          // Load more indicator for paginated files
          if (!_isLoadingMore) {
            // Schedule load for next frame to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadFiles();
            });
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(FolderItem folder) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.folder,
          color: AppTheme.primaryColor,
          size: 40,
        ),
        title: Text(
          folder.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (folder.fileCount != null)
              Text('${folder.fileCount} items • ${folder.timeAgo}'),
            if (folder.description != null && folder.description!.isNotEmpty)
              Text(
                folder.description!,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.folder_open, size: 20),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'open') {
              _navigateToFolder(folder.path);
            } else if (value == 'delete') {
              _showDeleteFolderDialog(folder);
            }
          },
        ),
        onTap: () => _navigateToFolder(folder.path),
      ),
    );
  }

  Widget _buildFolderItemCard(FolderItem item) {
    // Convert FolderItem to FileModel for compatibility
    // This is a workaround until we refactor the download/details methods
    final fileModel = _folderItemToFileModel(item);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _getFileIcon(item.name),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${item.fileSizeFormatted} • ${item.uploaderName ?? 'Unknown'}'),
            Text(item.timeAgo),
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'download' && fileModel != null) {
              _downloadFile(fileModel);
            } else if (value == 'delete') {
              _showDeleteFileDialog(item);
            }
          },
        ),
        onTap: () {
          // For now, just show a simple info dialog
          // Could be enhanced later with full file details
          if (fileModel != null) {
            _downloadFile(fileModel);
          }
        },
      ),
    );
  }

  // Helper method to convert FolderItem to FileModel
  FileModel? _folderItemToFileModel(FolderItem item) {
    if (item.id == null) return null;

    // This is a temporary solution - ideally we should refactor to use FolderItem directly
    try {
      return FileModel(
        id: item.id!,
        filename: item.name,
        originalFilename: item.name,
        fileSize: item.fileSize ?? 0,
        fileType: item.fileType ?? 'OTHER',
        mimeType: 'application/octet-stream',
        department: 'Unknown',
        collegeId: 0,
        uploadedBy: 0,
        uploadMetadata: {},
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        uploaderName: item.uploaderName ?? 'Unknown',
        collegeName: 'Unknown',
        description: item.description,
        folderPath: item.path,
        isFolder: item.isFolder,
      );
    } catch (e) {
      print('Error converting FolderItem to FileModel: $e');
      return null;
    }
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
