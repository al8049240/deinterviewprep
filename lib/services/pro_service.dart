import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceEntry {
  final DateTime date;
  final double score; // 0–100
  final double accuracy; // 0–100
  final int questionsAnswered;
  final String topic;

  const PerformanceEntry({
    required this.date,
    required this.score,
    required this.accuracy,
    required this.questionsAnswered,
    required this.topic,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'score': score,
    'accuracy': accuracy,
    'questionsAnswered': questionsAnswered,
    'topic': topic,
  };

  factory PerformanceEntry.fromJson(Map<String, dynamic> json) =>
      PerformanceEntry(
        date: DateTime.parse(json['date'] as String),
        score: (json['score'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        questionsAnswered: json['questionsAnswered'] as int,
        topic: json['topic'] as String,
      );
}

class ProService extends ChangeNotifier {
  /// Create both of these as non-consumable products in App Store Connect and
  /// Google Play Console. Enable the launch product at build time with:
  /// --dart-define=IAP_LAUNCH_PROMOTION=true
  static const String launchProductId = 'de_interview_prep_lifetime_launch';
  static const String lifetimeProductId = 'de_interview_prep_lifetime';
  static const bool isLaunchPromotion = bool.fromEnvironment(
    'IAP_LAUNCH_PROMOTION',
    defaultValue: true,
  );
  static const Set<String> _validProductIds = {
    launchProductId,
    lifetimeProductId,
  };
  static const String _proKey = 'is_pro_unlocked';
  static const String _streakKey = 'daily_streak';
  static const String _lastStudyKey = 'last_study_date';
  static const String _cardsMasteredKey = 'cards_mastered';
  static const String _performanceKey = 'performance_entries';

  bool _isProUnlocked = false;
  bool _isInitialized = false;
  bool _storeAvailable = false;
  bool _isLoadingStore = false;
  bool _purchasePending = false;
  bool _restorePending = false;
  String? _purchaseError;
  ProductDetails? _lifetimeProduct;
  // Kept for the lifetime of this app-scoped singleton.
  // ignore: unused_field
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  int _dailyStreak = 0;
  int _cardsMastered = 0;
  List<PerformanceEntry> _performanceHistory = [];

  bool get isProUnlocked => _isProUnlocked;
  bool get storeAvailable => _storeAvailable;
  bool get isLoadingStore => _isLoadingStore;
  bool get purchasePending => _purchasePending;
  bool get restorePending => _restorePending;
  String? get purchaseError => _purchaseError;
  ProductDetails? get lifetimeProduct => _lifetimeProduct;
  String get displayPrice =>
      _lifetimeProduct?.price ?? (isLaunchPromotion ? r'$9.99' : r'$14.99');
  String get activeProductId =>
      isLaunchPromotion ? launchProductId : lifetimeProductId;
  int get dailyStreak => _dailyStreak;
  int get cardsMastered => _cardsMastered;
  List<PerformanceEntry> get performanceHistory =>
      List.unmodifiable(_performanceHistory);

  static final ProService _instance = ProService._internal();
  factory ProService() => _instance;
  ProService._internal();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    final prefs = await SharedPreferences.getInstance();
    _isProUnlocked = prefs.getBool(_proKey) ?? false;
    _cardsMastered = prefs.getInt(_cardsMasteredKey) ?? 0;
    await _updateStreak(prefs);
    await _loadPerformanceHistory(prefs);
    notifyListeners();

    if (kIsWeb) return;
    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _purchasePending = false;
        _restorePending = false;
        _purchaseError = 'The store returned an unexpected error.';
        notifyListeners();
      },
    );
    await _loadStoreProduct();
  }

  Future<void> _loadStoreProduct() async {
    _isLoadingStore = true;
    _purchaseError = null;
    notifyListeners();
    try {
      _storeAvailable = await InAppPurchase.instance.isAvailable();
      if (!_storeAvailable) {
        _purchaseError = 'Purchases are not available on this device.';
        return;
      }
      final response = await InAppPurchase.instance.queryProductDetails({
        activeProductId,
      });
      if (response.error != null) {
        _purchaseError = response.error!.message;
      } else if (response.productDetails.isEmpty) {
        _purchaseError =
            'The lifetime product is not configured for this store yet.';
      } else {
        _lifetimeProduct = response.productDetails.first;
      }
    } catch (_) {
      _purchaseError = 'Could not connect to the store. Please try again.';
    } finally {
      _isLoadingStore = false;
      notifyListeners();
    }
  }

  Future<bool> purchaseLifetime() async {
    if (_isProUnlocked) return true;
    if (_lifetimeProduct == null) {
      await _loadStoreProduct();
    }
    final product = _lifetimeProduct;
    if (product == null) return false;
    _purchaseError = null;
    _purchasePending = true;
    notifyListeners();
    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _purchasePending = false;
        _purchaseError = 'The purchase could not be started.';
        notifyListeners();
      }
      return started;
    } catch (_) {
      _purchasePending = false;
      _purchaseError = 'The purchase could not be started. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!_validProductIds.contains(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // The stores have validated the transaction. Before a large-scale
          // launch, also send serverVerificationData to a backend for
          // server-side receipt verification and entitlement synchronization.
          if (purchase.verificationData.serverVerificationData.isNotEmpty) {
            await _grantProEntitlement();
            _purchaseError = null;
          } else {
            _purchaseError = 'The purchase receipt could not be verified.';
          }
          _purchasePending = false;
          _restorePending = false;
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _restorePending = false;
          _purchaseError = purchase.error?.message ?? 'Purchase failed.';
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          _restorePending = false;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  Future<void> _grantProEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    _isProUnlocked = true;
    await prefs.setBool(_proKey, true);
  }

  Future<void> _updateStreak(SharedPreferences prefs) async {
    final lastStudy = prefs.getString(_lastStudyKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastStudy == null) {
      _dailyStreak = 1;
    } else {
      final last = DateTime.parse(lastStudy);
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        _dailyStreak = prefs.getInt(_streakKey) ?? 1;
      } else if (diff == 1) {
        _dailyStreak = (prefs.getInt(_streakKey) ?? 0) + 1;
      } else {
        _dailyStreak = 1;
      }
    }
    await prefs.setInt(_streakKey, _dailyStreak);
    await prefs.setString(_lastStudyKey, todayStr);
  }

  Future<void> _loadPerformanceHistory(SharedPreferences prefs) async {
    final raw = prefs.getString(_performanceKey);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _performanceHistory = decoded
            .map((e) => PerformanceEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _performanceHistory = _generateSampleHistory();
      }
    } else {
      _performanceHistory = _generateSampleHistory();
      await _savePerformanceHistory(prefs);
    }
  }

  List<PerformanceEntry> _generateSampleHistory() {
    final now = DateTime.now();
    final topics = [
      'SQL',
      'PySpark',
      'System Design',
      'Data Modeling',
      'Incident Response',
    ];
    final entries = <PerformanceEntry>[];
    for (int i = 13; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final topic = topics[i % topics.length];
      entries.add(
        PerformanceEntry(
          date: date,
          score: 50 + (i % 5) * 8.0 + (i.isEven ? 5 : -3),
          accuracy: 55 + (i % 4) * 7.0 + (i.isOdd ? 4 : -2),
          questionsAnswered: 5 + (i % 6),
          topic: topic,
        ),
      );
    }
    return entries;
  }

  Future<void> _savePerformanceHistory(SharedPreferences prefs) async {
    final encoded = jsonEncode(
      _performanceHistory.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_performanceKey, encoded);
  }

  Future<void> recordPerformance({
    required double score,
    required double accuracy,
    required int questionsAnswered,
    required String topic,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _performanceHistory.add(
      PerformanceEntry(
        date: DateTime.now(),
        score: score,
        accuracy: accuracy,
        questionsAnswered: questionsAnswered,
        topic: topic,
      ),
    );
    // Keep last 30 entries
    if (_performanceHistory.length > 30) {
      _performanceHistory = _performanceHistory.sublist(
        _performanceHistory.length - 30,
      );
    }
    await _savePerformanceHistory(prefs);
    notifyListeners();
  }

  /// Returns entries for the last [days] days
  List<PerformanceEntry> getRecentEntries(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _performanceHistory.where((e) => e.date.isAfter(cutoff)).toList();
  }

  /// Returns accuracy per topic for the last [days] days
  Map<String, double> getAccuracyPerTopic(int days) {
    final entries = getRecentEntries(days);
    final Map<String, List<double>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(e.topic, () => []).add(e.accuracy);
    }
    return grouped.map((topic, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(topic, avg);
    });
  }

  /// Returns study consistency (days studied) in the last [days] days
  int getStudyConsistency(int days) {
    final entries = getRecentEntries(days);
    final uniqueDays = <String>{};
    for (final e in entries) {
      uniqueDays.add('${e.date.year}-${e.date.month}-${e.date.day}');
    }
    return uniqueDays.length;
  }

  Future<void> incrementCardsMastered() async {
    final prefs = await SharedPreferences.getInstance();
    _cardsMastered++;
    await prefs.setInt(_cardsMasteredKey, _cardsMastered);
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    if (kIsWeb || !_storeAvailable) {
      _purchaseError = 'Purchase restoration is unavailable on this device.';
      notifyListeners();
      return;
    }
    _purchaseError = null;
    _restorePending = true;
    notifyListeners();
    try {
      await InAppPurchase.instance.restorePurchases();
      _restorePending = false;
      notifyListeners();
    } catch (_) {
      _restorePending = false;
      _purchaseError = 'Could not restore purchases. Please try again.';
      notifyListeners();
    }
  }
}
