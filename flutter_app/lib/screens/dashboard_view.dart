import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/exercise_detail_sheet.dart';
import 'posture_scan_screen.dart'; // From team member's code!
import '../services/posture_history_manager.dart';

class DashboardView extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const DashboardView({super.key, this.onProfileTap});

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hourVal = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hourVal:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';

    return AnimatedBuilder(
      animation: PostureHistoryManager(),
      builder: (context, _) {
        final manager = PostureHistoryManager();
        final latest = manager.latestResult;

        final int score = latest != null ? (100 - latest.riskScore) : 82;
        final double progressValue = score / 100.0;

        final int streakVal = manager.streak;
        final int avgScoreVal = manager.averageScore.round();
        final int totalSessionsVal = manager.totalSessions;

        return Container(
          color: AppColors.background,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onProfileTap,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.surfaceLight,
                          child: const Icon(Icons.person, color: AppColors.primaryAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Posture Health Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceLight, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S POSTURE HEALTH',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$score',
                              style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.0,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                              child: Text(
                                '%',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor: AppColors.surfaceLight,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              latest != null ? 'Last angle: ${latest.angle.toStringAsFixed(1)}°' : '+4 pts today',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          latest != null 
                              ? 'Your last posture status was classified as ${latest.riskLevel.shortLabel}.'
                              : 'Good posture! Keep maintaining your spine alignment.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard('🔥', '$streakVal', 'days\nStreak'),
                      const SizedBox(width: 12),
                      _buildStatCard('📊', '$avgScoreVal%', '\nAvg Score'),
                      const SizedBox(width: 12),
                      _buildStatCard('✅', '$totalSessionsVal', 'total\nSessions'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // CTA Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PostureScanScreen()));
                      },
                      icon: const Icon(Icons.document_scanner, size: 24),
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Posture Scan',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'AI-powered body analysis',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Exercises
                  Text(
                    'Quick Exercises',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildExerciseCard(
                          context,
                          '🧘',
                          'Chin Tuck',
                          '2 min',
                          [
                            'Sit or stand tall with relaxed shoulders.',
                            'Look straight ahead and pull your chin straight back, as if making a double chin.',
                            'Hold this position for 5 seconds.',
                            'Relax and return to neutral. Repeat 10-15 times.'
                          ],
                        ),
                        const SizedBox(width: 16),
                        _buildExerciseCard(
                          context,
                          '🔄',
                          'Neck Roll',
                          '3 min',
                          [
                            'Sit comfortably. Slowly drop your chin towards your chest.',
                            'Roll your head slowly to the left shoulder, holding for 3 seconds.',
                            'Roll it back down and over to the right shoulder, holding for 3 seconds.',
                            'Repeat this gentle motion 5 times on each side.'
                          ],
                        ),
                        const SizedBox(width: 16),
                        _buildExerciseCard(
                          context,
                          '💪',
                          'Shoulder Shrug',
                          '1 min',
                          [
                            'Inhale and lift your shoulders up towards your ears as high as possible.',
                            'Hold the shrug for 3-5 seconds.',
                            'Exhale deeply and drop your shoulders back down, relaxing the muscles.',
                            'Repeat 10 times.'
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // Recent Sessions
                  Text(
                    'Recent Sessions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (manager.history.isNotEmpty)
                    ...manager.history.map((result) {
                      final scoreText = '${100 - result.riskScore}%';
                      return _buildSessionItem(
                        _formatDateTime(result.timestamp),
                        result.riskLevel.shortLabel,
                        scoreText,
                        result.riskLevel.color,
                      );
                    })
                  else ...[
                    _buildSessionItem('Today, 9:14 AM', 'Good', '82%', AppColors.riskLow),
                    _buildSessionItem('Yesterday, 6:30 PM', 'Fair', '71%', AppColors.riskModerate),
                    _buildSessionItem('Jul 10, 8:00 AM', 'Good', '78%', AppColors.riskLow),
                  ],
                  
                  const SizedBox(height: 100), // padding for the bottom nav bar
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$value ',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, String emoji, String title, String time, List<String> steps) {
    return GestureDetector(
      onTap: () {
        ExerciseDetailSheet.show(
          context,
          title: title,
          emoji: emoji,
          time: time,
          steps: steps,
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(String date, String status, String score, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Posture Score',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                score,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
