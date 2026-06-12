import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/timeline_project.dart';
import 'ratio_selector.dart';

class TimelineTools extends StatelessWidget {
  final String? selectedItemId;
  final TrackType? selectedItemType;
  final Duration playheadPosition;
  
  // Callbacks
  final VoidCallback? onSplit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final Function(String text) onAddText;
  final VoidCallback? onAddAudio;
  final double? currentRatio;
  final ValueChanged<double?> onRatioChanged;

  // New property sheet callbacks
  final VoidCallback? onOpenFilter;
  final VoidCallback? onOpenSpeed;
  final VoidCallback? onOpenVolume;
  final VoidCallback? onOpenTextSettings;
  final VoidCallback? onAddVideo;

  const TimelineTools({
    super.key,
    required this.selectedItemId,
    required this.selectedItemType,
    required this.playheadPosition,
    required this.onSplit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onAddText,
    required this.onAddAudio,
    required this.currentRatio,
    required this.onRatioChanged,
    this.onOpenFilter,
    this.onOpenSpeed,
    this.onOpenVolume,
    this.onOpenTextSettings,
    this.onAddVideo,
  });

  void _showAddTextDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text Clip', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter text overlay...',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                onAddText(textController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  void _showCanvasBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatioSelector(
                selectedRatio: currentRatio,
                onRatioChanged: (ratio) {
                  onRatioChanged(ratio);
                  Navigator.of(bottomSheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedItemId != null;

    // Build the lists of widgets depending on what track item type is selected
    List<Widget> toolsList = [];

    if (!hasSelection || selectedItemType == null) {
      // 1. GLOBAL TOOLS (No selection)
      toolsList = [
        _buildToolButton(
          icon: Icons.add_to_photos_rounded,
          label: 'Add Video',
          onPressed: onAddVideo,
        ),
        _buildToolButton(
          icon: Icons.text_fields_rounded,
          label: 'Text',
          onPressed: () => _showAddTextDialog(context),
        ),
        _buildToolButton(
          icon: Icons.music_note_rounded,
          label: 'Audio',
          onPressed: onAddAudio,
        ),
        _buildToolButton(
          icon: Icons.aspect_ratio_rounded,
          label: 'Canvas',
          onPressed: () => _showCanvasBottomSheet(context),
        ),
      ];
    } else {
      switch (selectedItemType!) {
        case TrackType.video:
          // 2. VIDEO CLIP SELECTED TOOLS
          toolsList = [
            _buildToolButton(
              icon: Icons.content_cut_rounded,
              label: 'Split',
              onPressed: onSplit,
            ),
            _buildToolButton(
              icon: Icons.speed_rounded,
              label: 'Speed',
              onPressed: onOpenSpeed,
            ),
            _buildToolButton(
              icon: Icons.volume_up_rounded,
              label: 'Volume',
              onPressed: onOpenVolume,
            ),
            _buildToolButton(
              icon: Icons.color_lens_rounded,
              label: 'Filters',
              onPressed: onOpenFilter,
            ),
            _buildToolButton(
              icon: Icons.copy_rounded,
              label: 'Duplicate',
              onPressed: onDuplicate,
            ),
            _buildToolButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onPressed: onDelete,
              color: AppColors.error,
            ),
            _buildToolButton(
              icon: Icons.add_to_photos_rounded,
              label: 'Add Video',
              onPressed: onAddVideo,
            ),
            _buildToolButton(
              icon: Icons.text_fields_rounded,
              label: 'Add Text',
              onPressed: () => _showAddTextDialog(context),
            ),
            _buildToolButton(
              icon: Icons.music_note_rounded,
              label: 'Add Audio',
              onPressed: onAddAudio,
            ),
            _buildToolButton(
              icon: Icons.aspect_ratio_rounded,
              label: 'Canvas',
              onPressed: () => _showCanvasBottomSheet(context),
            ),
          ];
          break;
        case TrackType.text:
          // 3. TEXT CLIP SELECTED TOOLS
          toolsList = [
            _buildToolButton(
              icon: Icons.edit_rounded,
              label: 'Edit Text',
              onPressed: onOpenTextSettings,
            ),
            _buildToolButton(
              icon: Icons.palette_rounded,
              label: 'Style',
              onPressed: onOpenTextSettings,
            ),
            _buildToolButton(
              icon: Icons.copy_rounded,
              label: 'Duplicate',
              onPressed: onDuplicate,
            ),
            _buildToolButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onPressed: onDelete,
              color: AppColors.error,
            ),
            _buildToolButton(
              icon: Icons.text_fields_rounded,
              label: 'Add Text',
              onPressed: () => _showAddTextDialog(context),
            ),
            _buildToolButton(
              icon: Icons.music_note_rounded,
              label: 'Add Audio',
              onPressed: onAddAudio,
            ),
            _buildToolButton(
              icon: Icons.aspect_ratio_rounded,
              label: 'Canvas',
              onPressed: () => _showCanvasBottomSheet(context),
            ),
          ];
          break;
        case TrackType.audio:
          // 4. AUDIO CLIP SELECTED TOOLS
          toolsList = [
            _buildToolButton(
              icon: Icons.content_cut_rounded,
              label: 'Split',
              onPressed: onSplit,
            ),
            _buildToolButton(
              icon: Icons.volume_up_rounded,
              label: 'Volume',
              onPressed: onOpenVolume,
            ),
            _buildToolButton(
              icon: Icons.copy_rounded,
              label: 'Duplicate',
              onPressed: onDuplicate,
            ),
            _buildToolButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onPressed: onDelete,
              color: AppColors.error,
            ),
            _buildToolButton(
              icon: Icons.text_fields_rounded,
              label: 'Add Text',
              onPressed: () => _showAddTextDialog(context),
            ),
            _buildToolButton(
              icon: Icons.music_note_rounded,
              label: 'Add Audio',
              onPressed: onAddAudio,
            ),
            _buildToolButton(
              icon: Icons.aspect_ratio_rounded,
              label: 'Canvas',
              onPressed: () => _showCanvasBottomSheet(context),
            ),
          ];
          break;
      }
    }

    return Container(
      color: AppColors.surface,
      width: double.infinity,
      height: 72,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: toolsList,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final bool enabled = onPressed != null;
    final Color buttonColor = enabled
        ? (color ?? AppColors.textPrimary)
        : AppColors.textMuted;

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: buttonColor,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: buttonColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
