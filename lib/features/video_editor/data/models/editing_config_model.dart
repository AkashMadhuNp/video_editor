import '../../domain/entities/editing_config.dart';

class EditingConfigModel extends EditingConfig {
  const EditingConfigModel({
    required super.trimStart,
    required super.trimEnd,
    super.filter,
    super.aspectRatio,
    super.speed,
    super.overlayText,
    super.overlayTextColor,
    super.overlayTextSize,
    super.overlayTextX,
    super.overlayTextY,
    super.isMuted,
    super.backgroundAudioPath,
    super.originalVolume,
    super.backgroundAudioVolume,
  });

  factory EditingConfigModel.fromDomain(EditingConfig config) {
    return EditingConfigModel(
      trimStart: config.trimStart,
      trimEnd: config.trimEnd,
      filter: config.filter,
      aspectRatio: config.aspectRatio,
      speed: config.speed,
      overlayText: config.overlayText,
      overlayTextColor: config.overlayTextColor,
      overlayTextSize: config.overlayTextSize,
      overlayTextX: config.overlayTextX,
      overlayTextY: config.overlayTextY,
      isMuted: config.isMuted,
      backgroundAudioPath: config.backgroundAudioPath,
      originalVolume: config.originalVolume,
      backgroundAudioVolume: config.backgroundAudioVolume,
    );
  }

  factory EditingConfigModel.fromJson(Map<String, dynamic> json) {
    return EditingConfigModel(
      trimStart: Duration(milliseconds: json['trimStartMs'] as int),
      trimEnd: Duration(milliseconds: json['trimEndMs'] as int),
      filter: json['filter'] as String? ?? 'original',
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      speed: (json['speed'] as num? ?? 1.0).toDouble(),
      overlayText: json['overlayText'] as String?,
      overlayTextColor: json['overlayTextColor'] as int? ?? 0xFFFFFFFF,
      overlayTextSize: (json['overlayTextSize'] as num? ?? 20.0).toDouble(),
      overlayTextX: (json['overlayTextX'] as num? ?? 0.5).toDouble(),
      overlayTextY: (json['overlayTextY'] as num? ?? 0.5).toDouble(),
      isMuted: json['isMuted'] as bool? ?? false,
      backgroundAudioPath: json['backgroundAudioPath'] as String?,
      originalVolume: (json['originalVolume'] as num? ?? 1.0).toDouble(),
      backgroundAudioVolume: (json['backgroundAudioVolume'] as num? ?? 0.5).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trimStartMs': trimStart.inMilliseconds,
      'trimEndMs': trimEnd.inMilliseconds,
      'filter': filter,
      'aspectRatio': aspectRatio,
      'speed': speed,
      'overlayText': overlayText,
      'overlayTextColor': overlayTextColor,
      'overlayTextSize': overlayTextSize,
      'overlayTextX': overlayTextX,
      'overlayTextY': overlayTextY,
      'isMuted': isMuted,
      'backgroundAudioPath': backgroundAudioPath,
      'originalVolume': originalVolume,
      'backgroundAudioVolume': backgroundAudioVolume,
    };
  }
}
