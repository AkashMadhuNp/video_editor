import '../../../../core/error/failures.dart';
import '../entities/timeline_project.dart';
import '../repositories/video_repository.dart';

class ExportVideoParams {
  final TimelineProject project;

  ExportVideoParams({required this.project});
}

class ExportVideo {
  final VideoRepository repository;

  ExportVideo(this.repository);

  Stream<Either<Failure, ExportProgress>> call(ExportVideoParams params) {
    return repository.exportVideo(params.project);
  }
}
