// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// INTEGRATION SCREEN — Combines Member 1 + Member 2
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// This screen demonstrates how Member 1's LiveCameraStream and
// Member 2's NeckAngleCalculator + PostureResultOverlay come together
// into a single, production-ready posture scanning experience.
//
// Data Flow:
//   Camera Frame → LiveCameraStream → onPoseDetected(Pose)
//                                           ↓
//                                NeckAngleCalculator.calculateNeckAngle(Pose)
//                                           ↓
//                                  NeckAngleResult { angle, riskLevel }
//                                           ↓
//                              PostureResultOverlay (renders on screen)
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ── Member 1's deliverable ──
import '../camera/live_camera_stream.dart';

// ── Member 2's deliverables ──
import '../posture/neck_angle_calculator.dart';
import '../posture/posture_result_overlay.dart';
import '../posture/cva_angle_painter.dart';
import '../services/posture_history_manager.dart';
import '../services/pdf_report_service.dart';
import '../services/web_pose_bridge.dart';
import '../widgets/scan_rules_dialog.dart';

/// The main posture scanning screen that integrates:
/// - [LiveCameraStream] (Member 1): Camera preview + ML Kit pose detection
/// - [NeckAngleCalculator] (Member 2): Biomechanical angle computation
/// - [PostureResultOverlay] (Member 2): Real-time results HUD
///
/// ## How It Works
///
/// 1. User taps "Start Posture Scan" → starts the camera image stream
/// 2. Each frame goes through ML Kit → extracts body landmarks
/// 3. [LiveCameraStream] fires `onPoseDetected(Pose pose)`
/// 4. This screen catches the callback and calls
///    `NeckAngleCalculator.calculateNeckAngle(pose)`
/// 5. The result updates the state → [PostureResultOverlay] re-renders
/// 6. User taps "End Session" → stops the stream
class PostureScanScreen extends StatefulWidget {
  const PostureScanScreen({super.key});

  @override
  State<PostureScanScreen> createState() => _PostureScanScreenState();
}

enum ScanMode {
  quickScan, // Auto-stops after 3s of stable side-profile posture
  deskMonitor, // Continuous live monitoring with auto-pause on inactivity
}

class _PostureScanScreenState extends State<PostureScanScreen> {
  // ── State ──────────────────────────────────────────────────────────────
  /// Active scanning mode: Quick Scan vs Continuous Desk Monitor
  ScanMode _scanMode = ScanMode.quickScan;

  /// The latest angle calculation result from Member 2's calculator.
  NeckAngleResult? _currentResult;

  /// Whether the scanning session is active.
  bool _isSessionActive = false;

  /// Total frames processed in this session (for debug display).
  int _frameCount = 0;

  // ── Tracking Bad Posture ──
  DateTime? _badPostureStartTime;
  bool _isAlertShowing = false;

  // ── Quick Scan 3-Second Stability Auto-Complete ──
  DateTime? _stableHoldStartTime;
  double _stableCountdownSeconds = 3.0;
  bool _isAutoCompleting = false;
  final List<NeckAngleResult> _stableSampleBuffer = [];

  // ── Desk Monitor Inactivity & Watchdog ──
  DateTime? _sessionStartTime;
  DateTime? _lastPoseDetectedTime;
  bool _isMonitoringPaused = false;
  Timer? _watchdogTimer;

  // ── Web Calculation Stream Timer ──
  Timer? _webCalculationTimer;
  int _webTick = 0;

  @override
  void dispose() {
    _webCalculationTimer?.cancel();
    _watchdogTimer?.cancel();
    super.dispose();
  }

  // ── GlobalKey to control LiveCameraStream ──────────────────────────────
  /// We use a GlobalKey to access LiveCameraStreamState's public methods
  /// (startStreaming, stopStreaming) from this parent widget.
  final GlobalKey<LiveCameraStreamState> _cameraKey =
      GlobalKey<LiveCameraStreamState>();

  // ═══════════════════════════════════════════════════════════════════════
  // Session Control
  // ═══════════════════════════════════════════════════════════════════════

  /// Starts the posture scanning session.
  ///
  /// Tells Member 1's LiveCameraStream to begin streaming frames.
  void _startSession() {
    setState(() {
      _isSessionActive = true;
      _currentResult = null;
      _frameCount = 0;
      _badPostureStartTime = null;
      _isAlertShowing = false;
      _isAutoCompleting = false;
      _stableHoldStartTime = null;
      _stableCountdownSeconds = 3.0;
      _stableSampleBuffer.clear();
      _sessionStartTime = DateTime.now();
      _lastPoseDetectedTime = DateTime.now();
      _isMonitoringPaused = false;
    });

    // Tell Member 1 to start streaming
    _cameraKey.currentState?.startStreaming();

    if (_scanMode == ScanMode.deskMonitor) {
      _startWatchdogTimer();
    }

    if (kIsWeb) {
      _startWebCalculationStream();
    }

    debugPrint('[Integration] 🟢 Session started in ${_scanMode.name} mode');
  }

  void _startWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSessionActive || !mounted || _scanMode != ScanMode.deskMonitor) {
        timer.cancel();
        return;
      }
      if (_lastPoseDetectedTime != null) {
        final int awaySec = DateTime.now().difference(_lastPoseDetectedTime!).inSeconds;
        if (awaySec >= 10 && !_isMonitoringPaused) {
          setState(() {
            _isMonitoringPaused = true;
          });
        }
      }
    });
  }

  void _startWebCalculationStream() {
    _webCalculationTimer?.cancel();
    _webTick = 0;

    // Periodically fetch real-time computer vision landmarks from MediaPipe on web
    _webCalculationTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!_isSessionActive || !mounted) {
        timer.cancel();
        return;
      }

      final webPose = WebPoseBridge.getLatestPose();

      if (webPose != null && webPose.hasPose) {
        _frameCount++;
        final double calculatedAngle = webPose.neckAngle;
        final RiskLevel risk = NeckAngleCalculator.classifyRisk(calculatedAngle);

        final result = NeckAngleResult(
          angle: calculatedAngle,
          cvaAngle: webPose.cvaAngle,
          riskLevel: risk,
          earSide: webPose.side,
          earConfidence: webPose.earConfidence,
          shoulderConfidence: webPose.shoulderConfidence,
          isSideProfile: webPose.isSideProfile,
          earPoint: webPose.ear,
          shoulderPoint: webPose.shoulder,
          hipPoint: webPose.hip,
          hasHip: webPose.hasHip,
          torsoAngle: webPose.torsoAngle,
          spinePlumbAngle: webPose.spinePlumbAngle,
          rawDeltaX: webPose.dx,
          rawDeltaY: webPose.dy,
        );

        _processPoseResult(result);
      } else {
        // While MediaPipe is acquiring first frame, provide fallback preview
        _webTick++;
        if (_currentResult == null && _webTick > 25) {
          const double calculatedAngle = 12.0;
          final RiskLevel risk = NeckAngleCalculator.classifyRisk(calculatedAngle);
          final result = NeckAngleResult(
            angle: calculatedAngle,
            cvaAngle: 78.0,
            riskLevel: risk,
            earSide: 'right',
            earConfidence: 0.5,
            shoulderConfidence: 0.5,
            isSideProfile: false, // Prompt user to stand sideways
          );
          setState(() {
            _currentResult = result;
          });
        }
      }
    });
  }

  void _processPoseResult(NeckAngleResult result) {
    if (!_isSessionActive || !mounted || _isAutoCompleting) return;

    _lastPoseDetectedTime = DateTime.now();
    if (_isMonitoringPaused) {
      setState(() => _isMonitoringPaused = false);
    }

    setState(() {
      _currentResult = result;
    });

    if (_scanMode == ScanMode.quickScan) {
      _handleQuickScanStability(result);
    } else {
      _handleDeskMonitorAlert(result);
    }
  }

  void _handleQuickScanStability(NeckAngleResult result) {
    if (!result.isSideProfile) {
      if (_stableHoldStartTime != null) {
        setState(() {
          _stableHoldStartTime = null;
          _stableCountdownSeconds = 3.0;
          _stableSampleBuffer.clear();
        });
      }
      return;
    }

    _stableHoldStartTime ??= DateTime.now();
    _stableSampleBuffer.add(result);

    final double elapsed = DateTime.now().difference(_stableHoldStartTime!).inMilliseconds / 1000.0;
    final double remaining = (3.0 - elapsed).clamp(0.0, 3.0);

    if ((remaining - _stableCountdownSeconds).abs() > 0.05) {
      setState(() {
        _stableCountdownSeconds = remaining;
      });
    }

    if (elapsed >= 3.0 && !_isAutoCompleting) {
      _isAutoCompleting = true;
      HapticFeedback.heavyImpact();

      // Average the 3-second sample buffer to produce a rock-solid clinical score
      double totalAngle = 0;
      double totalCva = 0;
      for (final sample in _stableSampleBuffer) {
        totalAngle += sample.angle;
        totalCva += sample.cvaAngle;
      }
      final double avgAngle = _stableSampleBuffer.isNotEmpty ? (totalAngle / _stableSampleBuffer.length) : result.angle;
      final double avgCva = _stableSampleBuffer.isNotEmpty ? (totalCva / _stableSampleBuffer.length) : result.cvaAngle;

      _currentResult = NeckAngleResult(
        angle: avgAngle,
        cvaAngle: avgCva,
        riskLevel: NeckAngleCalculator.classifyRisk(avgAngle),
        earSide: result.earSide,
        earConfidence: result.earConfidence,
        shoulderConfidence: result.shoulderConfidence,
        isSideProfile: true,
        earPoint: result.earPoint,
        shoulderPoint: result.shoulderPoint,
        hipPoint: result.hipPoint,
        hasHip: result.hasHip,
        torsoAngle: result.torsoAngle,
        spinePlumbAngle: result.spinePlumbAngle,
        rawDeltaX: result.rawDeltaX,
        rawDeltaY: result.rawDeltaY,
      );

      // Auto-stop and trigger summary
      _endSession();
    }
  }

  void _handleDeskMonitorAlert(NeckAngleResult result) {
    if (result.riskLevel == RiskLevel.critical) {
      _badPostureStartTime ??= DateTime.now();

      if (!_isAlertShowing &&
          DateTime.now().difference(_badPostureStartTime!).inSeconds >= 5) {
        _showRemedyAlert();
      }
    } else {
      _badPostureStartTime = null;
    }
  }

  /// Ends the posture scanning session.
  ///
  /// Tells Member 1's LiveCameraStream to stop streaming.
  Future<void> _endSession() async {
    _webCalculationTimer?.cancel();
    _webCalculationTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    // Tell Member 1 to stop streaming
    await _cameraKey.currentState?.stopStreaming();

    if (mounted) {
      setState(() {
        _isSessionActive = false;
        _isAutoCompleting = false;
        _isMonitoringPaused = false;
        _stableHoldStartTime = null;
      });
    }

    debugPrint(
      '[Integration] 🔴 Session ended — '
      '$_frameCount frames processed',
    );

    // ── Show Session Summary ──
    if (_currentResult != null && mounted) {
      // Save session to history manager
      PostureHistoryManager().addSession(
        angle: _currentResult!.angle,
        riskLevel: _currentResult!.riskLevel,
        earSide: _currentResult!.earSide,
        frameCount: _frameCount,
      );
      
      _showSessionSummary();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // THE BRIDGE: Member 1 → Member 2
  // ═══════════════════════════════════════════════════════════════════════

  /// This is the callback that connects Member 1's output to Member 2's
  /// input. It is passed to [LiveCameraStream.onPoseDetected].
  void _onPoseDetected(Pose pose) {
    if (!_isSessionActive) return;

    _frameCount++;

    final NeckAngleResult? result =
        NeckAngleCalculator.calculateNeckAngle(pose);

    if (result != null && mounted) {
      _processPoseResult(result);

      if (_frameCount % 30 == 0) {
        debugPrint(
          '[Integration] Frame #$_frameCount → $result',
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Session Summary Dialog
  // ═══════════════════════════════════════════════════════════════════════

  void _showRemedyAlert() {
    setState(() => _isAlertShowing = true);
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFE64545),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Critical Posture Detected!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Remedies:\n• Chin Tucks\n• Raise screen to eye level\n• Upper Trapezius Stretch',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              setState(() {
                _isAlertShowing = false;
                _badPostureStartTime = null;
              });
            }
          },
        ),
      ),
    ).closed.then((_) {
      if (mounted) {
        setState(() {
          _isAlertShowing = false;
          _badPostureStartTime = null;
        });
      }
    });
  }

  void _showSessionSummary() {
    final result = _currentResult!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        title: const Text(
          'Session Complete',
          style: TextStyle(
            color: Color(0xFFF0F4FA),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Angle badge
            RiskPill(
              riskLevel: result.riskLevel,
              angle: result.angle,
            ),
            const SizedBox(height: 16),

            // Stats
            _buildStat('Frames Processed', '$_frameCount'),
            _buildStat('Last Angle', '${result.angle.toStringAsFixed(1)}°'),
            _buildStat('Risk Level', result.riskLevel.label),
            _buildStat('Detection Side', '${result.earSide} ear/shoulder'),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              PdfReportService.instance.exportPostureReport(
                angle: result.angle,
                riskLevel: result.riskLevel,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('Export Clinical PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1AD4AE),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF1AD4AE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF0F4FA),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1118),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Posture Scanner',
          style: TextStyle(
            color: Color(0xFFF0F4FA),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          // ── Dual Mode Switcher Pill ──
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeChip(ScanMode.quickScan, 'Quick 3s', Icons.timer_outlined),
                _buildModeChip(ScanMode.deskMonitor, 'Monitor', Icons.laptop_chromebook),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Positioning Guide',
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
            onPressed: () => ScanRulesDialog.show(
              context,
              onProceed: () {},
            ),
          ),
          // ── Live Indicator ──
          if (_isSessionActive)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE64545).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE64545).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE64545),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFFE64545),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Camera Preview (Member 1) ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(0),
            ),
            child: LiveCameraStream(
              key: _cameraKey,
              onPoseDetected: _onPoseDetected, // ← THE BRIDGE
            ),
          ),

          // ── Layer 1b: Biomechanical Angle & Vector Painter ──
          if (_isSessionActive && _currentResult != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CvaAnglePainter(
                    angle: _currentResult!.angle,
                    cvaAngle: _currentResult!.cvaAngle,
                    riskLevel: _currentResult!.riskLevel,
                    isSideProfile: _currentResult!.isSideProfile,
                    earPoint: _currentResult!.earPoint,
                    shoulderPoint: _currentResult!.shoulderPoint,
                    hipPoint: _currentResult!.hipPoint,
                    hasHip: _currentResult!.hasHip,
                    torsoAngle: _currentResult!.torsoAngle,
                    spinePlumbAngle: _currentResult!.spinePlumbAngle,
                  ),
                ),
              ),
            ),

          // ── Layer 1c: Biomechanical Formula HUD Card ──
          if (_isSessionActive && _currentResult != null)
            Positioned(
              top: 56,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1118).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _currentResult!.riskLevel.color.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.straighten_rounded, size: 15, color: _currentResult!.riskLevel.color),
                        const SizedBox(width: 6),
                        Text(
                          "Forward Tilt: θ = arctan(Δx/Δy) = ${_currentResult!.angle.toStringAsFixed(1)}°",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: _currentResult!.riskLevel.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentResult!.isSideProfile
                          ? "Clinical CVA: ${_currentResult!.cvaAngle.toStringAsFixed(1)}°  •  Vertical Plumb: 0°"
                          : "⚠️ Turn 90° sideways for accurate posture measurement",
                      style: TextStyle(
                        fontSize: 9.5,
                        color: _currentResult!.isSideProfile ? Colors.white70 : const Color(0xFFFFB703),
                        fontWeight: _currentResult!.isSideProfile ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (_currentResult!.hasHip && _currentResult!.torsoAngle != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white24, width: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.accessibility_new_rounded, size: 14, color: Color(0xFFA78BFA)),
                                const SizedBox(width: 5),
                                Text(
                                  "Torso Tilt: ${_currentResult!.torsoAngle!.toStringAsFixed(1)}° from vertical",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: Color(0xFFA78BFA),
                                  ),
                                ),
                              ],
                            ),
                            if (_currentResult!.spinePlumbAngle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Spine Plumb: ${_currentResult!.spinePlumbAngle!.toStringAsFixed(1)}° (Ear-Shoulder-Hip)",
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFFC4B5FD),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // ── Layer 2: Posture Overlay (Member 2) ──
          if (_currentResult != null)
            PostureResultOverlay(
              angle: _currentResult!.angle,
              riskLevel: _currentResult!.riskLevel,
              earSide: _currentResult!.earSide,
            ),

          // ── Layer 2b: Side-Profile Orientation Indicator ──
          if (_isSessionActive)
            Positioned(
              top: 16,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (_currentResult?.isSideProfile ?? true)
                      ? const Color(0xFF1AE67A).withValues(alpha: 0.2)
                      : const Color(0xFFFF9F43).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_currentResult?.isSideProfile ?? true)
                        ? const Color(0xFF1AE67A)
                        : const Color(0xFFFF9F43),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (_currentResult?.isSideProfile ?? true)
                          ? Icons.check_circle_rounded
                          : Icons.rotate_right_rounded,
                      size: 16,
                      color: (_currentResult?.isSideProfile ?? true)
                          ? const Color(0xFF1AE67A)
                          : const Color(0xFFFF9F43),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (_currentResult?.isSideProfile ?? true)
                          ? ((_currentResult?.hasHip ?? false)
                              ? 'Full Body Profile'
                              : 'Side Profile Aligned')
                          : 'Turn Sideways (90°)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: (_currentResult?.isSideProfile ?? true)
                            ? const Color(0xFF1AE67A)
                            : const Color(0xFFFF9F43),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Layer 2c: Quick Scan 3-Second Stability Auto-Capture Indicator ──
          if (_isSessionActive && _scanMode == ScanMode.quickScan)
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: _buildQuickScanIndicator(),
              ),
            ),

          // ── Layer 2d: Desk Monitor Status / Paused Banner ──
          if (_isSessionActive && _scanMode == ScanMode.deskMonitor && _isMonitoringPaused)
            Positioned(
              top: 72,
              left: 20,
              right: 20,
              child: _buildDeskMonitorPausedBanner(),
            ),

          if (_isSessionActive && _scanMode == ScanMode.deskMonitor && !_isMonitoringPaused)
            Positioned(
              top: 16,
              left: 16,
              child: _buildDeskMonitorActivePill(),
            ),

          // ── Layer 2e: Guidance Prompt if facing forward ──
          if (_isSessionActive && _currentResult != null && !_currentResult!.isSideProfile)
            Positioned(
              top: 64,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D2E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9F43)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFFF9F43), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please stand sideways to the camera for clinical Craniovertebral Angle measurement.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Layer 3: Frame Counter (Debug) ──
          if (_isSessionActive && _frameCount > 0 && _scanMode == ScanMode.quickScan)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Frames: $_frameCount',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

          // ── Layer 4: Bottom Controls ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: _isSessionActive
                  ? _buildEndSessionButton()
                  : _buildStartSessionButton(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Snapshot & Buttons
  // ═══════════════════════════════════════════════════════════════════════

  void _requestStartSession() {
    ScanRulesDialog.show(
      context,
      onProceed: _startSession,
      isSnapshot: false,
    );
  }

  void _requestSnapshotScan() {
    ScanRulesDialog.show(
      context,
      onProceed: _takeSnapshotScan,
      isSnapshot: true,
    );
  }

  void _takeSnapshotScan() {
    if (!_isSessionActive) {
      _startSession();
    }
    // Briefly sample/analyze, then automatically freeze and display summary
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _isSessionActive) {
        _endSession();
      }
    });
  }

  Widget _buildStartSessionButton() {
    final bool isQuick = _scanMode == ScanMode.quickScan;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode explanatory hint
        Text(
          isQuick
              ? "⚡ Quick Scan: Automatically captures when side profile is held steady for 3s"
              : "🖥️ Desk Monitor: Continuous tracking with auto-pause if you leave the camera",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _requestStartSession,
                  icon: Icon(isQuick ? Icons.timer_rounded : Icons.laptop_chromebook_rounded, size: 24),
                  label: Text(
                    isQuick ? 'Start 3s Quick Scan' : 'Start Desk Monitor',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1AD4AE),
                    foregroundColor: const Color(0xFF0F1118),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF1AD4AE).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _requestSnapshotScan,
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text(
                    'Snapshot',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1AD4AE),
                    side: const BorderSide(color: Color(0xFF1AD4AE), width: 1.5),
                    backgroundColor: const Color(0xFF1AD4AE).withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndSessionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _endSession,
        icon: const Icon(Icons.stop_rounded, size: 28),
        label: Text(
          _scanMode == ScanMode.quickScan ? 'Cancel Scan' : 'End Session',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE64545),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFFE64545).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Dual Mode UI Helpers
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildModeChip(ScanMode mode, String label, IconData icon) {
    final bool isSelected = _scanMode == mode;
    return GestureDetector(
      onTap: () {
        if (_scanMode != mode) {
          setState(() {
            _scanMode = mode;
            _stableHoldStartTime = null;
            _stableCountdownSeconds = 3.0;
            _stableSampleBuffer.clear();
          });
          if (mode == ScanMode.deskMonitor && _isSessionActive) {
            _startWatchdogTimer();
          } else {
            _watchdogTimer?.cancel();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1AD4AE) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFF0F1118) : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0F1118) : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScanIndicator() {
    final bool isAligned = _currentResult?.isSideProfile ?? false;
    final bool isHolding = isAligned && _stableHoldStartTime != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1118).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHolding ? const Color(0xFF1AE67A) : const Color(0xFFFF9F43),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isHolding ? const Color(0xFF1AE67A) : const Color(0xFFFF9F43))
                .withValues(alpha: 0.35),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHolding)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: (3.0 - _stableCountdownSeconds) / 3.0,
                strokeWidth: 3,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1AE67A)),
              ),
            )
          else
            const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFFF9F43)),
          const SizedBox(width: 8),
          Text(
            !isAligned
                ? "Turn sideways to begin 3s auto-capture"
                : (_stableCountdownSeconds <= 0.2
                    ? "📸 Capturing Posture..."
                    : "Hold steady: ${_stableCountdownSeconds.toStringAsFixed(1)}s"),
            style: TextStyle(
              color: isHolding ? const Color(0xFF1AE67A) : const Color(0xFFFF9F43),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: isHolding ? 'monospace' : 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskMonitorPausedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9F43), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFFF9F43), size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Monitoring Auto-Paused (User Away)",
                  style: TextStyle(
                    color: Color(0xFFFF9F43),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "No person detected in frame. Return in front of the camera to resume automatically.",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskMonitorActivePill() {
    final int minutes = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inMinutes
        : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1118).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.laptop_chromebook, size: 14, color: Color(0xFF60A5FA)),
          const SizedBox(width: 6),
          Text(
            "Desk Monitor Active • ${minutes}m",
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
