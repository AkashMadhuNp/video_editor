import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../blocs/video_editor/video_editor_bloc.dart';
import '../blocs/video_editor/video_editor_event.dart';
import '../blocs/video_picker/video_picker_bloc.dart';
import '../blocs/video_picker/video_picker_event.dart';
import '../blocs/video_picker/video_picker_state.dart';
import 'editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<VideoPickerBloc>(),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<VideoPickerBloc, VideoPickerState>(
        listener: (context, state) {
          if (state is VideoPickerLoaded) {
            final pickerBloc = context.read<VideoPickerBloc>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => sl<VideoEditorBloc>()..add(InitEditorEvent(state.video)),
                  child: EditorPage(video: state.video),
                ),
              ),
            ).then((_) {
              // Reset picker state when returning to home
              pickerBloc.add(ResetPickerEvent());
            });
          } else if (state is VideoPickerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.darkGradient,
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Premium Header Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                          child: const Text(
                            'STUDIO V',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Clean Video Editor & Player',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Action Container (Upload / Loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: BlocBuilder<VideoPickerBloc, VideoPickerState>(
                      builder: (context, state) {
                        final isLoading = state is VideoPickerLoading;

                        return GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  context.read<VideoPickerBloc>().add(PickVideoEvent());
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.primaryGradient.colors
                                    .map((color) => color.withOpacity(0.08))
                                    .toList(),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isLoading ? AppColors.secondary : AppColors.primary.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                color: Colors.black12,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading) ...[
                                      const CircularProgressIndicator(
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Extracting video metadata...',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.video_library_rounded,
                                          color: AppColors.secondary,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Import New Video',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Supports MP4, MOV from gallery',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Mock Recent Projects History Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Exports',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent Grid list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final mockData = [
                          {'title': 'skateboard_slowmo.mp4', 'date': '2 hours ago', 'icon': Icons.directions_bike},
                          {'title': 'beach_vibe_edit.mp4', 'date': 'Yesterday', 'icon': Icons.beach_access},
                          {'title': 'concert_night_mix.mp4', 'date': '3 days ago', 'icon': Icons.music_note},
                          {'title': 'cooking_vlog_hdr.mp4', 'date': '1 week ago', 'icon': Icons.flatware},
                        ];
                        final item = mockData[index];

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Click "Import New Video" to edit custom videos.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        color: Colors.white24,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['title'] as String,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item['date'] as String,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
