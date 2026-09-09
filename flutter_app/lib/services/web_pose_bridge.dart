import 'package:flutter/material.dart';
import 'web_pose_bridge_stub.dart'
    if (dart.library.js) 'web_pose_bridge_web.dart' as bridge;

/// Normalized body landmarks and biomechanical posture measurements.
class WebPoseLandmarks {
  final bool hasPose;
  final bool isSideProfile;
  final String side; // "left" or "right"
  final Offset? ear; // Normalized (0.0 to 1.0)
  final Offset? shoulder; // Normalized (0.0 to 1.0)
  final Offset? hip; // Normalized (0.0 to 1.0)
  final bool hasHip;
  final double neckAngle; // Forward tilt from vertical plumb line (0° = upright)
  final double? cvaAngle; // Clinical Craniovertebral Angle from horizontal baseline (90° = upright)
  final double? torsoAngle;
  final double? spinePlumbAngle;
  final double earConfidence;
  final double shoulderConfidence;
  final double hipConfidence;
  final double dx;
  final double dy;
  final double shoulderDistance;

  const WebPoseLandmarks({
    required this.hasPose,
    required this.isSideProfile,
    required this.side,
    this.ear,
    this.shoulder,
    this.hip,
    this.hasHip = false,
    required this.neckAngle,
    this.cvaAngle,
    this.torsoAngle,
    this.spinePlumbAngle,
    this.earConfidence = 0.0,
    this.shoulderConfidence = 0.0,
    this.hipConfidence = 0.0,
    this.dx = 0.0,
    this.dy = 0.0,
    this.shoulderDistance = 0.0,
  });
}

class WebPoseBridge {
  /// Fetches the latest real-time MediaPipe pose data from the browser window.
  static WebPoseLandmarks? getLatestPose() => bridge.getLatestPose();
}
