import 'package:equatable/equatable.dart';

abstract class VideoPickerEvent extends Equatable {
  const VideoPickerEvent();

  @override
  List<Object?> get props => [];
}

class PickVideoEvent extends VideoPickerEvent {}

class ResetPickerEvent extends VideoPickerEvent {}
