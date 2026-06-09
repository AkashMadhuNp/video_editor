import 'package:equatable/equatable.dart';

enum TrackType { video, audio, text }

class TimelineItem extends Equatable {
  final String id;
  final String name;
  final Duration start;       // Absolute start time on the project timeline
  final Duration duration;    // Active duration on the timeline
  final Duration trimStart;   // Inner trim offset from original media source
  final Duration trimEnd;     // Inner trim end offset from original media source
  final Map<String, dynamic> properties;

  const TimelineItem({
    required this.id,
    required this.name,
    required this.start,
    required this.duration,
    required this.trimStart,
    required this.trimEnd,
    required this.properties,
  });

  TimelineItem copyWith({
    String? id,
    String? name,
    Duration? start,
    Duration? duration,
    Duration? trimStart,
    Duration? trimEnd,
    Map<String, dynamic>? properties,
  }) {
    return TimelineItem(
      id: id ?? this.id,
      name: name ?? this.name,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      properties: properties ?? Map<String, dynamic>.from(this.properties),
    );
  }

  @override
  List<Object?> get props => [id, name, start, duration, trimStart, trimEnd, properties];
}

class TimelineTrack extends Equatable {
  final String id;
  final TrackType type;
  final List<TimelineItem> items;

  const TimelineTrack({
    required this.id,
    required this.type,
    required this.items,
  });

  TimelineTrack copyWith({
    String? id,
    TrackType? type,
    List<TimelineItem>? items,
  }) {
    return TimelineTrack(
      id: id ?? this.id,
      type: type ?? this.type,
      items: items ?? List<TimelineItem>.from(this.items),
    );
  }

  @override
  List<Object?> get props => [id, type, items];
}

class TimelineProject extends Equatable {
  final String id;
  final String name;
  final Duration duration;
  final List<TimelineTrack> tracks;
  final double? aspectRatio;

  const TimelineProject({
    required this.id,
    required this.name,
    required this.duration,
    required this.tracks,
    this.aspectRatio,
  });

  TimelineProject copyWith({
    String? id,
    String? name,
    Duration? duration,
    List<TimelineTrack>? tracks,
    double? Function()? aspectRatio,
  }) {
    return TimelineProject(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      tracks: tracks ?? this.tracks,
      aspectRatio: aspectRatio != null ? aspectRatio() : this.aspectRatio,
    );
  }

  @override
  List<Object?> get props => [id, name, duration, tracks, aspectRatio];
}
