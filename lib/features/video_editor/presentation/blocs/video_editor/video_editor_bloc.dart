import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/timeline_project.dart';
import '../../../domain/usecases/export_video.dart';
import 'video_editor_event.dart';
import 'video_editor_state.dart';

class VideoEditorBloc extends Bloc<VideoEditorEvent, VideoEditorState> {
  final ExportVideo exportVideoUseCase;

  VideoEditorBloc({required this.exportVideoUseCase}) : super(const VideoEditorState()) {
    on<InitEditorEvent>(_onInitEditor);
    on<SelectItemEvent>(_onSelectItem);
    on<AddTextOverlayEvent>(_onAddTextOverlay);
    on<AddAudioTrackEvent>(_onAddAudioTrack);
    on<SplitItemEvent>(_onSplitItem);
    on<DuplicateItemEvent>(_onDuplicateItem);
    on<DeleteItemEvent>(_onDeleteItem);
    on<UpdateItemTimingEvent>(_onUpdateItemTiming);
    on<UpdateTextItemPropertiesEvent>(_onUpdateTextItemProperties);
    on<UpdateAudioItemPropertiesEvent>(_onUpdateAudioItemProperties);
    on<UpdateVideoItemPropertiesEvent>(_onUpdateVideoItemProperties);
    on<UpdateProjectAspectRatioEvent>(_onUpdateProjectAspectRatio);
    on<StartExportEvent>(_onStartExport);
  }

  void _onInitEditor(InitEditorEvent event, Emitter<VideoEditorState> emit) {
    final videoItem = TimelineItem(
      id: 'video_clip_${DateTime.now().millisecondsSinceEpoch}',
      name: event.video.name,
      start: Duration.zero,
      duration: event.video.duration,
      trimStart: Duration.zero,
      trimEnd: event.video.duration,
      properties: {
        'path': event.video.path,
        'aspectRatio': event.video.aspectRatio,
        'volume': 1.0,
        'speed': 1.0,
      },
    );

    final tracks = [
      TimelineTrack(id: 'track_video', type: TrackType.video, items: [videoItem]),
      const TimelineTrack(id: 'track_audio', type: TrackType.audio, items: []),
      const TimelineTrack(id: 'track_text', type: TrackType.text, items: []),
    ];

    final project = TimelineProject(
      id: 'project_${DateTime.now().millisecondsSinceEpoch}',
      name: 'NLE Project',
      duration: event.video.duration,
      tracks: tracks,
    );

    emit(VideoEditorState(
      video: event.video,
      project: project,
      exportStatus: ExportStateStatus.initial,
      exportProgress: 0.0,
    ));
  }

  void _onSelectItem(SelectItemEvent event, Emitter<VideoEditorState> emit) {
    emit(state.copyWith(
      selectedItemId: () => event.itemId,
    ));
  }

  void _onAddTextOverlay(AddTextOverlayEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final textItem = TimelineItem(
      id: 'text_clip_${DateTime.now().millisecondsSinceEpoch}',
      name: event.text,
      start: event.playheadPosition,
      duration: const Duration(seconds: 3), // Default 3s
      trimStart: Duration.zero,
      trimEnd: const Duration(seconds: 3),
      properties: {
        'text': event.text,
        'color': 0xFF00FFFF, // Default neon cyan
        'fontSize': 22.0,
        'x': 0.3,
        'y': 0.3,
      },
    );

    final updatedTracks = state.project!.tracks.map((track) {
      if (track.type == TrackType.text) {
        return track.copyWith(items: [...track.items, textItem]);
      }
      return track;
    }).toList();

    final newDuration = _calculateProjectDuration(updatedTracks);

    emit(state.copyWith(
      project: state.project!.copyWith(tracks: updatedTracks, duration: newDuration),
      selectedItemId: () => textItem.id,
    ));
  }

  void _onAddAudioTrack(AddAudioTrackEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final audioItem = TimelineItem(
      id: 'audio_clip_${DateTime.now().millisecondsSinceEpoch}',
      name: event.name,
      start: event.playheadPosition,
      duration: const Duration(seconds: 10), // Default 10s clip
      trimStart: Duration.zero,
      trimEnd: const Duration(seconds: 10),
      properties: {
        'path': event.path,
        'volume': 0.5,
      },
    );

    final updatedTracks = state.project!.tracks.map((track) {
      if (track.type == TrackType.audio) {
        return track.copyWith(items: [...track.items, audioItem]);
      }
      return track;
    }).toList();

    final newDuration = _calculateProjectDuration(updatedTracks);

    emit(state.copyWith(
      project: state.project!.copyWith(tracks: updatedTracks, duration: newDuration),
      selectedItemId: () => audioItem.id,
    ));
  }

  void _onSplitItem(SplitItemEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final project = state.project!;
    String? trackId;
    TimelineItem? targetItem;

    // Find the item and track
    for (final track in project.tracks) {
      for (final item in track.items) {
        if (item.id == event.itemId) {
          trackId = track.id;
          targetItem = item;
          break;
        }
      }
    }

    if (trackId == null || targetItem == null) return;

    final splitPosition = event.splitPosition;
    
    // Check if split position is within item bounds
    if (splitPosition <= targetItem.start || splitPosition >= (targetItem.start + targetItem.duration)) {
      return; // Split is out of bounds for this item
    }

    final splitOffsetInItem = splitPosition - targetItem.start;
    final speed = (targetItem.properties['speed'] as num? ?? 1.0).toDouble();
    final splitOffsetInSource = Duration(milliseconds: (splitOffsetInItem.inMilliseconds * speed).toInt());

    // Create first part
    final firstItem = targetItem.copyWith(
      duration: splitOffsetInItem,
      trimEnd: targetItem.trimStart + splitOffsetInSource,
    );

    // Create second part
    final secondItem = TimelineItem(
      id: '${targetItem.id}_split_${DateTime.now().millisecondsSinceEpoch}',
      name: '${targetItem.name} (Part 2)',
      start: splitPosition,
      duration: targetItem.duration - splitOffsetInItem,
      trimStart: targetItem.trimStart + splitOffsetInSource,
      trimEnd: targetItem.trimEnd,
      properties: Map<String, dynamic>.from(targetItem.properties),
    );

    final updatedTracks = project.tracks.map((track) {
      if (track.id == trackId) {
        final newItems = <TimelineItem>[];
        for (final item in track.items) {
          if (item.id == event.itemId) {
            newItems.add(firstItem);
            newItems.add(secondItem);
          } else {
            newItems.add(item);
          }
        }
        return track.copyWith(items: newItems);
      }
      return track;
    }).toList();

    final newDuration = _calculateProjectDuration(updatedTracks);

    emit(state.copyWith(
      project: project.copyWith(tracks: updatedTracks, duration: newDuration),
      selectedItemId: () => secondItem.id,
    ));
  }

  void _onDuplicateItem(DuplicateItemEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final project = state.project!;
    String? trackId;
    TimelineItem? targetItem;

    for (final track in project.tracks) {
      for (final item in track.items) {
        if (item.id == event.itemId) {
          trackId = track.id;
          targetItem = item;
          break;
        }
      }
    }

    if (trackId == null || targetItem == null) return;

    final duplicateItem = TimelineItem(
      id: '${targetItem.id}_dup_${DateTime.now().millisecondsSinceEpoch}',
      name: '${targetItem.name} (Copy)',
      start: targetItem.start + targetItem.duration, // Sequential default placement
      duration: targetItem.duration,
      trimStart: targetItem.trimStart,
      trimEnd: targetItem.trimEnd,
      properties: Map<String, dynamic>.from(targetItem.properties),
    );

    final updatedTracks = project.tracks.map((track) {
      if (track.id == trackId) {
        final newItems = List<TimelineItem>.from(track.items)..add(duplicateItem);
        // Sort items by timeline start offset
        newItems.sort((a, b) => a.start.compareTo(b.start));
        return track.copyWith(items: newItems);
      }
      return track;
    }).toList();

    final newDuration = _calculateProjectDuration(updatedTracks);

    emit(state.copyWith(
      project: project.copyWith(tracks: updatedTracks, duration: newDuration),
      selectedItemId: () => duplicateItem.id,
    ));
  }

  void _onDeleteItem(DeleteItemEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final project = state.project!;
    final updatedTracks = project.tracks.map((track) {
      final newItems = track.items.where((item) => item.id != event.itemId).toList();
      return track.copyWith(items: newItems);
    }).toList();

    final newDuration = _calculateProjectDuration(updatedTracks);
    final wasSelected = state.selectedItemId == event.itemId;

    emit(state.copyWith(
      project: project.copyWith(tracks: updatedTracks, duration: newDuration),
      selectedItemId: wasSelected ? () => null : null,
    ));
  }

  void _onUpdateItemTiming(UpdateItemTimingEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final project = state.project!;
    final updatedTracks = project.tracks.map((track) {
      final index = track.items.indexWhere((item) => item.id == event.itemId);
      if (index != -1) {
        final newItems = List<TimelineItem>.from(track.items);
        final currentItem = newItems[index];

        // Shift trimEnd proportional to new duration length
        final trimDiff = event.duration - currentItem.duration;
        final newTrimEnd = currentItem.trimEnd + trimDiff;

        newItems[index] = currentItem.copyWith(
          start: event.start,
          duration: event.duration,
          trimEnd: newTrimEnd,
        );
        newItems.sort((a, b) => a.start.compareTo(b.start));
        return track.copyWith(items: newItems);
      }
      return track;
    }).toList();

    final newDuration = _calculateProjectDuration(updatedTracks);

    emit(state.copyWith(
      project: project.copyWith(tracks: updatedTracks, duration: newDuration),
    ));
  }

  void _onUpdateTextItemProperties(UpdateTextItemPropertiesEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final project = state.project!;
    final updatedTracks = project.tracks.map((track) {
      final index = track.items.indexWhere((item) => item.id == event.itemId);
      if (index != -1 && track.type == TrackType.text) {
        final newItems = List<TimelineItem>.from(track.items);
        final item = newItems[index];
        final newProps = Map<String, dynamic>.from(item.properties);

        if (event.text != null) {
          newProps['text'] = event.text;
        }
        if (event.x != null) {
          newProps['x'] = event.x;
        }
        if (event.y != null) {
          newProps['y'] = event.y;
        }
        if (event.color != null) {
          newProps['color'] = event.color;
        }
        if (event.fontSize != null) {
          newProps['fontSize'] = event.fontSize;
        }

        newItems[index] = item.copyWith(
          name: event.text ?? item.name,
          properties: newProps,
        );
        return track.copyWith(items: newItems);
      }
      return track;
    }).toList();

    emit(state.copyWith(
      project: project.copyWith(tracks: updatedTracks),
    ));
  }

  void _onUpdateAudioItemProperties(UpdateAudioItemPropertiesEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final project = state.project!;
    final updatedTracks = project.tracks.map((track) {
      final index = track.items.indexWhere((item) => item.id == event.itemId);
      if (index != -1 && track.type == TrackType.audio) {
        final newItems = List<TimelineItem>.from(track.items);
        final item = newItems[index];
        final newProps = Map<String, dynamic>.from(item.properties);

        if (event.volume != null) {
          newProps['volume'] = event.volume;
        }

        newItems[index] = item.copyWith(properties: newProps);
        return track.copyWith(items: newItems);
      }
      return track;
    }).toList();

    emit(state.copyWith(
      project: project.copyWith(tracks: updatedTracks),
    ));
  }

  void _onUpdateVideoItemProperties(UpdateVideoItemPropertiesEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;

    final project = state.project!;
    final updatedTracks = project.tracks.map((track) {
      if (track.type == TrackType.video) {
        final index = track.items.indexWhere((item) => item.id == event.itemId);
        if (index != -1) {
          final newItems = List<TimelineItem>.from(track.items);
          final item = newItems[index];
          final newProps = Map<String, dynamic>.from(item.properties);

          double oldSpeed = (item.properties['speed'] as num? ?? 1.0).toDouble();
          double newSpeed = oldSpeed;

          if (event.filter != null) {
            newProps['filter'] = event.filter;
          }
          if (event.speed != null) {
            newProps['speed'] = event.speed;
            newSpeed = event.speed!;
          }
          if (event.volume != null) {
            newProps['volume'] = event.volume;
          }

          // If speed changed, calculate new duration
          Duration newDuration = item.duration;
          if (newSpeed != oldSpeed) {
            final sourceDur = item.trimEnd - item.trimStart;
            newDuration = Duration(milliseconds: (sourceDur.inMilliseconds / newSpeed).toInt());
          }

          newItems[index] = item.copyWith(
            properties: newProps,
            duration: newDuration,
          );

          // Ripple shift subsequent items in the video track to keep them contiguous
          for (int i = 0; i < newItems.length; i++) {
            if (i > 0) {
              final prev = newItems[i - 1];
              newItems[i] = newItems[i].copyWith(
                start: prev.start + prev.duration,
              );
            }
          }

          return track.copyWith(items: newItems);
        }
      }
      return track;
    }).toList();

    final newDuration = _calculateProjectDuration(updatedTracks);

    emit(state.copyWith(
      project: project.copyWith(tracks: updatedTracks, duration: newDuration),
    ));
  }

  void _onUpdateProjectAspectRatio(UpdateProjectAspectRatioEvent event, Emitter<VideoEditorState> emit) {
    if (state.project == null) return;
    emit(state.copyWith(
      project: state.project!.copyWith(aspectRatio: () => event.aspectRatio),
    ));
  }

  Future<void> _onStartExport(StartExportEvent event, Emitter<VideoEditorState> emit) async {
    if (state.project == null) return;

    emit(state.copyWith(
      exportStatus: ExportStateStatus.exporting,
      exportProgress: 0.0,
      exportedVideoPath: () => null,
      errorMessage: () => null,
    ));

    final stream = exportVideoUseCase(
      ExportVideoParams(project: state.project!),
    );

    await emit.forEach(
      stream,
      onData: (result) {
        return result.fold(
          (failure) => state.copyWith(
            exportStatus: ExportStateStatus.failure,
            errorMessage: () => failure.message,
          ),
          (progress) {
            if (progress.progress >= 1.0 && progress.outputPath != null) {
              return state.copyWith(
                exportStatus: ExportStateStatus.success,
                exportProgress: 1.0,
                exportedVideoPath: () => progress.outputPath,
              );
            } else {
              return state.copyWith(
                exportStatus: ExportStateStatus.exporting,
                exportProgress: progress.progress,
              );
            }
          },
        );
      },
      onError: (err, stackTrace) => state.copyWith(
        exportStatus: ExportStateStatus.failure,
        errorMessage: () => err.toString(),
      ),
    );
  }

  Duration _calculateProjectDuration(List<TimelineTrack> tracks) {
    Duration maxDuration = Duration.zero;
    for (final track in tracks) {
      for (final item in track.items) {
        final end = item.start + item.duration;
        if (end > maxDuration) {
          maxDuration = end;
        }
      }
    }
    return maxDuration;
  }
}
