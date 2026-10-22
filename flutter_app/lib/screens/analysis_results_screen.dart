import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../services/posture_history_manager.dart';
import '../services/pdf_report_service.dart';
import '../posture/neck_angle_calculator.dart';
import 'scan_detail_screen.dart';

class AnalysisResultsScreen extends StatelessWidget {
  const AnalysisResultsScreen({super.key});

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hourVal = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year - $hourVal:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([PostureHistoryManager(), ThemeController.instance]),
      builder: (context, _) {
        final manager = PostureHistoryManager();
        final latest = manager.latestResult;
        final bool hasData = manager.history.isNotEmpty;

        // Use real values
        final String dateText = latest != null ? _formatDateTime(latest.timestamp) : 'No scans recorded yet';
        final int postureScoreValue = latest != null ? latest.postureScore : 0;
        final int riskScoreValue = latest != null ? latest.riskScore : 0;
        final double neckAngleValue = latest != null ? latest.angle : 0.0;
        final double spineLoadValue = latest != null ? latest.spineLoadKg : 0.0;
        final RiskLevel riskLevel = latest != null ? latest.riskLevel : RiskLevel.good;

        final int streakVal = manager.streak;
        final int avgScoreVal = hasData ? manager.averageScore.round() : 0;
        final int totalSessionsVal = manager.totalSessions;

        // Dynamic risk color and label
        final Color riskColor = latest != null
            ? riskLevel.color
            : (hasData ? AppColors.brandGreen : AppColors.subtext(context));
        final String riskLabel = latest != null ? riskLevel.label : 'No data';

        // Dynamic stress ratio
        final double stressRatio = spineLoadValue / 5.0; // Normal is ~5kg

        // Chart spots: only plot actual session data, avoiding fake placeholder scores
        List<FlSpot> spots = [];
        final int historyCount = manager.history.length;
        final int displayCount = historyCount.clamp(0, 7);
        if (displayCount > 0) {
          final recentScans = manager.history.take(displayCount).toList().reversed.toList();
          for (int i = 0; i < recentScans.length; i++) {
            spots.add(FlSpot(i.toDouble(), recentScans[i].postureScore.toDouble()));
          }
          if (recentScans.length == 1) {
            // Keep single session horizontal line benchmark
            spots.add(FlSpot(1.0, recentScans[0].postureScore.toDouble()));
          }
        } else {
          for (int i = 0; i < 7; i++) {
            spots.add(FlSpot(i.toDouble(), 0));
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bool canPop = Navigator.canPop(context);

        return Container(
          color: AppColors.bg(context),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                      // ── Header (Harmonized with Home Screen) ──────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (canPop) ...[
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surf(context),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border(context)),
                                      ),
                                      child: Icon(Icons.arrow_back_rounded, color: AppColors.text(context), size: 20),
                                    ),
                                  ),
                                ),
                              ] else ...[
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
                              ],
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
                                          text: ' Stats',
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
                                    dateText,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.subtext(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
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
                              const SizedBox(width: 8),
                              // PDF Export Button
                              IconButton(
                                tooltip: 'Export Clinical PDF Report',
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryAccent, size: 20),
                                ),
                                onPressed: () {
                                  PdfReportService.instance.exportPostureReport(
                                    angle: neckAngleValue,
                                    riskLevel: riskLevel,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Main Posture Health Card (Matching Home Screen) ──────
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surf(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border(context), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TODAY'S POSTURE HEALTH",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: AppColors.subtext(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          hasData ? '$postureScoreValue' : '--',
                                          style: GoogleFonts.inter(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.text(context),
                                            height: 1.0,
                                          ),
                                        ),
                                        if (hasData)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                                            child: Text(
                                              '%',
                                              style: GoogleFonts.inter(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: riskColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: riskColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        hasData ? '$riskLabel ($riskScoreValue% Risk)' : 'No scans recorded yet',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: riskColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Circular Gauge Dial
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: 1.0,
                                        strokeWidth: 8,
                                        color: AppColors.surfLight(context),
                                      ),
                                      CircularProgressIndicator(
                                        value: (hasData ? postureScoreValue : 0) / 100.0,
                                        strokeWidth: 8,
                                        color: riskColor,
                                        strokeCap: StrokeCap.round,
                                      ),
                                      Text(
                                        hasData ? '$postureScoreValue%' : 'Score',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: riskColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Gradient Bar
                            Row(
                              children: [
                                Expanded(child: _buildGradientBarSegment(context, AppColors.riskLow, 'Low')),
                                const SizedBox(width: 4),
                                Expanded(child: _buildGradientBarSegment(context, AppColors.riskModerate, 'Moderate')),
                                const SizedBox(width: 4),
                                Expanded(child: _buildGradientBarSegment(context, AppColors.riskHigh, 'High')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Harmonized 3-Card Dashboard Stats Row ────────────────
                      Row(
                        children: [
                          _buildSummaryStat(
                            context,
                            icon: Icons.local_fire_department_rounded,
                            value: '$streakVal',
                            unit: 'days',
                            label: 'Streak',
                            iconColor: AppColors.streakIconLight,
                            iconBg: isDark ? AppColors.streakIconBgDark : AppColors.streakIconBgLight,
                            cardBg: isDark ? AppColors.streakBgDark : AppColors.streakBgLight,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryStat(
                            context,
                            icon: Icons.bar_chart_rounded,
                            value: hasData ? '$avgScoreVal%' : '--',
                            unit: '',
                            label: 'Avg Score',
                            iconColor: AppColors.avgIconLight,
                            iconBg: isDark ? AppColors.avgIconBgDark : AppColors.avgIconBgLight,
                            cardBg: isDark ? AppColors.avgBgDark : AppColors.avgBgLight,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryStat(
                            context,
                            icon: Icons.check_circle_rounded,
                            value: '$totalSessionsVal',
                            unit: 'total',
                            label: 'Sessions',
                            iconColor: AppColors.sessionIconLight,
                            iconBg: isDark ? AppColors.sessionIconBgDark : AppColors.sessionIconBgLight,
                            cardBg: isDark ? AppColors.sessionBgDark : AppColors.sessionBgLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Biomechanical Angle & Load Row ───────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              'NECK ANGLE',
                              hasData ? neckAngleValue.toStringAsFixed(1) : '0.0',
                              '°',
                              AppColors.dataBlue,
                              hasData ? '⚠ Normal: <15°' : 'No data',
                              neckAngleValue < 15 ? AppColors.riskLow : (neckAngleValue < 30 ? AppColors.riskModerate : AppColors.riskHigh),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              'SPINE LOAD',
                              hasData ? spineLoadValue.toStringAsFixed(1) : '0.0',
                              ' kg',
                              AppColors.dataPurple,
                              hasData ? (stressRatio <= 1.2 ? '⚠ Normal' : (stressRatio <= 3.0 ? '⚠ Elevated' : '⚠ Critical')) : 'No data',
                              stressRatio <= 1.2 ? AppColors.riskLow : (stressRatio <= 3.0 ? AppColors.riskModerate : AppColors.riskHigh),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Clinical Explanation Card ────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What this means',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              latest != null 
                                ? 'Your neck is tilted at ${neckAngleValue.toStringAsFixed(1)}°, causing approximately ${spineLoadValue.toStringAsFixed(1)}kg of stress on your cervical spine — roughly ${stressRatio.toStringAsFixed(1)}x its normal load. This increases your risk of text neck syndrome if sustained.'
                                : 'Complete a posture scan to see your detailed cervical spine load and clinical angle analysis here.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.subtext(context),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Daily Progress Chart ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Posture History',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          Text(
                            hasData ? 'Recent Scans' : 'No scans',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Chart Container
                      Container(
                        height: 180,
                        padding: const EdgeInsets.only(top: 24, right: 24, bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surf(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border(context), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: AppColors.surfLight(context),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (displayCount > 0) {
                                      if (displayCount == 1) {
                                        if (index == 0) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              'S1',
                                              style: GoogleFonts.inter(
                                                color: AppColors.subtext(context),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      }
                                      if (index >= 0 && index < displayCount) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'S${index + 1}',
                                            style: GoogleFonts.inter(
                                              color: AppColors.subtext(context),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    }
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    if (index >= 0 && index < days.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          days[index],
                                          style: GoogleFonts.inter(
                                            color: AppColors.subtext(context),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 20,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.inter(
                                        color: AppColors.subtext(context),
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.left,
                                    );
                                  },
                                  reservedSize: 42,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: displayCount > 1 ? (displayCount - 1).toDouble() : (displayCount == 1 ? 1.0 : 6.0),
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppColors.primaryAccent,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryAccent.withValues(alpha: 0.3),
                                      AppColors.primaryAccent.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 250),
                        ),
                      ),

                      // ── Session Records ──────────────────────────────────────
                      const SizedBox(height: 28),
                      Text(
                        'Session Records',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (hasData)
                        ...manager.history.map((result) {
                          final scoreText = '${result.postureScore}%';
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScanDetailScreen.fromSession(result),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surf(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border(context), width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDateTime(result.timestamp),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text(context),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${result.riskLevel.shortLabel} • Angle: ${result.angle.toStringAsFixed(1)}° • CVA: ${result.craniovertebralAngle.toStringAsFixed(1)}°',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: result.riskLevel.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        scoreText,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.text(context),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right, size: 18, color: AppColors.subtext(context)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                      else
                        _EmptyState(context: context),

                      // Generous bottom padding to clear the floating pill navbar completely
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            );
      },
    );
  }

  Widget _buildSummaryStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text(context),
                    height: 1.0,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subtext(context),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.subtext(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBarSegment(BuildContext context, Color color, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.subtext(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, String unit, Color valueColor, String subtitle, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.subtext(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
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
      Text('No scans recorded yet',
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text(ctx))),
      const SizedBox(height: 4),
      Text('Start a posture scan to see your history and trends',
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.subtext(ctx).withValues(alpha: 0.7)),
          textAlign: TextAlign.center),
    ]),
  );
}
