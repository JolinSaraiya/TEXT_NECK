import 'package:flutter/foundation.dart';
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

  // Risk score is scaled from 0% (0 degrees) to 100% (60+ degrees)
  int get riskScore {
    // 0 to 15 degrees: 0% to 20%
    // 15 to 30 degrees: 20% to 50%
    // 30 to 60+ degrees: 50% to 100%
    if (angle < 15) {
      return ((angle / 15.0) * 20).round();
    } else if (angle < 30) {
      return (20 + ((angle - 15) / 15.0) * 30).round();
    } else {
      return (50 + ((angle - 30) / 30.0) * 50).clamp(50, 100).round();
    }
  }

  // Spine load calculation based on neck angle (cervical spine stress approximations)
  double get spineLoadKg {
    // 0 deg: 5.0 kg
    // 15 deg: 12.0 kg
    // 30 deg: 18.0 kg
    // 45 deg: 22.0 kg
    // 60 deg: 27.0 kg
    if (angle <= 0) return 5.0;
    if (angle <= 15) return 5.0 + (angle / 15.0) * 7.0;
    if (angle <= 30) return 12.0 + ((angle - 15) / 15.0) * 6.0;
    if (angle <= 45) return 18.0 + ((angle - 30) / 15.0) * 4.0;
    if (angle <= 60) return 22.0 + ((angle - 45) / 15.0) * 5.0;
    return 27.0; // clamp at max load
  }
}

class PostureHistoryManager extends ChangeNotifier {
  static final PostureHistoryManager _instance = PostureHistoryManager._internal();

  factory PostureHistoryManager() => _instance;

  PostureHistoryManager._internal();

  final List<PostureSessionResult> _history = [];

  List<PostureSessionResult> get history => List.unmodifiable(_history);

  PostureSessionResult? get latestResult => _history.isNotEmpty ? _history.first : null;

  int get totalSessions => _history.length;

  double get averageScore {
    if (_history.isEmpty) return 74.0; // Default baseline score
    final total = _history.map((s) => 100.0 - s.riskScore).reduce((a, b) => a + b);
    return total / _history.length;
  }

  int get streak {
    if (_history.isEmpty) return 7; // Default baseline streak
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

  void addSession({
    required double angle,
    required RiskLevel riskLevel,
    required String earSide,
    required int frameCount,
  }) {
    final session = PostureSessionResult(
      timestamp: DateTime.now(),
      angle: angle,
      riskLevel: riskLevel,
      earSide: earSide,
      frameCount: frameCount,
    );
    _history.insert(0, session); // Insert at the beginning (most recent first)
    notifyListeners();
  }
}
