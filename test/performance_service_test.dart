import 'dart:convert';

import 'package:deinterviewprep/services/performance_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'quiz_sessions_v2': '[]'});
    await PerformanceService().init();
  });

  test('QuizSession calculates accuracy and round-trips JSON', () {
    final timestamp = DateTime(2026, 9, 13, 10, 30);
    final session = QuizSession(
      id: 'session-1',
      timestamp: timestamp,
      topicId: 'sql',
      topicName: 'SQL',
      totalQuestions: 20,
      correctAnswers: 15,
      durationSeconds: 300,
    );

    final restored = QuizSession.fromJson(session.toJson());
    expect(session.accuracyPercent, 75);
    expect(restored.id, session.id);
    expect(restored.timestamp, timestamp);
    expect(restored.durationSeconds, 300);
  });

  test('zero-question session has zero accuracy', () {
    final session = QuizSession(
      id: 'empty',
      timestamp: DateTime.now(),
      topicId: 'sql',
      topicName: 'SQL',
      totalQuestions: 0,
      correctAnswers: 0,
      durationSeconds: 0,
    );

    expect(session.accuracyPercent, 0);
  });

  test('saveSession ignores invalid empty quizzes', () async {
    await PerformanceService().saveSession(
      topicId: 'sql',
      topicName: 'SQL',
      totalQuestions: 0,
      correctAnswers: 0,
      durationSeconds: 10,
    );

    expect(PerformanceService().sessions, isEmpty);
  });

  test('saveSession persists and snapshot aggregates sessions', () async {
    await PerformanceService().saveSession(
      topicId: 'sql',
      topicName: 'SQL',
      totalQuestions: 10,
      correctAnswers: 8,
      durationSeconds: 120,
    );
    await PerformanceService().saveSession(
      topicId: 'spark',
      topicName: 'Spark',
      totalQuestions: 10,
      correctAnswers: 6,
      durationSeconds: 180,
    );

    final snapshot = PerformanceService().getSnapshot(7);
    expect(snapshot.totalSessions, 2);
    expect(snapshot.daysStudied, 1);
    expect(snapshot.avgScore, 70);
    expect(snapshot.scoreTrend, hasLength(7));
    expect(snapshot.accuracyByTopic['SQL'], 80);
    expect(snapshot.accuracyByTopic['Spark'], 60);

    final prefs = await SharedPreferences.getInstance();
    final persisted = jsonDecode(prefs.getString('quiz_sessions_v2')!) as List;
    expect(persisted, hasLength(2));
  });

  test('init handles corrupt persisted session data safely', () async {
    SharedPreferences.setMockInitialValues({
      'quiz_sessions_v2': 'not valid json',
    });

    await PerformanceService().init();

    expect(PerformanceService().sessions, isEmpty);
  });
}
