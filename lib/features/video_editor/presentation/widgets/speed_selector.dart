import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SpeedSelector extends StatelessWidget {
  final double selectedSpeed;
  final ValueChanged<double> onSpeedChanged;
  final Duration sourceDuration;

  const SpeedSelector({
    super.key,
    required this.selectedSpeed,
    required this.onSpeedChanged,
    required this.sourceDuration,
  });

  static const List<double> presetSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];

  @override
  Widget build(BuildContext context) {
    // Calculate new duration based on speed
    final newDurationMs = (sourceDuration.inMilliseconds / selectedSpeed).round();
    final newDuration = Duration(milliseconds: newDurationMs);

    final originalSeconds = sourceDuration.inMilliseconds / 1000.0;
    final newSeconds = newDuration.inMilliseconds / 1000.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header/Duration Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Speed Control',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Duration change comparison badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: AppColors.primary.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${originalSeconds.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white30,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${newSeconds.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Custom Continuous Speed Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                '${selectedSpeed.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.12),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: selectedSpeed.clamp(0.25, 4.0),
                    min: 0.25,
                    max: 4.0,
                    onChanged: (val) {
                      // Round to 2 decimal places
                      final double rounded = (val * 20).round() / 20.0;
                      onSpeedChanged(rounded);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Preset Quick Buttons
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: presetSpeeds.length,
            itemBuilder: (context, index) {
              final speed = presetSpeeds[index];
              final isSelected = (selectedSpeed - speed).abs() < 0.01;

              return GestureDetector(
                onTap: () => onSpeedChanged(speed),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white10,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
