import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'features/video_editor/data/datasources/video_export_data_source.dart';
import 'features/video_editor/data/datasources/video_local_data_source.dart';
import 'features/video_editor/data/repositories/video_repository_impl.dart';
import 'features/video_editor/domain/repositories/video_repository.dart';

import 'features/video_editor/domain/usecases/export_video.dart';
import 'features/video_editor/domain/usecases/pick_video.dart';
import 'features/video_editor/presentation/blocs/video_editor/video_editor_bloc.dart';
import 'features/video_editor/presentation/blocs/video_picker/video_picker_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => VideoPickerBloc(pickVideoUseCase: sl()));
  sl.registerFactory(() => VideoEditorBloc(exportVideoUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => PickVideo(sl()));
  sl.registerLazySingleton(() => ExportVideo(sl()));

  // Repository
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(
      localDataSource: sl(),
      exportDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<VideoLocalDataSource>(
    () => VideoLocalDataSourceImpl(picker: sl()),
  );
  sl.registerLazySingleton<VideoExportDataSource>(
    () => VideoExportDataSourceImpl(),
  );

  // External
  sl.registerLazySingleton(() => ImagePicker());
}
