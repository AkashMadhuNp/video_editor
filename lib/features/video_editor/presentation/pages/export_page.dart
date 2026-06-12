import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../blocs/video_editor/video_editor_bloc.dart';
import '../blocs/video_editor/video_editor_state.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  VideoPlayerController? _previewController;
  bool _isPreviewInitialized = false;

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  void _initializePreview(String path) {
    if (_previewController != null) return;
    
    _previewController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {
          _isPreviewInitialized = true;
        });
        _previewController!.play();
        _previewController!.setLooping(true);
      });
  }

  String _getRenderLog(double progress) {
    if (progress < 0.2) return 'Initializing canvas render pipeline...';
    if (progress < 0.5) return 'Compiling frames and applying crop constraints...';
    if (progress < 0.75) return 'Baking filter shaders on GPU...';
    if (progress < 0.9) return 'Muxing background audio track...';
    if (progress < 1.0) return 'Finalizing metadata and saving file...';
    return 'Video exported successfully!';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoEditorBloc, VideoEditorState>(
      builder: (context, state) {
        final progress = state.exportProgress;
        final status = state.exportStatus;
        final isSuccess = status == ExportStateStatus.success;
        final isFailure = status == ExportStateStatus.failure;

        if (isSuccess && state.exportedVideoPath != null) {
          _initializePreview(state.exportedVideoPath!);
        }

        // Prevent back button during active exporting
        return PopScope(
          canPop: isSuccess || isFailure,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isSuccess ? 'EXPORT COMPLETE' : 'COMPILING VIDEO'),
              automaticallyImplyLeading: isSuccess || isFailure,
            ),
            body: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (status == ExportStateStatus.exporting) ...[
                    // 1. Exporting state visualizer
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.white12,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _getRenderLog(progress),
                              key: ValueKey(_getRenderLog(progress)),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isSuccess) ...[
                    // 2. Success state visualizer
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: _isPreviewInitialized
                                      ? AspectRatio(
                                          aspectRatio: _previewController!.value.aspectRatio,
                                          child: VideoPlayer(_previewController!),
                                        )
                                      : const CircularProgressIndicator(color: AppColors.secondary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Export Complete',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Saved Path:\n${state.exportedVideoPath}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share File', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Video ready for sharing!'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                minimumSize: const Size(double.infinity, 50),
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.home_rounded),
                              label: const Text('Back to Dashboard'),
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (isFailure) ...[
                    // 3. Failure state visualizer
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
                            const SizedBox(height: 24),
                            const Text(
                              'Compilation Error',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: SelectableText(
                                state.errorMessage ?? 'Unknown compilation failure.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(200, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Dismiss & Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
