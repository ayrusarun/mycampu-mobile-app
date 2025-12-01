import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? title;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.title,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen to transformation changes
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final newIsZoomed = scale > 1.0;
    if (newIsZoomed != _isZoomed) {
      setState(() {
        _isZoomed = newIsZoomed;
      });
    }
  }

  void _resetZoom() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });

    _animationController.forward().then((_) {
      _animationController.reset();
      _animation = null;
    });
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _resetZoom();
    } else {
      // Zoom in
      final scale = 2.0;
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity()..scale(scale),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );

      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });

      _animationController.forward().then((_) {
        _animationController.reset();
        _animation = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.title != null
            ? Text(
                widget.title!,
                style: const TextStyle(color: Colors.white),
              )
            : null,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          onInteractionEnd: (details) {
            // Auto-reset if zoomed out too much
            if (_transformationController.value.getMaxScaleOnAxis() < 1.0) {
              _resetZoom();
            }
          },
          child: GestureDetector(
            onDoubleTap: _handleDoubleTap,
            onTap: () {
              // Toggle app bar visibility on single tap
              setState(() {
                // You can add logic here to hide/show the app bar if needed
              });
            },
            child: Hero(
              tag: widget.heroTag ?? widget.imageUrl,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _isZoomed
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Text(
                  'Tap to close • Double tap to zoom',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
    );
  }
}
