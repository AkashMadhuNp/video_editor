import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart' show Color;
import 'package:path_provider/path_provider.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/entities/timeline_project.dart';
import '../../presentation/widgets/overlay_renderer/text_overlay_renderer.dart';
import '../models/timeline_project_model.dart';

abstract class VideoExportDataSource {
  Stream<ExportProgress> exportVideo(TimelineProjectModel project);
}

class VideoExportDataSourceImpl implements VideoExportDataSource {
  @override
  Stream<ExportProgress> exportVideo(TimelineProjectModel project) async* {
    final controller = StreamController<ExportProgress>();

    runExport(project, controller);

    yield* controller.stream;
  }

  Future<void> runExport(TimelineProjectModel project, StreamController<ExportProgress> controller) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${tempDir.path}/compiled_video_$timestamp.mp4');

      // 1. Separate tracks
      final videoTrack = project.tracks.firstWhere(
        (t) => t.type == TrackType.video,
        orElse: () => const TimelineTrackModel(id: 'temp_v', type: TrackType.video, items: []),
      );
      final audioTrack = project.tracks.firstWhere(
        (t) => t.type == TrackType.audio,
        orElse: () => const TimelineTrackModel(id: 'temp_a', type: TrackType.audio, items: []),
      );
      final textTrack = project.tracks.firstWhere(
        (t) => t.type == TrackType.text,
        orElse: () => const TimelineTrackModel(id: 'temp_t', type: TrackType.text, items: []),
      );

      final videoItems = videoTrack.items;
      final audioItems = audioTrack.items;
      final textItems = textTrack.items;

      if (videoItems.isEmpty) {
        controller.addError(Exception('No video track found in composition'));
        controller.close();
        return;
      }

      // Determine target resolution based on selected canvas aspect ratio
      int targetWidth = 1280;
      int targetHeight = 720;
      final ratio = project.aspectRatio;
      if (ratio != null) {
        if ((ratio - 16 / 9).abs() < 0.01) {
          targetWidth = 1280;
          targetHeight = 720;
        } else if ((ratio - 9 / 16).abs() < 0.01) {
          targetWidth = 720;
          targetHeight = 1280;
        } else if ((ratio - 1.0).abs() < 0.01) {
          targetWidth = 720;
          targetHeight = 720;
        } else if ((ratio - 4 / 3).abs() < 0.01) {
          targetWidth = 960;
          targetHeight = 720;
        } else {
          targetWidth = 1280;
          targetHeight = (1280 / ratio).round();
          if (targetHeight % 2 != 0) targetHeight++;
        }
      } else {
        // Fallback or Free ratio: use the first video clip's original aspect ratio if available
        final firstVideoItem = videoItems.first;
        final double clipRatio = (firstVideoItem.properties['aspectRatio'] as num? ?? 16 / 9).toDouble();
        targetWidth = 1280;
        targetHeight = (1280 / clipRatio).round();
        if (targetHeight % 2 != 0) targetHeight++;
      }

      // Sort text items by zIndex before rendering
      final List<TimelineItem> sortedTextItems = List<TimelineItem>.from(textItems)
        ..sort((a, b) => (a.properties['zIndex'] as int? ?? 0).compareTo(b.properties['zIndex'] as int? ?? 0));

      // Render text overlay PNG files to a temporary folder
      final List<String> tempPngPaths = [];
      final List<int> tempPngWidths = [];
      final List<int> tempPngHeights = [];
      for (int k = 0; k < sortedTextItems.length; k++) {
        final item = sortedTextItems[k];
        final text = item.properties['text'] as String? ?? '';
        final colorVal = item.properties['color'] as int? ?? 0xFFFFFFFF;
        final fontSize = (item.properties['fontSize'] as num? ?? 72.0).toDouble();
        final scale = (item.properties['scale'] as num? ?? 1.0).toDouble();
        final opacity = (item.properties['opacity'] as num? ?? 1.0).toDouble();

        final tempPngPath = '${tempDir.path}/temp_overlay_${timestamp}_$k.png';
        tempPngPaths.add(tempPngPath);

        final result = await TextOverlayRenderer.renderTextToPng(
          text: text,
          fontSize: fontSize,
          color: Color(colorVal),
          maxWidth: targetWidth.toDouble(),
          maxHeight: targetHeight.toDouble(),
          outputPath: tempPngPath,
          scale: scale,
          opacity: opacity,
        );

        tempPngWidths.add(result.width);
        tempPngHeights.add(result.height);

        print("PATH: ${result.file.path}");
        print("EXISTS: ${result.file.existsSync()}");
        print("SIZE: ${result.file.lengthSync()} (${result.width}x${result.height})");
        developer.log("PATH: ${result.file.path}");
        developer.log("EXISTS: ${result.file.existsSync()}");
        developer.log("SIZE: ${result.file.lengthSync()} (${result.width}x${result.height})");
      }

      // 3. Check which video files have audio streams using FFprobe
      final List<bool> videoHasAudio = [];
      for (final item in videoItems) {
        final path = item.properties['path'] as String? ?? '';
        final hasAudio = await _checkHasAudioStream(path);
        videoHasAudio.add(hasAudio);
      }

      // 4. Construct FFmpeg command arguments
      final List<String> args = ['-y'];

      // Add video inputs
      for (final item in videoItems) {
        final path = item.properties['path'] as String? ?? '';
        final speed = (item.properties['speed'] as num? ?? 1.0).toDouble();
        final trimStartSec = item.trimStart.inMilliseconds / 1000.0;
        final sourceDurSec = (item.duration.inMilliseconds / 1000.0) * speed;

        args.addAll([
          '-ss', trimStartSec.toStringAsFixed(3),
          '-t', sourceDurSec.toStringAsFixed(3),
          '-i', path,
        ]);
      }

      // Add audio inputs
      for (final item in audioItems) {
        final path = item.properties['path'] as String? ?? '';
        final trimStartSec = item.trimStart.inMilliseconds / 1000.0;
        final durSec = item.duration.inMilliseconds / 1000.0;

        args.addAll([
          '-ss', trimStartSec.toStringAsFixed(3),
          '-t', durSec.toStringAsFixed(3),
          '-i', path,
        ]);
      }

      // Add global silence source (to use for video clips that lack audio)
      final silenceIndex = videoItems.length + audioItems.length;
      args.addAll([
        '-f', 'lavfi',
        '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100',
      ]);

      // Add temporary text overlay PNG inputs
      for (final tempPath in tempPngPaths) {
        args.addAll(['-i', tempPath]);
      }

      // 5. Build filter_complex string
      final filterComplexParts = <String>[];

      // A. Process each video clip (Scale, Pad, speed/PTS, color matrix/filter)
      for (int i = 0; i < videoItems.length; i++) {
        final item = videoItems[i];
        final speed = (item.properties['speed'] as num? ?? 1.0).toDouble();
        final filterId = item.properties['filter'] as String? ?? 'original';
        final volume = (item.properties['volume'] as num? ?? 1.0).toDouble();
        final hasAudio = videoHasAudio[i];

        // Video filter chain
        String videoFilter = '[$i:v]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=decrease,pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2,setsar=1';
        
        final effectFilter = _getFFmpegEffectFilter(filterId);
        if (effectFilter.isNotEmpty) {
          videoFilter += ',$effectFilter';
        }
        
        videoFilter += ',setpts=PTS/$speed[v_proc_$i]';
        filterComplexParts.add(videoFilter);

        // Audio filter chain
        if (hasAudio) {
          final audioSpeedFilter = _getFFmpegAudioSpeedFilter(speed);
          final atempoFilterStr = audioSpeedFilter.isNotEmpty ? ',$audioSpeedFilter' : '';
          filterComplexParts.add('[$i:a]volume=$volume$atempoFilterStr[a_proc_$i]');
        } else {
          // Slice silent source for the duration of this clip
          final durSec = item.duration.inMilliseconds / 1000.0;
          filterComplexParts.add('[$silenceIndex:a]atrim=end=${durSec.toStringAsFixed(3)},asetpts=PTS[a_proc_$i]');
        }
      }

      // B. Concatenate video segments
      final int vCount = videoItems.length;
      String lastVideoLabel = '[v_concat]';
      String lastAudioLabel = '[a_concat]';

      if (vCount > 1) {
        String videoConcatInput = '';
        String audioConcatInput = '';
        for (int i = 0; i < vCount; i++) {
          videoConcatInput += '[v_proc_$i]';
          audioConcatInput += '[a_proc_$i]';
        }
        filterComplexParts.add('${videoConcatInput}concat=n=$vCount:v=1:a=0[v_concat]');
        filterComplexParts.add('${audioConcatInput}concat=n=$vCount:v=0:a=1[a_concat]');
      } else {
        lastVideoLabel = '[v_proc_0]';
        lastAudioLabel = '[a_proc_0]';
      }

      // C. Process background audio inputs
      if (audioItems.isNotEmpty) {
        for (int j = 0; j < audioItems.length; j++) {
          final item = audioItems[j];
          final vol = (item.properties['volume'] as num? ?? 1.0).toDouble();
          final delayMs = item.start.inMilliseconds;
          final inputIdx = vCount + j;

          filterComplexParts.add('[$inputIdx:a]volume=$vol,adelay=$delayMs|$delayMs[a_delayed_$j]');
        }

        // Mix background audio with main concatenated audio
        String amixInput = lastAudioLabel;
        for (int j = 0; j < audioItems.length; j++) {
          amixInput += '[a_delayed_$j]';
        }
        final totalInputs = audioItems.length + 1;
        filterComplexParts.add('${amixInput}amix=inputs=$totalInputs:duration=first:dropout_transition=0[a_out]');
      } else {
        filterComplexParts.add('${lastAudioLabel}asplit=1[a_out]');
      }

      // D. Process text overlays on video using center-anchored normalized coordinates
      String currentVideoLabel = lastVideoLabel;
      if (sortedTextItems.isNotEmpty) {
        for (int k = 0; k < sortedTextItems.length; k++) {
          final item = sortedTextItems[k];
          final normalizedX = (item.properties['normalizedX'] as num? ?? 0.0).toDouble();
          final normalizedY = (item.properties['normalizedY'] as num? ?? 0.0).toDouble();
          final startSec = item.start.inMilliseconds / 1000.0;
          final endSec = (item.start + item.duration).inMilliseconds / 1000.0;

          // Convert normalized center coordinates (-1.0 to 1.0) to absolute target pixel center coordinates
          final double centerX = ((normalizedX + 1.0) / 2.0) * targetWidth;
          final double centerY = ((normalizedY + 1.0) / 2.0) * targetHeight;

          // Get raw PNG dimensions
          final double pngWidth = tempPngWidths[k].toDouble();
          final double pngHeight = tempPngHeights[k].toDouble();

          // Calculate top-left corner from center coordinate
          final int posX = (centerX - (pngWidth / 2.0)).round();
          final int posY = (centerY - (pngHeight / 2.0)).round();
          final int inputIdx = silenceIndex + 1 + k;

          final String overlayFilter = 'overlay=x=\'clip($posX,0,main_w-overlay_w)\':y=\'clip($posY,0,main_h-overlay_h)\':enable=\'between(t,${startSec.toStringAsFixed(3)},${endSec.toStringAsFixed(3)})\'';
          final outLabel = k == sortedTextItems.length - 1 ? '[v_out]' : '[v_text_tmp_$k]';

          filterComplexParts.add('$currentVideoLabel[$inputIdx:v]$overlayFilter$outLabel');
          currentVideoLabel = outLabel;
        }
      } else {
        filterComplexParts.add('${currentVideoLabel}split=1[v_out]');
      }

      // Join filters with semicolon
      final filterString = filterComplexParts.join(';');
      args.addAll(['-filter_complex', filterString]);

      // Add mappings for output
      args.addAll([
        '-map', '[v_out]',
        '-map', '[a_out]',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-pix_fmt', 'yuv420p',
        outputFile.path,
      ]);

      final totalDurationMs = project.duration.inMilliseconds;

      // 6. Execute FFmpeg command asynchronously
      await FFmpegKit.executeWithArgumentsAsync(
        args,
        (session) async {
          // Clean up temporary PNG files
          for (final path in tempPngPaths) {
            try {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              developer.log('Failed to delete temp overlay file: $e');
            }
          }

          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            controller.add(ExportProgress(1.0, outputPath: outputFile.path));
            controller.close();
          } else {
            final failStackTrace = await session.getFailStackTrace();
            final logs = await session.getLogsAsString();
            controller.addError(Exception(
              'FFmpeg failed with return code $returnCode.\nStack trace: $failStackTrace\nLogs: $logs'
            ));
            controller.close();
          }
        },
        (log) {
          developer.log('FFmpeg: ${log.getMessage()}');
        },
        (statistics) {
          final timeInMs = statistics.getTime();
          if (totalDurationMs > 0) {
            final progress = (timeInMs / totalDurationMs).clamp(0.0, 0.99);
            controller.add(ExportProgress(progress));
          }
        },
      );
    } catch (e, stackTrace) {
      developer.log('Export error', error: e, stackTrace: stackTrace);
      controller.addError(e);
      controller.close();
    }
  }

  Future<bool> _checkHasAudioStream(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final mediaInfo = session.getMediaInformation();
      if (mediaInfo == null) return false;
      final streams = mediaInfo.getStreams();
      for (final stream in streams) {
        if (stream.getType() == 'audio') {
          return true;
        }
      }
    } catch (e) {
      developer.log('FFprobe error for $filePath', error: e);
    }
    return false;
  }


  String _getFFmpegEffectFilter(String filterId) {
    switch (filterId) {
      case 'grayscale':
        return 'colorchannelmixer=0.2126:0.7152:0.0722:0:0.2126:0.7152:0.0722:0:0.2126:0.7152:0.0722';
      case 'sepia':
        return 'colorchannelmixer=0.393:0.769:0.189:0:0.349:0.686:0.168:0:0.272:0.534:0.131';
      case 'invert':
        return 'negate';
      case 'vintage':
        return 'colorchannelmixer=0.9:0:0:0:0:0.8:0:0:0:0:0.5';
      case 'warm':
        return 'lutrgb=r=\'val*1.2+10\':g=\'val*1.0+5\':b=\'val*0.8-10\'';
      case 'cool':
        return 'lutrgb=r=\'val*0.8-10\':g=\'val*1.0+5\':b=\'val*1.2+15\'';
      case 'original':
      default:
        return '';
    }
  }


  String _getFFmpegAudioSpeedFilter(double speed) {
    if (speed == 1.0) return '';
    
    final List<String> filters = [];
    double remainingSpeed = speed;
    
    while (remainingSpeed > 2.0) {
      filters.add('atempo=2.0');
      remainingSpeed /= 2.0;
    }
    while (remainingSpeed < 0.5) {
      filters.add('atempo=0.5');
      remainingSpeed /= 0.5;
    }
    if ((remainingSpeed - 1.0).abs() > 0.001) {
      filters.add('atempo=${remainingSpeed.toStringAsFixed(3)}');
    }
    
    return filters.join(',');
  }

}
