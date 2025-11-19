import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_model.dart';
import '../config/theme_config.dart';

class NewsDetailScreen extends StatefulWidget {
  final List<NewsArticle> articles;
  final int initialIndex;

  const NewsDetailScreen({
    super.key,
    required this.articles,
    this.initialIndex = 0,
  });

  // Static method to show as modal with optimized animation
  static void show(
      BuildContext context, List<NewsArticle> articles, int initialIndex) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'News Detail',
      barrierColor: Colors.black54,
      transitionDuration:
          const Duration(milliseconds: 200), // Faster for real devices
      pageBuilder: (context, animation, secondaryAnimation) {
        return NewsDetailScreen(
          articles: articles,
          initialIndex: initialIndex,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Optimized scale + fade for smooth performance on physical devices
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.85, // Start closer to final size (less jarring)
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut, // Simpler curve, no bounce
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openNewsUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final result = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!result) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          height: screenHeight * 0.85,
          width: screenWidth * 0.95,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000), // Simplified shadow
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content with PageView
              Padding(
                padding: const EdgeInsets.only(
                    top: 60, bottom: 80), // Space for header and button
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: widget.articles.length,
                  itemBuilder: (context, index) {
                    final article = widget.articles[index];
                    return _buildNewsDetail(article);
                  },
                ),
              ),

              // Header with primary color
              Container(
                decoration: const BoxDecoration(
                  color:
                      AppTheme.primaryColor, // Solid color instead of gradient
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),

                    // Header row with close button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Close button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Bottom fixed Read Full Article button with carousel dots
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 6,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Carousel dots indicator
                      if (widget.articles.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.articles.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: index == _currentIndex ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == _currentIndex
                                      ? AppTheme.primaryColor
                                      : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Read Full Article button
                      _buildReadFullArticleButton(),
                    ],
                  ),
                ),
              ),

              // Swipe hint (only show on first article)
              if (_currentIndex == 0 && widget.articles.length > 1)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Swipe to see more',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadFullArticleButton() {
    final article = widget.articles[_currentIndex];
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openNewsUrl(article.url),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 1, // Reduced elevation
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 16),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Read Full Article',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsDetail(NewsArticle article) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article image
          if (article.image != null && article.image!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 180,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  article.image!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Color(0xFF9E9E9E),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Source and date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDate(article.publishedAt),
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            article.title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            overflow: TextOverflow.fade,
            maxLines: 3,
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            article.description,
            style: const TextStyle(
              color: Color(0xFF616161),
              fontSize: 13,
              height: 1.4,
            ),
            overflow: TextOverflow.fade,
          ),

          const SizedBox(height: 14),

          // Content
          if (article.content.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                article.content,
                style: const TextStyle(
                  color: Color(0xFF424242),
                  fontSize: 12,
                  height: 1.5,
                ),
                overflow: TextOverflow.fade,
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
