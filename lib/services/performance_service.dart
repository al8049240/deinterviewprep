import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single completed quiz session record.
class QuizSession {
  final String id;
  final DateTime timestamp;
  final String topicId;
  final String topicName;
  final int totalQuestions;
  final int correctAnswers;
  final int durationSeconds;

  const QuizSession({
    required this.id,
    required this.timestamp,
    required this.topicId,
    required this.topicName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.durationSeconds,
  });

  double get accuracyPercent =>
      totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'topicId': topicId,
    'topicName': topicName,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'durationSeconds': durationSeconds,
  };

  factory QuizSession.fromJson(Map<String, dynamic> json) => QuizSession(
    id: json['id'] as String? ?? '',
    timestamp: DateTime.parse(json['timestamp'] as String),
    topicId: json['topicId'] as String? ?? '',
    topicName: json['topicName'] as String? ?? '',
    totalQuestions: json['totalQuestions'] as int? ?? 0,
    correctAnswers: json['correctAnswers'] as int? ?? 0,
    durationSeconds: json['durationSeconds'] as int? ?? 0,
  );
}

/// Analytics snapshot for a given time window.
class PerformanceSnapshot {
  final int windowDays;
  final int daysStudied;
  final int totalSessions;
  final double avgScore; // 0–100
  final List<DailyScorePoint> scoreTrend;
  final Map<String, double> accuracyByTopic;

  const PerformanceSnapshot({
    required this.windowDays,
    required this.daysStudied,
    required this.totalSessions,
    required this.avgScore,
    required this.scoreTrend,
    required this.accuracyByTopic,
  });
}

/// A single data point for the score trend chart.
class DailyScorePoint {
  final DateTime date;
  final double avgScore; // average accuracy% for that day

  const DailyScorePoint({required this.date, required this.avgScore});
}

/// Singleton service that persists every completed quiz session and
/// provides analytics calculations for the Performance Trends screen.
class PerformanceService extends ChangeNotifier {
  static const String _sessionsKey = 'quiz_sessions_v2';

  List<QuizSession> _sessions = [];

  List<QuizSession> get sessions => List.unmodifiable(_sessions);

  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadSessions(prefs);
    notifyListeners();
  }

  Future<void> _loadSessions(SharedPreferences prefs) async {
    final raw = prefs.getString(_sessionsKey);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _sessions = decoded
            .map((e) => QuizSession.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sort ascending by timestamp
        _sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      } catch (_) {
        _sessions = [];
      }
    }
  }

  Future<void> _saveSessions(SharedPreferences prefs) async {
    final encoded = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }

  // ── Save a completed session ──────────────────────────────────────────────

  Future<void> saveSession({
    required String topicId,
    required String topicName,
    required int totalQuestions,
    required int correctAnswers,
    required int durationSeconds,
  }) async {
    if (totalQuestions <= 0) return;
    final session = QuizSession(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      topicId: topicId,
      topicName: topicName,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      durationSeconds: durationSeconds,
    );
    _sessions.add(session);
    final prefs = await SharedPreferences.getInstance();
    await _saveSessions(prefs);
    notifyListeners();
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Returns a [PerformanceSnapshot] for the last [days] calendar days.
  PerformanceSnapshot getSnapshot(int days) {
    final now = DateTime.now();
    final windowStart = _startOfDay(now.subtract(Duration(days: days - 1)));

    final windowed = _sessions
        .where((s) => !s.timestamp.isBefore(windowStart))
        .toList();

    // Days studied: unique calendar days
    final uniqueDays = <String>{};
    for (final s in windowed) {
      uniqueDays.add(_dayKey(s.timestamp));
    }

    // Avg score
    double avgScore = 0;
    if (windowed.isNotEmpty) {
      final totalCorrect = windowed.fold<int>(
        0,
        (sum, s) => sum + s.correctAnswers,
      );
      final totalQ = windowed.fold<int>(0, (sum, s) => sum + s.totalQuestions);
      avgScore = totalQ == 0 ? 0 : (totalCorrect / totalQ) * 100;
    }

    // Score trend: one point per calendar day in the window
    final scoreTrend = _buildScoreTrend(days, windowed, now);

    // Accuracy by topic
    final accuracyByTopic = _buildAccuracyByTopic(windowed);

    return PerformanceSnapshot(
      windowDays: days,
      daysStudied: uniqueDays.length,
      totalSessions: windowed.length,
      avgScore: avgScore,
      scoreTrend: scoreTrend,
      accuracyByTopic: accuracyByTopic,
    );
  }

  List<DailyScorePoint> _buildScoreTrend(
    int days,
    List<QuizSession> windowed,
    DateTime now,
  ) {
    // Group sessions by day key
    final Map<String, List<QuizSession>> byDay = {};
    for (final s in windowed) {
      final key = _dayKey(s.timestamp);
      byDay.putIfAbsent(key, () => []).add(s);
    }

    final points = <DailyScorePoint>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = _startOfDay(now.subtract(Duration(days: i)));
      final key = _dayKey(day);
      final daySessions = byDay[key] ?? [];
      double avg = 0;
      if (daySessions.isNotEmpty) {
        final totalCorrect = daySessions.fold<int>(
          0,
          (s, e) => s + e.correctAnswers,
        );
        final totalQ = daySessions.fold<int>(0, (s, e) => s + e.totalQuestions);
        avg = totalQ == 0 ? 0 : (totalCorrect / totalQ) * 100;
      }
      points.add(DailyScorePoint(date: day, avgScore: avg));
    }
    return points;
  }

  Map<String, double> _buildAccuracyByTopic(List<QuizSession> windowed) {
    final Map<String, List<double>> grouped = {};
    for (final s in windowed) {
      if (s.totalQuestions > 0) {
        grouped.putIfAbsent(s.topicName, () => []).add(s.accuracyPercent);
      }
    }
    return grouped.map((topic, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(topic, avg);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
