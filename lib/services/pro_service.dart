import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const bool _launchPromotionEnabled = bool.fromEnvironment(
    'IAP_LAUNCH_PROMOTION',
    defaultValue: true,
  );
  static const String _launchStartUtcValue = String.fromEnvironment(
    'IAP_LAUNCH_START_UTC',
    defaultValue: '',
  );
  static const int launchPromotionDays = 45;
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
  bool _isServerProUnlocked = false;
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
  Timer? _purchaseWatchdog;
  // Kept for the lifetime of this app-scoped singleton.
  // ignore: unused_field
  StreamSubscription<AuthState>? _authSubscription;
  int _dailyStreak = 0;
  int _cardsMastered = 0;
  List<PerformanceEntry> _performanceHistory = [];

  /// Debug builds always unlock premium screens for local development.
  /// Profile and release builds still require a local or server entitlement.
  bool get isProUnlocked =>
      _isProUnlocked ||
      _isServerProUnlocked ||
      kDebugMode;
  bool get storeAvailable => _storeAvailable;
  bool get isLoadingStore => _isLoadingStore;
  bool get purchasePending => _purchasePending;
  bool get restorePending => _restorePending;
  String? get purchaseError => _purchaseError;
  ProductDetails? get lifetimeProduct => _lifetimeProduct;
  static DateTime? get launchStartsAt =>
      DateTime.tryParse(_launchStartUtcValue)?.toUtc();
  static DateTime? get launchEndsAt =>
      launchStartsAt?.add(const Duration(days: launchPromotionDays));
  static bool get isLaunchPromotion {
    if (!_launchPromotionEnabled) return false;
    final start = launchStartsAt;
    if (start == null) return true;
    final now = DateTime.now().toUtc();
    return !now.isBefore(start) && now.isBefore(launchEndsAt!);
  }

  String get displayPrice =>
      _lifetimeProduct?.price ?? (isLaunchPromotion ? r'$5.00' : r'$10.00');
  String get purchaseCtaText => isLaunchPromotion
      ? '$displayPrice launch offer — Lifetime access'
      : '$displayPrice — Lifetime access';
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
    await refreshEntitlement();
    if (Supabase.instance.isInitialized) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(
            (_) => refreshEntitlement(),
            onError: (Object error) {
              debugPrint('Failed to refresh Pro entitlement: $error');
            },
          );
    }
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

  /// Refreshes the signed-in user's server-managed Pro entitlement.
  ///
  /// The client only has SELECT permission. Entitlements must be granted by a
  /// trusted backend or an administrator, never by the mobile application.
  Future<void> refreshEntitlement() async {
    if (!Supabase.instance.isInitialized) {
      _isServerProUnlocked = false;
      notifyListeners();
      return;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _isServerProUnlocked = false;
      notifyListeners();
      return;
    }

    try {
      final result = await client
          .schema('de_mobile_app')
          .from('user_entitlements')
          .select('is_pro, expires_at')
          .eq('user_id', user.id)
          .maybeSingle();
      final expiresAtValue = result?['expires_at'] as String?;
      final expiresAt = expiresAtValue == null
          ? null
          : DateTime.tryParse(expiresAtValue)?.toUtc();
      _isServerProUnlocked =
          result?['is_pro'] == true &&
          (expiresAt == null || expiresAt.isAfter(DateTime.now().toUtc()));
    } catch (error) {
      _isServerProUnlocked = false;
      debugPrint('Failed to load Pro entitlement: $error');
    }
    notifyListeners();
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
    if (!_isUserSignedIn) {
      _purchaseError = 'Sign in before purchasing Serious Mode.';
      notifyListeners();
      return false;
    }
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
      } else {
        _purchaseWatchdog?.cancel();
        _purchaseWatchdog = Timer(const Duration(seconds: 60), () async {
          if (!_purchasePending) return;
          _purchasePending = false;
          _purchaseError = 'Checking your existing Google Play purchase…';
          notifyListeners();
          await restorePurchases();
        });
      }
      return started;
    } catch (error) {
      _purchasePending = false;
      if (_isAlreadyOwnedError(error)) {
        _purchaseError = 'Purchase already owned. Restoring access…';
        notifyListeners();
        await restorePurchases();
        return false;
      }
      _purchaseError = 'The purchase could not be started. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    var shouldRestoreOwnedPurchase = false;
    for (final purchase in purchases) {
      if (!_validProductIds.contains(purchase.productID)) continue;
      _purchaseWatchdog?.cancel();
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final verificationData =
                purchase.verificationData.serverVerificationData;
            if (verificationData.isEmpty) {
              throw const FormatException('The purchase receipt is empty.');
            }
            await _verifyAndGrantProEntitlement(
              productId: purchase.productID,
              verificationData: verificationData,
              source: purchase.verificationData.source,
            );
            _purchaseError = null;
          } catch (error) {
            debugPrint('Purchase verification failed: $error');
            _purchaseError = _purchaseVerificationError(error);
          } finally {
            _purchasePending = false;
            _restorePending = false;
          }
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _restorePending = false;
          if (_isAlreadyOwnedError(purchase.error)) {
            _purchaseError = 'Purchase already owned. Restoring access…';
            shouldRestoreOwnedPurchase = true;
          } else {
            _purchaseError = purchase.error?.message ?? 'Purchase failed.';
          }
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          _restorePending = false;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(purchase);
        } catch (error) {
          debugPrint('Failed to complete store purchase: $error');
          _purchaseError ??=
              'Payment succeeded, but the store could not finish the purchase. '
              'Tap Restore purchase to try again.';
        }
      }
    }
    notifyListeners();
    if (shouldRestoreOwnedPurchase) await restorePurchases();
  }

  bool _isAlreadyOwnedError(Object? error) {
    final text = error?.toString().toLowerCase() ?? '';
    return text.contains('already own') ||
        text.contains('already_owned') ||
        text.contains('itemalreadyowned') ||
        text.contains('item_already_owned');
  }

  Future<void> _verifyAndGrantProEntitlement({
    required String productId,
    required String verificationData,
    required String source,
  }) async {
    if (!Supabase.instance.isInitialized || !_isUserSignedIn) {
      throw StateError('Sign in before verifying a purchase.');
    }

    final response = await Supabase.instance.client.functions
        .invoke(
          'verify-play-purchase',
          body: {
            'productId': productId,
            'purchaseToken': verificationData,
            'source': source,
          },
        )
        .timeout(const Duration(seconds: 30));

    final data = response.data;
    if (response.status < 200 ||
        response.status >= 300 ||
        data is! Map ||
        data['isPro'] != true) {
      final message = data is Map ? data['error']?.toString() : null;
      throw StateError(message ?? 'The server rejected the purchase.');
    }

    // Keep the local cache for offline access only after server verification.
    final prefs = await SharedPreferences.getInstance();
    _isServerProUnlocked = true;
    _isProUnlocked = true;
    await prefs.setBool(_proKey, true);
  }

  String _purchaseVerificationError(Object error) {
    if (error is TimeoutException) {
      return 'Payment succeeded, but verification timed out. '
          'Tap Restore purchase to try again.';
    }
    final text = error.toString();
    final prefix = text.indexOf(': ');
    final message = prefix >= 0 ? text.substring(prefix + 2) : text;
    return message.isEmpty
        ? 'Payment succeeded, but verification failed. Tap Restore purchase.'
        : message;
  }

  Future<void> _updateStreak(SharedPreferences prefs) async {
    final lastStudy = prefs.getString(_lastStudyKey);
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (lastStudy == null) {
      _dailyStreak = 1;
    } else {
      final parts = lastStudy.split('-');
      final last =
          DateTime.tryParse(lastStudy) ??
          (parts.length == 3
              ? DateTime(
                  int.tryParse(parts[0]) ?? today.year,
                  int.tryParse(parts[1]) ?? today.month,
                  int.tryParse(parts[2]) ?? today.day,
                )
              : today);
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
    if (!_isUserSignedIn) {
      _restorePending = false;
      _purchaseError = 'Sign in before restoring purchases.';
      notifyListeners();
      return;
    }
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

  bool get _isUserSignedIn {
    if (!Supabase.instance.isInitialized) return false;
    return Supabase.instance.client.auth.currentUser != null;
  }
}
