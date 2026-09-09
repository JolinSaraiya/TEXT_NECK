import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'web_pose_bridge.dart';

WebPoseLandmarks? getLatestPose() {
  final raw = js.context['_latestPoseData'];
  if (raw == null) return null;

  try {
    final bool hasPose = raw['hasPose'] == true;
    if (!hasPose) {
      return const WebPoseLandmarks(
        hasPose: false,
        isSideProfile: false,
        side: 'unknown',
        neckAngle: 0.0,
      );
    }

    final bool isSideProfile = raw['isSideProfile'] == true;
    final String side = raw['side']?.toString() ?? 'right';

    final num? earX = raw['earX'];
    final num? earY = raw['earY'];
    final num? earVis = raw['earVis'];

    final num? shoulderX = raw['shoulderX'];
    final num? shoulderY = raw['shoulderY'];
    final num? shoulderVis = raw['shoulderVis'];

    final bool hasHip = raw['hasHip'] == true;
    final num? hipX = raw['hipX'];
    final num? hipY = raw['hipY'];
    final num? hipVis = raw['hipVis'];

    final num? rawNeckAngle = raw['neckAngle'];
    final num? rawCvaAngle = raw['cvaAngle'];
    final num? rawTorsoAngle = raw['torsoAngle'];
    final num? rawSpinePlumb = raw['spinePlumbAngle'];
    final num? rawDx = raw['dx'];
    final num? rawDy = raw['dy'];
    final num? rawShoulderDist = raw['shoulderDistance'];

    final Offset? ear = (earX != null && earY != null)
        ? Offset(earX.toDouble(), earY.toDouble())
        : null;
    final Offset? shoulder = (shoulderX != null && shoulderY != null)
        ? Offset(shoulderX.toDouble(), shoulderY.toDouble())
        : null;
    final Offset? hip = (hasHip && hipX != null && hipY != null)
        ? Offset(hipX.toDouble(), hipY.toDouble())
        : null;

    return WebPoseLandmarks(
      hasPose: true,
      isSideProfile: isSideProfile,
      side: side,
      ear: ear,
      shoulder: shoulder,
      hip: hip,
      hasHip: hasHip,
      neckAngle: (rawNeckAngle ?? 0.0).toDouble(),
      cvaAngle: rawCvaAngle?.toDouble(),
      torsoAngle: rawTorsoAngle?.toDouble(),
      spinePlumbAngle: rawSpinePlumb?.toDouble(),
      earConfidence: (earVis ?? 0.85).toDouble(),
      shoulderConfidence: (shoulderVis ?? 0.85).toDouble(),
      hipConfidence: (hipVis ?? 0.0).toDouble(),
      dx: (rawDx ?? 0.0).toDouble(),
      dy: (rawDy ?? 0.0).toDouble(),
      shoulderDistance: (rawShoulderDist ?? 0.0).toDouble(),
    );
  } catch (e) {
    return null;
  }
}
