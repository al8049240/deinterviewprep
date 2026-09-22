import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'statistics_repository.dart';

class ReviewPromptService {
  ReviewPromptService._();
  static final instance = ReviewPromptService._();

  String get _owner => Supabase.instance.client.auth.currentUser?.id ?? 'guest';
  String get _key => 'review_prompt_completed_v1_$_owner';
  String get _dismissedKey => 'review_prompt_dismissed_v1_$_owner';
  String get _lastPromptKey => 'review_prompt_last_shown_v1_$_owner';

  Future<bool> shouldShowPrompt() async {
    final preferences = await SharedPreferences.getInstance();
    return !(preferences.getBool(_key) ?? false) &&
        !(preferences.getBool(_dismissedKey) ?? false);
  }

  Future<bool> shouldShowAutomaticPrompt() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !await shouldShowPrompt()) return false;

    final preferences = await SharedPreferences.getInstance();
    final lastShown = DateTime.tryParse(
      preferences.getString(_lastPromptKey) ?? '',
    );
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < const Duration(days: 30)) {
      return false;
    }

    final attempts = await StatisticsRepository.instance.fetchAttempts(
      userId: user.id,
    );
    if (attempts.length < 3) return false;
    final activeDays = attempts.map((attempt) {
      final date = attempt.createdAt.toLocal();
      return '${date.year}-${date.month}-${date.day}';
    }).toSet();
    return activeDays.length >= 2;
  }

  Future<void> recordPromptShown() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastPromptKey, DateTime.now().toIso8601String());
  }

  Future<void> snooze() => recordPromptShown();

  Future<void> dismiss() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_dismissedKey, true);
  }

  Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
  }
}
