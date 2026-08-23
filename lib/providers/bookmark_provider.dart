import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bookmark type enum to distinguish between saved Interview Questions and Quiz Questions.
enum BookmarkType { question, quiz }

// ── Saved item data models ────────────────────────────────────────────────────

/// Lightweight snapshot of a quiz question stored with the bookmark.
class BookmarkedQuizQuestion {
  final String id;
  final String text;
  final String topicId;
  final String topicName;
  final String category;
  final String difficulty;

  const BookmarkedQuizQuestion({
    required this.id,
    required this.text,
    required this.topicId,
    required this.topicName,
    required this.category,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'topicId': topicId,
    'topicName': topicName,
    'category': category,
    'difficulty': difficulty,
  };

  factory BookmarkedQuizQuestion.fromJson(Map<String, dynamic> j) =>
      BookmarkedQuizQuestion(
        id: j['id'] as String? ?? '',
        text: j['text'] as String? ?? '',
        topicId: j['topicId'] as String? ?? '',
        topicName: j['topicName'] as String? ?? '',
        category: j['category'] as String? ?? '',
        difficulty: j['difficulty'] as String? ?? '',
      );
}

/// Lightweight snapshot of a flashcard stored with the bookmark.
class BookmarkedFlashcard {
  final String id;
  final String front;
  final String back;
  final String category;

  const BookmarkedFlashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'front': front,
    'back': back,
    'category': category,
  };

  factory BookmarkedFlashcard.fromJson(Map<String, dynamic> j) =>
      BookmarkedFlashcard(
        id: j['id'] as String? ?? '',
        front: j['front'] as String? ?? '',
        back: j['back'] as String? ?? '',
        category: j['category'] as String? ?? '',
      );
}

/// Lightweight snapshot of a real case scenario stored with the bookmark.
class BookmarkedRealCaseScenario {
  final String id;
  final String title;
  final String category;
  final String problemStatement;
  final String solutionBreakdown;
  final List<String> tags;

  const BookmarkedRealCaseScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.problemStatement,
    required this.solutionBreakdown,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'problemStatement': problemStatement,
    'solutionBreakdown': solutionBreakdown,
    'tags': tags,
  };

  factory BookmarkedRealCaseScenario.fromJson(Map<String, dynamic> j) =>
      BookmarkedRealCaseScenario(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        category: j['category'] as String? ?? '',
        problemStatement: j['problemStatement'] as String? ?? '',
        solutionBreakdown: j['solutionBreakdown'] as String? ?? '',
        tags:
            (j['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
            [],
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Global bookmark state — holds separate sets for interview questions, quiz questions,
/// flashcards, code playground items, developer experiences, and real case scenarios.
/// Persists to SharedPreferences so bookmarks survive app restarts.
class BookmarkProvider extends ChangeNotifier {
  static const String _questionKey = 'bookmarked_question_ids';
  static const String _quizDataKey = 'bookmarked_quiz_data'; // JSON map
  static const String _flashcardDataKey =
      'bookmarked_flashcard_data'; // JSON map
  static const String _playgroundKey = 'saved_playground_ids';
  static const String _devExperienceKey = 'saved_dev_experience_ids';
  static const String _realCaseDataKey =
      'bookmarked_real_case_data'; // JSON map

  final Set<String> _bookmarkedQuestionIds = {};
  // Quiz questions: id → BookmarkedQuizQuestion
  final Map<String, BookmarkedQuizQuestion> _bookmarkedQuizQuestions = {};
  // Flashcards: id → BookmarkedFlashcard
  final Map<String, BookmarkedFlashcard> _bookmarkedFlashcards = {};
  final Set<String> _bookmarkedPlaygroundIds = {};
  final Set<String> _bookmarkedDevExperienceIds = {};
  // Real case scenarios: id → BookmarkedRealCaseScenario
  final Map<String, BookmarkedRealCaseScenario> _bookmarkedRealCaseScenarios =
      {};

  BookmarkProvider() {
    _loadFromPrefs();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Question IDs (legacy)
      final questionIds = prefs.getStringList(_questionKey) ?? [];
      _bookmarkedQuestionIds.addAll(questionIds);

      // Quiz questions (JSON map)
      final quizJson = prefs.getString(_quizDataKey);
      if (quizJson != null) {
        final Map<String, dynamic> decoded =
            jsonDecode(quizJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _bookmarkedQuizQuestions[entry.key] = BookmarkedQuizQuestion.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }

      // Flashcards (JSON map)
      final flashcardJson = prefs.getString(_flashcardDataKey);
      if (flashcardJson != null) {
        final Map<String, dynamic> decoded =
            jsonDecode(flashcardJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _bookmarkedFlashcards[entry.key] = BookmarkedFlashcard.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }

      // Playground IDs
      final playgroundIds = prefs.getStringList(_playgroundKey) ?? [];
      _bookmarkedPlaygroundIds.addAll(playgroundIds);

      // Dev experience IDs
      final devExpIds = prefs.getStringList(_devExperienceKey) ?? [];
      _bookmarkedDevExperienceIds.addAll(devExpIds);

      // Real case scenarios (JSON map)
      final realCaseJson = prefs.getString(_realCaseDataKey);
      if (realCaseJson != null) {
        final Map<String, dynamic> decoded =
            jsonDecode(realCaseJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _bookmarkedRealCaseScenarios[entry.key] =
              BookmarkedRealCaseScenario.fromJson(
                entry.value as Map<String, dynamic>,
              );
        }
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(_questionKey, _bookmarkedQuestionIds.toList());

      final quizMap = <String, dynamic>{};
      for (final e in _bookmarkedQuizQuestions.entries) {
        quizMap[e.key] = e.value.toJson();
      }
      await prefs.setString(_quizDataKey, jsonEncode(quizMap));

      final flashcardMap = <String, dynamic>{};
      for (final e in _bookmarkedFlashcards.entries) {
        flashcardMap[e.key] = e.value.toJson();
      }
      await prefs.setString(_flashcardDataKey, jsonEncode(flashcardMap));

      await prefs.setStringList(
        _playgroundKey,
        _bookmarkedPlaygroundIds.toList(),
      );
      await prefs.setStringList(
        _devExperienceKey,
        _bookmarkedDevExperienceIds.toList(),
      );

      final realCaseMap = <String, dynamic>{};
      for (final e in _bookmarkedRealCaseScenarios.entries) {
        realCaseMap[e.key] = e.value.toJson();
      }
      await prefs.setString(_realCaseDataKey, jsonEncode(realCaseMap));
    } catch (_) {}
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  Set<String> get bookmarkedQuestionIds =>
      Set.unmodifiable(_bookmarkedQuestionIds);

  /// All bookmarked quiz question IDs
  Set<String> get bookmarkedQuizIds =>
      Set.unmodifiable(_bookmarkedQuizQuestions.keys.toSet());

  /// All bookmarked quiz question data objects
  List<BookmarkedQuizQuestion> get bookmarkedQuizQuestions =>
      List.unmodifiable(_bookmarkedQuizQuestions.values.toList());

  /// All bookmarked flashcard IDs
  Set<String> get bookmarkedFlashcardIds =>
      Set.unmodifiable(_bookmarkedFlashcards.keys.toSet());

  /// All bookmarked flashcard data objects
  List<BookmarkedFlashcard> get bookmarkedFlashcards =>
      List.unmodifiable(_bookmarkedFlashcards.values.toList());

  Set<String> get bookmarkedPlaygroundIds =>
      Set.unmodifiable(_bookmarkedPlaygroundIds);

  Set<String> get bookmarkedDevExperienceIds =>
      Set.unmodifiable(_bookmarkedDevExperienceIds);

  /// All bookmarked real case scenario IDs
  Set<String> get bookmarkedRealCaseIds =>
      Set.unmodifiable(_bookmarkedRealCaseScenarios.keys.toSet());

  /// All bookmarked real case scenario data objects
  List<BookmarkedRealCaseScenario> get bookmarkedRealCaseScenarios =>
      List.unmodifiable(_bookmarkedRealCaseScenarios.values.toList());

  int get totalBookmarkCount =>
      _bookmarkedQuestionIds.length +
      _bookmarkedQuizQuestions.length +
      _bookmarkedFlashcards.length +
      _bookmarkedPlaygroundIds.length +
      _bookmarkedDevExperienceIds.length +
      _bookmarkedRealCaseScenarios.length;

  int get totalBookmarksCount => totalBookmarkCount;

  bool isQuestionBookmarked(String id) => _bookmarkedQuestionIds.contains(id);
  bool isQuizBookmarked(String id) => _bookmarkedQuizQuestions.containsKey(id);
  bool isFlashcardBookmarked(String id) =>
      _bookmarkedFlashcards.containsKey(id);
  bool isPlaygroundBookmarked(String id) =>
      _bookmarkedPlaygroundIds.contains(id);
  bool isDevExperienceBookmarked(String id) =>
      _bookmarkedDevExperienceIds.contains(id);
  bool isRealCaseBookmarked(String id) =>
      _bookmarkedRealCaseScenarios.containsKey(id);

  bool isBookmarked(String id) =>
      _bookmarkedQuestionIds.contains(id) ||
      _bookmarkedQuizQuestions.containsKey(id) ||
      _bookmarkedFlashcards.containsKey(id) ||
      _bookmarkedPlaygroundIds.contains(id) ||
      _bookmarkedDevExperienceIds.contains(id) ||
      _bookmarkedRealCaseScenarios.containsKey(id);

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

  /// Toggle a quiz question bookmark. Pass [data] when adding so the full
  /// question snapshot is persisted. Pass null to remove.
  bool toggleQuiz(String id, {BookmarkedQuizQuestion? data}) {
    if (_bookmarkedQuizQuestions.containsKey(id)) {
      _bookmarkedQuizQuestions.remove(id);
    } else if (data != null) {
      _bookmarkedQuizQuestions[id] = data;
    } else {
      // No data provided — store minimal placeholder
      _bookmarkedQuizQuestions[id] = BookmarkedQuizQuestion(
        id: id,
        text: '',
        topicId: '',
        topicName: '',
        category: '',
        difficulty: '',
      );
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedQuizQuestions.containsKey(id);
  }

  /// Toggle a flashcard bookmark. Pass [data] when adding.
  bool toggleFlashcardBookmark(String id, {BookmarkedFlashcard? data}) {
    if (_bookmarkedFlashcards.containsKey(id)) {
      _bookmarkedFlashcards.remove(id);
    } else if (data != null) {
      _bookmarkedFlashcards[id] = data;
    } else {
      _bookmarkedFlashcards[id] = BookmarkedFlashcard(
        id: id,
        front: '',
        back: '',
        category: '',
      );
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedFlashcards.containsKey(id);
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

  /// Toggle a real case scenario bookmark. Pass [data] when adding.
  bool toggleRealCaseScenario(String id, {BookmarkedRealCaseScenario? data}) {
    if (_bookmarkedRealCaseScenarios.containsKey(id)) {
      _bookmarkedRealCaseScenarios.remove(id);
    } else if (data != null) {
      _bookmarkedRealCaseScenarios[id] = data;
    } else {
      _bookmarkedRealCaseScenarios[id] = BookmarkedRealCaseScenario(
        id: id,
        title: '',
        category: '',
        problemStatement: '',
        solutionBreakdown: '',
        tags: [],
      );
    }
    notifyListeners();
    _saveToPrefs();
    return _bookmarkedRealCaseScenarios.containsKey(id);
  }

  bool toggle(String id) => toggleQuestion(id);

  void removeQuestion(String id) {
    if (_bookmarkedQuestionIds.remove(id)) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void removeQuiz(String id) {
    if (_bookmarkedQuizQuestions.remove(id) != null) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void removeFlashcard(String id) {
    if (_bookmarkedFlashcards.remove(id) != null) {
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

  void removeRealCaseScenario(String id) {
    if (_bookmarkedRealCaseScenarios.remove(id) != null) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void clearAll() {
    _bookmarkedQuestionIds.clear();
    _bookmarkedQuizQuestions.clear();
    _bookmarkedFlashcards.clear();
    _bookmarkedPlaygroundIds.clear();
    _bookmarkedDevExperienceIds.clear();
    _bookmarkedRealCaseScenarios.clear();
    notifyListeners();
    _saveToPrefs();
  }

  void remove(String id) => removeQuestion(id);
}
