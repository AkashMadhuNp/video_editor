import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AspectRatioItem {
  final String label;
  final double? ratio;
  final double width;
  final double height;

  const AspectRatioItem({
    required this.label,
    required this.ratio,
    required this.width,
    required this.height,
  });
}

class RatioSelector extends StatelessWidget {
  final double? selectedRatio;
  final ValueChanged<double?> onRatioChanged;

  const RatioSelector({
    super.key,
    required this.selectedRatio,
    required this.onRatioChanged,
  });

  static const List<AspectRatioItem> items = [
    AspectRatioItem(label: 'Free', ratio: null, width: 24, height: 24),
    AspectRatioItem(label: '1:1 Square', ratio: 1.0, width: 20, height: 20),
    AspectRatioItem(label: '16:9 Cinema', ratio: 16 / 9, width: 28, height: 16),
    AspectRatioItem(label: '9:16 Portrait', ratio: 9 / 16, width: 16, height: 28),
    AspectRatioItem(label: '4:3 Classic', ratio: 4 / 3, width: 24, height: 18),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Aspect Ratio / Canvas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedRatio == item.ratio;

              return GestureDetector(
                onTap: () => onRatioChanged(item.ratio),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white10,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Container(
                          width: item.width,
                          height: item.height,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(2),
                            color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
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
