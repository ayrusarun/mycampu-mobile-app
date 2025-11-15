import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Navigation bar with notch
          CustomPaint(
            painter: _NavBarPainter(color: AppTheme.primaryColor),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.psychology_rounded,
                    label: 'AI Search',
                  ),
                  const SizedBox(width: 50), // Space for FAB
                  _buildNavItem(
                    index: 3,
                    icon: Icons.folder_rounded,
                    label: 'Files',
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.emoji_events_rounded,
                    label: 'Rewards',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return Flexible(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 10 : 6,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// Custom painter for navigation bar with notch
class _NavBarPainter extends CustomPainter {
  final Color color;

  _NavBarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();

    // Start from bottom left with reduced radius
    path.moveTo(0, size.height - 15);
    path.quadraticBezierTo(0, size.height, 15, size.height);

    // Bottom to right
    path.lineTo(size.width - 15, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 15);

    // Right side going up
    path.lineTo(size.width, 15);
    path.quadraticBezierTo(size.width, 0, size.width - 15, 0);

    // Top right to center (before notch)
    path.lineTo(size.width / 2 + 45, 0);

    // Notch for FAB - creating a circular cutout at the top
    path.quadraticBezierTo(
      size.width / 2 + 42,
      0,
      size.width / 2 + 38,
      8,
    );
    path.quadraticBezierTo(
      size.width / 2 + 25,
      30,
      size.width / 2,
      30,
    );
    path.quadraticBezierTo(
      size.width / 2 - 25,
      30,
      size.width / 2 - 38,
      8,
    );
    path.quadraticBezierTo(
      size.width / 2 - 42,
      0,
      size.width / 2 - 45,
      0,
    );

    // Top center to left
    path.lineTo(15, 0);
    path.quadraticBezierTo(0, 0, 0, 15);

    // Left side
    path.lineTo(0, size.height - 15);

    path.close();

    // Draw shadow
    canvas.drawPath(path, shadowPaint);

    // Draw main shape
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NavBarPainter oldDelegate) => color != oldDelegate.color;
}
