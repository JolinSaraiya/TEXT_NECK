// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MEMBER 1 — Computer Vision (Camera & ML Kit)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Responsibility:
//   Stream live video from the front-facing camera, convert each frame
//   to an ML Kit InputImage, run PoseDetector, and fire the
//   [onPoseDetected] callback with the raw Pose object.
//
// Tech Stack:
//   - camera ^0.11.0
//   - google_mlkit_pose_detection ^0.12.0
//
// Contract:
//   This widget exposes a single callback [onPoseDetected] that Member 2
//   will consume to calculate the neck angle and render the overlay.
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Callback Type Definition
// ─────────────────────────────────────────────────────────────────────────────

/// Callback signature for downstream consumers (Member 2).
///
/// Fired every time ML Kit successfully detects at least one pose in a frame.
/// The [pose] object contains all 33 body landmarks with (x, y, z) coordinates
/// and a [likelihood] confidence score.
typedef PoseCallback = void Function(Pose pose);

// ─────────────────────────────────────────────────────────────────────────────
// LiveCameraStream Widget
// ─────────────────────────────────────────────────────────────────────────────

/// A self-contained widget that:
///   1. Discovers and initializes the front-facing camera.
///   2. Renders a live camera preview.
///   3. Streams frames to Google ML Kit PoseDetector.
///   4. Extracts body landmarks and prints raw coordinates to console.
///   5. Fires [onPoseDetected] so Member 2 can calculate the neck angle.
///
/// Usage:
/// ```dart
/// LiveCameraStream(
///   onPoseDetected: (Pose pose) {
///     // Member 2 receives the Pose here
///     final angle = NeckAngleCalculator.calculateNeckAngle(pose);
///   },
/// )
/// ```
class LiveCameraStream extends StatefulWidget {
  /// Callback invoked on each successfully detected pose.
  /// Pass `null` to only enable debug printing without downstream processing.
  final PoseCallback? onPoseDetected;

  const LiveCameraStream({super.key, this.onPoseDetected});

  @override
  State<LiveCameraStream> createState() => LiveCameraStreamState();
}

class LiveCameraStreamState extends State<LiveCameraStream>
    with WidgetsBindingObserver {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  // ── ML Kit Pose Detection ──────────────────────────────────────────────
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      // Stream mode: optimized for real-time processing (lower accuracy,
      // higher throughput vs. single-image mode).
      mode: PoseDetectionMode.stream,
      // Base model: lightweight, runs on-device, sufficient for upper-body
      // landmarks (ear, shoulder, nose).
      model: PoseDetectionModel.base,
    ),
  );

  // ── Frame Processing Guard ─────────────────────────────────────────────
  // Prevents concurrent ML Kit invocations. Without this, the pipeline
  // would queue up frames faster than ML Kit can process them, leading to
  // memory pressure and eventual OOM crash.
  bool _isDetecting = false;

  // ── Streaming State ────────────────────────────────────────────────────
  bool _isStreaming = false;

  // ═══════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer so we can release the camera when the
    // app goes to background and re-acquire it on resume.
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStreaming();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  /// Handles app lifecycle transitions.
  ///
  /// - [inactive]: App is partially visible (e.g., incoming call overlay).
  ///   We release the camera to free the hardware resource.
  /// - [resumed]: App returns to foreground. We re-initialize.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopStreaming();
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 1: Camera Initialization
  // ═══════════════════════════════════════════════════════════════════════

  /// Discovers available cameras, selects the front-facing camera,
  /// and initializes the [CameraController].
  ///
  /// Configuration choices:
  /// - [ResolutionPreset.medium]: 480p — balances quality vs. ML Kit
  ///   processing speed. Higher resolutions slow down pose detection
  ///   without meaningful accuracy gains for upper-body landmarks.
  /// - [ImageFormatGroup.nv21]: The native format for Android camera
  ///   hardware. ML Kit's on-device pose detector is optimized for NV21
  ///   on Android and bgra8888 on iOS.
  /// - [enableAudio: false]: We don't need the microphone.
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        debugPrint('[Member1] ❌ No cameras found on this device');
        return;
      }

      // ── Select Front Camera ──
      // For posture detection, the user faces the screen, so we need
      // the front (selfie) camera. Fallback to the first available
      // camera if no front camera exists (rare on modern phones).
      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      debugPrint(
        '[Member1] 📷 Selected camera: ${frontCamera.name} '
        '(${frontCamera.lensDirection.name}, '
        'sensor orientation: ${frontCamera.sensorOrientation}°)',
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      debugPrint('[Member1] ✅ Camera initialized successfully');
    } catch (e) {
      debugPrint('[Member1] ❌ Camera initialization failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 2: Start / Stop Image Streaming
  // ═══════════════════════════════════════════════════════════════════════

  /// Starts the live image stream from the camera.
  ///
  /// Each frame arrives as a [CameraImage] which is then sent through
  /// the processing pipeline: CameraImage → InputImage → PoseDetector.
  ///
  /// This method is called by the parent widget (the integration screen)
  /// when the user taps "Start Scan".
  void startStreaming() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isStreaming) {
      return;
    }

    _isStreaming = true;
    _cameraController!.startImageStream(_onFrameAvailable);
    debugPrint('[Member1] 🟢 Image stream started');
  }

  /// Stops the live image stream.
  ///
  /// Called when the user taps "End Session" or the widget is disposed.
  Future<void> _stopStreaming() async {
    if (!_isStreaming || _cameraController == null) return;

    _isStreaming = false;
    try {
      await _cameraController!.stopImageStream();
      debugPrint('[Member1] 🔴 Image stream stopped');
    } catch (e) {
      // Silently handle — stream may already be stopped
      debugPrint('[Member1] ⚠️ Stop stream error (non-fatal): $e');
    }
  }

  /// Public method for the parent screen to stop the stream.
  Future<void> stopStreaming() async {
    await _stopStreaming();
  }

  /// Returns whether the camera is currently streaming frames.
  bool get isStreaming => _isStreaming;

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 3: Frame Processing Pipeline
  // ═══════════════════════════════════════════════════════════════════════

  /// Called for every frame from the camera's image stream.
  ///
  /// Pipeline:
  /// ```
  /// CameraImage → _convertToInputImage() → PoseDetector → _onPoseDetected()
  /// ```
  ///
  /// The [_isDetecting] mutex ensures we process only one frame at a time.
  /// Frames arriving while ML Kit is busy are silently dropped — this is
  /// intentional. Real-time pose detection at 10-15 FPS is sufficient for
  /// posture monitoring; we don't need 30 FPS accuracy.
  void _onFrameAvailable(CameraImage cameraImage) async {
    // ── Mutex Guard ──
    // If ML Kit is still processing the previous frame, skip this one.
    // This is the single most important performance optimization in the
    // entire pipeline.
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      // ── STEP 3a: Convert CameraImage → InputImage ──
      final inputImage = _convertToInputImage(cameraImage);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      // ── STEP 3b: Run ML Kit Pose Detection ──
      final List<Pose> poses = await _poseDetector.processImage(inputImage);

      // ── STEP 3c: Process First Detected Pose ──
      if (poses.isNotEmpty && mounted) {
        final Pose pose = poses.first;

        // ── STEP 3d: Extract & Print Key Landmarks ──
        _printLandmarks(pose);

        // ── STEP 3e: Fire Callback to Member 2 ──
        widget.onPoseDetected?.call(pose);
      }
    } catch (e) {
      // Silently catch ML Kit errors. Common causes:
      // - Image format mismatch on certain device models
      // - ML Kit internal buffer overflow under heavy load
      // - Race condition during camera disposal
      debugPrint('[Member1] ⚠️ Pose detection error: $e');
    }

    _isDetecting = false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 4: CameraImage → InputImage Conversion
  // ═══════════════════════════════════════════════════════════════════════

  /// Converts a Flutter [CameraImage] into Google ML Kit's [InputImage].
  ///
  /// This is the most device-specific part of the pipeline. Key details:
  ///
  /// 1. **Image Format**: The camera is configured to output NV21 (Android's
  ///    native YUV format). ML Kit expects this format for optimal performance.
  ///    On iOS, bgra8888 would be used instead.
  ///
  /// 2. **Byte Concatenation**: A [CameraImage] may contain multiple planes
  ///    (Y, U, V for NV21). We concatenate all planes into a single contiguous
  ///    byte buffer using [WriteBuffer].
  ///
  /// 3. **Rotation**: The camera sensor's physical orientation doesn't match
  ///    the screen orientation. We map the [sensorOrientation] (0°, 90°, 180°,
  ///    or 270°) to ML Kit's [InputImageRotation] enum so the pose detector
  ///    knows which way is "up".
  ///
  /// 4. **Metadata**: ML Kit needs the image dimensions, format, rotation,
  ///    and bytes-per-row to correctly decode the raw byte buffer.
  InputImage? _convertToInputImage(CameraImage cameraImage) {
    // ── Get the active camera's sensor orientation ──
    final camera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    final int sensorOrientation = camera.sensorOrientation;

    // ── Map sensor orientation to InputImageRotation ──
    InputImageRotation? rotation;
    switch (sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        rotation = InputImageRotation.rotation270deg;
        break;
      default:
        debugPrint(
          '[Member1] ⚠️ Unknown sensor orientation: $sensorOrientation',
        );
        return null;
    }

    // ── Determine the image format ──
    final format = InputImageFormatValue.fromRawValue(
      cameraImage.format.raw,
    );
    if (format == null) {
      debugPrint(
        '[Member1] ⚠️ Unsupported image format: ${cameraImage.format.raw}',
      );
      return null;
    }

    // ── Concatenate all image planes into a single byte buffer ──
    // NV21 typically has 2 planes (Y + interleaved UV), but we handle
    // any number of planes generically.
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // ── Build image dimensions ──
    final ui.Size imageSize = ui.Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

    // ── Assemble InputImage with metadata ──
    final InputImageMetadata metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: cameraImage.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 5: Landmark Extraction & Debug Printing
  // ═══════════════════════════════════════════════════════════════════════

  /// Extracts and prints the raw (X, Y) coordinates for the five key
  /// landmarks required by the project specification:
  ///
  /// - **Nose**: Central face reference point
  /// - **Left Ear / Right Ear**: Head position indicators
  /// - **Left Shoulder / Right Shoulder**: Base reference for cervical angle
  ///
  /// Each landmark's [likelihood] score (0.0 – 1.0) indicates how confident
  /// ML Kit is that the landmark is visible and correctly positioned.
  /// A likelihood below 0.5 typically means the landmark is occluded or
  /// out of frame.
  void _printLandmarks(Pose pose) {
    // Define the landmarks we care about
    final landmarkTypes = {
      'Nose': PoseLandmarkType.nose,
      'Left Ear': PoseLandmarkType.leftEar,
      'Right Ear': PoseLandmarkType.rightEar,
      'Left Shoulder': PoseLandmarkType.leftShoulder,
      'Right Shoulder': PoseLandmarkType.rightShoulder,
    };

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('─── Pose Landmarks ───');

    for (final entry in landmarkTypes.entries) {
      final landmark = pose.landmarks[entry.value];
      if (landmark != null) {
        buffer.writeln(
          '  ${entry.key.padRight(16)}: '
          'X=${landmark.x.toStringAsFixed(1).padLeft(7)}, '
          'Y=${landmark.y.toStringAsFixed(1).padLeft(7)}  '
          '(confidence: ${(landmark.likelihood * 100).toStringAsFixed(0)}%)',
        );
      } else {
        buffer.writeln('  ${entry.key.padRight(16)}: NOT DETECTED');
      }
    }

    debugPrint(buffer.toString());
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI — Camera Preview
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ── Camera Not Ready ──
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: const Color(0xFF0F1118),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: const Color(0xFF1AD4AE).withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Color(0xFFF0F4FA),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFF1AD4AE),
              ),
            ],
          ),
        ),
      );
    }

    // ── Camera Ready — Render Preview ──
    return CameraPreview(_cameraController!);
  }
}
