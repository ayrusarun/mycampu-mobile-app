import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '_expandable_post_content.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  Post? _post;
  bool _isLoading = true;
  String? _errorMessage;

  // Comments state
  List<dynamic> _comments = [];
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (_post == null) return;
    if (_isLoadingComments) return;
    if (!refresh && !_hasMoreComments) return;

    setState(() {
      _isLoadingComments = true;
      if (refresh) {
        _currentPage = 1;
        _comments = [];
        _hasMoreComments = true;
      }
    });

    try {
      print('📝 Loading comments for post ${_post!.id}, page: $_currentPage');
      final result =
          await _postService.getComments(_post!.id, page: _currentPage);

      print('📝 Comments result: $result');

      if (result != null && !result.containsKey('error')) {
        // API returns 'comments' not 'items'
        final List<dynamic> newComments = result['comments'] ?? [];
        final int total =
            newComments.length; // Use actual count since there's no total field

        print('📝 Found ${newComments.length} comments, total: $total');

        setState(() {
          if (refresh) {
            _comments = newComments;
          } else {
            _comments.addAll(newComments);
          }
          _hasMoreComments = _comments.length < total;
          _currentPage++;
          _isLoadingComments = false;
        });
      } else {
        print('📝 Comments result is null or has error');
        setState(() {
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('❌ Error loading comments: $e');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final post = await _postService.getPostById(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
        if (post == null) {
          _errorMessage = 'Post not found';
        }
      });

      // Load comments after post is loaded
      if (post != null) {
        _loadComments(refresh: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load post: $e';
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    try {
      final result = await _postService.toggleLike(_post!.id);
      if (result != null && !result.containsKey('error')) {
        // Reload post to get updated counts
        await _loadPost();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like post: $e')),
        );
      }
    }
  }

  Future<void> _toggleIgnite() async {
    if (_post == null) return;

    try {
      final result = await _postService.toggleIgnite(_post!.id);
      if (result != null && !result.containsKey('error')) {
        // Reload post to get updated counts
        await _loadPost();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ignite post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPost,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_post == null) {
      return const Center(
        child: Text('Post not found'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(),

          // Post Content
          _buildPostContent(),

          // Post Image (if available)
          if (_post!.imageUrl != null) _buildPostImage(),

          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(),

          const SizedBox(height: 8),

          // Comments Section with modern separator
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Author Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              _post!.authorInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Author Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post!.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _post!.authorDepartment,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (_post!.hasTargeting) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _post!.targetAudienceText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Time ago
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _post!.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (_post!.postType != 'GENERAL') ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPostTypeColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _post!.postType,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (_post!.title.isNotEmpty) ...[
            Text(
              _post!.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Content
          ExpandablePostContent(content: _post!.content),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _post!.imageUrl!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Like Button
          _buildActionButton(
            icon: _post!.userHasLiked
                ? Icons.thumb_up_alt
                : Icons.thumb_up_alt_outlined,
            label: _post!.likeCount.toString(),
            onTap: _toggleLike,
            color: _post!.userHasLiked
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(width: 24),
          // Comment Button
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: _post!.commentCount.toString(),
            onTap: () {
              // Scroll to comments section
              // TODO: Implement smooth scroll to comments
            },
          ),
          const SizedBox(width: 24),
          // Ignite Button
          _buildActionButton(
            icon: _post!.userHasIgnited
                ? Icons.local_fire_department
                : Icons.local_fire_department_outlined,
            label: _post!.igniteCount.toString(),
            onTap: _toggleIgnite,
            color: _post!.userHasIgnited ? Colors.orange : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.grey.shade600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: buttonColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color != null ? buttonColor : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 8,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comments (${_post!.commentCount})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isLoadingComments && _comments.isEmpty)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Comments list
            if (_comments.isEmpty && !_isLoadingComments)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No comments yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.grey[300]),
                ),
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return _buildCommentItem(comment);
                },
              ),

            // Load more button
            if (_hasMoreComments && _comments.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed:
                        _isLoadingComments ? null : () => _loadComments(),
                    child: _isLoadingComments
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load more comments'),
                  ),
                ),
              ),

            const SizedBox(height: 100), // Space at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final authorName = comment['user_name'] ?? 'Unknown';
    final authorDepartment = comment['user_department'] ?? '';
    final content = comment['content'] ?? '';
    final createdAt = comment['created_at'] ?? '';
    final authorInitials = authorName.isNotEmpty
        ? authorName
            .split(' ')
            .map((word) => word[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    // Simple time ago calculation
    String timeAgo = 'Just now';
    try {
      final commentTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(commentTime);

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes}m ago';
      }
    } catch (e) {
      // Keep default "Just now"
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              authorInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (authorDepartment.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              authorDepartment,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPostTypeColor() {
    switch (_post!.postType) {
      case 'ANNOUNCEMENT':
        return Colors.blue;
      case 'EVENT':
        return Colors.purple;
      case 'NEWS':
        return Colors.orange;
      case 'ACHIEVEMENT':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
