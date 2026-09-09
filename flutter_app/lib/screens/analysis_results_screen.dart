import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../services/posture_history_manager.dart';
import '../services/pdf_report_service.dart';
import '../posture/neck_angle_calculator.dart';

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
      animation: PostureHistoryManager(),
      builder: (context, _) {
        final manager = PostureHistoryManager();
        final latest = manager.latestResult;

        // Use real or mock values
        final String dateText = latest != null ? _formatDateTime(latest.timestamp) : 'Jul 12, 2026 - 10:42 AM';
        final int riskScoreValue = latest != null ? latest.riskScore : 34;
        final double neckAngleValue = latest != null ? latest.angle : 34.2;
        final double spineLoadValue = latest != null ? latest.spineLoadKg : 27.0;
        final RiskLevel riskLevel = latest != null ? latest.riskLevel : RiskLevel.warning;

        // Dynamic risk color and label
        final Color riskColor = riskLevel.color;
        final String riskLabel = riskLevel.label;

        // Dynamic stress ratio
        final double stressRatio = spineLoadValue / 5.0; // Normal is ~5kg

        // Chart spots
        List<FlSpot> spots = const [
          FlSpot(0, 68),
          FlSpot(1, 65),
          FlSpot(2, 75),
          FlSpot(3, 62),
          FlSpot(4, 71),
          FlSpot(5, 78),
          FlSpot(6, 82),
        ];

        // If we have actual history, let's plot the history of posture scores (100 - riskScore)
        if (manager.history.isNotEmpty) {
          final historyList = manager.history;
          final int len = historyList.length;
          List<FlSpot> newSpots = [];
          for (int i = 0; i < 7; i++) {
            // Plot the last 7 sessions, or fill with baseline
            if (i < len) {
              final item = historyList[len - 1 - i]; // chronological order (oldest first)
              final score = 100.0 - item.riskScore;
              newSpots.add(FlSpot(i.toDouble(), score));
            } else {
              // baseline fallback
              newSpots.add(FlSpot(i.toDouble(), 70.0));
            }
          }
          spots = newSpots;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          color: AppColors.bg(context),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            child: Icon(Icons.arrow_back, color: AppColors.text(context)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analysis Results',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                              Text(
                                dateText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.subtext(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                  const SizedBox(height: 32),

                  // Risk Score Card
                  Container(
                    padding: const EdgeInsets.all(24),
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
                                  'TEXT NECK RISK SCORE',
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
                                      '$riskScoreValue',
                                      style: GoogleFonts.inter(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text(context),
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
                                    riskLabel,
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
                                    value: riskScoreValue / 100.0,
                                    strokeWidth: 8,
                                    color: riskColor,
                                    strokeCap: StrokeCap.round,
                                  ),
                                  Text(
                                    'Risk',
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

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'NECK ANGLE',
                          neckAngleValue.toStringAsFixed(1),
                          '°',
                          AppColors.dataBlue,
                          '⚠ Normal: <15°',
                          neckAngleValue < 15 ? AppColors.riskLow : (neckAngleValue < 30 ? AppColors.riskModerate : AppColors.riskHigh),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'SPINE LOAD',
                          spineLoadValue.toStringAsFixed(1),
                          ' kg',
                          AppColors.dataPurple,
                          stressRatio <= 1.2 ? '⚠ Normal' : (stressRatio <= 3.0 ? '⚠ Elevated' : '⚠ Critical'),
                          stressRatio <= 1.2 ? AppColors.riskLow : (stressRatio <= 3.0 ? AppColors.riskModerate : AppColors.riskHigh),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Explanation Card
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
                            : 'Your neck is tilted at 34.2°, causing approximately 27.0kg of stress on your cervical spine — roughly 5.4x its normal load. This increases your risk of text neck syndrome if sustained.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.subtext(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Daily Progress Chart
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
                        manager.history.isNotEmpty ? 'Recent Scans' : 'This Week',
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
                                if (manager.history.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'S${value.toInt() + 1}',
                                      style: GoogleFonts.inter(
                                        color: AppColors.subtext(context),
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= 0 && value.toInt() < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      days[value.toInt()],
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
                        maxX: 6,
                        minY: 40,
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
                    ),
                  ),

                  const SizedBox(height: 100), // padding for the bottom nav bar
                ],
              ),
            ),
          ),
        );
      },
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
