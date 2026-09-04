import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/statistics_models.dart';
import '../services/statistics_repository.dart';
import '../services/auth_service.dart';

enum StatisticsStatus { initial, loading, loaded, error }

class StatisticsProvider extends ChangeNotifier {
  StatisticsStatus _status = StatisticsStatus.initial;
  UserStatistics _statistics = UserStatistics.empty();
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;
  int _loadGeneration = 0;

  StatisticsProvider() {
    _listenForAuthChanges();
  }

  StatisticsStatus get status => _status;
  UserStatistics get statistics => _statistics;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == StatisticsStatus.loading;
  bool get hasData => _status == StatisticsStatus.loaded;
  bool get hasError => _status == StatisticsStatus.error;
  bool get isEmpty =>
      _status == StatisticsStatus.loaded &&
      _statistics.totalQuizzesCompleted == 0;

  void _listenForAuthChanges() {
    try {
      _authSubscription = AuthService.instance.authStateChanges.listen(
        _handleAuthChange,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Statistics auth sync error: $error');
        },
      );
    } catch (error) {
      // Supabase can be unavailable in local builds without environment values.
      debugPrint('Statistics auth sync is unavailable: $error');
    }
  }

  void _handleAuthChange(AuthState authState) {
    switch (authState.event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
        if (authState.session?.user != null) {
          // Clear any guest or previous-account values before fetching.
          _statistics = UserStatistics.empty();
          unawaited(loadStatistics());
        } else {
          reset();
        }
      case AuthChangeEvent.signedOut:
        reset();
      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.mfaChallengeVerified:
        break;
      default:
        // Ignore auth events that do not change the active statistics owner.
        break;
    }
  }

  /// Load statistics from Supabase. Requires authenticated user.
  Future<void> loadStatistics() async {
    final userId = AuthService.instance.currentUser?.id;
    final generation = ++_loadGeneration;

    if (userId == null) {
      _status = StatisticsStatus.loaded;
      _statistics = UserStatistics.empty();
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = StatisticsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await StatisticsRepository.instance.calculateStatistics(
        userId: userId,
      );

      // Ignore a response if the account changed while the request was running.
      if (generation != _loadGeneration ||
          AuthService.instance.currentUser?.id != userId) {
        return;
      }
      _statistics = stats;
      _status = StatisticsStatus.loaded;
    } catch (e) {
      if (generation != _loadGeneration ||
          AuthService.instance.currentUser?.id != userId) {
        return;
      }
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = StatisticsStatus.error;
    }

    notifyListeners();
  }

  /// Refresh statistics (e.g., after completing a quiz).
  Future<void> refresh() => loadStatistics();

  /// Reset to initial state (e.g., on sign out).
  void reset() {
    _loadGeneration++;
    _status = StatisticsStatus.initial;
    _statistics = UserStatistics.empty();
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
