import 'dart:math';
import 'package:flutter/material.dart';
import 'neck_angle_calculator.dart';

/// CvaAnglePainter
/// Draws the exact biomechanical geometry of the Craniovertebral Angle (CVA)
/// directly over the live camera preview.
class CvaAnglePainter extends CustomPainter {
  final double angle;
  final RiskLevel riskLevel;
  final bool isSideProfile;

  CvaAnglePainter({
    required this.angle,
    required this.riskLevel,
    this.isSideProfile = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Center anchor in upper-middle of viewport for intuitive alignment overlay
    final double shoulderX = size.width * 0.48;
    final double shoulderY = size.height * 0.52;

    // Convert clinical CVA angle to ear vector coordinates:
    // CVA is measured from the horizontal plane (0°) upwards to the ear line (e.g. 48°)
    final double angleRad = angle * (pi / 180.0);
    const double vectorLength = 120.0;
    final double earX = shoulderX - (vectorLength * cos(angleRad));
    final double earY = shoulderY - (vectorLength * sin(angleRad));

    final Color primaryColor = riskLevel.color;

    // ── 1. Draw Dashed Horizontal Reference Line ──
    final Paint horizontalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedHorizontalLine(canvas, shoulderX, shoulderY, size.width * 0.35, horizontalPaint);

    // ── 2. Draw Ear-to-Shoulder Biomechanical Vector ──
    final Paint vectorPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Outer glow for vector
    final Paint glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(shoulderX, shoulderY), Offset(earX, earY), glowPaint);
    canvas.drawLine(Offset(shoulderX, shoulderY), Offset(earX, earY), vectorPaint);

    // ── 3. Draw Angle Arc ──
    const double arcRadius = 48.0;
    final Rect arcRect = Rect.fromCircle(center: Offset(shoulderX, shoulderY), radius: arcRadius);
    final Paint arcPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw arc sweeping from horizontal (180°) counter-clockwise toward the ear vector
    canvas.drawArc(arcRect, pi, angleRad, false, arcPaint);

    // ── 4. Keypoint Landmarks ──
    // Shoulder (C7/Acromion)
    _drawLandmarkPoint(canvas, Offset(shoulderX, shoulderY), "C7 / Shoulder", primaryColor);

    // Ear (Tragus)
    _drawLandmarkPoint(canvas, Offset(earX, earY), "Tragus (Ear)", const Color(0xFF00E5FF));

    // ── 5. Angle Degree Tag ──
    final TextPainter angleTextPainter = TextPainter(
      text: TextSpan(
        text: "${angle.toStringAsFixed(1)}°",
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position degree readout adjacent to arc
    final double textX = shoulderX - (arcRadius * 1.5);
    final double textY = shoulderY - (arcRadius * 0.8);
    angleTextPainter.paint(canvas, Offset(textX, textY));
  }

  void _drawDashedHorizontalLine(Canvas canvas, double cx, double cy, double halfWidth, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    double startX = cx - halfWidth;
    final double endX = cx + (halfWidth * 0.5);

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, cy),
        Offset(min(startX + dashWidth, endX), cy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawLandmarkPoint(Canvas canvas, Offset point, String label, Color color) {
    // Outer glow pulse
    canvas.drawCircle(point, 12, Paint()..color = color.withValues(alpha: 0.25));
    // Core circle
    canvas.drawCircle(point, 6, Paint()..color = color);
    canvas.drawCircle(point, 3, Paint()..color = Colors.white);

    // Text label
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(point.dx + 12, point.dy - 6));
  }

  @override
  bool shouldRepaint(covariant CvaAnglePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.riskLevel != riskLevel ||
        oldDelegate.isSideProfile != isSideProfile;
  }
}
