import 'package:equatable/equatable.dart';

class EditingConfig extends Equatable {
  final Duration trimStart;
  final Duration trimEnd;
  final String filter; // e.g. 'original', 'grayscale', 'sepia', 'invert', 'vintage', 'warm', 'cool'
  final double? aspectRatio; // e.g. 1.0 (1:1), 16/9, 9/16, 4/3, null (free/original)
  final double speed; // e.g. 0.5, 1.0, 1.5, 2.0
  final String? overlayText;
  final int overlayTextColor; // AARRGGBB hex representation
  final double overlayTextSize;
  final double overlayTextX; // 0.0 to 1.0 relative x coordinate
  final double overlayTextY; // 0.0 to 1.0 relative y coordinate
  final bool isMuted;
  final String? backgroundAudioPath;
  final double originalVolume; // 0.0 to 1.0
  final double backgroundAudioVolume; // 0.0 to 1.0

  const EditingConfig({
    required this.trimStart,
    required this.trimEnd,
    this.filter = 'original',
    this.aspectRatio,
    this.speed = 1.0,
    this.overlayText,
    this.overlayTextColor = 0xFFFFFFFF,
    this.overlayTextSize = 20.0,
    this.overlayTextX = 0.5,
    this.overlayTextY = 0.5,
    this.isMuted = false,
    this.backgroundAudioPath,
    this.originalVolume = 1.0,
    this.backgroundAudioVolume = 0.5,
  });

  EditingConfig copyWith({
    Duration? trimStart,
    Duration? trimEnd,
    String? filter,
    double? Function()? aspectRatio, // Supports setting to null
    double? speed,
    String? Function()? overlayText, // Supports setting to null
    int? overlayTextColor,
    double? overlayTextSize,
    double? overlayTextX,
    double? overlayTextY,
    bool? isMuted,
    String? Function()? backgroundAudioPath, // Supports setting to null
    double? originalVolume,
    double? backgroundAudioVolume,
  }) {
    return EditingConfig(
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      filter: filter ?? this.filter,
      aspectRatio: aspectRatio != null ? aspectRatio() : this.aspectRatio,
      speed: speed ?? this.speed,
      overlayText: overlayText != null ? overlayText() : this.overlayText,
      overlayTextColor: overlayTextColor ?? this.overlayTextColor,
      overlayTextSize: overlayTextSize ?? this.overlayTextSize,
      overlayTextX: overlayTextX ?? this.overlayTextX,
      overlayTextY: overlayTextY ?? this.overlayTextY,
      isMuted: isMuted ?? this.isMuted,
      backgroundAudioPath: backgroundAudioPath != null ? backgroundAudioPath() : this.backgroundAudioPath,
      originalVolume: originalVolume ?? this.originalVolume,
      backgroundAudioVolume: backgroundAudioVolume ?? this.backgroundAudioVolume,
    );
  }

  @override
  List<Object?> get props => [
        trimStart,
        trimEnd,
        filter,
        aspectRatio,
        speed,
        overlayText,
        overlayTextColor,
        overlayTextSize,
        overlayTextX,
        overlayTextY,
        isMuted,
        backgroundAudioPath,
        originalVolume,
        backgroundAudioVolume,
      ];
}
