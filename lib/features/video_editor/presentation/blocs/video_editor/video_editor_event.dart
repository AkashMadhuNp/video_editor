import 'package:equatable/equatable.dart';
import '../../../domain/entities/video_file.dart';

abstract class VideoEditorEvent extends Equatable {
  const VideoEditorEvent();

  @override
  List<Object?> get props => [];
}

class InitEditorEvent extends VideoEditorEvent {
  final List<VideoFile> videos;

  const InitEditorEvent(this.videos);

  @override
  List<Object?> get props => [videos];
}

class SelectItemEvent extends VideoEditorEvent {
  final String? itemId;

  const SelectItemEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class AddTextOverlayEvent extends VideoEditorEvent {
  final String text;
  final Duration playheadPosition;

  const AddTextOverlayEvent(this.text, this.playheadPosition);

  @override
  List<Object?> get props => [text, playheadPosition];
}

class AddAudioTrackEvent extends VideoEditorEvent {
  final String name;
  final String path;
  final Duration playheadPosition;
  final Duration? duration;

  const AddAudioTrackEvent(this.name, this.path, this.playheadPosition, {this.duration});

  @override
  List<Object?> get props => [name, path, playheadPosition, duration];
}

class SplitItemEvent extends VideoEditorEvent {
  final String itemId;
  final Duration splitPosition;

  const SplitItemEvent(this.itemId, this.splitPosition);

  @override
  List<Object?> get props => [itemId, splitPosition];
}

class DuplicateItemEvent extends VideoEditorEvent {
  final String itemId;

  const DuplicateItemEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class DeleteItemEvent extends VideoEditorEvent {
  final String itemId;

  const DeleteItemEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class UpdateItemTimingEvent extends VideoEditorEvent {
  final String itemId;
  final Duration start;
  final Duration duration;

  const UpdateItemTimingEvent(this.itemId, this.start, this.duration);

  @override
  List<Object?> get props => [itemId, start, duration];
}

class UpdateTextItemPropertiesEvent extends VideoEditorEvent {
  final String itemId;
  final String? text;
  final double? normalizedX;
  final double? normalizedY;
  final double? scale;
  final double? rotation;
  final double? opacity;
  final int? zIndex;
  final int? color;
  final double? fontSize;

  const UpdateTextItemPropertiesEvent(
    this.itemId, {
    this.text,
    this.normalizedX,
    this.normalizedY,
    this.scale,
    this.rotation,
    this.opacity,
    this.zIndex,
    this.color,
    this.fontSize,
  });

  @override
  List<Object?> get props => [
        itemId,
        text,
        normalizedX,
        normalizedY,
        scale,
        rotation,
        opacity,
        zIndex,
        color,
        fontSize,
      ];
}

class UpdateAudioItemPropertiesEvent extends VideoEditorEvent {
  final String itemId;
  final double? volume;

  const UpdateAudioItemPropertiesEvent(this.itemId, {this.volume});

  @override
  List<Object?> get props => [itemId, volume];
}

class UpdateVideoItemPropertiesEvent extends VideoEditorEvent {
  final String itemId;
  final String? filter;
  final double? speed;
  final double? volume;

  const UpdateVideoItemPropertiesEvent(
    this.itemId, {
    this.filter,
    this.speed,
    this.volume,
  });

  @override
  List<Object?> get props => [itemId, filter, speed, volume];
}

class StartExportEvent extends VideoEditorEvent {}

class UpdateProjectAspectRatioEvent extends VideoEditorEvent {
  final double? aspectRatio;
  const UpdateProjectAspectRatioEvent(this.aspectRatio);

  @override
  List<Object?> get props => [aspectRatio];
}

class AddVideoClipsEvent extends VideoEditorEvent {
  final List<VideoFile> videos;

  const AddVideoClipsEvent(this.videos);

  @override
  List<Object?> get props => [videos];
}
