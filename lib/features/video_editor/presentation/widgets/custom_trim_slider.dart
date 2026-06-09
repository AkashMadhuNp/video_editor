import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CustomTrimSlider extends StatelessWidget {
  final Duration duration;
  final Duration start;
  final Duration end;
  final Function(Duration start, Duration end) onChange;

  const CustomTrimSlider({
    super.key,
    required this.duration,
    required this.start,
    required this.end,
    required this.onChange,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final ms = ((duration.inMilliseconds % 1000) / 100).toStringAsFixed(0);
    return '$minutes:$seconds.$ms';
  }

  @override
  Widget build(BuildContext context) {
    const double handleWidth = 16.0;
    const double sliderHeight = 60.0;
    const double minDurationMs = 1000.0; // Min 1 second video

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double trackWidth = totalWidth - (handleWidth * 2);

        final double leftFraction = start.inMilliseconds / duration.inMilliseconds;
        final double rightFraction = end.inMilliseconds / duration.inMilliseconds;

        final double leftPos = leftFraction * trackWidth;
        final double rightPos = rightFraction * trackWidth + handleWidth;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start: ${_formatDuration(start)}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Length: ${_formatDuration(end - start)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'End: ${_formatDuration(end)}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: sliderHeight,
              width: totalWidth,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Darkened unselected start region
                  Positioned(
                    left: handleWidth,
                    width: leftPos,
                    top: 4,
                    bottom: 4,
                    child: Container(color: Colors.black45),
                  ),
                  // 2. Selected region Highlight
                  Positioned(
                    left: leftPos + handleWidth,
                    width: (rightPos - leftPos) - handleWidth,
                    top: 2,
                    bottom: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        border: const Border.symmetric(
                          horizontal: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  // 3. Darkened unselected end region
                  Positioned(
                    left: rightPos + handleWidth,
                    right: handleWidth,
                    top: 4,
                    bottom: 4,
                    child: Container(color: Colors.black45),
                  ),
                  // 4. Grid lines simulation for visual look
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      10,
                      (index) => Container(
                        width: 1,
                        height: 20,
                        color: Colors.white12,
                      ),
                    ),
                  ),
                  // 5. Left Handle
                  Positioned(
                    left: leftPos,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final double newLeftPos = (leftPos + details.delta.dx).clamp(
                          0.0,
                          rightPos - handleWidth - (minDurationMs / duration.inMilliseconds * trackWidth),
                        );
                        final double fraction = newLeftPos / trackWidth;
                        final int startMs = (fraction * duration.inMilliseconds).toInt();
                        onChange(Duration(milliseconds: startMs), end);
                      },
                      child: Container(
                        width: handleWidth,
                        height: sliderHeight,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary,
                              blurRadius: 4,
                              offset: Offset(-1, 0),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                  // 6. Right Handle
                  Positioned(
                    left: rightPos,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final double newRightPos = (rightPos + details.delta.dx).clamp(
                          leftPos + handleWidth + (minDurationMs / duration.inMilliseconds * trackWidth),
                          totalWidth - handleWidth,
                        );
                        final double fraction = (newRightPos - handleWidth) / trackWidth;
                        final int endMs = (fraction * duration.inMilliseconds).toInt();
                        onChange(start, Duration(milliseconds: endMs));
                      },
                      child: Container(
                        width: handleWidth,
                        height: sliderHeight,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary,
                              blurRadius: 4,
                              offset: Offset(1, 0),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
