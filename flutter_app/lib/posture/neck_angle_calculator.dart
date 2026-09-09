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
  /// The calculated forward neck tilt angle from vertical plumb line in degrees.
  /// Range: 0° (perfectly upright) to 45°+ (severe forward text neck).
  final double angle;

  /// The clinical Craniovertebral Angle (CVA) in degrees from horizontal baseline.
  /// Range: 90° (perfectly upright) down to < 45° (severe forward slouch).
  final double cvaAngle;

  /// The risk classification derived from [angle].
  final RiskLevel riskLevel;

  /// Which side of the body was used for the calculation.
  final String earSide;

  /// Confidence score of the ear landmark used (0.0 – 1.0).
  final double earConfidence;

  /// Confidence score of the shoulder landmark used (0.0 – 1.0).
  final double shoulderConfidence;

  /// Whether the user is correctly oriented in side-profile (true) or facing front (false).
  final bool isSideProfile;

  /// Normalized landmark coordinates (0.0 to 1.0)
  final Offset? earPoint;
  final Offset? shoulderPoint;
  final Offset? hipPoint;
  final bool hasHip;

  /// Trunk / Torso vertical inclination angle (degrees from vertical plumb line)
  final double? torsoAngle;

  /// Full posture alignment angle (Ear-Shoulder-Hip angle in degrees)
  final double? spinePlumbAngle;

  /// Real-time coordinate deltas
  final double rawDeltaX;
  final double rawDeltaY;

  const NeckAngleResult({
    required this.angle,
    double? cvaAngle,
    required this.riskLevel,
    required this.earSide,
    required this.earConfidence,
    required this.shoulderConfidence,
    this.isSideProfile = true,
    this.earPoint,
    this.shoulderPoint,
    this.hipPoint,
    this.hasHip = false,
    this.torsoAngle,
    this.spinePlumbAngle,
    this.rawDeltaX = 0.0,
    this.rawDeltaY = 0.0,
  }) : cvaAngle = cvaAngle ?? (90.0 - angle);

  @override
  String toString() =>
      'NeckAngleResult(tilt: ${angle.toStringAsFixed(1)}°, '
      'CVA: ${cvaAngle.toStringAsFixed(1)}°, '
      '${riskLevel.shortLabel}, $earSide side, '
      'sideProfile: $isSideProfile, '
      'hasHip: $hasHip, '
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
  /// Validates whether the detected pose represents a true side-profile (sagittal view).
  /// When facing forward, both shoulders are separated horizontally and nose is centered.
  /// In 90° lateral profile, shoulders overlap horizontally (< 0.13 normalized) or one ear is occluded.
  static bool isSideProfile(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];

    if (leftShoulder == null || rightShoulder == null) return true;
    final double deltaX = (leftShoulder.x - rightShoulder.x).abs();
    final bool isNormalized = leftShoulder.x <= 1.0 && rightShoulder.x <= 1.0;
    final double threshold = isNormalized ? 0.13 : 90.0;

    final double leftVis = leftEar?.likelihood ?? 0.0;
    final double rightVis = rightEar?.likelihood ?? 0.0;
    final bool bothEarsVisible = leftVis > 0.45 && rightVis > 0.45;

    bool noseBetweenShoulders = false;
    if (nose != null) {
      final double minSx = min(leftShoulder.x, rightShoulder.x);
      final double maxSx = max(leftShoulder.x, rightShoulder.x);
      if (nose.x >= minSx && nose.x <= maxSx) {
        noseBetweenShoulders = true;
      }
    }

    if (deltaX > threshold && (bothEarsVisible || noseBetweenShoulders)) {
      return false; // User is facing camera / front view
    }
    return deltaX < (isNormalized ? 0.17 : 120.0);
  }

  static NeckAngleResult? calculateNeckAngle(Pose pose) {
    final bool sideProfile = isSideProfile(pose);

    // ── Try Left Side First ──
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];

    if (leftEar != null &&
        leftShoulder != null &&
        leftEar.likelihood > _confidenceThreshold &&
        leftShoulder.likelihood > _confidenceThreshold) {
      final forwardTilt = _computeAngle(
        earX: leftEar.x,
        earY: leftEar.y,
        shoulderX: leftShoulder.x,
        shoulderY: leftShoulder.y,
      );

      final hasHip = leftHip != null && leftHip.likelihood > _confidenceThreshold;
      double? torsoAngle;
      double? spinePlumbAngle;

      if (hasHip) {
        final double tDx = (leftShoulder.x - leftHip.x).abs();
        final double tDy = (leftHip.y - leftShoulder.y).abs();
        torsoAngle = tDy == 0 ? 0.0 : atan(tDx / tDy) * (180.0 / pi);

        final double v1x = leftEar.x - leftShoulder.x;
        final double v1y = leftEar.y - leftShoulder.y;
        final double v2x = leftHip.x - leftShoulder.x;
        final double v2y = leftHip.y - leftShoulder.y;
        final double dot = v1x * v2x + v1y * v2y;
        final double mag1 = sqrt(v1x * v1x + v1y * v1y);
        final double mag2 = sqrt(v2x * v2x + v2y * v2y);
        if (mag1 > 0 && mag2 > 0) {
          final double cosVal = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
          spinePlumbAngle = acos(cosVal) * (180.0 / pi);
        }
      }

      return NeckAngleResult(
        angle: forwardTilt,
        cvaAngle: (90.0 - forwardTilt).clamp(0.0, 90.0),
        riskLevel: _classifyRisk(forwardTilt),
        earSide: 'left',
        earConfidence: leftEar.likelihood,
        shoulderConfidence: leftShoulder.likelihood,
        isSideProfile: sideProfile,
        earPoint: Offset(leftEar.x, leftEar.y),
        shoulderPoint: Offset(leftShoulder.x, leftShoulder.y),
        hipPoint: hasHip ? Offset(leftHip.x, leftHip.y) : null,
        hasHip: hasHip,
        torsoAngle: torsoAngle,
        spinePlumbAngle: spinePlumbAngle,
        rawDeltaX: (leftEar.x - leftShoulder.x).abs(),
        rawDeltaY: (leftShoulder.y - leftEar.y).abs(),
      );
    }

    // ── Fall Back to Right Side ──
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (rightEar != null &&
        rightShoulder != null &&
        rightEar.likelihood > _confidenceThreshold &&
        rightShoulder.likelihood > _confidenceThreshold) {
      final forwardTilt = _computeAngle(
        earX: rightEar.x,
        earY: rightEar.y,
        shoulderX: rightShoulder.x,
        shoulderY: rightShoulder.y,
      );

      final hasHip = rightHip != null && rightHip.likelihood > _confidenceThreshold;
      double? torsoAngle;
      double? spinePlumbAngle;

      if (hasHip) {
        final double tDx = (rightShoulder.x - rightHip.x).abs();
        final double tDy = (rightHip.y - rightShoulder.y).abs();
        torsoAngle = tDy == 0 ? 0.0 : atan(tDx / tDy) * (180.0 / pi);

        final double v1x = rightEar.x - rightShoulder.x;
        final double v1y = rightEar.y - rightShoulder.y;
        final double v2x = rightHip.x - rightShoulder.x;
        final double v2y = rightHip.y - rightShoulder.y;
        final double dot = v1x * v2x + v1y * v2y;
        final double mag1 = sqrt(v1x * v1x + v1y * v1y);
        final double mag2 = sqrt(v2x * v2x + v2y * v2y);
        if (mag1 > 0 && mag2 > 0) {
          final double cosVal = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
          spinePlumbAngle = acos(cosVal) * (180.0 / pi);
        }
      }

      return NeckAngleResult(
        angle: forwardTilt,
        cvaAngle: (90.0 - forwardTilt).clamp(0.0, 90.0),
        riskLevel: _classifyRisk(forwardTilt),
        earSide: 'right',
        earConfidence: rightEar.likelihood,
        shoulderConfidence: rightShoulder.likelihood,
        isSideProfile: sideProfile,
        earPoint: Offset(rightEar.x, rightEar.y),
        shoulderPoint: Offset(rightShoulder.x, rightShoulder.y),
        hipPoint: hasHip ? Offset(rightHip.x, rightHip.y) : null,
        hasHip: hasHip,
        torsoAngle: torsoAngle,
        spinePlumbAngle: spinePlumbAngle,
        rawDeltaX: (rightEar.x - rightShoulder.x).abs(),
        rawDeltaY: (rightShoulder.y - rightEar.y).abs(),
      );
    }

    // ── Neither Side Has Confident Landmarks ──
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Core Trigonometric Computation
  // ─────────────────────────────────────────────────────────────────────

  /// Computes the Forward Neck Tilt Angle θ from the vertical gravity plumb line:
  ///
  /// ```
  /// dx = |x_ear − x_shoulder|     ← horizontal displacement forward
  /// dy = |y_shoulder − y_ear|     ← vertical distance
  /// θ  = arctan(dx / dy) × (180 / π)
  /// ```
  ///
  /// When posture is ideal, the ear is directly above the shoulder (dx ≈ 0) → θ ≈ 0°.
  /// As text neck worsens, ear juts forward (dx increases) → θ increases (15°, 30°, 45°+).
  static double _computeAngle({
    required double earX,
    required double earY,
    required double shoulderX,
    required double shoulderY,
  }) {
    final double dx = (earX - shoulderX).abs();
    final double dy = (shoulderY - earY).abs();

    if (dy == 0) return 90.0;
    if (dx == 0) return 0.0;

    final double angleRadians = atan(dx / dy);
    return angleRadians * (180.0 / pi);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Risk Classification
  // ─────────────────────────────────────────────────────────────────────

  /// Classifies a forward tilt angle into ergonomic risk tiers:
  /// - **Good**:     θ < 15° (Upright, minimal forward load)
  /// - **Warning**: 15° ≤ θ < 30° (Mild to moderate text neck)
  /// - **Critical**: θ ≥ 30° (Excessive cervical stress, correct posture)
  static RiskLevel classifyRisk(double angle) {
    if (angle < 15.0) return RiskLevel.good;
    if (angle < 30.0) return RiskLevel.warning;
    return RiskLevel.critical;
  }

  static RiskLevel _classifyRisk(double angle) => classifyRisk(angle);
}
