import '../../../../core/error/failures.dart';
import '../entities/video_file.dart';
import '../entities/timeline_project.dart';

class ExportProgress {
  final double progress;
  final String? outputPath;

  const ExportProgress(this.progress, {this.outputPath});
}

abstract class VideoRepository {
  Future<Either<Failure, List<VideoFile>>> pickVideos();
  Stream<Either<Failure, ExportProgress>> exportVideo(TimelineProject project);
}
