import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../posture/neck_angle_calculator.dart';

class PostureSessionResult {
  final DateTime timestamp;
  final double angle;
  final RiskLevel riskLevel;
  final String earSide;
  final int frameCount;

  PostureSessionResult({
    required this.timestamp,
    required this.angle,
    required this.riskLevel,
    required this.earSide,
    required this.frameCount,
  });

  // Factory to create from Firestore Map
  factory PostureSessionResult.fromMap(Map<String, dynamic> data) {
    return PostureSessionResult(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      angle: (data['angle'] ?? 0.0).toDouble(),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == data['riskLevel'], 
        orElse: () => RiskLevel.warning,
      ),
      earSide: data['earSide'] ?? 'unknown',
      frameCount: data['frameCount'] ?? 0,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'angle': angle,
      'riskLevel': riskLevel.name,
      'earSide': earSide,
      'frameCount': frameCount,
    };
  }

  /// Craniovertebral Angle (degrees from horizontal baseline).
  double get craniovertebralAngle => angle <= 45 ? (90.0 - angle) : angle;

  /// Forward head tilt angle (degrees from vertical plumb line).
  double get forwardTiltAngle => angle <= 45 ? angle : (90.0 - angle);

  // Risk score accurately mapped from clinical cervical forward tilt:
  // 0°..14° (Good): 0%..15% risk -> 85%..100% posture health score
  // 15°..29° (Warning): 16%..50% risk -> 50%..84% posture health score
  // 30°+ (Critical): 51%..100% risk -> 0%..49% posture health score
  int get riskScore {
    final tilt = forwardTiltAngle.clamp(0.0, 90.0);
    if (tilt < 15.0) {
      return ((tilt / 15.0) * 15.0).round().clamp(0, 15);
    } else if (tilt < 30.0) {
      return (16.0 + ((tilt - 15.0) / 15.0) * 34.0).round().clamp(16, 50);
    } else {
      return (51.0 + ((tilt - 30.0) / 30.0) * 49.0).round().clamp(51, 100);
    }
  }

  /// Calculated Posture Health Score (0%..100%).
  int get postureScore => (100 - riskScore).clamp(0, 100);

  // Spine load calculation based on neck angle (cervical spine stress approximations)
  double get spineLoadKg {
    double verticalDeviation = forwardTiltAngle.clamp(0.0, 90.0);
    
    if (verticalDeviation <= 0) return 5.0;
    if (verticalDeviation <= 15) return 5.0 + (verticalDeviation / 15.0) * 7.0;
    if (verticalDeviation <= 30) return 12.0 + ((verticalDeviation - 15) / 15.0) * 6.0;
    if (verticalDeviation <= 45) return 18.0 + ((verticalDeviation - 30) / 15.0) * 4.0;
    if (verticalDeviation <= 60) return 22.0 + ((verticalDeviation - 45) / 15.0) * 5.0;
    return 27.0; // clamp at max load
  }
}

class PostureHistoryManager extends ChangeNotifier {
  static final PostureHistoryManager _instance = PostureHistoryManager._internal();

  factory PostureHistoryManager() => _instance;

  List<PostureSessionResult> _history = [];
  StreamSubscription<QuerySnapshot>? _sessionSub;
  StreamSubscription<User?>? _authSub;

  PostureHistoryManager._internal() {
    // Listen to authentication state changes to fetch the correct user's data
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToSessions(user.uid);
      } else {
        _sessionSub?.cancel();
        _history.clear();
        notifyListeners();
      }
    });
  }

  void _subscribeToSessions(String uid) {
    _sessionSub?.cancel();
    _sessionSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _history = snapshot.docs
          .map((doc) => PostureSessionResult.fromMap(doc.data()))
          .toList();
      notifyListeners();
    });
  }

  List<PostureSessionResult> get history => List.unmodifiable(_history);

  PostureSessionResult? get latestResult => _history.isNotEmpty ? _history.first : null;

  int get totalSessions => _history.length;

  double get averageScore {
    if (_history.isEmpty) return 0.0;
    final total = _history.map((s) => s.postureScore.toDouble()).reduce((a, b) => a + b);
    return total / _history.length;
  }

  int get streak {
    if (_history.isEmpty) return 0;
    return _calculateStreak();
  }

  int _calculateStreak() {
    if (_history.isEmpty) return 0;
    // Extract unique calendar days sorted descending
    final dates = _history
        .map((s) => DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day))
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));

    int streakCount = 0;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // If the latest scan is not today or yesterday, streak is broken
    if (dates.first != today && dates.first != today.subtract(const Duration(days: 1))) {
      return 0;
    }

    DateTime expected = dates.first;
    for (final date in dates) {
      if (date == expected) {
        streakCount++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streakCount;
  }

  Future<void> addSession({
    required double angle,
    required RiskLevel riskLevel,
    required String earSide,
    required int frameCount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final session = PostureSessionResult(
      timestamp: DateTime.now(),
      angle: angle,
      riskLevel: riskLevel,
      earSide: earSide,
      frameCount: frameCount,
    );

    // Write to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .add(session.toMap());
        
    // Note: The UI will automatically update because the Firestore 
    // snapshot listener will see the new document and call notifyListeners()
  }

  Future<void> clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .get();
    for (final doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

