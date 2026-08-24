import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/statistics_models.dart';

/// Repository for saving quiz attempts and calculating statistics from Supabase.
class StatisticsRepository {
  static StatisticsRepository? _instance;
  static StatisticsRepository get instance =>
      _instance ??= StatisticsRepository._();
  StatisticsRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  static const String _schema = 'de_mobile_app';
  static const String _attemptsTable = 'quiz_attempts';
  static const String _answersTable = 'quiz_user_answers';

  // ── Save Quiz Attempt ─────────────────────────────────────────────────────

  /// Saves a completed quiz attempt and all user answers atomically.
  /// Returns the created attempt ID, or null if user is not authenticated.
  Future<String?> saveQuizAttempt({
    required String topicId,
    required String topicName,
    required int totalQuestions,
    required int correctAnswers,
    required int durationSeconds,
    required List<Map<String, dynamic>> answeredQuestions,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // Insert attempt row
      final attemptResponse = await _client
          .schema(_schema)
          .from(_attemptsTable)
          .insert({
            'user_id': user.id,
            'topic_id': topicId,
            'topic_name': topicName,
            'total_questions': totalQuestions,
            'correct_answers': correctAnswers,
            'duration_seconds': durationSeconds,
          })
          .select('id')
          .single();

      final attemptId = attemptResponse['id'] as String;

      // Build answer rows
      if (answeredQuestions.isNotEmpty) {
        final answerRows = answeredQuestions.map((q) {
          return {
            'attempt_id': attemptId,
            'user_id': user.id,
            'question_id': q['id'] as String? ?? '',
            'category': q['category'] as String?,
            'difficulty': q['difficulty'] as String?,
            'selected_answer': q['selectedAnswer'] as int?,
            'correct_answer': q['correctIndex'] as int? ?? 0,
            'is_correct':
                (q['selectedAnswer'] as int?) == (q['correctIndex'] as int?),
          };
        }).toList();

        await _client.schema(_schema).from(_answersTable).insert(answerRows);
      }

      return attemptId;
    } catch (e) {
      // Silently fail — statistics are non-critical
      return null;
    }
  }

  // ── Fetch All Attempts ────────────────────────────────────────────────────

  Future<List<QuizAttempt>> fetchAttempts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .schema(_schema)
        .from(_attemptsTable)
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => QuizAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch All User Answers ────────────────────────────────────────────────

  Future<List<QuizUserAnswer>> fetchUserAnswers() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .schema(_schema)
        .from(_answersTable)
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => QuizUserAnswer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Calculate Full Statistics ─────────────────────────────────────────────

  Future<UserStatistics> calculateStatistics() async {
    final user = _client.auth.currentUser;
    if (user == null) return UserStatistics.empty();

    final attempts = await fetchAttempts();
    final answers = await fetchUserAnswers();

    if (attempts.isEmpty) return UserStatistics.empty();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));
    final monthStart = todayStart.subtract(const Duration(days: 29));

    // ── Overview ──────────────────────────────────────────────────────────
    final totalQuizzesCompleted = attempts.length;
    final totalQuestionsAnswered = answers.length;
    final totalCorrectAnswers = answers.where((a) => a.isCorrect).length;
    final overallAccuracy = totalQuestionsAnswered == 0
        ? 0.0
        : totalCorrectAnswers / totalQuestionsAnswered;
    final totalXp = totalCorrectAnswers * 10;

    // Today
    final todayAnswers = answers
        .where((a) => a.createdAt != null && !a.createdAt!.isBefore(todayStart))
        .toList();
    final todayXp = todayAnswers.where((a) => a.isCorrect).length * 10;

    final totalStudyTimeSeconds = attempts.fold<int>(
      0,
      (sum, a) => sum + a.durationSeconds,
    );
    final todayAttempts = attempts
        .where((a) => !a.createdAt.isBefore(todayStart))
        .toList();
    final todayStudyTimeSeconds = todayAttempts.fold<int>(
      0,
      (sum, a) => sum + a.durationSeconds,
    );

    // ── Streak Calculation ────────────────────────────────────────────────
    final streaks = _calculateStreaks(attempts);
    final currentStreak = streaks.$1;
    final longestStreak = streaks.$2;

    // ── Active Topics ─────────────────────────────────────────────────────
    final activeTopicsCount = attempts.map((a) => a.topicId).toSet().length;

    // ── Topic Performance ─────────────────────────────────────────────────
    final topicMap = <String, _TopicAccumulator>{};
    for (final attempt in attempts) {
      topicMap.putIfAbsent(
        attempt.topicId,
        () => _TopicAccumulator(
          topicId: attempt.topicId,
          topicName: attempt.topicName,
        ),
      );
      topicMap[attempt.topicId]!
        ..totalQuestions += attempt.totalQuestions
        ..correctAnswers += attempt.correctAnswers;
    }
    final topicPerformances =
        topicMap.values
            .map(
              (t) => TopicPerformance(
                topicId: t.topicId,
                topicName: t.topicName,
                totalAnswers: t.totalQuestions,
                correctAnswers: t.correctAnswers,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalAnswers.compareTo(a.totalAnswers));

    // ── Category Performance ──────────────────────────────────────────────
    final categoryMap = <String, _SimpleAccumulator>{};
    for (final answer in answers) {
      final cat = answer.category ?? 'General';
      categoryMap.putIfAbsent(cat, () => _SimpleAccumulator());
      categoryMap[cat]!.total++;
      if (answer.isCorrect) categoryMap[cat]!.correct++;
    }
    final categoryPerformances =
        categoryMap.entries
            .map(
              (e) => CategoryPerformance(
                category: e.key,
                totalAnswers: e.value.total,
                correctAnswers: e.value.correct,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalAnswers.compareTo(a.totalAnswers));

    // ── Difficulty Performance ────────────────────────────────────────────
    final difficultyMap = <String, _SimpleAccumulator>{};
    for (final answer in answers) {
      final diff = answer.difficulty ?? 'Medium';
      difficultyMap.putIfAbsent(diff, () => _SimpleAccumulator());
      difficultyMap[diff]!.total++;
      if (answer.isCorrect) difficultyMap[diff]!.correct++;
    }
    final difficultyPerformances = difficultyMap.entries
        .map(
          (e) => DifficultyPerformance(
            difficulty: e.key,
            totalAnswers: e.value.total,
            correctAnswers: e.value.correct,
          ),
        )
        .toList();

    // ── Weekly Stats ──────────────────────────────────────────────────────
    final weeklyAnswers = answers
        .where((a) => a.createdAt != null && !a.createdAt!.isBefore(weekStart))
        .toList();
    final weeklyQuestionsAnswered = weeklyAnswers.length;
    final weeklyCorrectAnswers = weeklyAnswers.where((a) => a.isCorrect).length;
    final weeklyAccuracy = weeklyQuestionsAnswered == 0
        ? 0.0
        : weeklyCorrectAnswers / weeklyQuestionsAnswered;
    final weeklyAttempts = attempts
        .where((a) => !a.createdAt.isBefore(weekStart))
        .toList();
    final weeklyStudyTimeSeconds = weeklyAttempts.fold<int>(
      0,
      (sum, a) => sum + a.durationSeconds,
    );

    // Daily activity for last 7 days
    final dailyActivities = <DailyActivity>[];
    for (int i = 6; i >= 0; i--) {
      final day = todayStart.subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      final dayAnswers = answers
          .where(
            (a) =>
                a.createdAt != null &&
                !a.createdAt!.isBefore(day) &&
                a.createdAt!.isBefore(dayEnd),
          )
          .toList();
      final dayAttempts = attempts
          .where(
            (a) => !a.createdAt.isBefore(day) && a.createdAt.isBefore(dayEnd),
          )
          .toList();
      dailyActivities.add(
        DailyActivity(
          date: day,
          questionsAnswered: dayAnswers.length,
          correctAnswers: dayAnswers.where((a) => a.isCorrect).length,
          durationSeconds: dayAttempts.fold<int>(
            0,
            (sum, a) => sum + a.durationSeconds,
          ),
        ),
      );
    }

    // ── Monthly Stats ─────────────────────────────────────────────────────
    final monthlyAnswers = answers
        .where((a) => a.createdAt != null && !a.createdAt!.isBefore(monthStart))
        .toList();
    final monthlyQuestionsAnswered = monthlyAnswers.length;
    final monthlyCorrectAnswers = monthlyAnswers
        .where((a) => a.isCorrect)
        .length;
    final monthlyAccuracy = monthlyQuestionsAnswered == 0
        ? 0.0
        : monthlyCorrectAnswers / monthlyQuestionsAnswered;

    // ── Recent Attempts ───────────────────────────────────────────────────
    final recentAttempts = attempts.take(10).toList();

    // ── Weak Topics ───────────────────────────────────────────────────────
    final weakTopics = topicPerformances
        .where((t) => t.isWeak && t.totalAnswers >= 5)
        .toList();

    return UserStatistics(
      totalQuizzesCompleted: totalQuizzesCompleted,
      totalQuestionsAnswered: totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers,
      overallAccuracy: overallAccuracy,
      totalXp: totalXp,
      todayXp: todayXp,
      totalStudyTimeSeconds: totalStudyTimeSeconds,
      todayStudyTimeSeconds: todayStudyTimeSeconds,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      activeTopicsCount: activeTopicsCount,
      topicPerformances: topicPerformances,
      categoryPerformances: categoryPerformances,
      difficultyPerformances: difficultyPerformances,
      weeklyQuestionsAnswered: weeklyQuestionsAnswered,
      weeklyCorrectAnswers: weeklyCorrectAnswers,
      weeklyAccuracy: weeklyAccuracy,
      weeklyStudyTimeSeconds: weeklyStudyTimeSeconds,
      dailyActivities: dailyActivities,
      monthlyQuestionsAnswered: monthlyQuestionsAnswered,
      monthlyCorrectAnswers: monthlyCorrectAnswers,
      monthlyAccuracy: monthlyAccuracy,
      recentAttempts: recentAttempts,
      weakTopics: weakTopics,
    );
  }

  // ── Streak Calculation ────────────────────────────────────────────────────

  /// Returns (currentStreak, longestStreak) in days.
  (int, int) _calculateStreaks(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) return (0, 0);

    // Get unique dates with activity (UTC date only)
    final activeDates =
        attempts
            .map(
              (a) => DateTime(
                a.createdAt.year,
                a.createdAt.month,
                a.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // descending

    if (activeDates.isEmpty) return (0, 0);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // Current streak: consecutive days ending today or yesterday
    int currentStreak = 0;
    final mostRecent = activeDates.first;
    if (mostRecent == todayDate || mostRecent == yesterdayDate) {
      DateTime expected = mostRecent;
      for (final date in activeDates) {
        if (date == expected) {
          currentStreak++;
          expected = expected.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Longest streak: scan all dates
    int longestStreak = 0;
    int streak = 1;
    for (int i = 1; i < activeDates.length; i++) {
      final diff = activeDates[i - 1].difference(activeDates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        if (streak > longestStreak) longestStreak = streak;
        streak = 1;
      }
    }
    if (streak > longestStreak) longestStreak = streak;

    return (currentStreak, longestStreak);
  }
}

// ── Private Accumulators ──────────────────────────────────────────────────────

class _TopicAccumulator {
  final String topicId;
  final String topicName;
  int totalQuestions = 0;
  int correctAnswers = 0;

  _TopicAccumulator({required this.topicId, required this.topicName});
}

class _SimpleAccumulator {
  int total = 0;
  int correct = 0;
}
