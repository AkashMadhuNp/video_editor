import 'package:flutter/material.dart';

class TextOverlayWidget extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double x;
  final double y;
  final double parentWidth;
  final double parentHeight;
  final Function(double x, double y) onPositionChanged;
  final bool isEditable;
  final VoidCallback? onTap;

  const TextOverlayWidget({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.x,
    required this.y,
    required this.parentWidth,
    required this.parentHeight,
    required this.onPositionChanged,
    required this.isEditable,
    this.onTap,
  });

  @override
  State<TextOverlayWidget> createState() => _TextOverlayWidgetState();
}

class _TextOverlayWidgetState extends State<TextOverlayWidget> {
  double? _dragX;
  double? _dragY;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    // Use local drag positions if dragging, otherwise use widget properties
    final currentX = _dragX ?? widget.x;
    final currentY = _dragY ?? widget.y;

    final double maxWidth = widget.parentWidth;
    final double maxHeight = widget.parentHeight;

    // Position coordinates based on parent constraints
    final double leftPos = (currentX * maxWidth).clamp(0.0, maxWidth - 80);
    final double topPos = (currentY * maxHeight).clamp(0.0, maxHeight - 35);

    Widget textContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isEditable ? widget.color.withOpacity(0.6) : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isEditable) ...[
            const Icon(
              Icons.drag_indicator,
              color: Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Color(0xD7000000),
                  offset: Offset(1, 1),
                  blurRadius: 2,
                )
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.isEditable) {
      return Positioned(
        left: leftPos,
        top: topPos,
        child: GestureDetector(
          onTap: widget.onTap,
          child: textContent,
        ),
      );
    }

    return Positioned(
      left: leftPos,
      top: topPos,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (details) {
          setState(() {
            _dragX = widget.x;
            _dragY = widget.y;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final double currentDragX = _dragX ?? widget.x;
            final double currentDragY = _dragY ?? widget.y;
            _dragX = ((currentDragX * maxWidth + details.delta.dx) / maxWidth).clamp(0.0, 0.95);
            _dragY = ((currentDragY * maxHeight + details.delta.dy) / maxHeight).clamp(0.0, 0.95);
          });
        },
        onPanEnd: (details) {
          if (_dragX != null && _dragY != null) {
            widget.onPositionChanged(_dragX!, _dragY!);
          }
          setState(() {
            _dragX = null;
            _dragY = null;
          });
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: textContent,
        ),
      ),
    );
  }
}
