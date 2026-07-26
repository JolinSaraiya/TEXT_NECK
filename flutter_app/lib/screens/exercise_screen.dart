import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/exercise_detail_sheet.dart';

class Exercise {
  final String title;
  final String emoji;
  final String time;
  final String category;
  final List<String> steps;

  const Exercise({
    required this.title,
    required this.emoji,
    required this.time,
    required this.category,
    required this.steps,
  });
}

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  static const List<Exercise> _exercises = [
    Exercise(
      title: 'Chin Tuck',
      emoji: '🧘',
      time: '2 min',
      category: 'Spine Alignment',
      steps: [
        'Sit or stand tall with relaxed shoulders.',
        'Look straight ahead and pull your chin straight back, as if making a double chin.',
        'Hold this position for 5 seconds.',
        'Relax and return to neutral. Repeat 10-15 times.',
      ],
    ),
    Exercise(
      title: 'Neck Roll',
      emoji: '🔄',
      time: '3 min',
      category: 'Muscle Relief',
      steps: [
        'Sit comfortably. Slowly drop your chin towards your chest.',
        'Roll your head slowly to the left shoulder, holding for 3 seconds.',
        'Roll it back down and over to the right shoulder, holding for 3 seconds.',
        'Repeat this gentle motion 5 times on each side.',
      ],
    ),
    Exercise(
      title: 'Shoulder Shrug',
      emoji: '💪',
      time: '1 min',
      category: 'Tension Release',
      steps: [
        'Inhale and lift your shoulders up towards your ears as high as possible.',
        'Hold the shrug for 3-5 seconds.',
        'Exhale deeply and drop your shoulders back down, relaxing the muscles.',
        'Repeat 10 times.',
      ],
    ),
    Exercise(
      title: 'Cat-Cow Stretch',
      emoji: '🐈',
      time: '4 min',
      category: 'Spine Flexibility',
      steps: [
        'Get on your hands and knees (tabletop position).',
        'Inhale, arch your back downwards, and look up towards the ceiling (Cow).',
        'Exhale, round your spine upwards, and tuck your chin to your chest (Cat).',
        'Flow between these two positions smoothly for 2-3 minutes.',
      ],
    ),
    Exercise(
      title: 'Corner Chest Stretch',
      emoji: '🚪',
      time: '2 min',
      category: 'Posture Correction',
      steps: [
        'Stand facing a corner, about 2 feet away.',
        'Place your forearms on each wall with elbows at shoulder height.',
        'Lean forward slowly until you feel a gentle stretch across your chest.',
        'Hold for 20-30 seconds, breathe deeply, and repeat 3 times.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercise Library',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daily routines to fix your text neck.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 110), // Padding to clear the bottom nav pill
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return _buildExerciseListItem(context, exercise);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseListItem(BuildContext context, Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surfaceLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ExerciseDetailSheet.show(
              context,
              title: exercise.title,
              emoji: exercise.emoji,
              time: exercise.time,
              steps: exercise.steps,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Emoji Icon Box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    exercise.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            exercise.category,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            exercise.time,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                // Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
