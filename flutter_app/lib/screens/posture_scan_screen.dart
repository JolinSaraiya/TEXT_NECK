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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ── Member 1's deliverable ──
import '../camera/live_camera_stream.dart';

// ── Member 2's deliverables ──
import '../posture/neck_angle_calculator.dart';
import '../posture/posture_result_overlay.dart';

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

class _PostureScanScreenState extends State<PostureScanScreen> {
  // ── State ──────────────────────────────────────────────────────────────
  /// The latest angle calculation result from Member 2's calculator.
  NeckAngleResult? _currentResult;

  /// Whether the scanning session is active.
  bool _isSessionActive = false;

  /// Total frames processed in this session (for debug display).
  int _frameCount = 0;

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
    });

    // Tell Member 1 to start streaming
    _cameraKey.currentState?.startStreaming();

    debugPrint('[Integration] 🟢 Session started');
  }

  /// Ends the posture scanning session.
  ///
  /// Tells Member 1's LiveCameraStream to stop streaming.
  Future<void> _endSession() async {
    // Tell Member 1 to stop streaming
    await _cameraKey.currentState?.stopStreaming();

    if (mounted) {
      setState(() {
        _isSessionActive = false;
      });
    }

    debugPrint(
      '[Integration] 🔴 Session ended — '
      '$_frameCount frames processed',
    );

    // ── Show Session Summary ──
    if (_currentResult != null && mounted) {
      _showSessionSummary();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // THE BRIDGE: Member 1 → Member 2
  // ═══════════════════════════════════════════════════════════════════════

  /// This is the callback that connects Member 1's output to Member 2's
  /// input. It is passed to [LiveCameraStream.onPoseDetected].
  ///
  /// Flow:
  /// ```
  /// Pose (from Member 1)
  ///   → NeckAngleCalculator.calculateNeckAngle(pose) [Member 2's math]
  ///   → setState() → PostureResultOverlay re-renders [Member 2's UI]
  /// ```
  void _onPoseDetected(Pose pose) {
    // Guard: ignore poses if session is not active
    if (!_isSessionActive) return;

    _frameCount++;

    // ── Call Member 2's Calculator ──
    final NeckAngleResult? result =
        NeckAngleCalculator.calculateNeckAngle(pose);

    if (result != null && mounted) {
      setState(() {
        _currentResult = result;
      });

      // ── Haptic Feedback on Risk Transitions ──
      if (_currentResult?.riskLevel == RiskLevel.critical) {
        HapticFeedback.mediumImpact();
      }

      // Debug: print every 30th frame to avoid console flooding
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

  void _showSessionSummary() {
    final result = _currentResult!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
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
              color: Colors.white.withOpacity(0.5),
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
          // ── Live Indicator ──
          if (_isSessionActive)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE64545).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE64545).withOpacity(0.5),
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

          // ── Layer 2: Posture Overlay (Member 2) ──
          if (_currentResult != null)
            PostureResultOverlay(
              angle: _currentResult!.angle,
              riskLevel: _currentResult!.riskLevel,
              earSide: _currentResult!.earSide,
            ),

          // ── Layer 3: Frame Counter (Debug) ──
          if (_isSessionActive && _frameCount > 0)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Frames: $_frameCount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
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
  // Buttons
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStartSessionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _startSession,
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text(
          'Start Posture Scan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1AD4AE),
          foregroundColor: const Color(0xFF0F1118),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF1AD4AE).withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildEndSessionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _endSession,
        icon: const Icon(Icons.stop_rounded, size: 28),
        label: const Text(
          'End Session',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE64545),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFFE64545).withOpacity(0.4),
        ),
      ),
    );
  }
}
