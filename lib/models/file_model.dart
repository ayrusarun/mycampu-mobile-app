class FileModel {
  final int id;
  final String filename;
  final String originalFilename;
  final int fileSize;
  final String fileType;
  final String mimeType;
  final int? departmentId;
  final String? departmentName;
  final String? departmentCode;
  final int collegeId;
  final int uploadedBy;
  final Map<String, dynamic> uploadMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String uploaderName;
  final String collegeName;
  final String? description;
  final String folderPath;
  final bool isFolder;

  FileModel({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.fileSize,
    required this.fileType,
    required this.mimeType,
    this.departmentId,
    this.departmentName,
    this.departmentCode,
    required this.collegeId,
    required this.uploadedBy,
    required this.uploadMetadata,
    required this.createdAt,
    required this.updatedAt,
    required this.uploaderName,
    required this.collegeName,
    this.description,
    this.folderPath = '/',
    this.isFolder = false,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      filename: json['filename'],
      originalFilename: json['original_filename'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
      mimeType: json['mime_type'],
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      departmentCode: json['department_code'],
      collegeId: json['college_id'],
      uploadedBy: json['uploaded_by'],
      uploadMetadata: json['upload_metadata'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      uploaderName: json['uploader_name'],
      collegeName: json['college_name'],
      description: json['description'],
      folderPath: json['folder_path'] ?? '/',
      isFolder: json['is_folder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'file_type': fileType,
      'mime_type': mimeType,
      'department_id': departmentId,
      'department_name': departmentName,
      'department_code': departmentCode,
      'college_id': collegeId,
      'uploaded_by': uploadedBy,
      'upload_metadata': uploadMetadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'uploader_name': uploaderName,
      'college_name': collegeName,
      'description': description,
      'folder_path': folderPath,
      'is_folder': isFolder,
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get fileExtension {
    return originalFilename.split('.').last.toLowerCase();
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
}

class FileUploadResponse {
  final int id;
  final String filename;
  final String originalFilename;
  final int fileSize;
  final String fileType;
  final String mimeType;
  final int? departmentId;
  final String? departmentName;
  final String? departmentCode;
  final int collegeId;
  final int uploadedBy;
  final Map<String, dynamic> uploadMetadata;
  final DateTime createdAt;
  final String uploaderName;
  final String collegeName;
  final String folderPath;
  final bool isFolder;

  FileUploadResponse({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.fileSize,
    required this.fileType,
    required this.mimeType,
    this.departmentId,
    this.departmentName,
    this.departmentCode,
    required this.collegeId,
    required this.uploadedBy,
    required this.uploadMetadata,
    required this.createdAt,
    required this.uploaderName,
    required this.collegeName,
    this.folderPath = '/',
    this.isFolder = false,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      id: json['id'],
      filename: json['filename'],
      originalFilename: json['original_filename'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
      mimeType: json['mime_type'],
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      departmentCode: json['department_code'],
      collegeId: json['college_id'],
      uploadedBy: json['uploaded_by'],
      uploadMetadata: json['upload_metadata'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      uploaderName: json['uploader_name'],
      collegeName: json['college_name'],
      folderPath: json['folder_path'] ?? '/',
      isFolder: json['is_folder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'file_type': fileType,
      'mime_type': mimeType,
      'department_id': departmentId,
      'department_name': departmentName,
      'department_code': departmentCode,
      'college_id': collegeId,
      'uploaded_by': uploadedBy,
      'upload_metadata': uploadMetadata,
      'created_at': createdAt.toIso8601String(),
      'uploader_name': uploaderName,
      'college_name': collegeName,
      'folder_path': folderPath,
      'is_folder': isFolder,
    };
  }
}

class FileListResponse {
  final List<FileModel> files;
  final int totalCount;
  final int page;
  final int pageSize;

  FileListResponse({
    required this.files,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory FileListResponse.fromJson(Map<String, dynamic> json) {
    return FileListResponse(
      files: (json['files'] as List)
          .map((file) => FileModel.fromJson(file))
          .toList(),
      totalCount: json['total_count'],
      page: json['page'],
      pageSize: json['page_size'],
    );
  }
}

enum FileTypeFilter {
  all,
  document,
  presentation,
  spreadsheet,
  image,
  video,
  audio,
  archive,
  text,
  other
}

extension FileTypeFilterExtension on FileTypeFilter {
  String get displayName {
    switch (this) {
      case FileTypeFilter.all:
        return 'All Files';
      case FileTypeFilter.document:
        return 'Documents';
      case FileTypeFilter.presentation:
        return 'Presentations';
      case FileTypeFilter.spreadsheet:
        return 'Spreadsheets';
      case FileTypeFilter.image:
        return 'Images';
      case FileTypeFilter.video:
        return 'Videos';
      case FileTypeFilter.audio:
        return 'Audio';
      case FileTypeFilter.archive:
        return 'Archives';
      case FileTypeFilter.text:
        return 'Text Files';
      case FileTypeFilter.other:
        return 'Other';
    }
  }

  String get apiValue {
    switch (this) {
      case FileTypeFilter.all:
        return '';
      case FileTypeFilter.document:
        return 'DOCUMENT';
      case FileTypeFilter.presentation:
        return 'PRESENTATION';
      case FileTypeFilter.spreadsheet:
        return 'SPREADSHEET';
      case FileTypeFilter.image:
        return 'IMAGE';
      case FileTypeFilter.video:
        return 'VIDEO';
      case FileTypeFilter.audio:
        return 'AUDIO';
      case FileTypeFilter.archive:
        return 'ARCHIVE';
      case FileTypeFilter.text:
        return 'TEXT';
      case FileTypeFilter.other:
        return 'OTHER';
    }
  }
}
