import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  ReviewRepository._();
  static final instance = ReviewRepository._();

  SupabaseClient get _client => Supabase.instance.client;
  static const _schema = 'de_mobile_app';
  static const appTargetId = 'de-interview-prep';

  Future<void> createReview({
    required int rating,
    required String title,
    required String comment,
    List<String> mediaUrls = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sign in to send feedback.');
    await _client.schema(_schema).from('reviews').insert({
      'target_id': appTargetId,
      'user_id': user.id,
      'rating': rating,
      'title': title.trim().isEmpty ? null : title.trim(),
      'comment': comment.trim(),
      'media_urls': mediaUrls,
    });
  }

  Future<List<Map<String, dynamic>>> fetchReviews({
    int page = 0,
    int pageSize = 20,
    int? rating,
  }) async {
    dynamic query = _client.schema(_schema).from('reviews').select()
        .eq('target_id', appTargetId).eq('status', 'published');
    if (rating != null) query = query.eq('rating', rating);
    final rows = await query.order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> updateReview(String id, Map<String, dynamic> values) async {
    await _client.schema(_schema).from('reviews').update(values).eq('id', id);
  }

  Future<void> deleteReview(String id) async {
    await _client.schema(_schema).from('reviews').delete().eq('id', id);
  }

  Future<void> vote(String reviewId, int value) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sign in to vote.');
    await _client.schema(_schema).from('review_votes').upsert({
      'review_id': reviewId,
      'user_id': user.id,
      'value': value,
    });
  }
}
