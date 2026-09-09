import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

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

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
              margin: const EdgeInsets.only(bottom: 20),
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
                      widget.isSnapshot ? 'Snapshot Alignment Guide' : 'Scan Positioning Rules',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Follow these 3 steps for clinically accurate CVA readings',
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

          const SizedBox(height: 20),

          // Steps
          _buildRuleTile(
            number: '1',
            icon: Icons.rotate_right_rounded,
            title: 'Turn 90° Sideways (Profile View)',
            description: 'Sit or stand perpendicular to the camera so your ear and shoulder are clearly visible in the preview.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildRuleTile(
            number: '2',
            icon: Icons.smartphone_rounded,
            title: 'Adopt Your Natural Posture',
            description: 'Do not strain or pose. Look at your phone or screen naturally as you would during normal daily usage.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildRuleTile(
            number: '3',
            icon: Icons.light_mode_rounded,
            title: 'Clear Lighting & Framing',
            description: 'Ensure your side contour is well lit and free of heavy hair or loose clothing obscuring the ear-shoulder line.',
            isDark: isDark,
          ),

          const SizedBox(height: 16),

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

          const SizedBox(height: 12),

          // Proceed Button
          SizedBox(
            height: 52,
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
                widget.isSnapshot ? 'Take Snapshot' : 'I Understand — Start Scan',
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
