import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: AppColors.bg(context),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // ── Header (Harmonized with Home & Stats) ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Posture',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Sense',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandGreen,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' Routines',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.subtext(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Daily clinical exercises for spinal relief',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.subtext(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Light / Dark Mode Toggle
                      GestureDetector(
                        onTap: () => ThemeController.instance.toggleTheme(),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.surf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Exercise Library',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Follow guided micro-routines to relieve neck tension and reset cervical curvature.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.subtext(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 140), // Fully clear the floating nav pill
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
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(context),
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
                    color: AppColors.surfLight(context),
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
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            exercise.category,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.subtext(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.subtext(context),
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.subtext(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
