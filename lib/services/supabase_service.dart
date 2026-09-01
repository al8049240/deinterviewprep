import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Fetch all flashcards from de_mobile_app.flashcards.
  Future<List<Map<String, dynamic>>> fetchFlashcards({int? topicId}) async {
    try {
      var query = client
          .schema('de_mobile_app')
          .from('flashcards')
          .select(
            'flashcard_id, name, explanation, topic_id, subtopic_id, created_at',
          );

      if (topicId != null) {
        query = query.eq('topic_id', topicId);
      }

      final result = await query.order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Fetch all topics from de_mobile_app.topics-legacy.
  Future<List<Map<String, dynamic>>> fetchTopics() async {
    try {
      final result = await client
          .schema('de_mobile_app')
          .from('topics-legacy')
          .select('id, name')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Fetch real case scenarios from de_mobile_app.real_case_scenarios.
  Future<List<Map<String, dynamic>>> fetchRealCaseScenarios({
    String? category,
    String? tag,
  }) async {
    try {
      var query = client
          .schema('de_mobile_app')
          .from('real_case_scenarios')
          .select(
            'id, title, category, tags, problem_statement, solution_breakdown, is_active, published_date, created_at',
          )
          .eq('is_active', true);

      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }

      final result = await query.order('published_date', ascending: false);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Fetch user-created real case scenarios.
  Future<List<Map<String, dynamic>>> fetchUserRealCaseScenarios() async {
    if (!AuthService.instance.isSignedIn) return [];

    try {
      final result = await client
          .schema('de_mobile_app')
          .from('user_real_case_scenarios')
          .select(
            'id, title, category, tags, problem_statement, solution_breakdown, created_at',
          )
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Create a user-generated real case scenario.
  Future<void> createUserRealCaseScenario({
    required String title,
    required String category,
    required String problemStatement,
    required String solutionBreakdown,
    List<String> tags = const [],
  }) async {
    if (!AuthService.instance.isSignedIn) {
      throw StateError('Please sign in to create a custom real case scenario.');
    }

    try {
      await client
          .schema('de_mobile_app')
          .from('user_real_case_scenarios')
          .insert({
            'title': title,
            'category': category,
            'problem_statement': problemStatement,
            'solution_breakdown': solutionBreakdown,
            'tags': tags,
          })
          .select();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user-created flashcards.
  Future<List<Map<String, dynamic>>> fetchUserFlashcards() async {
    if (!AuthService.instance.isSignedIn) return [];

    try {
      final result = await client
          .schema('de_mobile_app')
          .from('user_flashcards')
          .select('id, front, back, category, tags, created_at')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Create a user-generated flashcard.
  Future<void> createUserFlashcard({
    required String front,
    required String back,
    required String category,
    List<String> tags = const [],
  }) async {
    if (!AuthService.instance.isSignedIn) {
      throw StateError('Please sign in to create a custom flashcard.');
    }

    try {
      final userId = AuthService.instance.currentUser?.id;
      await client.schema('de_mobile_app').from('user_flashcards').insert({
        'front': front,
        'back': back,
        'category': category,
        'tags': tags,
        if (userId != null) 'user_id': userId,
      }).select();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user-created developer experiences.
  Future<List<Map<String, dynamic>>> fetchUserDeveloperExperiences() async {
    if (!AuthService.instance.isSignedIn) return [];

    try {
      final result = await client
          .schema('de_mobile_app')
          .from('user_developer_experiences')
          .select(
            'id, title, category_tag, situation, task_description, action_taken, result_achieved, key_takeaway, created_at',
          )
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Create a user-generated developer experience.
  Future<void> createUserDeveloperExperience({
    required String title,
    required String categoryTag,
    required String situation,
    required String taskDescription,
    required String actionTaken,
    required String resultAchieved,
    required String keyTakeaway,
  }) async {
    if (!AuthService.instance.isSignedIn) {
      throw StateError('Please sign in to create a custom developer experience.');
    }

    await client
        .schema('de_mobile_app')
        .from('user_developer_experiences')
        .insert({
          'title': title,
          'category_tag': categoryTag,
          'situation': situation,
          'task_description': taskDescription,
          'action_taken': actionTaken,
          'result_achieved': resultAchieved,
          'key_takeaway': keyTakeaway,
        });
  }

  /// Fetch the lightweight list of code playground challenges.
  Future<List<Map<String, dynamic>>> fetchPlaygroundChallenges() async {
    try {
      final result = await client
          .schema('de_mobile_app')
          .from('code_playground')
          .select(
            'playground_id, title, description, language, difficulty, tips',
          )
          .order('title', ascending: true);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Fetch the lightweight list of code playground challenges for the list screen.
  Future<List<Map<String, dynamic>>> fetchPlaygroundChallengesList() async {
    try {
      final result = await client
          .schema('de_mobile_app')
          .from('code_playground')
          .select(
            'playground_id, title, description, use_case, language, difficulty',
          )
          .order('title', ascending: true);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Fetch a single code playground challenge by [playgroundId].
  Future<Map<String, dynamic>?> fetchPlaygroundChallengeById(
    String playgroundId,
  ) async {
    try {
      final result = await client
          .schema('de_mobile_app')
          .from('code_playground')
          .select(
            'playground_id, title, description, use_case, language, difficulty, tips, solution_code, solution_explanation',
          )
          .eq('playground_id', playgroundId)
          .single();
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      return null;
    }
  }
}
