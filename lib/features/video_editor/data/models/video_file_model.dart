import '../../domain/entities/video_file.dart';

class VideoFileModel extends VideoFile {
  const VideoFileModel({
    required super.path,
    required super.duration,
    required super.aspectRatio,
    required super.name,
    required super.size,
    super.thumbnailPath,
  });

  factory VideoFileModel.fromJson(Map<String, dynamic> json) {
    return VideoFileModel(
      path: json['path'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      aspectRatio: (json['aspectRatio'] as num).toDouble(),
      name: json['name'] as String,
      size: json['size'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'durationMs': duration.inMilliseconds,
      'aspectRatio': aspectRatio,
      'name': name,
      'size': size,
      'thumbnailPath': thumbnailPath,
    };
  }
}
