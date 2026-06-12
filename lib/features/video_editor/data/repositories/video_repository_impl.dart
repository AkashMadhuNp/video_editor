import '../../../../core/error/failures.dart';
import '../../domain/entities/video_file.dart';
import '../../domain/entities/timeline_project.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_local_data_source.dart';
import '../datasources/video_export_data_source.dart';
import '../models/timeline_project_model.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoLocalDataSource localDataSource;
  final VideoExportDataSource exportDataSource;

  VideoRepositoryImpl({
    required this.localDataSource,
    required this.exportDataSource,
  });

  @override
  Future<Either<Failure, List<VideoFile>>> pickVideos() async {
    try {
      final videos = await localDataSource.pickVideos();
      return Right(videos);
    } catch (e) {
      return Left(PickVideoFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, ExportProgress>> exportVideo(
    TimelineProject project,
  ) async* {
    final projectModel = TimelineProjectModel.fromDomain(project);

    try {
      await for (final progress in exportDataSource.exportVideo(projectModel)) {
        yield Right(progress);
      }
    } catch (e) {
      yield Left(ExportVideoFailure(e.toString()));
    }
  }
}
