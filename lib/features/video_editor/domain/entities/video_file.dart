import 'package:equatable/equatable.dart';

class VideoFile extends Equatable {
  final String path;
  final Duration duration;
  final double aspectRatio;
  final String name;
  final int size;
  final String? thumbnailPath;

  const VideoFile({
    required this.path,
    required this.duration,
    required this.aspectRatio,
    required this.name,
    required this.size,
    this.thumbnailPath,
  });

  @override
  List<Object?> get props => [path, duration, aspectRatio, name, size, thumbnailPath];
}
