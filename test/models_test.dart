import 'package:deinterviewprep/models/developer_experience_model.dart';
import 'package:deinterviewprep/models/flashcard_model.dart';
import 'package:deinterviewprep/models/statistics_models.dart';
import 'package:deinterviewprep/services/quiz_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeveloperExperienceModel', () {
    test('maps a complete database story', () {
      final story = DeveloperExperienceModel.fromDataDevStory({
        'id': 42,
        'title': 'Pipeline recovery',
        'category_tag': 'Failure Lesson',
        'situation': 'A pipeline failed.',
        'task_description': 'Restore service.',
        'action_taken': 'Replayed safely.',
        'result_achieved': 'Recovered.',
        'key_takeaway': 'Design idempotently.',
      });

      expect(story.id, '42');
      expect(story.title, 'Pipeline recovery');
      expect(story.categoryTag, 'Failure Lesson');
      expect(story.task, 'Restore service.');
      expect(story.keyTakeaway, 'Design idempotently.');
    });

    test('uses safe defaults for missing nullable values', () {
      final story = DeveloperExperienceModel.fromDataDevStory({});

      expect(story.id, isEmpty);
      expect(story.categoryTag, 'Behavioral');
      expect(story.title, isEmpty);
    });
  });

  group('FlashcardModel', () {
    test('maps Supabase data and stringifies tags', () {
      final card = FlashcardModel.fromSupabase({
        'flashcard_id': 7,
        'name': 'What is a DAG?',
        'explanation': 'A directed acyclic graph.',
        'tags': ['Airflow', 101],
      }, category: 'Orchestration');

      expect(card.id, '7');
      expect(card.front, 'What is a DAG?');
      expect(card.category, 'Orchestration');
      expect(card.tags, ['Airflow', '101']);
      expect(card.isMastered, isFalse);
    });

    test('uses empty values when optional fields are absent', () {
      final card = FlashcardModel.fromSupabase({}, category: 'Custom');

      expect(card.id, isEmpty);
      expect(card.front, isEmpty);
      expect(card.back, isEmpty);
      expect(card.tags, isEmpty);
    });
  });

  group('Statistics models', () {
    test('QuizAttempt maps values and calculates accuracy and XP', () {
      final attempt = QuizAttempt.fromJson({
        'id': 'attempt-1',
        'user_id': 'user-1',
        'topic_id': 'sql',
        'topic_name': 'SQL',
        'total_questions': 10,
        'correct_answers': 8,
        'duration_seconds': 120,
        'created_at': '2026-09-13T01:00:00Z',
      });

      expect(attempt.accuracy, 0.8);
      expect(attempt.xpEarned, 80);
      expect(attempt.toJson()['topic_name'], 'SQL');
    });

    test('zero-question attempts have zero accuracy', () {
      final attempt = QuizAttempt(
        id: 'empty',
        userId: 'user',
        topicId: 'sql',
        topicName: 'SQL',
        totalQuestions: 0,
        correctAnswers: 0,
        durationSeconds: 0,
        createdAt: DateTime(2026),
      );

      expect(attempt.accuracy, 0);
    });

    test('QuizUserAnswer round-trips database fields', () {
      final answer = QuizUserAnswer.fromJson({
        'id': 'answer-1',
        'attempt_id': 'attempt-1',
        'user_id': 'user-1',
        'question_id': 'question-1',
        'category': 'SQL',
        'difficulty': 'Senior',
        'selected_answer': 2,
        'correct_answer': 2,
        'is_correct': true,
        'created_at': '2026-09-13T01:00:00Z',
      });

      expect(answer.isCorrect, isTrue);
      expect(answer.createdAt, DateTime.utc(2026, 9, 13, 1));
      expect(answer.toJson()['selected_answer'], 2);
    });

    test('performance calculations handle boundaries', () {
      const weak = TopicPerformance(
        topicId: 'spark',
        topicName: 'Spark',
        totalAnswers: 10,
        correctAnswers: 6,
      );
      const passing = TopicPerformance(
        topicId: 'sql',
        topicName: 'SQL',
        totalAnswers: 10,
        correctAnswers: 7,
      );
      final daily = DailyActivity(
        date: DateTime(2026),
        questionsAnswered: 4,
        correctAnswers: 3,
        durationSeconds: 60,
      );

      expect(weak.isWeak, isTrue);
      expect(passing.isWeak, isFalse);
      expect(daily.accuracy, 0.75);
      expect(UserStatistics.empty().totalQuizzesCompleted, 0);
    });
  });

  group('Offline quiz serialization', () {
    test('preserves a complete quiz question', () {
      const original = QuizQuestionModel(
        id: 'sql-1',
        text: 'Which clause filters rows?',
        options: ['WHERE', 'GROUP BY', 'ORDER BY'],
        correctIndex: 0,
        correctIndices: [0],
        explanation: 'WHERE filters rows before grouping.',
        difficulty: 'junior',
        proTip: 'Filter early.',
        interviewTip: 'Explain logical query order.',
        hint: 'It appears before GROUP BY.',
        interviewNote: 'Common screening question.',
        category: 'SQL',
        type: 'mcq',
        subtag: 'filtering',
      );

      final restored = QuizQuestionModel.fromCacheMap(original.toCacheMap());

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.options, original.options);
      expect(restored.correctIndices, original.correctIndices);
      expect(restored.explanation, original.explanation);
      expect(restored.interviewNote, original.interviewNote);
      expect(restored.subtag, original.subtag);
    });
  });
}
