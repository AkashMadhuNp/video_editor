import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player_mobile/core/usecases/usecase.dart';
import '../../../domain/usecases/pick_video.dart';
import 'video_picker_event.dart';
import 'video_picker_state.dart';

class VideoPickerBloc extends Bloc<VideoPickerEvent, VideoPickerState> {
  final PickVideo pickVideoUseCase;

  VideoPickerBloc({required this.pickVideoUseCase}) : super(VideoPickerInitial()) {
    on<PickVideoEvent>(_onPickVideo);
    on<ResetPickerEvent>(_onResetPicker);
  }

  Future<void> _onPickVideo(
    PickVideoEvent event,
    Emitter<VideoPickerState> emit,
  ) async {
    emit(VideoPickerLoading());
    final result = await pickVideoUseCase(NoParams());
    result.fold(
      (failure) => emit(VideoPickerError(failure.message)),
      (videos) => emit(VideoPickerLoaded(videos)),
    );
  }

  void _onResetPicker(
    ResetPickerEvent event,
    Emitter<VideoPickerState> emit,
  ) {
    emit(VideoPickerInitial());
  }
}
