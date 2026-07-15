// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MEMBER 2 (Part A) — Math & AI Logic: Neck Angle Calculator
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Responsibility:
//   Pure Dart utility that takes a Pose object (from Member 1) and
//   calculates the cervical forward-head inclination angle using
//   trigonometry. No Flutter UI dependency — this is pure math.
//
// Tech Stack:
//   - dart:math (atan, pi)
//   - google_mlkit_pose_detection (Pose, PoseLandmark types)
//
// Formula:
//   θ = arctan(|x_ear − x_shoulder| / |y_shoulder − y_ear|) × (180 / π)
//
// Risk Scoring:
//   Good     (0–14°)  → Normal posture (Green)
//   Warning  (15–29°) → Mild text neck risk (Orange)
//   Critical (30°+)   → Severe text neck (Red)
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Risk Level Enum
// ─────────────────────────────────────────────────────────────────────────────

/// Categorization of cervical inclination angle into clinical risk tiers.
///
/// Based on established physiotherapy thresholds for Forward Head Posture (FHP):
/// - **Good**: Ear is nearly vertically aligned above the shoulder.
/// - **Warning**: Noticeable forward tilt — common in casual phone use.
/// - **Critical**: Excessive tilt — sustained posture at this angle can
///   cause cervical strain, headaches, and long-term spinal issues.
enum RiskLevel {
  /// 0°–14°: Healthy cervical alignment.
  good(
    label: 'Good Posture',
    shortLabel: 'Good',
    color: Color(0xFF1AE67A),
    icon: Icons.check_circle_outline,
    description: 'Excellent! Spine is well-aligned.',
  ),

  /// 15°–29°: Mild forward head tilt.
  warning(
    label: 'Warning: Mild Risk',
    shortLabel: 'Warning',
    color: Color(0xFFFF9F43),
    icon: Icons.info_outline,
    description: 'Slight forward head tilt detected.',
  ),

  /// 30°+: Severe forward head tilt — text neck territory.
  critical(
    label: 'Critical: Severe Risk',
    shortLabel: 'Critical',
    color: Color(0xFFE64545),
    icon: Icons.warning_amber_rounded,
    description: 'Excessive forward tilt! Correct immediately.',
  );

  /// Human-readable label for the UI overlay.
  final String label;

  /// Short label for compact displays (e.g., badges).
  final String shortLabel;

  /// Color associated with this risk tier.
  final Color color;

  /// Icon associated with this risk tier.
  final IconData icon;

  /// Descriptive text explaining the risk.
  final String description;

  const RiskLevel({
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.icon,
    required this.description,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Result Data Class
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable result of a single neck angle calculation.
///
/// Produced by [NeckAngleCalculator.calculateNeckAngle] and consumed by
/// [PostureResultOverlay] for rendering.
class NeckAngleResult {
  /// The calculated cervical inclination angle in degrees.
  ///
  /// Range: 0° (perfectly upright) to 90° (fully forward).
  /// Typical phone usage: 15°–45°.
  final double angle;

  /// The risk classification derived from [angle].
  final RiskLevel riskLevel;

  /// Which side of the body was used for the calculation.
  ///
  /// Either `'left'` or `'right'`. We prefer the left side but fall back
  /// to right if the left ear/shoulder pair isn't confidently detected.
  final String earSide;

  /// Confidence score of the ear landmark used (0.0 – 1.0).
  final double earConfidence;

  /// Confidence score of the shoulder landmark used (0.0 – 1.0).
  final double shoulderConfidence;

  const NeckAngleResult({
    required this.angle,
    required this.riskLevel,
    required this.earSide,
    required this.earConfidence,
    required this.shoulderConfidence,
  });

  @override
  String toString() =>
      'NeckAngleResult(${angle.toStringAsFixed(1)}°, '
      '${riskLevel.shortLabel}, $earSide side, '
      'ear: ${(earConfidence * 100).toStringAsFixed(0)}%, '
      'shoulder: ${(shoulderConfidence * 100).toStringAsFixed(0)}%)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Neck Angle Calculator
// ─────────────────────────────────────────────────────────────────────────────

/// Pure utility class that computes the cervical forward-head inclination
/// angle from ML Kit's [Pose] object.
///
/// This class has **no state** — all methods are static. This is intentional:
/// the calculator is a pure function that transforms input (Pose) to output
/// (NeckAngleResult). Any temporal smoothing or buffering belongs in a
/// separate class (see the PostureMonitor in the existing codebase).
///
/// ## Biomechanical Model
///
/// We measure the angle between:
/// - The **vertical axis** (gravity direction, pointing upward)
/// - The **ear-to-shoulder vector** (the line from shoulder to ear)
///
/// When standing/sitting with perfect posture, the ear is directly above
/// the shoulder → the vector is vertical → angle ≈ 0°.
///
/// When the head tilts forward (text neck), the ear moves forward relative
/// to the shoulder → the horizontal component (dx) increases → angle grows.
///
/// ```
///          Ear (forward)
///         /
///        / θ ← this angle
///       /
///      Shoulder ──── vertical axis
/// ```
///
/// ## Landmark Selection Strategy
///
/// ML Kit detects landmarks on both sides of the body. We need one
/// ear-shoulder pair. Strategy:
///
/// 1. **Check left side first** (leftEar + leftShoulder)
/// 2. If both have `likelihood > 0.5`, use them
/// 3. Otherwise, **fall back to right side** (rightEar + rightShoulder)
/// 4. If neither side is confident enough, return `null`
///
/// We don't average both sides because the user may be angled relative
/// to the camera, making one side unreliable.
class NeckAngleCalculator {
  // ── Private constructor — this class should not be instantiated ──
  NeckAngleCalculator._();

  /// Minimum confidence threshold for a landmark to be considered reliable.
  ///
  /// ML Kit's `likelihood` ranges from 0.0 (not detected) to 1.0 (certain).
  /// At 0.5, the landmark position is a rough estimate. Below 0.5, the
  /// position is essentially a guess and should not be used for angle
  /// calculation.
  static const double _confidenceThreshold = 0.5;

  // ─────────────────────────────────────────────────────────────────────
  // Main Entry Point
  // ─────────────────────────────────────────────────────────────────────

  /// Calculates the neck inclination angle from a [Pose] object.
  ///
  /// Returns a [NeckAngleResult] if a valid ear-shoulder pair is found,
  /// or `null` if no landmarks are confident enough.
  ///
  /// This is the primary function that Member 1's callback feeds into:
  /// ```dart
  /// LiveCameraStream(
  ///   onPoseDetected: (Pose pose) {
  ///     final result = NeckAngleCalculator.calculateNeckAngle(pose);
  ///     if (result != null) {
  ///       setState(() => _currentResult = result);
  ///     }
  ///   },
  /// )
  /// ```
  static NeckAngleResult? calculateNeckAngle(Pose pose) {
    // ── Try Left Side First ──
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (leftEar != null &&
        leftShoulder != null &&
        leftEar.likelihood > _confidenceThreshold &&
        leftShoulder.likelihood > _confidenceThreshold) {
      final angle = _computeAngle(
        earX: leftEar.x,
        earY: leftEar.y,
        shoulderX: leftShoulder.x,
        shoulderY: leftShoulder.y,
      );

      return NeckAngleResult(
        angle: angle,
        riskLevel: _classifyRisk(angle),
        earSide: 'left',
        earConfidence: leftEar.likelihood,
        shoulderConfidence: leftShoulder.likelihood,
      );
    }

    // ── Fall Back to Right Side ──
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (rightEar != null &&
        rightShoulder != null &&
        rightEar.likelihood > _confidenceThreshold &&
        rightShoulder.likelihood > _confidenceThreshold) {
      final angle = _computeAngle(
        earX: rightEar.x,
        earY: rightEar.y,
        shoulderX: rightShoulder.x,
        shoulderY: rightShoulder.y,
      );

      return NeckAngleResult(
        angle: angle,
        riskLevel: _classifyRisk(angle),
        earSide: 'right',
        earConfidence: rightEar.likelihood,
        shoulderConfidence: rightShoulder.likelihood,
      );
    }

    // ── Neither Side Has Confident Landmarks ──
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Core Trigonometric Computation
  // ─────────────────────────────────────────────────────────────────────

  /// Computes the forward cervical inclination angle θ using:
  ///
  /// ```
  /// dx = |x_ear − x_shoulder|     ← horizontal displacement
  /// dy = |y_shoulder − y_ear|     ← vertical displacement
  /// θ  = arctan(dx / dy) × (180 / π)
  /// ```
  ///
  /// ### Why this formula works:
  ///
  /// In screen coordinates, Y increases downward. When posture is good,
  /// the ear is above the shoulder (lower Y value), so `dy` is large
  /// and `dx` is small → `arctan` yields a small angle.
  ///
  /// As the head tilts forward, `dx` grows → the angle increases.
  ///
  /// ### Edge case:
  /// If `dy == 0` (ear at the same vertical level as shoulder), the head
  /// is fully forward → we return 90° (maximum angle).
  ///
  /// ### Why arctan(dx/dy) instead of arctan(dy/dx):
  /// We measure the angle FROM the vertical axis. `arctan(dx/dy)` gives
  /// the deviation from vertical, which is what clinicians measure for
  /// Forward Head Posture.
  static double _computeAngle({
    required double earX,
    required double earY,
    required double shoulderX,
    required double shoulderY,
  }) {
    // Absolute horizontal distance between ear and shoulder
    final double dx = (earX - shoulderX).abs();

    // Absolute vertical distance (shoulder.y > ear.y when upright,
    // because Y grows downward in screen coordinates)
    final double dy = (shoulderY - earY).abs();

    // Guard: if ear is at the exact same vertical level as shoulder,
    // the head is fully forward — return maximum angle.
    if (dy == 0) return 90.0;

    // Core trigonometric calculation
    final double angleRadians = atan(dx / dy);
    final double angleDegrees = angleRadians * (180.0 / pi);

    return angleDegrees;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Risk Classification
  // ─────────────────────────────────────────────────────────────────────

  /// Classifies a calculated angle into one of three risk tiers.
  ///
  /// Thresholds:
  /// - **Good**:     0° ≤ θ < 15°
  /// - **Warning**: 15° ≤ θ < 30°
  /// - **Critical**: θ ≥ 30°
  ///
  /// These thresholds are based on clinical literature for Forward Head
  /// Posture assessment (Hansraj, 2014 — "Assessment of Stresses in the
  /// Cervical Spine Caused by Posture and Position of the Head").
  static RiskLevel _classifyRisk(double angle) {
    if (angle < 15.0) return RiskLevel.good;
    if (angle < 30.0) return RiskLevel.warning;
    return RiskLevel.critical;
  }
}
