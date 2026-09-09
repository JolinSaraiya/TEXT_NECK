import 'dart:math';
import 'package:flutter/material.dart';
import 'neck_angle_calculator.dart';

/// CvaAnglePainter
/// Draws the exact biomechanical geometry of Forward Neck Tilt and Craniovertebral Angle (CVA),
/// as well as full-body posture alignment (including Ear -> Shoulder -> Hip plumb line)
/// directly over the live camera preview.
class CvaAnglePainter extends CustomPainter {
  final double angle; // Forward tilt from vertical plumb line (0° = upright)
  final double? cvaAngle; // Clinical CVA from horizontal (90° = upright)
  final RiskLevel riskLevel;
  final bool isSideProfile;
  final Offset? earPoint;
  final Offset? shoulderPoint;
  final Offset? hipPoint;
  final bool hasHip;
  final double? torsoAngle;
  final double? spinePlumbAngle;
  final bool isMirrored;

  CvaAnglePainter({
    required this.angle,
    this.cvaAngle,
    required this.riskLevel,
    this.isSideProfile = true,
    this.earPoint,
    this.shoulderPoint,
    this.hipPoint,
    this.hasHip = false,
    this.torsoAngle,
    this.spinePlumbAngle,
    this.isMirrored = true,
  });

  Offset _toCanvas(Offset normalized, Size size) {
    // Account for mirrored front-camera preview
    final double x = isMirrored ? (1.0 - normalized.dx) * size.width : normalized.dx * size.width;
    final double y = normalized.dy * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // ── 1. If NOT in Side Profile: Draw Guidance Overlay ──
    if (!isSideProfile) {
      _drawFrontFacingWarning(canvas, size);
      return;
    }

    // ── 2. Determine Coordinates from Actual Detected Points ──
    final double shoulderX;
    final double shoulderY;
    final double earX;
    final double earY;

    if (shoulderPoint != null) {
      final s = _toCanvas(shoulderPoint!, size);
      shoulderX = s.dx;
      shoulderY = s.dy;
    } else {
      shoulderX = size.width * 0.50;
      shoulderY = size.height * 0.52;
    }

    if (earPoint != null) {
      final e = _toCanvas(earPoint!, size);
      earX = e.dx;
      earY = e.dy;
    } else {
      final double angleRad = angle * (pi / 180.0);
      const double vectorLength = 110.0;
      earX = shoulderX - (vectorLength * sin(angleRad));
      earY = shoulderY - (vectorLength * cos(angleRad));
    }

    final Color primaryColor = riskLevel.color;

    // ── 3. Draw Vertical 0° Plumb Line Through Shoulder (Gravity Baseline) ──
    final Paint plumbPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double plumbTop = max(16.0, earY - 60);
    final double plumbBottom = hasHip && hipPoint != null
        ? _toCanvas(hipPoint!, size).dy + 40
        : shoulderY + 80;
    _drawDashedVerticalLine(canvas, shoulderX, plumbTop, plumbBottom, plumbPaint);
    _drawSmallLabel(canvas, Offset(shoulderX + 6, plumbTop + 8), "Vertical 0° Plumb", const Color(0xFF60A5FA));

    // ── 4. Draw Horizontal 90° Baseline Through Shoulder ──
    final Paint horizontalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double horizExtent = size.width * 0.30;
    _drawDashedHorizontalLine(canvas, shoulderX, shoulderY, horizExtent, horizontalPaint);
    final double horizLabelX = (earX < shoulderX) ? shoulderX + 12 : shoulderX - 110;
    _drawSmallLabel(canvas, Offset(horizLabelX, shoulderY + 6), "Horizontal Baseline", Colors.white60);

    // ── 5. Draw Ear-to-Shoulder Biomechanical Vector ──
    final Paint glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint vectorPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(shoulderX, shoulderY), Offset(earX, earY), glowPaint);
    canvas.drawLine(Offset(shoulderX, shoulderY), Offset(earX, earY), vectorPaint);

    // ── 6. Draw Forward Tilt Angle Arc ──
    // Arc sweeps from vertical plumb line (-pi/2) toward the ear vector
    const double arcRadius = 48.0;
    final Rect arcRect = Rect.fromCircle(center: Offset(shoulderX, shoulderY), radius: arcRadius);
    final Paint arcPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    final double earAngle = atan2(earY - shoulderY, earX - shoulderX);
    const double verticalAngle = -pi / 2; // straight up
    double sweep = earAngle - verticalAngle;
    if (sweep > pi) sweep -= 2 * pi;
    if (sweep < -pi) sweep += 2 * pi;

    canvas.drawArc(arcRect, verticalAngle, sweep, false, arcPaint);

    // Angle Degree Callout Badge
    final TextPainter angleTextPainter = TextPainter(
      text: TextSpan(
        text: "${angle.toStringAsFixed(1)}°",
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double textX = shoulderX + (sweep < 0 ? -arcRadius * 1.5 : arcRadius * 0.4);
    final double textY = shoulderY - arcRadius * 0.85;
    angleTextPainter.paint(canvas, Offset(textX, textY));

    // ── 7. Draw Hip / Standing Sideways Plumb Line (Full Body Posture) ──
    if (hasHip && hipPoint != null) {
      final h = _toCanvas(hipPoint!, size);
      final double hipX = h.dx;
      final double hipY = h.dy;

      // Draw dashed vertical plumb line through Hip
      _drawDashedVerticalLine(canvas, hipX, hipY - 50, hipY + 50, plumbPaint);

      // Torso vector connecting Shoulder to Hip
      const Color torsoColor = Color(0xFFA78BFA);
      final Paint torsoPaint = Paint()
        ..color = torsoColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final Paint torsoGlow = Paint()
        ..color = torsoColor.withValues(alpha: 0.3)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(shoulderX, shoulderY), Offset(hipX, hipY), torsoGlow);
      canvas.drawLine(Offset(shoulderX, shoulderY), Offset(hipX, hipY), torsoPaint);

      // Full Spine Plumb Line (Ear -> Shoulder -> Hip)
      final Paint spineConnector = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(earX, earY), Offset(hipX, hipY), spineConnector);

      // Hip Landmark Pin
      _drawLandmarkPoint(canvas, Offset(hipX, hipY), "Greater Trochanter (Hip)", torsoColor);

      // Torso Alignment degree label
      if (torsoAngle != null) {
        _drawSmallLabel(
          canvas,
          Offset(shoulderX + (hipX - shoulderX) * 0.5 + 14, shoulderY + (hipY - shoulderY) * 0.5),
          "Torso Tilt: ${torsoAngle!.toStringAsFixed(1)}°",
          torsoColor,
        );
      }
    }

    // ── 8. Keypoint Landmarks ──
    // Shoulder (C7/Acromion)
    _drawLandmarkPoint(canvas, Offset(shoulderX, shoulderY), "C7 / Acromion", primaryColor);

    // Ear (Tragus)
    _drawLandmarkPoint(canvas, Offset(earX, earY), "Tragus (Ear)", const Color(0xFF00E5FF));
  }

  void _drawFrontFacingWarning(Canvas canvas, Size size) {
    final double bannerWidth = min(size.width * 0.86, 380.0);
    const double bannerHeight = 84.0;
    final double bannerX = (size.width - bannerWidth) / 2;
    final double bannerY = size.height * 0.20;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bannerX, bannerY, bannerWidth, bannerHeight),
      const Radius.circular(16),
    );

    // Shadow / glow
    canvas.drawRRect(
      rrect.inflate(4),
      Paint()..color = const Color(0xFFFF9F43).withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Background container
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF141724).withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final Paint borderPaint = Paint()
      ..color = const Color(0xFFFF9F43)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // Warning Text Content
    final TextPainter tp = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(
            text: "⚠️ Side Profile Required (90°)\n",
            style: TextStyle(
              color: Color(0xFFFF9F43),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: "Please turn 90° sideways to the camera.\nAccurate neck angle & spine plumb line can only be calculated from a lateral profile.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: bannerWidth - 24);

    tp.paint(canvas, Offset(bannerX + 12, bannerY + 12));
  }

  void _drawDashedHorizontalLine(Canvas canvas, double cx, double cy, double halfWidth, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    double startX = cx - halfWidth;
    final double endX = cx + halfWidth;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, cy),
        Offset(min(startX + dashWidth, endX), cy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawDashedVerticalLine(Canvas canvas, double cx, double topY, double bottomY, Paint paint) {
    const double dashHeight = 7.0;
    const double dashSpace = 5.0;
    double currentY = topY;

    while (currentY < bottomY) {
      canvas.drawLine(
        Offset(cx, currentY),
        Offset(cx, min(currentY + dashHeight, bottomY)),
        paint,
      );
      currentY += dashHeight + dashSpace;
    }
  }

  void _drawLandmarkPoint(Canvas canvas, Offset point, String label, Color color) {
    // Outer glow pulse
    canvas.drawCircle(point, 13, Paint()..color = color.withValues(alpha: 0.25));
    // Core circle
    canvas.drawCircle(point, 6, Paint()..color = color);
    canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);

    // Text label
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.95), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(point.dx + 12, point.dy - 6));
  }

  void _drawSmallLabel(Canvas canvas, Offset point, String text, Color color) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.95), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, point);
  }

  @override
  bool shouldRepaint(covariant CvaAnglePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.cvaAngle != cvaAngle ||
        oldDelegate.riskLevel != riskLevel ||
        oldDelegate.isSideProfile != isSideProfile ||
        oldDelegate.earPoint != earPoint ||
        oldDelegate.shoulderPoint != shoulderPoint ||
        oldDelegate.hipPoint != hipPoint ||
        oldDelegate.hasHip != hasHip ||
        oldDelegate.torsoAngle != torsoAngle ||
        oldDelegate.spinePlumbAngle != spinePlumbAngle;
  }
}
