import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/video_file_model.dart';

abstract class VideoLocalDataSource {
  Future<List<VideoFileModel>> pickVideos();
}

class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  final ImagePicker picker;

  VideoLocalDataSourceImpl({required this.picker});

  @override
  Future<List<VideoFileModel>> pickVideos() async {
    // In newer image_picker, pickMultipleMedia lets the user select multiple videos/images.
    final List<XFile> pickedFiles = await picker.pickMultipleMedia();

    if (pickedFiles.isEmpty) {
      throw Exception('No videos selected');
    }

    final List<VideoFileModel> videoModels = [];
    for (final pickedFile in pickedFiles) {
      final pathLower = pickedFile.path.toLowerCase();
      // Ensure we only process video files
      if (!pathLower.endsWith('.mp4') &&
          !pathLower.endsWith('.mov') &&
          !pathLower.endsWith('.mkv') &&
          !pathLower.endsWith('.avi') &&
          !pathLower.endsWith('.3gp') &&
          !pathLower.endsWith('.webm')) {
        continue;
      }

      final file = File(pickedFile.path);
      final size = await file.length();
      final name = pickedFile.name;

      final controller = VideoPlayerController.file(file);
      try {
        await controller.initialize();
        final duration = controller.value.duration;
        final aspectRatio = controller.value.aspectRatio;
        await controller.dispose();

        videoModels.add(VideoFileModel(
          path: file.path,
          duration: duration,
          aspectRatio: aspectRatio,
          name: name,
          size: size,
        ));
      } catch (e) {
        await controller.dispose();
        debugPrint('Failed to load video metadata for ${file.path}: $e');
      }
    }

    if (videoModels.isEmpty) {
      throw Exception('No valid video files selected');
    }

    return videoModels;
  }
}
