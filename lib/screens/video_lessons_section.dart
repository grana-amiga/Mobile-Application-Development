import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../data/videos_data.dart';
import '../models/lesson_video.dart';
import '../theme/app_theme.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';

/// Seção "Videoaulas" da aba Aprender: uma lista com as 6 aulas rápidas.
class VideoLessonsSection extends StatelessWidget {
  const VideoLessonsSection({super.key});

  String _duration(Duration time) {
    final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
    return '${time.inMinutes}:$seconds min';
  }

  @override
  Widget build(BuildContext context) {
    // Column simples: esta seção fica dentro do ListView da aba Aprender.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('Videoaulas', trailing: '${allVideos.length} aulas rápidas'),
        for (final video in allVideos)
          _VideoTile(
            video: video,
            duration: _duration(video.duration),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.video,
              arguments: video,
            ),
          ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.video,
    required this.duration,
    required this.onTap,
  });

  final LessonVideo video;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(14),
            decoration: AppDecor.card(radius: 24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.petrol,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(video.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aula ${video.number} · ${video.title}', style: AppText.h3),
                      const SizedBox(height: 2),
                      Text(video.description, style: AppText.small),
                      const SizedBox(height: 6),
                      TagChip(
                        icon: Icons.schedule,
                        label: duration,
                        background: AppColors.mintSoft,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.play_circle_fill, color: AppColors.petrol, size: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
