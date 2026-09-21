import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './providers/bookmark_provider.dart';
import './providers/statistics_provider.dart';
import './services/performance_service.dart';
import './services/pro_service.dart';
import './services/reminder_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - web does not support this, guard with kIsWeb
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (error) {
      debugPrint('Failed to set device orientation: $error');
    }
  }
  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: MyApp(),
    ),
  );

  // Non-critical plugins and persisted state must not block app launch.
  unawaited(_initializeOptionalServices());
}

Future<void> _initializeOptionalServices() async {
  try {
    await PerformanceService().init();
  } catch (error) {
    debugPrint('Failed to load performance history: $error');
  }
  try {
    await ProService().init();
  } catch (error) {
    debugPrint('Failed to initialize purchases: $error');
  }
  try {
    await ReminderService.instance.initialize();
  } catch (error) {
    debugPrint('Failed to initialize study reminders: $error');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (Supabase.instance.isInitialized) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (state) async {
          final user = state.session?.user;
          final provider = user?.appMetadata['provider']?.toString();
          final confirmedAt = DateTime.tryParse(
            user?.emailConfirmedAt?.toString() ?? '',
          );
          final wasJustConfirmed = confirmedAt != null &&
              DateTime.now().toUtc().difference(confirmedAt.toUtc()).abs() <
                  const Duration(minutes: 5);
          if (state.event == AuthChangeEvent.signedIn &&
              user != null &&
              provider == 'email' &&
              wasJustConfirmed) {
            final confirmationKey =
                'email_confirmation_notice_${user.id}_${confirmedAt!.toIso8601String()}';
            try {
              final preferences = await SharedPreferences.getInstance();
              if (preferences.getBool(confirmationKey) == true) return;
              await preferences.setBool(confirmationKey, true);
            } catch (error) {
              debugPrint('Failed to persist email confirmation notice: $error');
              return;
            }
            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scaffoldMessengerKey.currentState
                ?..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Email confirmation completed. You can sign in now.',
                    ),
                  ),
                );
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Auth confirmation listener failed: $error');
        },
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: 'deinterviewprep',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        );
      },
    );
  }
}
