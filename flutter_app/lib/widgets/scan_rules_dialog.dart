import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'posture_guide_image.dart';

/// Pre-Scan Positioning Guide Modal
/// Displays clear instructions to the user on how to position themselves in frame
/// for accurate Craniovertebral Angle (CVA) measurement.
class ScanRulesDialog extends StatefulWidget {
  final VoidCallback onProceed;
  final bool isSnapshot;

  const ScanRulesDialog({
    super.key,
    required this.onProceed,
    this.isSnapshot = false,
  });

  static bool skipGuide = false;

  /// Shows the dialog if not previously dismissed.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onProceed,
    bool isSnapshot = false,
  }) async {
    if (skipGuide) {
      onProceed();
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScanRulesDialog(
        onProceed: onProceed,
        isSnapshot: isSnapshot,
      ),
    );
  }

  @override
  State<ScanRulesDialog> createState() => _ScanRulesDialogState();
}

class _ScanRulesDialogState extends State<ScanRulesDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF232D4B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.accessibility_new_rounded,
                  color: AppColors.primaryAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isSnapshot ? 'Snapshot Alignment Guide' : 'Scan & Photo Guide',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'How to position yourself & upload photos for CVA analysis',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Visual Comparison Cards: How to Stand & Photo Guidelines
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B233C) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B3658) : const Color(0xFFCBD5E1),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.compare_rounded, size: 16, color: AppColors.primaryAccent),
                            const SizedBox(width: 6),
                            Text(
                              'HOW TO STAND / PHOTO CRITERIA',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Correct Pose Card
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                     ClipRRect(
                                       borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                       child: const AspectRatio(
                                         aspectRatio: 1.0,
                                         child: PostureGuideImage(
                                           isCorrect: true,
                                           fit: BoxFit.cover,
                                         ),
                                       ),
                                     ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Column(
                                        children: [
                                          const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'CORRECT',
                                                style: TextStyle(
                                                  color: Color(0xFF22C55E),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '90° sideways profile. Ear & shoulder line visible.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 9.5,
                                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Wrong Pose Card
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                     ClipRRect(
                                       borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                       child: const AspectRatio(
                                         aspectRatio: 1.0,
                                         child: PostureGuideImage(
                                           isCorrect: false,
                                           fit: BoxFit.cover,
                                         ),
                                       ),
                                     ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Column(
                                        children: [
                                          const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'WRONG PHOTO',
                                                style: TextStyle(
                                                  color: Color(0xFFEF4444),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Front-facing or diagonal poses will be rejected.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 9.5,
                                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Steps / Rules
                  _buildRuleTile(
                    number: '1',
                    icon: Icons.rotate_right_rounded,
                    title: 'Stand 90° Sideways to Camera',
                    description: 'Stand or sit upright perpendicular to the camera so your ear, shoulder, and neck contour are clearly seen.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildRuleTile(
                    number: '2',
                    icon: Icons.add_photo_alternate_rounded,
                    title: 'If Uploading a Photo',
                    description: 'Take a clear sideways photo at eye/shoulder height against good lighting. Avoid selfies, front poses, or heavy coats.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildRuleTile(
                    number: '3',
                    icon: Icons.warning_amber_rounded,
                    title: 'Wrong Photo Detection',
                    description: 'Our AI checks for lateral alignment. If you upload a frontal or obscured picture, it will be flagged as an invalid photo with re-take tips.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildRuleTile(
                    number: '4',
                    icon: Icons.smartphone_rounded,
                    title: 'Adopt Your Natural Posture',
                    description: 'Do not stiffen or artificially stand tall. Hold your phone or gaze naturally as you do during everyday use.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Don't show again checkbox
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                activeColor: AppColors.primaryAccent,
                onChanged: (val) {
                  setState(() => _dontShowAgain = val ?? false);
                  ScanRulesDialog.skipGuide = _dontShowAgain;
                },
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _dontShowAgain = !_dontShowAgain);
                  ScanRulesDialog.skipGuide = _dontShowAgain;
                },
                child: Text(
                  "Don't show this guide before every scan",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Proceed Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onProceed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: const Color(0xFF0F1118),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                widget.isSnapshot ? 'Take Snapshot' : 'I Understand — Continue',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleTile({
    required String number,
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B233C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3658) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
