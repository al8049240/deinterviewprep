import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bookmark type enum to distinguish between saved Interview Questions and Quiz Questions.
enum BookmarkType { question, quiz }

/// Global bookmark state — holds separate sets for interview questions, quiz questions,
/// flashcards, code playground items, and developer experiences.
/// Persists to SharedPreferences so bookmarks survive app restarts.
class BookmarkProvider extends ChangeNotifier {
  static const String _questionKey = 'bookmarked_question_ids';
  static const String _quizKey = 'bookmarked_quiz_ids';
  static const String _flashcardKey = 'saved_flashcard_ids';
  static const String _playgroundKey = 'saved_playground_ids';
  static const String _devExperienceKey = 'saved_dev_experience_ids';

  final Set<String> _bookmarkedQuestionIds = {};
  final Set<String> _bookmarkedQuizIds = {};
  final Set<String> _bookmarkedFlashcardIds = {};
  final Set<String> _bookmarkedPlaygroundIds = {};
  final Set<String> _bookmarkedDevExperienceIds = {};

  BookmarkProvider() {
    _loadFromPrefs();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionIds = prefs.getStringList(_questionKey) ?? [];
      final quizIds = prefs.getStringList(_quizKey) ?? [];
      final flashcardIds = prefs.getStringList(_flashcardKey) ?? [];
      final playgroundIds = prefs.getStringList(_playgroundKey) ?? [];
      final devExpIds = prefs.getStringList(_devExperienceKey) ?? [];
      _bookmarkedQuestionIds.addAll(questionIds);
      _bookmarkedQuizIds.addAll(quizIds);
      _bookmarkedFlashcardIds.addAll(flashcardIds);
      _bookmarkedPlaygroundIds.addAll(playgroundIds);
      _bookmarkedDevExperienceIds.addAll(devExpIds);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_questionKey, _bookmarkedQuestionIds.toList());
      await prefs.setStringList(_quizKey, _bookmarkedQuizIds.toList());
      await prefs.setStringList(
        _flashcardKey,
        _bookmarkedFlashcardIds.toList(),
      );
      await prefs.setStringList(
        _playgroundKey,
        _bookmarkedPlaygroundIds.toList(),
      );
      await prefs.setStringList(
        _devExperienceKey,
        _bookmarkedDevExperienceIds.toList(),
      );
    } catch (_) {}
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  Set<String> get bookmarkedQuestionIds =>
      Set.unmodifiable(_bookmarkedQuestionIds);
  Set<String> get bookmarkedQuizIds => Set.unmodifiable(_bookmarkedQuizIds);
  Set<String> get bookmarkedFlashcardIds =>
      Set.unmodifiable(_bookmarkedFlashcardIds);
  Set<String> get bookmarkedPlaygroundIds =>
      Set.unmodifiable(_bookmarkedPlaygroundIds);
  Set<String> get bookmarkedDevExperienceIds =>
      Set.unmodifiable(_bookmarkedDevExperienceIds);

  int get totalBookmarkCount =>
      _bookmarkedQuestionIds.length +
      _bookmarkedQuizIds.length +
      _bookmarkedFlashcardIds.length +
      _bookmarkedPlaygroundIds.length +
      _bookmarkedDevExperienceIds.length;

  int get totalBookmarksCount => totalBookmarkCount;

  bool isQuestionBookmarked(String id) => _bookmarkedQuestionIds.contains(id);
  bool isQuizBookmarked(String id) => _bookmarkedQuizIds.contains(id);
  bool isFlashcardBookmarked(String id) => _bookmarkedFlashcardIds.contains(id);
  bool isPlaygroundBookmarked(String id) =>
      _bookmarkedPlaygroundIds.contains(id);
  bool isDevExperienceBookmarked(String id) =>
      _bookmarkedDevExperienceIds.contains(id);

  bool isBookmarked(String id) =>
      _bookmarkedQuestionIds.contains(id) ||
      _bookmarkedQuizIds.contains(id) ||
      _bookmarkedFlashcardIds.contains(id) ||
      _bookmarkedPlaygroundIds.contains(id) ||
      _bookmarkedDevExperienceIds.contains(id);

  // ── Mutators ──────────────────────────────────────────────────────────────

  bool toggleQuestion(String id) {
    if (_bookmarkedQuestionIds.contains(id)) {
      _bookmarkedQuestionIds.remove(id);
    } else {
      _bookmarkedQuestionIds.add(id);
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedQuestionIds.contains(id);
  }

  bool toggleQuiz(String id) {
    if (_bookmarkedQuizIds.contains(id)) {
      _bookmarkedQuizIds.remove(id);
    } else {
      _bookmarkedQuizIds.add(id);
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedQuizIds.contains(id);
  }

  bool toggleFlashcardBookmark(String id) {
    if (_bookmarkedFlashcardIds.contains(id)) {
      _bookmarkedFlashcardIds.remove(id);
    } else {
      _bookmarkedFlashcardIds.add(id);
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedFlashcardIds.contains(id);
  }

  bool togglePlaygroundBookmark(String id) {
    if (_bookmarkedPlaygroundIds.contains(id)) {
      _bookmarkedPlaygroundIds.remove(id);
    } else {
      _bookmarkedPlaygroundIds.add(id);
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedPlaygroundIds.contains(id);
  }

  bool toggleDevExperience(String id) {
    if (_bookmarkedDevExperienceIds.contains(id)) {
      _bookmarkedDevExperienceIds.remove(id);
    } else {
      _bookmarkedDevExperienceIds.add(id);
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedDevExperienceIds.contains(id);
  }

  bool toggle(String id) => toggleQuestion(id);

  void removeQuestion(String id) {
    if (_bookmarkedQuestionIds.remove(id)) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void removeQuiz(String id) {
    if (_bookmarkedQuizIds.remove(id)) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void removeFlashcard(String id) {
    if (_bookmarkedFlashcardIds.remove(id)) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void removePlayground(String id) {
    if (_bookmarkedPlaygroundIds.remove(id)) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void removeDevExperience(String id) {
    if (_bookmarkedDevExperienceIds.remove(id)) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void clearAll() {
    _bookmarkedQuestionIds.clear();
    _bookmarkedQuizIds.clear();
    _bookmarkedFlashcardIds.clear();
    _bookmarkedPlaygroundIds.clear();
    _bookmarkedDevExperienceIds.clear();
    notifyListeners();
    _saveToPrefs();
  }

  void remove(String id) => removeQuestion(id);
}
