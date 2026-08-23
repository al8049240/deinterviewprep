import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Model matching the de_mobile_app."quiz-question" + "quiz-answer" joined schema
class QuizQuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final List<int> correctIndices;
  final String explanation;
  final String difficulty;
  final String proTip;
  final String interviewTip;
  final String hint;
  final String interviewNote;
  final String category;
  final String type;
  final String subtag;

  const QuizQuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.correctIndices = const [],
    required this.explanation,
    required this.difficulty,
    required this.proTip,
    required this.interviewTip,
    this.hint = '',
    this.interviewNote = '',
    required this.category,
    required this.type,
    this.subtag = '',
  });

  /// Build from quiz-question row + list of quiz-answer rows (sorted by order)
  factory QuizQuestionModel.fromJoined(
    Map<String, dynamic> questionRow,
    List<Map<String, dynamic>> answerRows,
  ) {
    final sorted = List<Map<String, dynamic>>.from(answerRows)
      ..sort(
        (a, b) => ((a['order'] as num?)?.toInt() ?? 0).compareTo(
          (b['order'] as num?)?.toInt() ?? 0,
        ),
      );

    final options = sorted
        .map((a) => a['option_text']?.toString() ?? '')
        .toList();

    final correctIndices = <int>[];
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i]['is_correct'] == true) {
        correctIndices.add(i);
      }
    }
    final correctIndex = correctIndices.isNotEmpty ? correctIndices.first : 0;

    // Handle both 'explaination' (DB typo) and 'explanation' column names
    final explanationText =
        questionRow['explaination']?.toString() ??
        questionRow['explanation']?.toString() ??
        '';

    return QuizQuestionModel(
      id: questionRow['question_id']?.toString() ?? '',
      text: questionRow['question']?.toString() ?? '',
      options: options,
      correctIndex: correctIndex,
      correctIndices: correctIndices,
      explanation: explanationText,
      difficulty: questionRow['difficulty']?.toString() ?? 'junior',
      proTip: questionRow['pro_tips']?.toString() ?? '',
      interviewTip: questionRow['interview_tips']?.toString() ?? '',
      hint: questionRow['hint']?.toString() ?? '',
      interviewNote: questionRow['interview_note']?.toString() ?? '',
      category:
          questionRow['topic_name']?.toString() ??
          questionRow['topic']?.toString() ??
          '',
      type: questionRow['type']?.toString() ?? 'mcq',
      subtag: questionRow['subtopic_name']?.toString() ?? '',
    );
  }

  /// Convert to the legacy map format used by QuestionModel.fromMap
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'correctIndices': correctIndices,
      'explanation': explanation,
      'difficulty': difficulty,
      'proTip': proTip,
      'interviewTip': interviewTip,
      'hint': hint,
      'interviewNote': interviewNote,
      'category': category,
      'type': type,
    };
  }
}

// ── Lightweight question metadata (Tier-1 payload) ─────────────────────────

/// Lightweight metadata fetched first for list views.
/// Does NOT include heavy fields: explanation, pro_tips, interview_tips, hint, interview_note.
class QuizQuestionMeta {
  final String id;
  final String text;
  final String difficulty;
  final String type;
  final int topicId;
  final int? subtopicId;

  const QuizQuestionMeta({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.type,
    required this.topicId,
    this.subtopicId,
  });

  factory QuizQuestionMeta.fromRow(Map<String, dynamic> row) {
    return QuizQuestionMeta(
      id: row['question_id']?.toString() ?? '',
      text: row['question']?.toString() ?? '',
      difficulty: row['difficulty']?.toString() ?? 'junior',
      type: row['type']?.toString() ?? 'mcq',
      topicId: (row['topic'] as num?)?.toInt() ?? 0,
      subtopicId: (row['sub_topics'] as num?)?.toInt(),
    );
  }
}

// ── Cache entry with TTL ───────────────────────────────────────────────────

class _CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;
  final Duration ttl;

  _CacheEntry(this.data, {this.ttl = const Duration(minutes: 10)})
    : fetchedAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(fetchedAt) > ttl;
}

class QuizService {
  static QuizService? _instance;
  static QuizService get instance => _instance ??= QuizService._();
  QuizService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // ── Hardcoded fallback IDs (used when dynamic lookup fails) ───────────────
  static const int kSparkTopicId = 758910;
  static const int kSparkCoreSubtopicId = 719060;

  // ── Table name constants ───────────────────────────────────────────────────
  static const String _topicsTable = 'topics-legacy';
  static const String _subtopicsTable = 'subtopics-legacy';
  static const String _questionTable = 'quiz-question';
  static const String _answerTable = 'quiz-answer';

  // ── Smart in-memory cache (Tier-2: prevents repeat network requests) ──────

  /// Cache: topic name → integer ID (long-lived, topics rarely change)
  final Map<String, int> _topicIdCache = {};

  /// Cache: topicId → subtopic rows (10-min TTL)
  final Map<int, _CacheEntry<List<Map<String, dynamic>>>> _subtopicCache = {};

  /// Cache: topic name → question count (10-min TTL)
  _CacheEntry<Map<String, int>>? _topicCountsCache;

  /// Cache: subtopicId → question count (10-min TTL)
  final Map<int, _CacheEntry<int>> _subtopicCountCache = {};

  /// Cache: topicId → full question list (5-min TTL, heavier payload)
  final Map<int, _CacheEntry<List<QuizQuestionModel>>> _questionsByTopicCache =
      {};

  /// Cache: subtopicId → full question list (5-min TTL)
  final Map<int, _CacheEntry<List<QuizQuestionModel>>>
  _questionsBySubtopicCache = {};

  /// Cache: topicId → lightweight metadata list (10-min TTL)
  final Map<int, _CacheEntry<List<QuizQuestionMeta>>> _metaByTopicCache = {};

  // ── Topic ID resolution ────────────────────────────────────────────────────

  Future<int?> _resolveTopicId(String topicName) async {
    if (_topicIdCache.containsKey(topicName)) {
      return _topicIdCache[topicName];
    }
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_topicsTable)
          .select('id')
          .eq('name', topicName)
          .limit(1);
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        if (topicName == 'Apache Spark') {
          _topicIdCache[topicName] = kSparkTopicId;
          return kSparkTopicId;
        }
        return null;
      }
      final id = (data.first['id'] as num?)?.toInt();
      if (id != null) _topicIdCache[topicName] = id;
      return id;
    } catch (_) {
      if (topicName == 'Apache Spark') return kSparkTopicId;
      return null;
    }
  }

  // ── Subtopic cache ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _loadSubtopics(int topicId) async {
    final cached = _subtopicCache[topicId];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_subtopicsTable)
          .select('id, name, description')
          .eq('topic_id', topicId);
      final List<dynamic> data = response as List<dynamic>;
      final rows = data.cast<Map<String, dynamic>>();
      _subtopicCache[topicId] = _CacheEntry(rows);
      return rows;
    } catch (_) {
      return [];
    }
  }

  void _invalidateSubtopicCache() {
    _subtopicCache.clear();
    _questionsByTopicCache.clear();
    _questionsBySubtopicCache.clear();
    _metaByTopicCache.clear();
  }

  Map<String, dynamic>? _findSubtopicByName(
    List<Map<String, dynamic>> subtopics,
    String name,
  ) {
    final normTarget = _normName(name);
    for (final s in subtopics) {
      if (s['name']?.toString() == name) return s;
    }
    for (final s in subtopics) {
      final normName = _normName(s['name']?.toString() ?? '');
      if (normName == normTarget ||
          normName.contains(normTarget) ||
          normTarget.contains(normName)) {
        return s;
      }
    }
    return null;
  }

  String _normName(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s/_\-]'), '');

  // ── Public: Spark subtopic IDs ─────────────────────────────────────────────

  Future<({int? coreId, int? sqlDfId})> fetchSparkSubtopicIds() async {
    final topicId = await _resolveTopicId('Apache Spark');
    if (topicId == null) return (coreId: kSparkCoreSubtopicId, sqlDfId: null);

    final subtopics = await _loadSubtopics(topicId);

    final coreRow =
        _findSubtopicByName(subtopics, 'Spark Core') ??
        subtopics.firstWhere(
          (s) => _normName(s['name']?.toString() ?? '').contains('core'),
          orElse: () => {},
        );

    final sqlDfRow =
        _findSubtopicByName(subtopics, 'Spark SQL/DataFrame') ??
        _findSubtopicByName(subtopics, 'Spark DataFrame/SQL') ??
        subtopics.firstWhere((s) {
          final n = _normName(s['name']?.toString() ?? '');
          return n.contains('sql') ||
              n.contains('dataframe') ||
              n.contains('df');
        }, orElse: () => {});

    final coreId = coreRow.isNotEmpty
        ? (coreRow['id'] as num?)?.toInt() ?? kSparkCoreSubtopicId
        : kSparkCoreSubtopicId;
    final sqlDfId = sqlDfRow.isNotEmpty
        ? (sqlDfRow['id'] as num?)?.toInt()
        : null;

    return (coreId: coreId, sqlDfId: sqlDfId);
  }

  // ── Real-time subscription management ─────────────────────────────────────

  final Map<String, RealtimeChannel> _channels = {};

  Future<void Function()> subscribeToTopicChanges({
    required int topicId,
    required void Function() onDataChanged,
  }) async {
    final channelName = 'quiz_topic_$topicId';
    await _removeChannel(channelName);

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'de_mobile_app',
          table: _questionTable,
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'de_mobile_app',
          table: _answerTable,
          callback: (_) => onDataChanged(),
        )
        .subscribe();

    _channels[channelName] = channel;
    return () => _removeChannel(channelName);
  }

  Future<void Function()> subscribeToSubtopicChanges({
    required int topicId,
    required void Function() onDataChanged,
  }) async {
    final channelName = 'quiz_subtopics_$topicId';
    await _removeChannel(channelName);

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'de_mobile_app',
          table: _subtopicsTable,
          callback: (_) {
            _invalidateSubtopicCache();
            onDataChanged();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'de_mobile_app',
          table: _questionTable,
          callback: (_) => onDataChanged(),
        )
        .subscribe();

    _channels[channelName] = channel;
    return () => _removeChannel(channelName);
  }

  Future<void> _removeChannel(String channelName) async {
    final existing = _channels.remove(channelName);
    if (existing != null) {
      try {
        await existing.unsubscribe();
      } catch (_) {}
    }
  }

  Future<void> unsubscribeAll() async {
    final keys = List<String>.from(_channels.keys);
    for (final key in keys) {
      await _removeChannel(key);
    }
  }

  // ── Topic / Subtopic ID resolution (public) ────────────────────────────────

  Future<int?> fetchTopicId(String topicName) async {
    return _resolveTopicId(topicName);
  }

  Future<List<Map<String, dynamic>>> fetchSubtopics(int topicId) async {
    return _loadSubtopics(topicId);
  }

  Future<int?> fetchSubtopicId(int topicId, String subtopicName) async {
    final subtopics = await _loadSubtopics(topicId);
    final row = _findSubtopicByName(subtopics, subtopicName);
    return row != null ? (row['id'] as num?)?.toInt() : null;
  }

  // ── Tier-1: Lightweight metadata fetch (fast, minimal payload) ────────────

  /// Fetches only question_id, question text, difficulty, type, topic, sub_topics.
  /// Use this for list/preview views. Call [fetchQuestionsByTopicId] for full content.
  Future<List<QuizQuestionMeta>> fetchQuestionMetaByTopicId(int topicId) async {
    final cached = _metaByTopicCache[topicId];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select('question_id, question, difficulty, type, topic, sub_topics')
          .eq('topic', topicId);
      final List<dynamic> data = response as List<dynamic>;
      final metas = data
          .map((row) => QuizQuestionMeta.fromRow(row as Map<String, dynamic>))
          .where((m) => m.id.isNotEmpty)
          .toList();
      _metaByTopicCache[topicId] = _CacheEntry(metas);
      return metas;
    } catch (_) {
      return [];
    }
  }

  // ── Question fetching (Tier-2: full content, cached) ──────────────────────

  Future<List<QuizQuestionModel>> fetchSparkQuestions() async {
    final topicId = await _resolveTopicId('Apache Spark');
    if (topicId == null) return [];
    return fetchQuestionsByTopicId(topicId);
  }

  Future<List<QuizQuestionModel>> fetchQuestionsByTopicId(int topicId) async {
    // Return from cache if still fresh
    final cached = _questionsByTopicCache[topicId];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select(
            'question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips, hint, interview_note',
          )
          .eq('topic', topicId);

      final List<dynamic> questionData = response as List<dynamic>;
      if (questionData.isEmpty) return [];
      final models = await _buildModelsFromQuestionData(questionData);
      _questionsByTopicCache[topicId] = _CacheEntry(
        models,
        ttl: const Duration(minutes: 5),
      );
      return models;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  Future<List<QuizQuestionModel>> fetchQuestionsByTopic(String topicId) async {
    try {
      final numericId = int.tryParse(topicId);
      if (numericId != null) {
        return fetchQuestionsByTopicId(numericId);
      }
      final resolvedId = await _resolveTopicId(topicId);
      if (resolvedId != null) {
        return fetchQuestionsByTopicId(resolvedId);
      }
      return [];
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  Future<List<QuizQuestionModel>> fetchQuestionsBySubtopicId(
    int subtopicId,
  ) async {
    // Return from cache if still fresh
    final cached = _questionsBySubtopicCache[subtopicId];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select(
            'question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips, hint, interview_note',
          )
          .eq('sub_topics', subtopicId);

      final List<dynamic> questionData = response as List<dynamic>;
      if (questionData.isNotEmpty) {
        final models = await _buildModelsFromQuestionData(questionData);
        _questionsBySubtopicCache[subtopicId] = _CacheEntry(
          models,
          ttl: const Duration(minutes: 5),
        );
        return models;
      }
      return [];
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch questions by subtopic: $e');
    }
  }

  Future<List<QuizQuestionModel>> fetchQuestionsBySubtag(String subtag) async {
    try {
      String subtopicName;
      if (subtag == 'spark') {
        subtopicName = 'Spark Core';
      } else if (subtag == 'spark_df' || subtag == 'spark_sql') {
        subtopicName = 'Spark SQL/DataFrame';
      } else {
        subtopicName = subtag;
      }
      final topicId = await _resolveTopicId('Apache Spark');
      if (topicId == null) return [];
      final subtopicId = await fetchSubtopicId(topicId, subtopicName);
      if (subtopicId != null) {
        return await fetchQuestionsBySubtopicId(subtopicId);
      }
      return await fetchQuestionsByTopicId(topicId);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch questions by subtag: $e');
    }
  }

  Future<int> fetchSubtopicQuestionCount(int subtopicId) async {
    // Return from cache if still fresh
    final cached = _subtopicCountCache[subtopicId];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select('question_id')
          .eq('sub_topics', subtopicId);
      final List<dynamic> data = response as List<dynamic>;
      final count = data.length;
      _subtopicCountCache[subtopicId] = _CacheEntry(count);
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> fetchSubtagQuestionCount(String subtag) async {
    try {
      String subtopicName;
      if (subtag == 'spark') {
        subtopicName = 'Spark Core';
      } else if (subtag == 'spark_df' || subtag == 'spark_sql') {
        subtopicName = 'Spark SQL/DataFrame';
      } else if (subtag == 'big_data') {
        subtopicName = 'Spark SQL/DataFrame';
      } else {
        subtopicName = subtag;
      }
      final topicId = await _resolveTopicId('Apache Spark');
      if (topicId == null) return 0;
      final subtopicId = await fetchSubtopicId(topicId, subtopicName);
      if (subtopicId != null) {
        return await fetchSubtopicQuestionCount(subtopicId);
      }
      return await fetchTopicQuestionCountById(topicId);
    } catch (_) {
      return 0;
    }
  }

  Future<int> fetchTopicQuestionCountById(int topicId) async {
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select('question_id')
          .eq('topic', topicId);
      final List<dynamic> data = response as List<dynamic>;
      return data.length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<QuizQuestionModel>> fetchAllQuestions() async {
    try {
      final questionsResponse = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select(
            'question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips, hint, interview_note',
          );

      final List<dynamic> questionData = questionsResponse as List<dynamic>;
      if (questionData.isEmpty) return [];
      return await _buildModelsFromQuestionData(questionData);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  Future<Map<String, int>> fetchTopicQuestionCounts() async {
    // Return from cache if still fresh (avoids N+1 queries on repeat navigation)
    if (_topicCountsCache != null && !_topicCountsCache!.isExpired) {
      return _topicCountsCache!.data;
    }
    try {
      // Step 1: Fetch all topics from topics-legacy
      final topicsResponse = await _client
          .schema('de_mobile_app')
          .from(_topicsTable)
          .select('id, name');
      final List<dynamic> topicsData = topicsResponse as List<dynamic>;
      if (topicsData.isEmpty) return {};

      // Step 2: For each topic, fetch exact count
      final Map<String, int> countsByName = {};
      for (final topic in topicsData) {
        final id = (topic['id'] as num?)?.toInt();
        final name = topic['name']?.toString() ?? '';
        if (id == null || name.isEmpty) continue;

        try {
          final countResponse = await _client
              .schema('de_mobile_app')
              .from(_questionTable)
              .select('question_id')
              .eq('topic', id);
          final count = (countResponse as List<dynamic>).length;
          if (count > 0) {
            countsByName[name] = count;
          }
        } catch (_) {
          // Skip topics that fail individually
        }
      }

      // Legacy alias for Apache Spark
      if (countsByName.containsKey('Apache Spark')) {
        countsByName['spark'] = countsByName['Apache Spark']!;
      }

      _topicCountsCache = _CacheEntry(countsByName);
      return countsByName;
    } catch (_) {
      return {};
    }
  }

  // ── Chunked question fetching for custom quiz (pagination) ────────────────

  /// Fetches a batch of [batchSize] questions for [subtopicId] starting at [offset].
  /// Used by the custom quiz builder to load questions in chunks rather than all at once.
  Future<List<QuizQuestionModel>> fetchQuestionsBySubtopicIdPaged({
    required int subtopicId,
    required int offset,
    required int batchSize,
  }) async {
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select(
            'question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips, hint, interview_note',
          )
          .eq('sub_topics', subtopicId)
          .range(offset, offset + batchSize - 1);

      final List<dynamic> questionData = response as List<dynamic>;
      if (questionData.isEmpty) return [];
      return await _buildModelsFromQuestionData(questionData);
    } catch (_) {
      return [];
    }
  }

  /// Fetches a batch of [batchSize] questions for [topicId] starting at [offset].
  Future<List<QuizQuestionModel>> fetchQuestionsByTopicIdPaged({
    required int topicId,
    required int offset,
    required int batchSize,
  }) async {
    try {
      final response = await _client
          .schema('de_mobile_app')
          .from(_questionTable)
          .select(
            'question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips, hint, interview_note',
          )
          .eq('topic', topicId)
          .range(offset, offset + batchSize - 1);

      final List<dynamic> questionData = response as List<dynamic>;
      if (questionData.isEmpty) return [];
      return await _buildModelsFromQuestionData(questionData);
    } catch (_) {
      return [];
    }
  }

  // ── Cache invalidation ─────────────────────────────────────────────────────

  /// Clears all in-memory caches. Call when data is known to have changed.
  void clearAllCaches() {
    _topicIdCache.clear();
    _subtopicCache.clear();
    _topicCountsCache = null;
    _subtopicCountCache.clear();
    _questionsByTopicCache.clear();
    _questionsBySubtopicCache.clear();
    _metaByTopicCache.clear();
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<List<QuizQuestionModel>> _buildModelsFromQuestionData(
    List<dynamic> questionData,
  ) async {
    final questionIds = questionData
        .map((q) => q['question_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (questionIds.isEmpty) return [];

    final answersResponse = await _client
        .schema('de_mobile_app')
        .from(_answerTable)
        .select('option_id, question_id, option_text, is_correct, "order"')
        .inFilter('question_id', questionIds);

    final List<dynamic> answerData = answersResponse as List<dynamic>;

    final Map<String, List<Map<String, dynamic>>> answersByQuestion = {};
    for (final answer in answerData) {
      final qId = answer['question_id']?.toString() ?? '';
      if (qId.isNotEmpty) {
        answersByQuestion.putIfAbsent(qId, () => []);
        answersByQuestion[qId]!.add(answer as Map<String, dynamic>);
      }
    }

    final results = <QuizQuestionModel>[];
    for (final questionRow in questionData) {
      final qId = questionRow['question_id']?.toString() ?? '';
      final answers = answersByQuestion[qId] ?? [];
      if (qId.isEmpty || answers.isEmpty) continue;

      final model = QuizQuestionModel.fromJoined(
        questionRow as Map<String, dynamic>,
        answers,
      );
      if (model.text.isNotEmpty && model.options.length >= 2) {
        results.add(model);
      }
    }
    return results;
  }
}
