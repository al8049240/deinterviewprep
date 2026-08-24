/// Typed Dart models for quiz statistics system.
library;

// ── QuizAttempt ───────────────────────────────────────────────────────────────

class QuizAttempt {
  final String id;
  final String userId;
  final String topicId;
  final String topicName;
  final int totalQuestions;
  final int correctAnswers;
  final int durationSeconds;
  final DateTime createdAt;

  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.topicName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.durationSeconds,
    required this.createdAt,
  });

  double get accuracy =>
      totalQuestions == 0 ? 0.0 : correctAnswers / totalQuestions;

  int get xpEarned => correctAnswers * 10;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      topicId: json['topic_id'] as String,
      topicName: json['topic_name'] as String,
      totalQuestions: json['total_questions'] as int,
      correctAnswers: json['correct_answers'] as int,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'topic_id': topicId,
    'topic_name': topicName,
    'total_questions': totalQuestions,
    'correct_answers': correctAnswers,
    'duration_seconds': durationSeconds,
  };
}

// ── QuizUserAnswer ────────────────────────────────────────────────────────────

class QuizUserAnswer {
  final String? id;
  final String attemptId;
  final String userId;
  final String questionId;
  final String? category;
  final String? difficulty;
  final int? selectedAnswer;
  final int correctAnswer;
  final bool isCorrect;
  final DateTime? createdAt;

  const QuizUserAnswer({
    this.id,
    required this.attemptId,
    required this.userId,
    required this.questionId,
    this.category,
    this.difficulty,
    this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.createdAt,
  });

  factory QuizUserAnswer.fromJson(Map<String, dynamic> json) {
    return QuizUserAnswer(
      id: json['id'] as String?,
      attemptId: json['attempt_id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      selectedAnswer: json['selected_answer'] as int?,
      correctAnswer: json['correct_answer'] as int,
      isCorrect: json['is_correct'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'attempt_id': attemptId,
    'user_id': userId,
    'question_id': questionId,
    'category': category,
    'difficulty': difficulty,
    'selected_answer': selectedAnswer,
    'correct_answer': correctAnswer,
    'is_correct': isCorrect,
  };
}

// ── TopicPerformance ──────────────────────────────────────────────────────────

class TopicPerformance {
  final String topicId;
  final String topicName;
  final int totalAnswers;
  final int correctAnswers;

  const TopicPerformance({
    required this.topicId,
    required this.topicName,
    required this.totalAnswers,
    required this.correctAnswers,
  });

  double get accuracy =>
      totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;

  bool get isWeak => accuracy < 0.70;
}

// ── CategoryPerformance ───────────────────────────────────────────────────────

class CategoryPerformance {
  final String category;
  final int totalAnswers;
  final int correctAnswers;

  const CategoryPerformance({
    required this.category,
    required this.totalAnswers,
    required this.correctAnswers,
  });

  double get accuracy =>
      totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;
}

// ── DifficultyPerformance ─────────────────────────────────────────────────────

class DifficultyPerformance {
  final String difficulty;
  final int totalAnswers;
  final int correctAnswers;

  const DifficultyPerformance({
    required this.difficulty,
    required this.totalAnswers,
    required this.correctAnswers,
  });

  double get accuracy =>
      totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;
}

// ── DailyActivity ─────────────────────────────────────────────────────────────

class DailyActivity {
  final DateTime date;
  final int questionsAnswered;
  final int correctAnswers;
  final int durationSeconds;

  const DailyActivity({
    required this.date,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.durationSeconds,
  });

  double get accuracy =>
      questionsAnswered == 0 ? 0.0 : correctAnswers / questionsAnswered;
}

// ── UserStatistics ────────────────────────────────────────────────────────────

class UserStatistics {
  // Overview
  final int totalQuizzesCompleted;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final double overallAccuracy;
  final int totalXp;
  final int todayXp;
  final int totalStudyTimeSeconds;
  final int todayStudyTimeSeconds;
  final int currentStreak;
  final int longestStreak;
  final int activeTopicsCount;

  // Breakdowns
  final List<TopicPerformance> topicPerformances;
  final List<CategoryPerformance> categoryPerformances;
  final List<DifficultyPerformance> difficultyPerformances;

  // Weekly (last 7 days)
  final int weeklyQuestionsAnswered;
  final int weeklyCorrectAnswers;
  final double weeklyAccuracy;
  final int weeklyStudyTimeSeconds;
  final List<DailyActivity> dailyActivities;

  // Monthly (last 30 days)
  final int monthlyQuestionsAnswered;
  final int monthlyCorrectAnswers;
  final double monthlyAccuracy;

  // Recent attempts
  final List<QuizAttempt> recentAttempts;

  // Weak topics
  final List<TopicPerformance> weakTopics;

  const UserStatistics({
    required this.totalQuizzesCompleted,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.overallAccuracy,
    required this.totalXp,
    required this.todayXp,
    required this.totalStudyTimeSeconds,
    required this.todayStudyTimeSeconds,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeTopicsCount,
    required this.topicPerformances,
    required this.categoryPerformances,
    required this.difficultyPerformances,
    required this.weeklyQuestionsAnswered,
    required this.weeklyCorrectAnswers,
    required this.weeklyAccuracy,
    required this.weeklyStudyTimeSeconds,
    required this.dailyActivities,
    required this.monthlyQuestionsAnswered,
    required this.monthlyCorrectAnswers,
    required this.monthlyAccuracy,
    required this.recentAttempts,
    required this.weakTopics,
  });

  static UserStatistics empty() => const UserStatistics(
    totalQuizzesCompleted: 0,
    totalQuestionsAnswered: 0,
    totalCorrectAnswers: 0,
    overallAccuracy: 0.0,
    totalXp: 0,
    todayXp: 0,
    totalStudyTimeSeconds: 0,
    todayStudyTimeSeconds: 0,
    currentStreak: 0,
    longestStreak: 0,
    activeTopicsCount: 0,
    topicPerformances: [],
    categoryPerformances: [],
    difficultyPerformances: [],
    weeklyQuestionsAnswered: 0,
    weeklyCorrectAnswers: 0,
    weeklyAccuracy: 0.0,
    weeklyStudyTimeSeconds: 0,
    dailyActivities: [],
    monthlyQuestionsAnswered: 0,
    monthlyCorrectAnswers: 0,
    monthlyAccuracy: 0.0,
    recentAttempts: [],
    weakTopics: [],
  );
}
