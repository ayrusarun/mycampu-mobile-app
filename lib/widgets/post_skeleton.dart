import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import 'shimmer_widget.dart';

/// Post skeleton - loading placeholder that matches the actual post card layout
/// Shows shimmer effect while posts are loading, like YouTube/Instagram
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header (avatar + author info)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar shimmer
              const ShimmerCircle(size: 50),
              const SizedBox(width: 12),

              // Author info shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLine(
                      width: 120,
                      height: 14,
                    ),
                    const SizedBox(height: 6),
                    // Department name - can wrap to multiple lines
                    ShimmerLine(
                      width: double.infinity,
                      height: 12,
                    ),
                    const SizedBox(height: 4),
                    // Second line for long department names
                    ShimmerLine(
                      width: 100,
                      height: 12,
                    ),
                  ],
                ),
              ),

              // Post type badge shimmer
              ShimmerBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Post title shimmer
          ShimmerLine(
            width: double.infinity,
            height: 16,
          ),
          const SizedBox(height: 8),
          ShimmerLine(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 16,
          ),

          const SizedBox(height: 12),

          // Post content shimmer (multiple lines)
          ShimmerLine(
            width: double.infinity,
            height: 14,
          ),
          const SizedBox(height: 6),
          ShimmerLine(
            width: double.infinity,
            height: 14,
          ),
          const SizedBox(height: 6),
          ShimmerLine(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 14,
          ),

          const SizedBox(height: 16),

          // Post image placeholder shimmer
          ShimmerBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
          ),

          const SizedBox(height: 16),

          // Action buttons shimmer
          Row(
            children: [
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 24),
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 24),
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simplified post skeleton without image - for faster loading perception
class PostSkeletonCompact extends StatelessWidget {
  const PostSkeletonCompact({super.key});

  @override
  Widget build(BuildContext context) {
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
              const ShimmerCircle(size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLine(width: 120, height: 14),
                    const SizedBox(height: 6),
                    // Department name - can wrap to multiple lines
                    ShimmerLine(width: double.infinity, height: 12),
                    const SizedBox(height: 4),
                    ShimmerLine(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content shimmer
          ShimmerLine(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          ShimmerLine(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          ShimmerLine(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 14,
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 24),
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 24),
              ShimmerBox(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grid of post skeletons for initial loading state
class PostSkeletonList extends StatelessWidget {
  final int itemCount;
  final bool showImages;

  const PostSkeletonList({
    super.key,
    this.itemCount = 3,
    this.showImages = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child:
              showImages ? const PostSkeleton() : const PostSkeletonCompact(),
        );
      },
    );
  }
}
