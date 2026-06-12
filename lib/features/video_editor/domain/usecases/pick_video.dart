import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/video_file.dart';
import '../repositories/video_repository.dart';

class PickVideo implements UseCase<Either<Failure, List<VideoFile>>, NoParams> {
  final VideoRepository repository;

  PickVideo(this.repository);

  @override
  Future<Either<Failure, List<VideoFile>>> call(NoParams params) async {
    return await repository.pickVideos();
  }
}
