// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MEMBER 2 (Part B) — PostureResultOverlay Widget
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Responsibility:
//   Render a beautiful, glassmorphic HUD overlay on top of the camera
//   preview. Displays the current neck angle, risk classification,
//   and a gradient progress bar — all with smooth animated transitions.
//
// Inputs (from the integration screen):
//   - double angle: The calculated cervical inclination angle
//   - RiskLevel riskLevel: The risk tier (good / warning / critical)
//
// Design System:
//   - Green (#1AE67A)  → Good posture
//   - Orange (#FF9F43) → Mild risk
//   - Red (#E64545)    → Severe risk / Critical
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:ui';
import 'package:flutter/material.dart';
import 'neck_angle_calculator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PostureResultOverlay Widget
// ─────────────────────────────────────────────────────────────────────────────

/// A glassmorphic, animated overlay that displays real-time posture analysis
/// results on top of the camera preview.
///
/// Features:
/// - **Color-coded background** that transitions smoothly between risk tiers
/// - **Large monospace angle readout** (e.g., "35.2°")
/// - **Risk category label** with icon (✓ Good / ⚠ Warning / ✖ Critical)
/// - **Gradient progress bar** showing angle on a 0°–45° scale
/// - **Glassmorphism** effect using [BackdropFilter] for a premium feel
/// - **AnimatedContainer** for smooth transitions between states
///
/// Usage:
/// ```dart
/// PostureResultOverlay(
///   angle: 25.3,
///   riskLevel: RiskLevel.warning,
/// )
/// ```
class PostureResultOverlay extends StatelessWidget {
  /// The current cervical inclination angle in degrees.
  final double angle;

  /// The risk classification derived from [angle].
  final RiskLevel riskLevel;

  /// Optional: which side of the body was used ('left' or 'right').
  final String? earSide;

  const PostureResultOverlay({
    super.key,
    required this.angle,
    required this.riskLevel,
    this.earSide,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = riskLevel.color;

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          // ── Glassmorphism: blur the camera preview behind the overlay ──
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              // Semi-transparent background tinted with the risk color
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Row 1: Risk Info + Angle Display ──
                _buildTopRow(color),

                const SizedBox(height: 18),

                // ── Row 2: Gradient Progress Bar ──
                _buildAngleProgressBar(color),

                const SizedBox(height: 14),

                // ── Row 3: Description + Side Indicator ──
                _buildBottomRow(color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Row 1: Risk Icon + Label + Angle Readout
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTopRow(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Left: Icon + Risk Label ──
        Expanded(
          child: Row(
            children: [
              // Animated icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(riskLevel.icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              // Risk label and sublabel
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riskLevel.shortLabel.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      riskLevel.label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // ── Right: Large Angle Readout ──
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The big number
            Text(
              '${angle.toStringAsFixed(1)}°',
              style: TextStyle(
                color: color,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                height: 1.0,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'CERVICAL ANGLE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Row 2: Gradient Progress Bar (0° → 45°+)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAngleProgressBar(Color color) {
    // Normalize the angle to a 0.0 – 1.0 fraction over the 0°–45° range.
    // Angles above 45° are clamped to 1.0.
    final double fraction = (angle / 45.0).clamp(0.0, 1.0);

    return Column(
      children: [
        // ── Scale Labels ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildScaleLabel('0°'),
            _buildScaleLabel('15°'),
            _buildScaleLabel('30°'),
            _buildScaleLabel('45°+'),
          ],
        ),
        const SizedBox(height: 6),

        // ── Gradient Track with Indicator ──
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            const dotSize = 12.0;
            // Position dot so it stays within the bar bounds
            final dotLeft =
                (fraction * (barWidth - dotSize)).clamp(0.0, barWidth - dotSize);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Background track with gradient
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1AE67A), // Green  — Good
                        Color(0xFFFFD93D), // Yellow — Transition
                        Color(0xFFFF9F43), // Orange — Warning
                        Color(0xFFE64545), // Red    — Critical
                      ],
                      stops: [0.0, 0.33, 0.66, 1.0],
                    ),
                  ),
                ),

                // ── Animated Indicator Dot ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: dotLeft,
                  top: -2,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: color, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }



  /// Builds a small scale label for the progress bar.
  Widget _buildScaleLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Row 3: Description + Side Indicator
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBottomRow(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Risk Description ──
        Flexible(
          child: Text(
            riskLevel.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
        ),

        // ── Side Indicator Badge ──
        if (earSide != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Text(
              '${earSide!.toUpperCase()} SIDE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                fontFamily: 'Inter',
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Risk Pill (Bonus widget)
// ─────────────────────────────────────────────────────────────────────────────

/// A small, pill-shaped badge showing the risk category.
///
/// Usage:
/// ```dart
/// RiskPill(riskLevel: RiskLevel.critical, angle: 35.2)
/// ```
///
/// Renders as: [✖ Critical: 35.2°] in a red pill.
class RiskPill extends StatelessWidget {
  final RiskLevel riskLevel;
  final double angle;

  const RiskPill({
    super.key,
    required this.riskLevel,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = riskLevel.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskLevel.icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '${riskLevel.shortLabel}: ${angle.toStringAsFixed(1)}°',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
