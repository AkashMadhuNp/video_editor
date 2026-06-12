import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/timeline_project.dart';

class TimelineWidget extends StatefulWidget {
  final TimelineProject project;
  final Duration playheadPosition;
  final String? selectedItemId;
  final Function(Duration position) onScrub;
  final Function(String? itemId) onSelectItem;
  final Function(String itemId, Duration start, Duration duration) onTrimItem;

  const TimelineWidget({
    super.key,
    required this.project,
    required this.playheadPosition,
    required this.selectedItemId,
    required this.onScrub,
    required this.onSelectItem,
    required this.onTrimItem,
  });

  static double calculateHeight(TimelineProject project) {
    double totalHeight = 30.0; // Ruler height
    
    final hasText = project.tracks.any((t) => t.type == TrackType.text);
    final hasVideo = project.tracks.any((t) => t.type == TrackType.video);
    final hasAudio = project.tracks.any((t) => t.type == TrackType.audio);

    if (hasText) {
      totalHeight += 36.0;
    }
    if (hasVideo) {
      totalHeight += 48.0;
      if (hasText) totalHeight += 6.0; // Spacer
    }
    if (hasAudio) {
      totalHeight += 36.0;
      if (hasVideo || hasText) totalHeight += 6.0; // Spacer
    }
    
    totalHeight += 12.0; // Bottom spacing padding
    return totalHeight;
  }

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;
  final double _pixelsPerSecond = 40.0; // Scale of timeline

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPlayheadToScroll();
    });
  }

  @override
  void didUpdateWidget(covariant TimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto scroll timeline when player updates progress (unless user is scrubbing/dragging)
    if (!_isUserScrolling && oldWidget.playheadPosition != widget.playheadPosition) {
      _syncPlayheadToScroll();
    }
  }

  void _syncPlayheadToScroll() {
    if (!_scrollController.hasClients) return;
    final double targetOffset = (widget.playheadPosition.inMilliseconds / 1000) * _pixelsPerSecond;
    _scrollController.jumpTo(targetOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double halfWidth = width / 2;

        final double contentWidth = (widget.project.duration.inMilliseconds / 1000) * _pixelsPerSecond;

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Scrollable multi-track timeline content
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  if (notification.dragDetails != null) {
                    _isUserScrolling = true;
                  }
                } else if (notification is ScrollUpdateNotification) {
                  if (_isUserScrolling) {
                    final double scrollOffset = _scrollController.offset;
                    final double seconds = scrollOffset / _pixelsPerSecond;
                    final int ms = (seconds * 1000).toInt().clamp(0, widget.project.duration.inMilliseconds);
                    widget.onScrub(Duration(milliseconds: ms));
                  }
                } else if (notification is ScrollEndNotification) {
                  _isUserScrolling = false;
                }
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Start padding to allow starting playhead alignment
                    SizedBox(width: halfWidth),
                    // Timeline tracks block
                    Container(
                      width: contentWidth,
                      color: Colors.white.withOpacity(0.01),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. Time Ruler tick marks row
                          SizedBox(
                            height: 30,
                            width: contentWidth,
                            child: CustomPaint(
                              painter: TimeRulerPainter(
                                duration: widget.project.duration,
                                pixelsPerSecond: _pixelsPerSecond,
                              ),
                            ),
                          ),
                          // B. Track Lanes (Text, Video, Audio)
                          _buildTrackLane(TrackType.text, 'Text overlay track', contentWidth),
                          const SizedBox(height: 6),
                          _buildTrackLane(TrackType.video, 'Main video track', contentWidth),
                          const SizedBox(height: 6),
                          _buildTrackLane(TrackType.audio, 'Background audio track', contentWidth),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    // End padding to scroll last frame to the playhead
                    SizedBox(width: halfWidth),
                  ],
                ),
              ),
            ),
            
            // 2. Playhead Center Guideline (Static Red neon indicator)
            Positioned(
              left: halfWidth,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            
            // 3. Playhead Handle Cap at the top of ruler
            Positioned(
              left: halfWidth - 6,
              top: 24,
              child: Container(
                width: 14,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackLane(TrackType type, String name, double width) {
    // Locate the track
    final track = widget.project.tracks.firstWhere(
      (t) => t.type == type,
      orElse: () => TimelineTrack(id: 'temp', type: type, items: const []),
    );

    double height = type == TrackType.video ? 48.0 : 36.0;
    Color laneColor = Colors.white.withOpacity(0.02);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: laneColor,
        border: const Border.symmetric(
          horizontal: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: Stack(
        children: track.items.map((item) => _buildTimelineItem(item, type, height)).toList(),
      ),
    );
  }

  Widget _buildTimelineItem(TimelineItem item, TrackType type, double trackHeight) {
    final double left = (item.start.inMilliseconds / 1000) * _pixelsPerSecond;
    final double width = (item.duration.inMilliseconds / 1000) * _pixelsPerSecond;
    final isSelected = widget.selectedItemId == item.id;

    Color itemColor;
    IconData icon;
    switch (type) {
      case TrackType.video:
        itemColor = AppColors.secondary;
        icon = Icons.video_collection_rounded;
        break;
      case TrackType.audio:
        itemColor = AppColors.success;
        icon = Icons.audiotrack_rounded;
        break;
      case TrackType.text:
        itemColor = AppColors.primary;
        icon = Icons.text_fields_rounded;
        break;
    }

    return Positioned(
      left: left,
      width: width,
      height: trackHeight,
      child: GestureDetector(
        onTap: () => widget.onSelectItem(item.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(isSelected ? 0.4 : 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.white : itemColor.withOpacity(0.5),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inside Clip visuals
              (() {
                String nameSuffix = '';
                IconData? volumeStateIcon;

                if (type == TrackType.video) {
                  final double vol = (item.properties['volume'] as num? ?? 1.0).toDouble();
                  if (vol == 0.0) {
                    volumeStateIcon = Icons.volume_off_rounded;
                  } else if (vol < 1.0) {
                    nameSuffix = ' (${(vol * 100).toInt()}%)';
                  }
                } else if (type == TrackType.audio) {
                  final double vol = (item.properties['volume'] as num? ?? 0.5).toDouble();
                  if (vol == 0.0) {
                    volumeStateIcon = Icons.volume_off_rounded;
                  } else if (vol != 0.5) {
                    nameSuffix = ' (${(vol * 100).toInt()}%)';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(icon, size: 14, color: isSelected ? Colors.white : itemColor),
                      const SizedBox(width: 4),
                      if (volumeStateIcon != null) ...[
                        Icon(volumeStateIcon, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          '${item.name}$nameSuffix',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              })(),

              // Left Trim Handle (only visible and interactive if selected)
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 14,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final double deltaSeconds = details.delta.dx / _pixelsPerSecond;
                      final int deltaMs = (deltaSeconds * 1000).toInt();

                      final newStartMs = (item.start.inMilliseconds + deltaMs).clamp(0, item.start.inMilliseconds + item.duration.inMilliseconds - 1000);
                      final newDurationMs = item.duration.inMilliseconds - (newStartMs - item.start.inMilliseconds);

                      if (newDurationMs >= 1000) {
                        widget.onTrimItem(
                          item.id,
                          Duration(milliseconds: newStartMs),
                          Duration(milliseconds: newDurationMs),
                        );
                      }
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, size: 12, color: Colors.black),
                    ),
                  ),
                ),

              // Right Trim Handle (only visible and interactive if selected)
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 14,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final double deltaSeconds = details.delta.dx / _pixelsPerSecond;
                      final int deltaMs = (deltaSeconds * 1000).toInt();

                      final newDurationMs = (item.duration.inMilliseconds + deltaMs).clamp(1000, 3600 * 1000);

                      widget.onTrimItem(
                        item.id,
                        item.start,
                        Duration(milliseconds: newDurationMs),
                      );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 12, color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeRulerPainter extends CustomPainter {
  final Duration duration;
  final double pixelsPerSecond;

  TimeRulerPainter({required this.duration, required this.pixelsPerSecond});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final totalSeconds = duration.inSeconds + 1;
    for (int i = 0; i < totalSeconds; i++) {
      final x = i * pixelsPerSecond;
      
      // Draw tick marks and labels every 5 seconds
      if (i % 5 == 0) {
        canvas.drawLine(Offset(x, 15), Offset(x, 30), paint..color = Colors.white54);
        
        final minutes = i ~/ 60;
        final seconds = i % 60;
        final timeText = '$minutes:${seconds.toString().padLeft(2, '0')}';
        
        textPainter.text = TextSpan(
          text: timeText,
          style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 4, 15));
      } else {
        canvas.drawLine(Offset(x, 22), Offset(x, 30), paint..color = Colors.white24);
      }
    }
  }

  @override
  bool shouldRepaint(TimeRulerPainter oldDelegate) =>
      oldDelegate.duration != duration || oldDelegate.pixelsPerSecond != pixelsPerSecond;
}
