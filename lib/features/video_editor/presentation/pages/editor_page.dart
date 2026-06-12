import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/timeline_project.dart';
import '../../domain/entities/video_file.dart';
import '../../domain/usecases/pick_video.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_filters.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../blocs/video_editor/video_editor_bloc.dart';
import '../blocs/video_editor/video_editor_event.dart';
import '../blocs/video_editor/video_editor_state.dart';
import '../widgets/filter_selector.dart';
import '../widgets/player_controls.dart';
import '../widgets/speed_selector.dart';
import '../widgets/text_overlay_widget.dart';
import '../widgets/timeline_tools.dart';
import '../widgets/timeline_widget.dart';
import 'export_page.dart';

class EditorPage extends StatefulWidget {
  final List<VideoFile> videos;
  const EditorPage({super.key, required this.videos});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late VideoPlayerController _controller;
  bool _isPlayerInitialized = false;
  String? _initError;
  Duration _playheadPosition = Duration.zero;

  // Synchronization engine variables
  String? _currentVideoPath;
  bool _isSeeking = false;
  bool _isTimelinePlaying = false;
  final Map<String, VideoPlayerController> _audioControllers = {};
  TimelineProject? _lastAppliedProject;

  @override
  void initState() {
    super.initState();
    _currentVideoPath = widget.videos.first.path;
    _initializePlayer(widget.videos.first.path);
  }

  void _initializePlayer(String path) {
    setState(() {
      _isPlayerInitialized = false;
    });

    _controller = VideoPlayerController.file(File(path));
    _controller.initialize().then((_) async {
      if (!mounted) return;

      // Sync properties on start
      final state = context.read<VideoEditorBloc>().state;
      final project = state.project;
      final activeVideo = _getActiveVideoItem(project, _playheadPosition);
      final double speed = (activeVideo?.properties['speed'] as num? ?? 1.0).toDouble();
      final double volume = (activeVideo?.properties['volume'] as num? ?? 1.0).toDouble();
      await _controller.setPlaybackSpeed(speed);
      await _controller.setVolume(volume);

      setState(() {
        _isPlayerInitialized = true;
      });
      _controller.play();
      _controller.setLooping(false);
      _controller.addListener(_videoListener);
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _initError = error.toString();
      });
      debugPrint('Video player initialization error: $error');
    });
  }

  TimelineItem? _getActiveVideoItem(TimelineProject? project, Duration position) {
    if (project == null) return null;
    final videoTrack = project.tracks.firstWhere(
      (t) => t.type == TrackType.video,
      orElse: () => const TimelineTrack(id: '', type: TrackType.video, items: []),
    );
    for (final item in videoTrack.items) {
      if (position >= item.start && position < (item.start + item.duration)) {
        return item;
      }
    }
    // If exactly at or beyond the end of the project, return the last item
    if (position >= project.duration && videoTrack.items.isNotEmpty) {
      return videoTrack.items.last;
    }
    return null;
  }

  bool _hasProjectStructureOrTimingChanged(TimelineProject? oldProj, TimelineProject? newProj) {
    if (oldProj == null || newProj == null) return true;
    if (oldProj.duration != newProj.duration) return true;
    if (oldProj.tracks.length != newProj.tracks.length) return true;

    for (int i = 0; i < oldProj.tracks.length; i++) {
      final oldTrack = oldProj.tracks[i];
      final newTrack = newProj.tracks[i];
      if (oldTrack.items.length != newTrack.items.length) return true;
      for (int j = 0; j < oldTrack.items.length; j++) {
        final oldItem = oldTrack.items[j];
        final newItem = newTrack.items[j];
        if (oldItem.id != newItem.id ||
            oldItem.start != newItem.start ||
            oldItem.duration != newItem.duration ||
            oldItem.trimStart != newItem.trimStart ||
            oldItem.trimEnd != newItem.trimEnd ||
            oldItem.properties['path'] != newItem.properties['path']) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _seekPlayersToPlayhead(Duration newPlayhead, {bool startPlaying = false}) async {
    if (_isSeeking) return;
    _isSeeking = true;

    final shouldPlay = startPlaying || _isTimelinePlaying;

    try {
      final state = context.read<VideoEditorBloc>().state;
      final project = state.project;
      if (project == null) return;

      // A. Sync Video Player
      final activeVideo = _getActiveVideoItem(project, newPlayhead);
      if (activeVideo != null) {
        final path = activeVideo.properties['path'] as String? ?? '';
        final speed = (activeVideo.properties['speed'] as num? ?? 1.0).toDouble();
        final volume = (activeVideo.properties['volume'] as num? ?? 1.0).toDouble();
        
        final localOffset = newPlayhead - activeVideo.start;
        final targetMediaPos = activeVideo.trimStart + localOffset * speed;

        // Check if we need to switch video source
        if (path != _currentVideoPath) {
          _controller.removeListener(_videoListener);
          final oldController = _controller;
          
          final newController = VideoPlayerController.file(File(path));
          await newController.initialize();
          newController.setLooping(false);
          newController.addListener(_videoListener);
          
          // Configure the new controller offline before attaching it to the UI
          await newController.seekTo(targetMediaPos);
          await newController.setPlaybackSpeed(speed);
          await newController.setVolume(volume);
          if (shouldPlay) {
            await newController.play();
          }

          _controller = newController;
          _currentVideoPath = path;

          setState(() {});
          await oldController.dispose();
        } else {
          // Seek video player if difference is substantial to avoid seek stuttering
          final currentPos = _controller.value.position;
          final diff = (currentPos - targetMediaPos).inMilliseconds.abs();
          if (diff > 150 || startPlaying) {
            await _controller.seekTo(targetMediaPos);
          }

          await _controller.setPlaybackSpeed(speed);
          await _controller.setVolume(volume);

          if (shouldPlay && !_controller.value.isPlaying) {
            await _controller.play();
          }
        }
      } else {
        // No video clip active, pause video player
        if (_controller.value.isPlaying) {
          await _controller.pause();
        }
      }

      // B. Sync Audio Players
      final audioTrack = project.tracks.firstWhere(
        (t) => t.type == TrackType.audio,
        orElse: () => const TimelineTrack(id: '', type: TrackType.audio, items: []),
      );

      final Set<String> activeAudioIds = {};

      for (final item in audioTrack.items) {
        final isWithinClip = newPlayhead >= item.start && newPlayhead < (item.start + item.duration);
        if (isWithinClip) {
          activeAudioIds.add(item.id);
          final path = item.properties['path'] as String? ?? '';
          final volume = (item.properties['volume'] as num? ?? 0.5).toDouble();
          final localOffset = newPlayhead - item.start;
          final targetAudioPos = item.trimStart + localOffset;

          VideoPlayerController? audioCtrl = _audioControllers[item.id];
          if (audioCtrl == null) {
            audioCtrl = VideoPlayerController.file(File(path));
            await audioCtrl.initialize();
            await audioCtrl.setLooping(false);
            _audioControllers[item.id] = audioCtrl;
          }

          await audioCtrl.setVolume(volume);
          
          final diff = (audioCtrl.value.position - targetAudioPos).inMilliseconds.abs();
          if (diff > 150 || shouldPlay) {
            await audioCtrl.seekTo(targetAudioPos);
          }

          // Match play/pause state
          if (shouldPlay && !audioCtrl.value.isPlaying) {
            await audioCtrl.play();
          } else if (!shouldPlay && audioCtrl.value.isPlaying) {
            await audioCtrl.pause();
          }
        }
      }

      // Dispose and remove any controllers that are no longer active
      final inactiveIds = _audioControllers.keys.where((id) => !activeAudioIds.contains(id)).toList();
      for (final id in inactiveIds) {
        final ctrl = _audioControllers.remove(id);
        if (ctrl != null) {
          await ctrl.pause();
          await ctrl.dispose();
        }
      }
    } catch (e) {
      debugPrint('Error seeking players: $e');
    } finally {
      _isSeeking = false;
    }
  }

  Future<void> _resetToStart() async {
    _isTimelinePlaying = false;
    if (_controller.value.isPlaying) {
      await _controller.pause();
    }
    for (final ctrl in _audioControllers.values) {
      if (ctrl.value.isPlaying) {
        await ctrl.pause();
      }
    }
    setState(() {
      _playheadPosition = Duration.zero;
    });
    await _seekPlayersToPlayhead(Duration.zero);
  }

  void _videoListener() {
    if (!mounted || !_isPlayerInitialized || _isSeeking) return;

    final state = context.read<VideoEditorBloc>().state;
    final project = state.project;
    if (project == null) return;

    final activeVideo = _getActiveVideoItem(project, _playheadPosition);
    if (activeVideo == null) {
      // If no active video, slowly progress playhead
      final nextPlayhead = _playheadPosition + const Duration(milliseconds: 50);
      if (nextPlayhead >= project.duration) {
        _resetToStart();
      } else {
        setState(() {
          _playheadPosition = nextPlayhead;
        });
      }
      return;
    }

    final currentMediaPos = _controller.value.position;
    final speed = (activeVideo.properties['speed'] as num? ?? 1.0).toDouble();

    // Calculate remaining duration in the clip
    final remainingMedia = activeVideo.trimEnd - currentMediaPos;

    // We consider the clip finished if:
    // 1. The playhead has naturally passed or reached trimEnd.
    // 2. The playhead is within a small threshold (150ms) of trimEnd.
    // 3. The controller is no longer playing (it reached the end of the source file),
    //    but the timeline is supposed to be playing, and we have played past the start,
    //    and we are near the end (within 300ms of trimEnd or 150ms of the absolute duration).
    final bool isFinished = currentMediaPos >= activeVideo.trimEnd ||
        remainingMedia.inMilliseconds.abs() < 150 ||
        (!_controller.value.isPlaying &&
            _isTimelinePlaying &&
            currentMediaPos > activeVideo.trimStart &&
            (remainingMedia.inMilliseconds < 300 ||
                _controller.value.position >= _controller.value.duration - const Duration(milliseconds: 150)));

    if (isFinished) {
      final nextPlayhead = activeVideo.start + activeVideo.duration;
      if (nextPlayhead >= project.duration) {
        _resetToStart();
      } else {
        setState(() {
          _playheadPosition = nextPlayhead;
        });
        _seekPlayersToPlayhead(nextPlayhead, startPlaying: _isTimelinePlaying);
      }
      return;
    }

    // Otherwise, compute the project playhead from the media position
    final elapsedMedia = currentMediaPos - activeVideo.trimStart;
    final elapsedProject = Duration(milliseconds: (elapsedMedia.inMilliseconds / speed).toInt());
    final computedPlayhead = activeVideo.start + elapsedProject;

    // Sync background audios play state
    for (final entry in _audioControllers.entries) {
      final audioTrack = project.tracks.firstWhere(
        (t) => t.type == TrackType.audio,
        orElse: () => const TimelineTrack(id: '', type: TrackType.audio, items: []),
      );
      final matchingItems = audioTrack.items.where((item) => item.id == entry.key);
      if (matchingItems.isEmpty) continue;
      
      final audioItem = matchingItems.first;
      final isWithinClip = computedPlayhead >= audioItem.start && computedPlayhead < (audioItem.start + audioItem.duration);

      if (isWithinClip) {
        if (_controller.value.isPlaying && !entry.value.value.isPlaying) {
          entry.value.play();
        } else if (!_controller.value.isPlaying && entry.value.value.isPlaying) {
          entry.value.pause();
        }
      } else {
        if (entry.value.value.isPlaying) {
          entry.value.pause();
        }
      }
    }

    if (computedPlayhead >= project.duration) {
      _resetToStart();
    } else {
      setState(() {
        _playheadPosition = computedPlayhead;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    for (final ctrl in _audioControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<VideoEditorBloc, VideoEditorState>(
      listenWhen: (previous, current) {
        return previous.project != current.project ||
            previous.exportStatus != current.exportStatus;
      },
      listener: (context, state) {
        if (!_isPlayerInitialized) return;

        final project = state.project;
        if (project != null) {
          // Whenever the project state changes (splits, trims, property changes), sync player positions/properties
          final activeVideo = _getActiveVideoItem(project, _playheadPosition);
          if (activeVideo != null) {
            final double speed = (activeVideo.properties['speed'] as num? ?? 1.0).toDouble();
            final double volume = (activeVideo.properties['volume'] as num? ?? 1.0).toDouble();
            _controller.setPlaybackSpeed(speed);
            _controller.setVolume(volume);
          }
          
          final audioTrack = project.tracks.firstWhere(
            (t) => t.type == TrackType.audio,
            orElse: () => const TimelineTrack(id: '', type: TrackType.audio, items: []),
          );
          for (final item in audioTrack.items) {
            final ctrl = _audioControllers[item.id];
            if (ctrl != null) {
              final double volume = (item.properties['volume'] as num? ?? 0.5).toDouble();
              ctrl.setVolume(volume);
            }
          }
          
          // Only seek if structure/timing changed
          final structureChanged = _hasProjectStructureOrTimingChanged(_lastAppliedProject, project);
          if (structureChanged) {
            _seekPlayersToPlayhead(_playheadPosition);
          }
          _lastAppliedProject = project;
        }

        // Navigate to export screen
        if (state.exportStatus == ExportStateStatus.exporting) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (navContext) => BlocProvider.value(
                value: context.read<VideoEditorBloc>(),
                child: const ExportPage(),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text(
            'EDIT WORKSPACE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  context.read<VideoEditorBloc>().add(StartExportEvent());
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: BlocBuilder<VideoEditorBloc, VideoEditorState>(
          builder: (context, state) {
            if (state.video == null || state.project == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final project = state.project!;
            final videoItem = _getActiveVideoItem(project, _playheadPosition);
            
            TrackType? selectedItemType;
            TimelineItem? selectedItem;
            if (state.selectedItemId != null) {
              for (final track in project.tracks) {
                for (final item in track.items) {
                  if (item.id == state.selectedItemId) {
                    selectedItemType = track.type;
                    selectedItem = item;
                    break;
                  }
                }
              }
            }
            
            final double displayRatio = project.aspectRatio ?? widget.videos.first.aspectRatio;
            final filterId = videoItem?.properties['filter'] as String? ?? 'original';

            // Active text overlays on timeline
            final textTrack = project.tracks.firstWhere(
              (t) => t.type == TrackType.text,
              orElse: () => const TimelineTrack(id: '', type: TrackType.text, items: []),
            );
            final activeTextItems = textTrack.items.where((item) {
              return _playheadPosition >= item.start && _playheadPosition <= (item.start + item.duration);
            }).toList();

            return Column(
              children: [
                // 1. Live Preview Viewport
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _initError != null
                            ? Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Failed to play video:\n$_initError',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : _isPlayerInitialized
                                ? ColorFiltered(
                                    colorFilter: AppFilters.getFilter(filterId),
                                    child: AspectRatio(
                                      aspectRatio: displayRatio,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Center(
                                                  child: FittedBox(
                                                    fit: BoxFit.contain,
                                                    child: SizedBox(
                                                      width: _controller.value.size.width > 0 
                                                          ? _controller.value.size.width 
                                                          : 1280,
                                                      height: _controller.value.size.height > 0 
                                                          ? _controller.value.size.height 
                                                          : 720,
                                                      child: VideoPlayer(_controller),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              
                                              // Dynamic active text overlays sorted by zIndex
                                              ...(() {
                                                final list = List<TimelineItem>.from(activeTextItems);
                                                list.sort((a, b) => (a.properties['zIndex'] as int? ?? 0).compareTo(b.properties['zIndex'] as int? ?? 0));
                                                return list;
                                              })().map((item) {
                                                final textVal = item.properties['text'] as String? ?? '';
                                                final colorVal = item.properties['color'] as int? ?? 0xFFFFFFFF;
                                                
                                                // Dynamic scaling and legacy coordinate mapping
                                                final double rawFontSize = (item.properties['fontSize'] as num? ?? 72.0).toDouble();
                                                final double fontSize = rawFontSize <= 48.0 ? rawFontSize * 3.0 : rawFontSize;
                                                
                                                final double normX = (item.properties['normalizedX'] as num? ?? 
                                                    (item.properties['x'] != null ? (item.properties['x'] as num).toDouble() * 2.0 - 1.0 : 0.0)).toDouble();
                                                final double normY = (item.properties['normalizedY'] as num? ?? 
                                                    (item.properties['y'] != null ? (item.properties['y'] as num).toDouble() * 2.0 - 1.0 : 0.0)).toDouble();
                                                
                                                final double scaleVal = (item.properties['scale'] as num? ?? 1.0).toDouble();
                                                final double rotationVal = (item.properties['rotation'] as num? ?? 0.0).toDouble();
                                                final double opacityVal = (item.properties['opacity'] as num? ?? 1.0).toDouble();
                                                final isSelected = state.selectedItemId == item.id;
 
                                                return TextOverlayWidget(
                                                  key: ValueKey(item.id),
                                                  text: textVal,
                                                  color: Color(colorVal),
                                                  fontSize: fontSize,
                                                  normalizedX: normX,
                                                  normalizedY: normY,
                                                  scale: scaleVal,
                                                  rotation: rotationVal,
                                                  opacity: opacityVal,
                                                  parentWidth: constraints.maxWidth,
                                                  parentHeight: constraints.maxHeight,
                                                  isEditable: isSelected,
                                                  onTap: () {
                                                    context.read<VideoEditorBloc>().add(
                                                          SelectItemEvent(item.id),
                                                        );
                                                  },
                                                  onPositionChanged: (newX, newY) {
                                                    context.read<VideoEditorBloc>().add(
                                                      UpdateTextItemPropertiesEvent(
                                                        item.id,
                                                        normalizedX: newX,
                                                        normalizedY: newY,
                                                      ),
                                                    );
                                                  },
                                                );
                                              }),
 
                                              // Player controls overlay
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: PlayerControls(
                                                  isPlaying: _isTimelinePlaying,
                                                  position: _playheadPosition,
                                                  duration: project.duration,
                                                  onPlayToggle: () async {
                                                    if (!_isPlayerInitialized) return;
                                                    if (_isTimelinePlaying) {
                                                      _isTimelinePlaying = false;
                                                      await _controller.pause();
                                                      for (final ctrl in _audioControllers.values) {
                                                        await ctrl.pause();
                                                      }
                                                    } else {
                                                      _isTimelinePlaying = true;
                                                      if (_playheadPosition >= project.duration) {
                                                        await _seekPlayersToPlayhead(Duration.zero, startPlaying: true);
                                                      } else {
                                                        await _controller.play();
                                                        final activeVideo = _getActiveVideoItem(project, _playheadPosition);
                                                        if (activeVideo != null) {
                                                          final double speed = (activeVideo.properties['speed'] as num? ?? 1.0).toDouble();
                                                          await _controller.setPlaybackSpeed(speed);
                                                          
                                                          final audioTrack = project.tracks.firstWhere(
                                                            (t) => t.type == TrackType.audio,
                                                            orElse: () => const TimelineTrack(id: '', type: TrackType.audio, items: []),
                                                          );
                                                          for (final item in audioTrack.items) {
                                                            final isWithinClip = _playheadPosition >= item.start && _playheadPosition < (item.start + item.duration);
                                                            if (isWithinClip) {
                                                              await _audioControllers[item.id]?.play();
                                                            }
                                                          }
                                                        }
                                                      }
                                                    }
                                                    if (mounted) setState(() {});
                                                  },
                                                  onScrub: (position) {
                                                    setState(() {
                                                      _playheadPosition = position;
                                                    });
                                                    _seekPlayersToPlayhead(position);
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      ),
                                    ),
                                  )
                                : const CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),

                // 2. Multi-Track Timeline Board
                SizedBox(
                  height: TimelineWidget.calculateHeight(project),
                  child: TimelineWidget(
                    project: project,
                    playheadPosition: _playheadPosition,
                    selectedItemId: state.selectedItemId,
                    onScrub: (position) {
                      setState(() {
                        _playheadPosition = position;
                      });
                      _seekPlayersToPlayhead(position);
                    },
                    onSelectItem: (itemId) {
                      context.read<VideoEditorBloc>().add(SelectItemEvent(itemId));
                    },
                    onTrimItem: (itemId, start, duration) {
                      context.read<VideoEditorBloc>().add(
                            UpdateItemTimingEvent(itemId, start, duration),
                          );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // 3. Contextual Action Toolbar
                TimelineTools(
                  selectedItemId: state.selectedItemId,
                  selectedItemType: selectedItemType,
                  playheadPosition: _playheadPosition,
                  onAddVideo: () async {
                    final picker = sl<PickVideo>();
                    final result = await picker(NoParams());
                    result.fold(
                      (failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(failure.message),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      },
                      (videos) {
                        context.read<VideoEditorBloc>().add(
                              AddVideoClipsEvent(videos),
                            );
                      },
                    );
                  },
                  onSplit: state.selectedItemId != null && (selectedItemType == TrackType.video || selectedItemType == TrackType.audio)
                      ? () {
                          context.read<VideoEditorBloc>().add(
                                SplitItemEvent(state.selectedItemId!, _playheadPosition),
                              );
                        }
                      : null,
                  onDuplicate: state.selectedItemId != null
                      ? () {
                          context.read<VideoEditorBloc>().add(
                                DuplicateItemEvent(state.selectedItemId!),
                              );
                        }
                      : null,
                  onDelete: state.selectedItemId != null
                      ? () {
                          context.read<VideoEditorBloc>().add(
                                DeleteItemEvent(state.selectedItemId!),
                              );
                        }
                      : null,
                  onAddText: (text) {
                    context.read<VideoEditorBloc>().add(
                          AddTextOverlayEvent(text, _playheadPosition),
                        );
                  },
                  onAddAudio: () async {
                    try {
                      final result = await FilePicker.pickFiles(
                        type: FileType.audio,
                        allowMultiple: false,
                      );

                      if (result != null && result.files.single.path != null) {
                        final file = result.files.single;
                        final name = file.name;
                        final path = file.path!;

                        final tempController = VideoPlayerController.file(File(path));
                        Duration duration = const Duration(seconds: 10);
                        try {
                          await tempController.initialize();
                          duration = tempController.value.duration;
                        } catch (e) {
                          debugPrint('Failed to get audio duration: $e');
                        } finally {
                          await tempController.dispose();
                        }

                        if (context.mounted) {
                          context.read<VideoEditorBloc>().add(
                                AddAudioTrackEvent(
                                  name,
                                  path,
                                  _playheadPosition,
                                  duration: duration,
                                ),
                              );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to pick audio: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  currentRatio: project.aspectRatio ?? widget.videos.first.aspectRatio,
                  onRatioChanged: (ratio) {
                    context.read<VideoEditorBloc>().add(
                          UpdateProjectAspectRatioEvent(ratio),
                        );
                  },
                  onOpenFilter: state.selectedItemId != null && selectedItemType == TrackType.video
                      ? () {
                          final currentFilter = selectedItem?.properties['filter'] as String? ?? 'original';
                          _showFilterBottomSheet(context, state.selectedItemId!, currentFilter);
                        }
                      : null,
                  onOpenSpeed: state.selectedItemId != null && selectedItemType == TrackType.video
                      ? () {
                          final currentSpeed = (selectedItem?.properties['speed'] as num? ?? 1.0).toDouble();
                          _showSpeedBottomSheet(context, state.selectedItemId!, currentSpeed);
                        }
                      : null,
                  onOpenVolume: state.selectedItemId != null && (selectedItemType == TrackType.video || selectedItemType == TrackType.audio)
                      ? () {
                          final currentVolume = (selectedItem?.properties['volume'] as num? ?? 1.0).toDouble();
                          if (selectedItemType == TrackType.video) {
                            _showVolumeBottomSheet(context, state.selectedItemId!, currentVolume);
                          } else {
                            _showAudioVolumeBottomSheet(context, state.selectedItemId!, currentVolume);
                          }
                        }
                      : null,
                  onOpenTextSettings: state.selectedItemId != null && selectedItemType == TrackType.text
                      ? () {
                          _showTextPropertiesBottomSheet(context, state.selectedItemId!, selectedItem!);
                        }
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, String itemId, String currentFilter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Filter',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: FilterSelector(
                  selectedFilter: currentFilter,
                  onFilterChanged: (filter) {
                    context.read<VideoEditorBloc>().add(
                          UpdateVideoItemPropertiesEvent(itemId, filter: filter),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedBottomSheet(BuildContext context, String itemId, double currentSpeed) async {
    final bloc = context.read<VideoEditorBloc>();
    final originalSpeed = currentSpeed;
    final originalPlayhead = _playheadPosition;
    bool applied = false;

    final project = bloc.state.project;
    if (project == null) return;
    final videoTrack = project.tracks.firstWhere(
      (t) => t.type == TrackType.video,
      orElse: () => const TimelineTrack(id: '', type: TrackType.video, items: []),
    );
    final activeVideo = videoTrack.items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => const TimelineItem(id: '', name: '', start: Duration.zero, duration: Duration.zero, trimStart: Duration.zero, trimEnd: Duration.zero, properties: {}),
    );
    if (activeVideo.id.isEmpty) return;

    final sourceDuration = activeVideo.trimEnd - activeVideo.trimStart;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Clip Speed',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                      onPressed: () {
                        applied = true;
                        Navigator.of(bottomSheetContext).pop();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return SpeedSelector(
                      selectedSpeed: currentSpeed,
                      sourceDuration: sourceDuration,
                      onSpeedChanged: (speed) {
                        if (speed == currentSpeed) return;
                        
                        final state = bloc.state;
                        final latestProject = state.project;
                        if (latestProject != null) {
                          final latestTrack = latestProject.tracks.firstWhere((t) => t.type == TrackType.video);
                          final latestItem = latestTrack.items.firstWhere((item) => item.id == itemId);
                          final localOffset = _playheadPosition - latestItem.start;
                          if (localOffset >= Duration.zero && localOffset <= latestItem.duration) {
                            final double oldSpeed = (latestItem.properties['speed'] as num? ?? 1.0).toDouble();
                            final double newSpeed = speed;
                            final double factor = oldSpeed / newSpeed;
                            final newLocalOffset = Duration(milliseconds: (localOffset.inMilliseconds * factor).toInt());
                            final newPlayhead = latestItem.start + newLocalOffset;
                            
                            setState(() {
                              _playheadPosition = newPlayhead;
                            });
                          }
                        }

                        setModalState(() {
                          currentSpeed = speed;
                        });
                        _controller.setPlaybackSpeed(speed);
                        bloc.add(
                          UpdateVideoItemPropertiesEvent(itemId, speed: speed),
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!applied) {
      if (!mounted) return;
      // Revert speed and playhead
      bloc.add(
        UpdateVideoItemPropertiesEvent(itemId, speed: originalSpeed),
      );
      setState(() {
        _playheadPosition = originalPlayhead;
      });
      _seekPlayersToPlayhead(originalPlayhead);
    }
  }

  Widget _buildPresetButton(String label, double val, bool isSelected, ValueChanged<double> onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.white10,
        width: 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onSelected: (_) => onTap(val),
    );
  }

  void _showVolumeBottomSheet(BuildContext context, String itemId, double currentVolume) {
    double lastNonZeroVolume = currentVolume > 0.0 ? currentVolume : 1.0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          IconData volumeIcon;
          if (currentVolume == 0.0) {
            volumeIcon = Icons.volume_off_rounded;
          } else if (currentVolume <= 0.5) {
            volumeIcon = Icons.volume_down_rounded;
          } else {
            volumeIcon = Icons.volume_up_rounded;
          }

          void updateVolume(double val) {
            if (val > 0.0) {
              lastNonZeroVolume = val;
            }
            setModalState(() {
              currentVolume = val;
            });
            _controller.setVolume(val);
            context.read<VideoEditorBloc>().add(
                  UpdateVideoItemPropertiesEvent(itemId, volume: val),
                );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentVolume > 0.0) {
                            updateVolume(0.0);
                          } else {
                            updateVolume(lastNonZeroVolume);
                          }
                        },
                        child: Icon(
                          volumeIcon, 
                          color: currentVolume == 0.0 ? AppColors.textMuted : AppColors.secondary, 
                          size: 24
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Clip Volume',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(currentVolume * 100).toInt()}%',
                        style: TextStyle(
                          color: currentVolume == 0.0 ? AppColors.textMuted : AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: AppColors.secondary,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: AppColors.secondary,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayColor: AppColors.secondary.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: currentVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: updateVolume,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetButton('Mute', 0.0, currentVolume == 0.0, updateVolume),
                      _buildPresetButton('20%', 0.2, (currentVolume - 0.2).abs() < 0.01, updateVolume),
                      _buildPresetButton('50%', 0.5, (currentVolume - 0.5).abs() < 0.01, updateVolume),
                      _buildPresetButton('100%', 1.0, (currentVolume - 1.0).abs() < 0.01, updateVolume),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAudioVolumeBottomSheet(BuildContext context, String itemId, double currentVolume) {
    double lastNonZeroVolume = currentVolume > 0.0 ? currentVolume : 0.5;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          IconData volumeIcon;
          if (currentVolume == 0.0) {
            volumeIcon = Icons.volume_off_rounded;
          } else if (currentVolume <= 0.5) {
            volumeIcon = Icons.volume_down_rounded;
          } else {
            volumeIcon = Icons.volume_up_rounded;
          }

          void updateVolume(double val) {
            if (val > 0.0) {
              lastNonZeroVolume = val;
            }
            setModalState(() {
              currentVolume = val;
            });
            final ctrl = _audioControllers[itemId];
            if (ctrl != null) {
              ctrl.setVolume(val);
            }
            context.read<VideoEditorBloc>().add(
                  UpdateAudioItemPropertiesEvent(itemId, volume: val),
                );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentVolume > 0.0) {
                            updateVolume(0.0);
                          } else {
                            updateVolume(lastNonZeroVolume);
                          }
                        },
                        child: Icon(
                          volumeIcon, 
                          color: currentVolume == 0.0 ? AppColors.textMuted : AppColors.success, 
                          size: 24
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Track Volume',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(currentVolume * 100).toInt()}%',
                        style: TextStyle(
                          color: currentVolume == 0.0 ? AppColors.textMuted : AppColors.success,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: AppColors.success,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: AppColors.success,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayColor: AppColors.success.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: currentVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: updateVolume,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetButton('Mute', 0.0, currentVolume == 0.0, updateVolume),
                      _buildPresetButton('20%', 0.2, (currentVolume - 0.2).abs() < 0.01, updateVolume),
                      _buildPresetButton('50%', 0.5, (currentVolume - 0.5).abs() < 0.01, updateVolume),
                      _buildPresetButton('100%', 1.0, (currentVolume - 1.0).abs() < 0.01, updateVolume),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTextPropertiesBottomSheet(BuildContext context, String itemId, TimelineItem selectedItem) {
    final bloc = BlocProvider.of<VideoEditorBloc>(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return BlocBuilder<VideoEditorBloc, VideoEditorState>(
                builder: (blocContext, state) {
                  TimelineItem? item;
                  if (state.project != null) {
                    for (final track in state.project!.tracks) {
                      for (final tItem in track.items) {
                        if (tItem.id == itemId) {
                          item = tItem;
                          break;
                        }
                      }
                    }
                  }
                  item ??= selectedItem;

                  final textVal = item.properties['text'] as String? ?? '';
                  final double rawFontSize = (item.properties['fontSize'] as num? ?? 72.0).toDouble();
                  final double fontSize = rawFontSize <= 48.0 ? rawFontSize * 3.0 : rawFontSize;
                  final sizeVal = fontSize / 3.0;
                  final colorVal = item.properties['color'] as int? ?? 0xFFFFFFFF;

                  return SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 16.0,
                        bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Text Properties',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                                onPressed: () => Navigator.of(bottomSheetContext).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Edit overlay text...',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              prefixIcon: const Icon(Icons.text_fields_rounded, color: AppColors.primary, size: 18),
                            ),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            controller: TextEditingController.fromValue(
                              TextEditingValue(
                                text: textVal,
                                selection: TextSelection.collapsed(offset: textVal.length),
                              ),
                            ),
                            onChanged: (val) {
                              context.read<VideoEditorBloc>().add(
                                    UpdateTextItemPropertiesEvent(itemId, text: val),
                                  );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.format_size_rounded, color: AppColors.textSecondary, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Size: ',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                  ),
                                  child: Slider(
                                    value: sizeVal,
                                    min: 12,
                                    max: 48,
                                    activeColor: AppColors.primary,
                                    inactiveColor: Colors.white12,
                                    onChanged: (val) {
                                      context.read<VideoEditorBloc>().add(
                                            UpdateTextItemPropertiesEvent(itemId, fontSize: val * 3.0),
                                          );
                                    },
                                  ),
                                ),
                              ),
                              Text('${sizeVal.toInt()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Color',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                0xFFFFFFFF, // White
                                0xFF000000, // Black
                                0xFF00FFFF, // Neon Cyan
                                0xFF00FF00, // Neon Green
                                0xFFFF00FF, // Neon Pink
                                0xFFFFD700, // Gold/Yellow
                                0xFFFF4500, // Orange Red
                                0xFFE040FB, // Neon Purple
                                0xFFFF1744, // Red
                                0xFF29B6F6, // Blue
                              ].map((colorHex) {
                                final isSelected = colorVal == colorHex;
                                return GestureDetector(
                                  onTap: () {
                                    context.read<VideoEditorBloc>().add(
                                          UpdateTextItemPropertiesEvent(itemId, color: colorHex),
                                        );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Color(colorHex),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.white24,
                                        width: isSelected ? 2.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Color(colorHex).withOpacity(0.5),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: colorHex == 0xFFFFFFFF ? Colors.black : Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Align Preset',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPositionButton(context, itemId, 'Top Left', -0.5, -0.7),
                                const SizedBox(width: 8),
                                _buildPositionButton(context, itemId, 'Top Right', 0.5, -0.7),
                                const SizedBox(width: 8),
                                _buildPositionButton(context, itemId, 'Center', 0.0, 0.0),
                                const SizedBox(width: 8),
                                _buildPositionButton(context, itemId, 'Bottom Left', -0.5, 0.7),
                                const SizedBox(width: 8),
                                _buildPositionButton(context, itemId, 'Bottom Right', 0.5, 0.7),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPositionButton(BuildContext context, String itemId, String label, double normalizedX, double normalizedY) {
    return GestureDetector(
      onTap: () {
        context.read<VideoEditorBloc>().add(
              UpdateTextItemPropertiesEvent(itemId, normalizedX: normalizedX, normalizedY: normalizedY),
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
