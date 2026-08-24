import 'package:flutter/foundation.dart';

import '../models/statistics_models.dart';
import '../services/statistics_repository.dart';
import '../services/auth_service.dart';

enum StatisticsStatus { initial, loading, loaded, error }

class StatisticsProvider extends ChangeNotifier {
  StatisticsStatus _status = StatisticsStatus.initial;
  UserStatistics _statistics = UserStatistics.empty();
  String? _errorMessage;

  StatisticsStatus get status => _status;
  UserStatistics get statistics => _statistics;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == StatisticsStatus.loading;
  bool get hasData => _status == StatisticsStatus.loaded;
  bool get hasError => _status == StatisticsStatus.error;
  bool get isEmpty =>
      _status == StatisticsStatus.loaded &&
      _statistics.totalQuizzesCompleted == 0;

  /// Load statistics from Supabase. Requires authenticated user.
  Future<void> loadStatistics() async {
    if (!AuthService.instance.isSignedIn) {
      _status = StatisticsStatus.loaded;
      _statistics = UserStatistics.empty();
      notifyListeners();
      return;
    }

    _status = StatisticsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await StatisticsRepository.instance.calculateStatistics();
      _statistics = stats;
      _status = StatisticsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = StatisticsStatus.error;
    }

    notifyListeners();
  }

  /// Refresh statistics (e.g., after completing a quiz).
  Future<void> refresh() => loadStatistics();

  /// Reset to initial state (e.g., on sign out).
  void reset() {
    _status = StatisticsStatus.initial;
    _statistics = UserStatistics.empty();
    _errorMessage = null;
    notifyListeners();
  }
}
