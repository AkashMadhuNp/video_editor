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
  final VideoFile video;

  const VideoPickerLoaded(this.video);

  @override
  List<Object?> get props => [video];
}

class VideoPickerError extends VideoPickerState {
  final String message;

  const VideoPickerError(this.message);

  @override
  List<Object?> get props => [message];
}
