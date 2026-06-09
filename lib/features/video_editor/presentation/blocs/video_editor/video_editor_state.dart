import 'package:equatable/equatable.dart';
import '../../../domain/entities/timeline_project.dart';
import '../../../domain/entities/video_file.dart';

enum ExportStateStatus { initial, exporting, success, failure }

class VideoEditorState extends Equatable {
  final VideoFile? video;
  final TimelineProject? project;
  final String? selectedItemId; // Tracks which track clip is currently selected

  // Export process states
  final ExportStateStatus exportStatus;
  final double exportProgress;
  final String? exportedVideoPath;
  final String? errorMessage;

  const VideoEditorState({
    this.video,
    this.project,
    this.selectedItemId,
    this.exportStatus = ExportStateStatus.initial,
    this.exportProgress = 0.0,
    this.exportedVideoPath,
    this.errorMessage,
  });

  VideoEditorState copyWith({
    VideoFile? video,
    TimelineProject? project,
    String? Function()? selectedItemId,
    ExportStateStatus? exportStatus,
    double? exportProgress,
    String? Function()? exportedVideoPath,
    String? Function()? errorMessage,
  }) {
    return VideoEditorState(
      video: video ?? this.video,
      project: project ?? this.project,
      selectedItemId: selectedItemId != null ? selectedItemId() : this.selectedItemId,
      exportStatus: exportStatus ?? this.exportStatus,
      exportProgress: exportProgress ?? this.exportProgress,
      exportedVideoPath: exportedVideoPath != null ? exportedVideoPath() : this.exportedVideoPath,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        video,
        project,
        selectedItemId,
        exportStatus,
        exportProgress,
        exportedVideoPath,
        errorMessage,
      ];
}
