import 'dart:math' as math;
import 'package:flutter/material.dart';

class TextOverlayWidget extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double normalizedX;
  final double normalizedY;
  final double scale;
  final double rotation;
  final double opacity;
  final double parentWidth;
  final double parentHeight;
  final Function(double normalizedX, double normalizedY) onPositionChanged;
  final bool isEditable;
  final VoidCallback? onTap;

  const TextOverlayWidget({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.normalizedX,
    required this.normalizedY,
    required this.scale,
    required this.rotation,
    required this.opacity,
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
    final currentX = _dragX ?? widget.normalizedX;
    final currentY = _dragY ?? widget.normalizedY;

    final double maxWidth = widget.parentWidth;
    final double maxHeight = widget.parentHeight;

    // 1. Calculate base scale relative to 1080p reference width
    final double scaleFactor = maxWidth / 1080.0;
    final double scaledFontSize = widget.fontSize * scaleFactor;

    // 2. Convert normalized center coordinates (-1.0 to 1.0) to pixels
    final double centerX = ((currentX + 1.0) / 2.0) * maxWidth;
    final double centerY = ((currentY + 1.0) / 2.0) * maxHeight;

    Widget textContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.0 * scaleFactor,
        vertical: 6.0 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8.0 * scaleFactor),
        border: Border.all(
          color: widget.isEditable ? widget.color.withOpacity(0.6) : Colors.white24,
          width: 1.5 * scaleFactor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isEditable) ...[
            Icon(
              Icons.drag_indicator,
              color: Colors.white70,
              size: 14.0 * scaleFactor,
            ),
            SizedBox(width: 4.0 * scaleFactor),
          ],
          Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
              fontSize: scaledFontSize,
              fontWeight: FontWeight.bold,
              height: 1.2,
              shadows: [
                Shadow(
                  color: const Color(0xD7000000),
                  offset: Offset(1.0 * scaleFactor, 1.0 * scaleFactor),
                  blurRadius: 2.0 * scaleFactor,
                )
              ],
            ),
          ),
        ],
      ),
    );

    // Apply Opacity, Rotation, and Scaling transforms
    Widget interactiveContent = Opacity(
      opacity: widget.opacity,
      child: Transform.rotate(
        angle: widget.rotation * (math.pi / 180.0),
        child: Transform.scale(
          scale: widget.scale,
          child: textContent,
        ),
      ),
    );

    if (!widget.isEditable) {
      return Positioned(
        left: centerX,
        top: centerY,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: GestureDetector(
            onTap: widget.onTap,
            child: interactiveContent,
          ),
        ),
      );
    }

    return Positioned(
      left: centerX,
      top: centerY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: widget.onTap,
          onPanStart: (details) {
            setState(() {
              _dragX = widget.normalizedX;
              _dragY = widget.normalizedY;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              final double currentDragX = _dragX ?? widget.normalizedX;
              final double currentDragY = _dragY ?? widget.normalizedY;
              _dragX = (currentDragX + (details.delta.dx * 2.0) / maxWidth).clamp(-0.9, 0.9);
              _dragY = (currentDragY + (details.delta.dy * 2.0) / maxHeight).clamp(-0.9, 0.9);
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
            child: interactiveContent,
          ),
        ),
      ),
    );
  }
}
