import 'package:deinterviewprep/providers/bookmark_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _flushPreferences() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('bookmark snapshots serialize and deserialize', () {
    const quiz = BookmarkedQuizQuestion(
      id: 'q1',
      text: 'Question?',
      topicId: 'sql',
      topicName: 'SQL',
      category: 'Database',
      difficulty: 'Mid',
    );
    const flashcard = BookmarkedFlashcard(
      id: 'f1',
      front: 'Front',
      back: 'Back',
      category: 'SQL',
    );
    const scenario = BookmarkedRealCaseScenario(
      id: 'r1',
      title: 'Incident',
      category: 'Reliability',
      problemStatement: 'Problem',
      solutionBreakdown: 'Solution',
      tags: ['Kafka', 'SRE'],
    );

    expect(BookmarkedQuizQuestion.fromJson(quiz.toJson()).text, 'Question?');
    expect(BookmarkedFlashcard.fromJson(flashcard.toJson()).back, 'Back');
    expect(BookmarkedRealCaseScenario.fromJson(scenario.toJson()).tags, [
      'Kafka',
      'SRE',
    ]);
  });

  test('all bookmark types toggle and contribute to the total', () async {
    final provider = BookmarkProvider();
    await _flushPreferences();

    expect(provider.toggleQuestion('question'), isTrue);
    expect(
      provider.toggleQuiz(
        'quiz',
        data: const BookmarkedQuizQuestion(
          id: 'quiz',
          text: 'Question',
          topicId: 'sql',
          topicName: 'SQL',
          category: 'SQL',
          difficulty: 'Junior',
        ),
      ),
      isTrue,
    );
    expect(
      provider.toggleFlashcardBookmark(
        'flashcard',
        data: const BookmarkedFlashcard(
          id: 'flashcard',
          front: 'Front',
          back: 'Back',
          category: 'SQL',
        ),
      ),
      isTrue,
    );
    expect(provider.togglePlaygroundBookmark('playground'), isTrue);
    expect(provider.toggleDevExperience('story'), isTrue);
    expect(
      provider.toggleRealCaseScenario(
        'scenario',
        data: const BookmarkedRealCaseScenario(
          id: 'scenario',
          title: 'Scenario',
          category: 'Cloud',
          problemStatement: 'Problem',
          solutionBreakdown: 'Solution',
          tags: [],
        ),
      ),
      isTrue,
    );

    expect(provider.totalBookmarkCount, 6);
    expect(provider.isBookmarked('story'), isTrue);

    provider.clearAll();
    expect(provider.totalBookmarksCount, 0);
  });

  test('bookmarks persist into a new provider instance', () async {
    final first = BookmarkProvider();
    await _flushPreferences();
    first.toggleQuestion('persisted-question');
    first.toggleDevExperience('persisted-story');
    await _flushPreferences();

    final second = BookmarkProvider();
    await _flushPreferences();

    expect(second.isQuestionBookmarked('persisted-question'), isTrue);
    expect(second.isDevExperienceBookmarked('persisted-story'), isTrue);
  });

  test('remove methods remove only their matching bookmark type', () async {
    final provider = BookmarkProvider();
    await _flushPreferences();
    provider.toggleQuestion('same');
    provider.togglePlaygroundBookmark('same');

    provider.removeQuestion('same');

    expect(provider.isQuestionBookmarked('same'), isFalse);
    expect(provider.isPlaygroundBookmarked('same'), isTrue);
  });
}
