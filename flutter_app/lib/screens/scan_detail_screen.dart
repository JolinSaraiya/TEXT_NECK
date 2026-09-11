import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../posture/neck_angle_calculator.dart';
import '../services/posture_history_manager.dart';
import '../services/pdf_report_service.dart';

/// Full-page scan detail screen showing complete posture analysis data.
/// Used both:
/// - After completing a live scan (replacing the old AlertDialog summary)
/// - When tapping a history session from Dashboard or Results tab
class ScanDetailScreen extends StatelessWidget {
  final double angle;
  final RiskLevel riskLevel;
  final String earSide;
  final int frameCount;
  final DateTime timestamp;
  final bool showNewScanButton;

  const ScanDetailScreen({
    super.key,
    required this.angle,
    required this.riskLevel,
    required this.earSide,
    required this.frameCount,
    required this.timestamp,
    this.showNewScanButton = false,
  });

  /// Creates from a PostureSessionResult (for history items).
  factory ScanDetailScreen.fromSession(PostureSessionResult session, {bool showNewScanButton = false}) {
    return ScanDetailScreen(
      angle: session.angle,
      riskLevel: session.riskLevel,
      earSide: session.earSide,
      frameCount: session.frameCount,
      timestamp: session.timestamp,
      showNewScanButton: showNewScanButton,
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hourVal = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year — $hourVal:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cvaAngle = (90.0 - angle).clamp(0.0, 90.0);
    
    // Spine load calculation (same logic as PostureSessionResult)
    double verticalDeviation = angle.clamp(0.0, 90.0);
    double spineLoadKg;
    if (verticalDeviation <= 0) {
      spineLoadKg = 5.0;
    } else if (verticalDeviation <= 15) {
      spineLoadKg = 5.0 + (verticalDeviation / 15.0) * 7.0;
    } else if (verticalDeviation <= 30) {
      spineLoadKg = 12.0 + ((verticalDeviation - 15) / 15.0) * 6.0;
    } else if (verticalDeviation <= 45) {
      spineLoadKg = 18.0 + ((verticalDeviation - 30) / 15.0) * 4.0;
    } else if (verticalDeviation <= 60) {
      spineLoadKg = 22.0 + ((verticalDeviation - 45) / 15.0) * 5.0;
    } else {
      spineLoadKg = 27.0;
    }

    final double stressRatio = spineLoadKg / 5.0;
    final int postureScore = (100 - _riskScoreFromAngle(angle)).clamp(0, 100);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Results',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text(context),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Export PDF Report',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryAccent, size: 18),
            ),
            onPressed: () {
              PdfReportService.instance.exportPostureReport(
                angle: angle,
                riskLevel: riskLevel,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scan timestamp
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfLight(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDateTime(timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.subtext(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Main Risk Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: riskLevel.color.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: riskLevel.color.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: riskLevel.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(riskLevel.icon, color: riskLevel.color, size: 40),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: riskLevel.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        riskLevel.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: riskLevel.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      riskLevel.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.subtext(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$postureScore',
                          style: GoogleFonts.inter(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: riskLevel.color,
                            height: 1.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '% Score',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.subtext(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.straighten_rounded,
                      label: 'FORWARD TILT',
                      value: '${angle.toStringAsFixed(1)}°',
                      subtitle: angle < 15 ? 'Normal' : (angle < 30 ? 'Elevated' : 'Severe'),
                      valueColor: riskLevel.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.architecture_rounded,
                      label: 'CVA ANGLE',
                      value: '${cvaAngle.toStringAsFixed(1)}°',
                      subtitle: cvaAngle >= 50 ? 'Healthy' : (cvaAngle >= 40 ? 'At Risk' : 'Critical'),
                      valueColor: AppColors.dataBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.fitness_center_rounded,
                      label: 'SPINE LOAD',
                      value: '${spineLoadKg.toStringAsFixed(1)} kg',
                      subtitle: '${stressRatio.toStringAsFixed(1)}x normal load',
                      valueColor: AppColors.dataPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.visibility_rounded,
                      label: 'DETECTION',
                      value: '${earSide[0].toUpperCase()}${earSide.substring(1)}',
                      subtitle: '$frameCount frames analyzed',
                      valueColor: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Clinical Explanation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surf(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_information_rounded, color: AppColors.primaryAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Clinical Summary',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your cervical spine is tilted ${angle.toStringAsFixed(1)}° forward from the vertical plumb line, '
                      'with a Craniovertebral Angle (CVA) of ${cvaAngle.toStringAsFixed(1)}°. '
                      'This creates approximately ${spineLoadKg.toStringAsFixed(1)} kg of stress on your cervical spine — '
                      '${stressRatio.toStringAsFixed(1)}x its normal resting load of ~5 kg.\n\n'
                      '${_getRecommendation()}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.subtext(context),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    PdfReportService.instance.exportPostureReport(
                      angle: angle,
                      riskLevel: riskLevel,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: Text(
                    'Download PDF Report',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (showNewScanButton) ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.replay_rounded, size: 18, color: AppColors.text(context)),
                    label: Text(
                      'New Scan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text(context),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    'Back to Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
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
          Icon(icon, color: valueColor.withValues(alpha: 0.7), size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.subtext(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendation() {
    switch (riskLevel) {
      case RiskLevel.good:
        return 'Your posture is excellent. Continue maintaining this alignment to prevent cervical strain.';
      case RiskLevel.warning:
        return 'Recommendation: Practice chin tucks, raise your screen to eye level, and take posture breaks every 30 minutes. Consider upper trapezius stretches.';
      case RiskLevel.critical:
        return 'Immediate action recommended: Your forward head posture significantly increases cervical disc pressure. Practice chin tucks, neck retraction exercises, and consult a physiotherapist if symptoms persist.';
    }
  }

  int _riskScoreFromAngle(double ang) {
    final cva = (90.0 - ang).clamp(0.0, 90.0);
    if (cva >= 48.0) return 0;
    if (cva >= 43.0) return (((48.0 - cva) / 5.0) * 50.0).round();
    return (50.0 + ((43.0 - cva) / 13.0) * 50.0).clamp(50, 100).round();
  }
}
