import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayToggle;
  final ValueChanged<Duration> onScrub;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayToggle,
    required this.onScrub,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
            onPressed: onPlayToggle,
          ),
          Text(
            _formatDuration(position),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble().clamp(
                      0.0,
                      duration.inMilliseconds.toDouble(),
                    ),
                min: 0.0,
                max: duration.inMilliseconds.toDouble() > 0 
                    ? duration.inMilliseconds.toDouble() 
                    : 1.0,
                onChanged: (newValue) {
                  onScrub(Duration(milliseconds: newValue.toInt()));
                },
              ),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
