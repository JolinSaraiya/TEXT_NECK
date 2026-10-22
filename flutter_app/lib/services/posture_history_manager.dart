import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    DateTime ts;
    final rawTs = data['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      ts = DateTime.now();
    }

    return PostureSessionResult(
      timestamp: ts,
      angle: (data['angle'] as num?)?.toDouble() ?? 0.0,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == data['riskLevel'], 
        orElse: () => RiskLevel.warning,
      ),
      earSide: (data['earSide'] as String?) ?? 'unknown',
      frameCount: (data['frameCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Factory to create from Local JSON Map
  factory PostureSessionResult.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    final rawTs = json['timestamp'];
    if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      ts = DateTime.now();
    }

    return PostureSessionResult(
      timestamp: ts,
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => RiskLevel.warning,
      ),
      earSide: (json['earSide'] as String?) ?? 'unknown',
      frameCount: (json['frameCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Convert to JSON Map for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'angle': angle,
      'riskLevel': riskLevel.name,
      'earSide': earSide,
      'frameCount': frameCount,
    };
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
  String? _activeUid;

  PostureHistoryManager._internal() {
    // 1. Immediately check current user upon singleton initialization
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _activeUid = currentUser.uid;
      _loadLocalHistory(currentUser.uid);
      _subscribeToSessions(currentUser.uid);
    } else {
      _loadLocalHistory(null);
    }

    // 2. Listen to idTokenChanges to ensure auth token state changes are fully handled
    _authSub = FirebaseAuth.instance.idTokenChanges().listen((user) {
      if (user != null) {
        _activeUid = user.uid;
        _loadLocalHistory(user.uid);
        _subscribeToSessions(user.uid);
      } else {
        _activeUid = null;
        _sessionSub?.cancel();
        _sessionSub = null;
        _history.clear();
        notifyListeners();
      }
    });
  }

  /// Load session history from persistent SharedPreferences storage.
  Future<void> _loadLocalHistory(String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = uid != null ? 'posture_sessions_$uid' : 'posture_sessions_last_active';
      List<String>? jsonList = prefs.getStringList(key);

      // Fallback to active backup if specific user key is empty
      if ((jsonList == null || jsonList.isEmpty) && uid != null) {
        jsonList = prefs.getStringList('posture_sessions_last_active');
      }

      if (jsonList != null && jsonList.isNotEmpty) {
        final loaded = <PostureSessionResult>[];
        for (final item in jsonList) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            loaded.add(PostureSessionResult.fromJson(map));
          } catch (e) {
            debugPrint('Error parsing session from local storage: $e');
          }
        }
        if (loaded.isNotEmpty) {
          _history = loaded;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading local history: $e');
    }
  }

  /// Persist session history to persistent SharedPreferences storage.
  Future<void> _saveLocalHistory(String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _history.map((s) => jsonEncode(s.toJson())).toList();
      if (uid != null) {
        await prefs.setStringList('posture_sessions_$uid', jsonList);
      }
      await prefs.setStringList('posture_sessions_last_active', jsonList);
    } catch (e) {
      debugPrint('Error saving local history: $e');
    }
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
      final firestoreList = snapshot.docs.map((doc) {
        return PostureSessionResult.fromMap(doc.data());
      }).toList();

      // Merge Firestore documents with local sessions so no scan is ever lost
      final Map<String, PostureSessionResult> merged = {};
      for (final s in firestoreList) {
        final key = '${s.timestamp.millisecondsSinceEpoch}_${s.angle.toStringAsFixed(1)}';
        merged[key] = s;
      }
      for (final s in _history) {
        final key = '${s.timestamp.millisecondsSinceEpoch}_${s.angle.toStringAsFixed(1)}';
        merged.putIfAbsent(key, () => s);
      }

      final resultList = merged.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _history = resultList;
      _saveLocalHistory(uid);
      notifyListeners();
    }, onError: (error) {
      debugPrint("Firestore fetch error: $error");
      // If Firestore has network or permission delay, local storage remains safe and displayed.
      Future.delayed(const Duration(seconds: 2), () {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == uid && _sessionSub != null) {
          _subscribeToSessions(uid);
        }
      });
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
    final uid = user?.uid ?? _activeUid;

    final session = PostureSessionResult(
      timestamp: DateTime.now(),
      angle: angle,
      riskLevel: riskLevel,
      earSide: earSide,
      frameCount: frameCount,
    );

    // 1. Immediately insert into in-memory history (real-time instant UI update!)
    _history.insert(0, session);
    notifyListeners();

    // 2. Persist locally to SharedPreferences immediately
    await _saveLocalHistory(uid);

    // 3. Sync to Firestore in the background
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .add(session.toMap());
      } catch (e) {
        debugPrint("Warning: Firestore sync error, safely kept in local storage: $e");
      }
    }
  }

  Future<void> clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? _activeUid;

    _history.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (uid != null) {
        await prefs.remove('posture_sessions_$uid');
      }
      await prefs.remove('posture_sessions_last_active');
    } catch (e) {
      debugPrint('Error clearing local history: $e');
    }

    if (user != null) {
      try {
        final snapshots = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .get();
        for (final doc in snapshots.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Error clearing Firestore history: $e');
      }
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}


