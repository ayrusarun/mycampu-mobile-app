import 'package:flutter/material.dart';

class ExpandablePostContent extends StatefulWidget {
  final String content;
  const ExpandablePostContent({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  State<ExpandablePostContent> createState() => _ExpandablePostContentState();
}

class _ExpandablePostContentState extends State<ExpandablePostContent> {
  bool _expanded = false;
  static const int _maxLines = 4;
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      fontSize: 13,
      height: 1.4,
      color: Colors.black87,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure if text overflows
        final span = TextSpan(text: widget.content, style: textStyle);
        final tp = TextPainter(
          text: span,
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);
        _isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.content,
              style: textStyle,
              maxLines: _expanded ? null : _maxLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_isOverflowing && !_expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Show more',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            if (_expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Show less',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
