class FolderItem {
  final int? id;
  final String name;
  final String path;
  final bool isFolder;
  final String? fileType;
  final int? fileSize;
  final int? fileCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? uploaderName;
  final String? description;

  FolderItem({
    this.id,
    required this.name,
    required this.path,
    required this.isFolder,
    this.fileType,
    this.fileSize,
    this.fileCount,
    required this.createdAt,
    required this.updatedAt,
    this.uploaderName,
    this.description,
  });

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'],
      name: json['name'] ?? 'Unnamed',
      path: json['path'] ?? '/',
      isFolder: json['is_folder'] ?? true, // Default to true for folder items
      fileType: json['file_type'],
      fileSize: json['file_size'],
      fileCount: json['file_count'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      uploaderName: json['uploader_name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'is_folder': isFolder,
      'file_type': fileType,
      'file_size': fileSize,
      'file_count': fileCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'uploader_name': uploaderName,
      'description': description,
    };
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '-';
    if (fileSize! < 1024) {
      return '$fileSize B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
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

class BreadcrumbItem {
  final String name;
  final String path;

  BreadcrumbItem({
    required this.name,
    required this.path,
  });

  factory BreadcrumbItem.fromJson(Map<String, dynamic> json) {
    return BreadcrumbItem(
      name: json['name'],
      path: json['path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
    };
  }
}

class FolderContentsResponse {
  final String currentPath;
  final String? parentPath;
  final List<FolderItem> folders;
  final List<FolderItem> files;
  final int totalItems;
  final List<BreadcrumbItem> breadcrumbs;

  FolderContentsResponse({
    required this.currentPath,
    this.parentPath,
    required this.folders,
    required this.files,
    required this.totalItems,
    required this.breadcrumbs,
  });

  factory FolderContentsResponse.fromJson(Map<String, dynamic> json) {
    return FolderContentsResponse(
      currentPath: json['current_path'],
      parentPath: json['parent_path'],
      folders: (json['folders'] as List)
          .map((folder) => FolderItem.fromJson(folder))
          .toList(),
      files: (json['files'] as List)
          .map((file) => FolderItem.fromJson(file))
          .toList(),
      totalItems: json['total_items'],
      breadcrumbs: (json['breadcrumbs'] as List)
          .map((breadcrumb) => BreadcrumbItem.fromJson(breadcrumb))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_path': currentPath,
      'parent_path': parentPath,
      'folders': folders.map((f) => f.toJson()).toList(),
      'files': files.map((f) => f.toJson()).toList(),
      'total_items': totalItems,
      'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
    };
  }
}

class FolderCreate {
  final String name;
  final String parentPath;
  final String? description;

  FolderCreate({
    required this.name,
    this.parentPath = '/',
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parent_path': parentPath,
      if (description != null) 'description': description,
    };
  }
}
