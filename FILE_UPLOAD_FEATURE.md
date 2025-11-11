# File Upload Feature Documentation

## Overview

The file upload feature has been implemented in the MyCampus Mobile App, replacing the chat functionality. Users can now manage and share files within their college community.

## Features Implemented

### 1. File Management Screen
- **Location**: Accessible via the "Files" tab in the bottom navigation (4th icon)
- **Tabs**: 
  - All Files: View all uploaded files
  - My Dept: Filter files by user's department
  - My Uploads: View files uploaded by the current user

### 2. File Operations
- **Upload**: Tap the floating action button (📄+) to upload files
- **Download**: Tap on any file to download/open it
- **Delete**: Access via file options menu (for files uploaded by the user)
- **Search**: Use the search bar to find specific files
- **Filter**: Filter files by type (Documents, Images, Videos, etc.)

### 3. File Information Display
- Original filename
- File size (formatted)
- Uploader name and department
- Upload timestamp (relative time)
- File description (optional)
- File type indicators with color coding

### 4. API Integration
- Complete integration with backend file API endpoints:
  - `POST /files/upload` - File upload with multipart form data
  - `GET /files/` - Paginated file listing with filters
  - `GET /files/{id}` - Get specific file details
  - `GET /files/{id}/download` - Download file
  - `DELETE /files/{id}` - Delete file (owner only)
  - `PUT /files/{id}` - Update file description
  - `GET /files/departments/list` - Get available departments
  - `GET /files/stats/summary` - File statistics

### 5. File Type Support
The system supports various file types with appropriate icons:
- Documents (Word, PDF, etc.) - Blue icon
- Presentations (PowerPoint, etc.) - Orange icon  
- Spreadsheets (Excel, etc.) - Green icon
- Images (PNG, JPG, etc.) - Purple icon
- Videos (MP4, etc.) - Red icon
- Audio (MP3, etc.) - Pink icon
- Archives (ZIP, etc.) - Brown icon
- Text files - Grey icon
- Other files - Default grey icon

## Technical Implementation

### Models
- **FileModel**: Complete file information with formatting helpers
- **FileUploadResponse**: Response from upload API
- **FileListResponse**: Paginated file list response
- **FileTypeFilter**: Enum for file type filtering

### Services
- **FileService**: Complete API integration service with:
  - Authentication headers
  - Error handling
  - Session management
  - Multipart file upload
  - URL generation for downloads

### UI Components
- **FileUploadScreen**: Main file management interface
- **Tabbed interface**: Organized file browsing
- **Search and filter**: Enhanced file discovery
- **Responsive design**: Works on various screen sizes
- **Material Design**: Consistent with app theme

### Security & Permissions
- **Authentication**: All API calls require valid JWT token
- **Authorization**: Users can only delete their own files
- **Department filtering**: Respects user's department context
- **Session management**: Automatic logout on token expiry

## Current Status

### ✅ Completed
- File listing and filtering
- Department-based filtering
- Search functionality
- File information display
- Download functionality
- Delete functionality (for own files)
- API service integration
- Error handling
- UI/UX implementation
- Authentication integration

### 🚧 In Progress
- File upload functionality (UI ready, needs compatible file picker library)
- File preview functionality
- Bulk operations

### 📋 Future Enhancements
- File sharing with specific users
- File categories and tags
- File versioning
- Collaborative editing
- File comments and reviews
- Advanced search filters
- File activity tracking

## Usage Instructions

1. **Navigate to Files**: Tap the folder icon in the bottom navigation
2. **Browse Files**: 
   - Use tabs to switch between All Files, My Dept, and My Uploads
   - Scroll to load more files automatically
3. **Search Files**: Use the search bar to find specific files
4. **Filter by Type**: Tap the filter icon to filter by file type
5. **Upload Files**: Tap the + button (currently shows placeholder)
6. **Download Files**: Tap on any file to download/open it
7. **Manage Files**: Use the options menu (⋮) to delete your own files

## API Endpoints Documentation

All endpoints are relative to the base URL and require authentication headers.

### File Upload
```
POST /files/upload
Content-Type: multipart/form-data
Body: 
- file: File binary data
- description: Optional file description
```

### File Listing
```
GET /files/?page=1&page_size=20&department=CS&file_type=DOCUMENT&search=query
```

### File Download
```
GET /files/{id}/download?token={jwt_token}
```

### File Management
```
GET /files/{id}          # Get file details
PUT /files/{id}          # Update file description  
DELETE /files/{id}       # Delete file (owner only)
```

### Utility Endpoints
```
GET /files/departments/list    # Get available departments
GET /files/stats/summary       # Get file statistics
```

## Dependencies

### Required
- `http: ^1.1.0` - API communication
- `url_launcher: ^6.2.1` - File opening/downloading

### Optional (for future file upload)
- `file_picker` - File selection (currently disabled due to compatibility)
- `permission_handler` - File system permissions

## Error Handling

The app includes comprehensive error handling:
- Network connectivity issues
- Authentication failures (automatic logout)
- API errors with user-friendly messages
- File access permissions
- Invalid file operations

## Security Considerations

- All file operations require valid authentication
- Files are scoped to the user's college/tenant
- Department-based access control
- Secure file download URLs with token validation
- Automatic session cleanup on authentication failure