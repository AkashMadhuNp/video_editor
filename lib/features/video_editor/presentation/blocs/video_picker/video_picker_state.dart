import 'package:equatable/equatable.dart';
import '../../../domain/entities/video_file.dart';

abstract class VideoPickerState extends Equatable {
  const VideoPickerState();

  @override
  List<Object?> get props => [];
}

class VideoPickerInitial extends VideoPickerState {}

class VideoPickerLoading extends VideoPickerState {}

class VideoPickerLoaded extends VideoPickerState {
  final List<VideoFile> videos;

  const VideoPickerLoaded(this.videos);

  @override
  List<Object?> get props => [videos];
}

class VideoPickerError extends VideoPickerState {
  final String message;

  const VideoPickerError(this.message);

  @override
  List<Object?> get props => [message];
}
