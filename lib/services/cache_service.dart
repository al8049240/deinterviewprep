import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_model.dart';

/// Local cache service for premium content offline access.
class CacheService {
  static const String _cachedQuestionsKey = 'cached_questions';
  static const String _cachedFlashcardsKey = 'cached_flashcards';
  static const String _cachedCodeSamplesKey = 'cached_code_samples';
  static const String _cacheTimestampKey = 'cache_timestamp';

  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // ── Questions ──────────────────────────────────────────────────────────────

  Future<void> cacheQuestions(List<InterviewQuestionModel> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = questions
        .map(
          (q) => {
            'id': q.id,
            'title': q.title,
            'description': q.description,
            'answer': q.answer,
            'category': q.category,
            'difficulty': q.difficulty,
            'isPro': q.isPro,
            'tags': q.tags,
          },
        )
        .toList();
    await prefs.setString(_cachedQuestionsKey, jsonEncode(encoded));
    await _updateTimestamp();
  }

  Future<List<InterviewQuestionModel>?> getCachedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedQuestionsKey);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map(
            (e) => InterviewQuestionModel(
              id: e['id'] as String,
              title: e['title'] as String,
              description: e['description'] as String,
              answer: e['answer'] as String,
              category: e['category'] as String,
              difficulty: e['difficulty'] as String,
              isPro: e['isPro'] as bool,
              tags: List<String>.from(e['tags'] as List),
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Flashcards ─────────────────────────────────────────────────────────────

  Future<void> cacheFlashcards(List<FlashcardModel> flashcards) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = flashcards
        .map(
          (f) => {
            'id': f.id,
            'front': f.front,
            'back': f.back,
            'category': f.category,
            'isMastered': f.isMastered,
          },
        )
        .toList();
    await prefs.setString(_cachedFlashcardsKey, jsonEncode(encoded));
    await _updateTimestamp();
  }

  Future<List<FlashcardModel>?> getCachedFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedFlashcardsKey);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map(
            (e) => FlashcardModel(
              id: e['id'] as String,
              front: e['front'] as String,
              back: e['back'] as String,
              category: e['category'] as String,
              isMastered: e['isMastered'] as bool? ?? false,
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Code Samples ───────────────────────────────────────────────────────────

  Future<void> cacheCodeSamples(Map<String, String> samples) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedCodeSamplesKey, jsonEncode(samples));
    await _updateTimestamp();
  }

  Future<Map<String, String>?> getCachedCodeSamples() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedCodeSamplesKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return null;
    }
  }

  // ── Cache Status ───────────────────────────────────────────────────────────

  Future<bool> hasCachedContent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cachedQuestionsKey) ||
        prefs.containsKey(_cachedFlashcardsKey);
  }

  Future<DateTime?> getCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_cacheTimestampKey);
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedQuestionsKey);
    await prefs.remove(_cachedFlashcardsKey);
    await prefs.remove(_cachedCodeSamplesKey);
    await prefs.remove(_cacheTimestampKey);
  }

  Future<void> _updateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }
}
