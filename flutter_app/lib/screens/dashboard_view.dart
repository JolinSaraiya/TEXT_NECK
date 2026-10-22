import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/exercise_detail_sheet.dart';
import 'posture_scan_screen.dart';
import 'photo_analysis_screen.dart';
import '../services/posture_history_manager.dart';
import 'scan_detail_screen.dart';

class DashboardView extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onExercisesTap;

  const DashboardView({
    super.key,
    this.onProfileTap,
    this.onExercisesTap,
  });

  String _formatDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([PostureHistoryManager(), ThemeController.instance]),
      builder: (context, _) {
        final manager = PostureHistoryManager();
        final latest = manager.latestResult;
        final bool hasData = manager.history.isNotEmpty;
        final int score = latest != null
            ? latest.postureScore
            : (hasData ? manager.averageScore.round() : 0);
        final double progressValue = hasData ? (score / 100.0).clamp(0.0, 1.0) : 0.0;
        final Color statusColor = latest != null
            ? latest.riskLevel.color
            : (hasData ? AppColors.brandGreen : AppColors.subtext(context));
        final int streakVal = manager.streak;
        final int avgScoreVal = hasData ? manager.averageScore.round() : 0;
        final int totalSessionsVal = manager.totalSessions;
        final String angleLabel = latest != null
            ? 'Last angle: ${latest.angle.toStringAsFixed(1)}\u00b0'
            : (hasData ? 'Posture active' : 'No scans yet');
        final String statusLabel = latest != null
            ? latest.riskLevel.shortLabel
            : (hasData ? 'Active' : 'No scans yet');

        return Container(
          color: AppColors.bg(context),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────────
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
                                  ],
                                ),
                              ),
                              Text(
                                'Better Posture \u2022 Healthier You',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.subtext(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _ActionBtn(
                            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? const Color(0xFFFBBF24) : AppColors.brandGreenDark,
                            bgColor: isDark ? const Color(0xFF263246) : const Color(0xFFE5ECE8),
                            borderColor: AppColors.border(context),
                            onTap: () => ThemeController.instance.toggleTheme(),
                          ),
                          const SizedBox(width: 8),
                          _ActionBtn(
                            icon: Icons.settings_outlined,
                            color: AppColors.text(context),
                            bgColor: AppColors.surf(context),
                            borderColor: AppColors.border(context),
                            onTap: onProfileTap ?? () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Greeting ────────────────────────────────────────────────
                  Text.rich(TextSpan(children: [
                    TextSpan(
                      text: 'Hello, $displayName ',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text(context),
                      ),
                    ),
                    const TextSpan(text: '\ud83d\udc4b', style: TextStyle(fontSize: 22)),
                  ])),
                  const SizedBox(height: 4),
                  Text(
                    'Keep tracking your posture for a healthier spine.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.subtext(context)),
                  ),
                  const SizedBox(height: 20),

                  // ── Today's Posture Health Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surf(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border(context), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow(context),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TODAY'S POSTURE HEALTH",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.subtext(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Score + angle badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              hasData ? '$score' : '--',
                              style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text(context),
                                height: 1.0,
                              ),
                            ),
                            if (hasData)
                              Text(
                                '%',
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: isDark ? 0.22 : 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                angleLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: isDark
                                ? const Color(0xFF263346)
                                : const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                hasData ? statusColor : AppColors.subtext(context)),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 14),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.subtext(context),
                            ),
                            children: hasData
                                ? [
                                    const TextSpan(
                                        text: 'Your last posture status was classified as '),
                                    TextSpan(
                                      text: '$statusLabel.',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ]
                                : [
                                    const TextSpan(
                                      text: 'Start a scan below to measure your posture in real time.',
                                    ),
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  // ── Stat Cards ───────────────────────────────────────────────
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '$streakVal',
                        unit: 'days',
                        label: 'Streak',
                        iconColor: AppColors.streakIconLight,
                        iconBg: isDark ? AppColors.streakIconBgDark : AppColors.streakIconBgLight,
                        cardBg: isDark ? AppColors.streakBgDark : AppColors.streakBgLight,
                        subtextColor: AppColors.subtext(context),
                        textColor: AppColors.text(context),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.bar_chart_rounded,
                        value: hasData ? '$avgScoreVal%' : '--',
                        unit: '',
                        label: 'Avg Score',
                        iconColor: AppColors.avgIconLight,
                        iconBg: isDark ? AppColors.avgIconBgDark : AppColors.avgIconBgLight,
                        cardBg: isDark ? AppColors.avgBgDark : AppColors.avgBgLight,
                        subtextColor: AppColors.subtext(context),
                        textColor: AppColors.text(context),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.check_circle_rounded,
                        value: '$totalSessionsVal',
                        unit: 'total',
                        label: 'Sessions',
                        iconColor: AppColors.sessionIconLight,
                        iconBg: isDark ? AppColors.sessionIconBgDark : AppColors.sessionIconBgLight,
                        cardBg: isDark ? AppColors.sessionBgDark : AppColors.sessionBgLight,
                        subtextColor: AppColors.subtext(context),
                        textColor: AppColors.text(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Start Posture Scan ───────────────────────────────────────
                  GestureDetector(
                    onTap: () => _showScanModeSelection(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: isDark
                          ? BoxDecoration(
                              color: const Color(0xFF143026),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: AppColors.brandGreen.withValues(alpha: 0.3),
                                  width: 1.2),
                            )
                          : BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandGreen.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.brandGreen.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.center_focus_strong_rounded,
                              color: isDark ? AppColors.brandGreen : Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Posture Scan',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.text(context) : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'AI-powered body analysis',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.subtext(context)
                                        : Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.brandGreen : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: isDark ? const Color(0xFF0F1723) : const Color(0xFF0D9488),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Quick Exercises ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_run_rounded,
                              color: AppColors.brandGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Exercises',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onExercisesTap,
                        child: Row(
                          children: [
                            Text('See All',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandGreen,
                                )),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.brandGreen, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _ExerciseCard(
                        isDark: isDark,
                        icon: Icons.self_improvement_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        iconBg: isDark ? const Color(0xFF2E1F4A) : const Color(0xFFEDE9FE),
                        title: 'Neck Stretch',
                        subtitle: 'Relieve tension',
                        time: '2 min',
                        emoji: '\ud83e\uddd8',
                        steps: const [
                          'Sit or stand tall with relaxed shoulders.',
                          'Look straight ahead and pull your chin straight back.',
                          'Hold this position for 5 seconds.',
                          'Relax and return to neutral. Repeat 10-15 times.',
                        ],
                        onTap: (t, e, ti, s) => ExerciseDetailSheet.show(
                          context, title: t, emoji: e, time: ti, steps: s,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ExerciseCard(
                        isDark: isDark,
                        icon: Icons.rotate_right_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        iconBg: isDark ? const Color(0xFF1A2947) : const Color(0xFFDBEAFE),
                        title: 'Shoulder Roll',
                        subtitle: 'Improve flexibility',
                        time: '3 min',
                        emoji: '\ud83d\udd04',
                        steps: const [
                          'Sit comfortably. Drop your chin towards your chest.',
                          'Roll your head to the left shoulder, hold for 3 sec.',
                          'Roll down and over to the right shoulder.',
                          'Repeat 5 times on each side.',
                        ],
                        onTap: (t, e, ti, s) => ExerciseDetailSheet.show(
                          context, title: t, emoji: e, time: ti, steps: s,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ExerciseCard(
                        isDark: isDark,
                        icon: Icons.fitness_center_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        iconBg: isDark ? const Color(0xFF2C1E0A) : const Color(0xFFFEF3C7),
                        title: 'Upper Back',
                        subtitle: 'Build strength',
                        time: '1 min',
                        emoji: '\ud83d\udcaa',
                        steps: const [
                          'Inhale and lift shoulders up towards your ears.',
                          'Hold the shrug for 3-5 seconds.',
                          'Exhale and drop your shoulders back down.',
                          'Repeat 10 times.',
                        ],
                        onTap: (t, e, ti, s) => ExerciseDetailSheet.show(
                          context, title: t, emoji: e, time: ti, steps: s,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── Recent Sessions ──────────────────────────────────────────
                  Text(
                    'Recent Sessions',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (manager.history.isNotEmpty)
                    ...manager.history.map((result) => _SessionTile(
                          isDark: isDark,
                          date: _formatDateTime(result.timestamp),
                          status: result.riskLevel.shortLabel,
                          score: '${result.postureScore}%',
                          statusColor: result.riskLevel.color,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScanDetailScreen.fromSession(result),
                            ),
                          ),
                        ))
                  else
                    _EmptyState(context: context),

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showScanModeSelection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.center_focus_strong_rounded,
                    color: AppColors.brandGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Choose Scan Method',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context))),
                  Text('How would you like to analyze your posture?',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.subtext(context))),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            _ScanTile(
              context: context, isDark: isDark,
              icon: Icons.videocam_rounded,
              iconBg: AppColors.brandGreen.withValues(alpha: 0.12),
              iconColor: AppColors.brandGreen,
              badge: 'LIVE \u2022 3s AUTO-LOCK',
              badgeBg: AppColors.brandGreen.withValues(alpha: 0.15),
              badgeColor: AppColors.brandGreen,
              title: 'Live Camera Scan',
              description: 'Real-time camera with live biomechanical angle overlays. Posture is auto-locked after 3 seconds.',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PostureScanScreen()));
              },
            ),
            const SizedBox(height: 12),
            _ScanTile(
              context: context, isDark: isDark,
              icon: Icons.add_photo_alternate_rounded,
              iconBg: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              iconColor: const Color(0xFF38BDF8),
              badge: 'GALLERY & FILES',
              badgeBg: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              badgeColor: const Color(0xFF38BDF8),
              title: 'Upload Photo Analysis',
              description: 'Upload a lateral side-profile photo. Detects landmarks and computes posture metrics automatically.',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PhotoAnalysisScreen()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bgColor, borderColor;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color,
      required this.bgColor, required this.borderColor, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, unit, label;
  final Color iconColor, iconBg, cardBg, subtextColor, textColor;
  const _StatCard({required this.icon, required this.value, required this.unit,
      required this.label, required this.iconColor, required this.iconBg,
      required this.cardBg, required this.subtextColor, required this.textColor});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 19, fontWeight: FontWeight.w900, color: textColor)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(unit, style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: subtextColor, fontWeight: FontWeight.w500)),
              Icon(Icons.chevron_right_rounded,
                  size: 15, color: subtextColor.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ExerciseCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle, time, emoji;
  final List<String> steps;
  final void Function(String, String, String, List<String>) onTap;

  const _ExerciseCard({
    required this.isDark, required this.icon, required this.iconColor,
    required this.iconBg, required this.title, required this.subtitle,
    required this.time, required this.emoji, required this.steps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onTap(title, emoji, time, steps),
    child: Container(
      width: 148,
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 88,
            width: double.infinity,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context))),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.subtext(context)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 15,
                        color: AppColors.subtext(context).withValues(alpha: 0.6)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SessionTile extends StatelessWidget {
  final bool isDark;
  final String date, status, score;
  final Color statusColor;
  final VoidCallback onTap;

  const _SessionTile({required this.isDark, required this.date,
      required this.status, required this.score, required this.statusColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2D40) : const Color(0xFFF0F7F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.history_rounded, color: AppColors.brandGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date,
                style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context))),
            const SizedBox(height: 2),
            Text('Posture Score',
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.subtext(context))),
          ]),
        ),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
          ),
          const SizedBox(width: 8),
          Text(score,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text(context))),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: AppColors.subtext(context), size: 18),
        ]),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final BuildContext context;
  const _EmptyState({required this.context});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.surf(ctx),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border(ctx), width: 1),
    ),
    child: Column(children: [
      Icon(Icons.bar_chart_outlined,
          size: 40, color: AppColors.subtext(ctx).withValues(alpha: 0.4)),
      const SizedBox(height: 10),
      Text('No scans yet',
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.subtext(ctx))),
      const SizedBox(height: 4),
      Text('Start a posture scan to see your history',
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.subtext(ctx).withValues(alpha: 0.7)),
          textAlign: TextAlign.center),
    ]),
  );
}

class _ScanTile extends StatelessWidget {
  final BuildContext context;
  final bool isDark;
  final IconData icon;
  final Color iconBg, iconColor, badgeBg, badgeColor;
  final String badge, title, description;
  final VoidCallback onTap;

  const _ScanTile({required this.context, required this.isDark,
      required this.icon, required this.iconBg, required this.iconColor,
      required this.badge, required this.badgeBg, required this.badgeColor,
      required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF192238) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? const Color(0xFF283454) : const Color(0xFFE2E8F0),
              width: 1.2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(ctx))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(badge,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: badgeColor)),
                ),
              ]),
              const SizedBox(height: 5),
              Text(description,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.subtext(ctx), height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.subtext(ctx).withValues(alpha: 0.5)),
        ]),
      ),
    ),
  );
}
