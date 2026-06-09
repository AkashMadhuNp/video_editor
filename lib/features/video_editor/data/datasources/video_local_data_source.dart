import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/video_file_model.dart';

abstract class VideoLocalDataSource {
  Future<VideoFileModel> pickVideo();
}

class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  final ImagePicker picker;

  VideoLocalDataSourceImpl({required this.picker});

  @override
  Future<VideoFileModel> pickVideo() async {
    final XFile? pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      throw Exception('No video selected');
    }

    final file = File(pickedFile.path);
    final size = await file.length();
    final name = pickedFile.name;

    // Use VideoPlayerController to extract duration and aspect ratio
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      final duration = controller.value.duration;
      final aspectRatio = controller.value.aspectRatio;
      await controller.dispose();

      return VideoFileModel(
        path: file.path,
        duration: duration,
        aspectRatio: aspectRatio,
        name: name,
        size: size,
      );
    } catch (e) {
      await controller.dispose();
      throw Exception('Failed to load video metadata: $e');
    }
  }
}
