import '../../domain/entities/timeline_project.dart';

class TimelineItemModel extends TimelineItem {
  const TimelineItemModel({
    required super.id,
    required super.name,
    required super.start,
    required super.duration,
    required super.trimStart,
    required super.trimEnd,
    required super.properties,
  });

  factory TimelineItemModel.fromDomain(TimelineItem item) {
    return TimelineItemModel(
      id: item.id,
      name: item.name,
      start: item.start,
      duration: item.duration,
      trimStart: item.trimStart,
      trimEnd: item.trimEnd,
      properties: item.properties,
    );
  }

  factory TimelineItemModel.fromJson(Map<String, dynamic> json) {
    return TimelineItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      start: Duration(milliseconds: json['startMs'] as int),
      duration: Duration(milliseconds: json['durationMs'] as int),
      trimStart: Duration(milliseconds: json['trimStartMs'] as int),
      trimEnd: Duration(milliseconds: json['trimEndMs'] as int),
      properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startMs': start.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'trimStartMs': trimStart.inMilliseconds,
      'trimEndMs': trimEnd.inMilliseconds,
      'properties': properties,
    };
  }
}

class TimelineTrackModel extends TimelineTrack {
  const TimelineTrackModel({
    required super.id,
    required super.type,
    required super.items,
  });

  factory TimelineTrackModel.fromDomain(TimelineTrack track) {
    return TimelineTrackModel(
      id: track.id,
      type: track.type,
      items: track.items.map((i) => TimelineItemModel.fromDomain(i)).toList(),
    );
  }

  factory TimelineTrackModel.fromJson(Map<String, dynamic> json) {
    return TimelineTrackModel(
      id: json['id'] as String,
      type: TrackType.values.byName(json['type'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => TimelineItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'items': items.map((item) {
        if (item is TimelineItemModel) {
          return item.toJson();
        } else {
          return TimelineItemModel.fromDomain(item).toJson();
        }
      }).toList(),
    };
  }
}

class TimelineProjectModel extends TimelineProject {
  const TimelineProjectModel({
    required super.id,
    required super.name,
    required super.duration,
    required super.tracks,
    super.aspectRatio,
  });

  factory TimelineProjectModel.fromDomain(TimelineProject project) {
    return TimelineProjectModel(
      id: project.id,
      name: project.name,
      duration: project.duration,
      tracks: project.tracks.map((t) => TimelineTrackModel.fromDomain(t)).toList(),
      aspectRatio: project.aspectRatio,
    );
  }

  factory TimelineProjectModel.fromJson(Map<String, dynamic> json) {
    return TimelineProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((track) => TimelineTrackModel.fromJson(track as Map<String, dynamic>))
              .toList() ??
          [],
      aspectRatio: json['aspectRatio'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMs': duration.inMilliseconds,
      'aspectRatio': aspectRatio,
      'tracks': tracks.map((track) {
        if (track is TimelineTrackModel) {
          return track.toJson();
        } else {
          return TimelineTrackModel.fromDomain(track).toJson();
        }
      }).toList(),
    };
  }
}
