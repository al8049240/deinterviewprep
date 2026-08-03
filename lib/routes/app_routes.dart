import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/quiz_screen/quiz_screen.dart';
import '../presentation/results_screen/results_screen.dart';
import '../presentation/topics_list_screen/topics_list_screen.dart';
import '../presentation/bookmarks_screen/bookmarks_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/flashcards_screen/flashcards_screen.dart';
import '../presentation/question_bank_screen/question_bank_screen.dart';
import '../presentation/code_playground_screen/code_playground_screen.dart';
import '../presentation/performance_trends_screen/performance_trends_screen.dart';
import '../presentation/main_screen/main_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String mainScreen = '/main-screen';
  static const String topicsListScreen = '/topics-list-screen';
  static const String quizScreen = '/quiz-screen';
  static const String resultsScreen = '/results-screen';
  static const String bookmarksScreen = '/bookmarks-screen';
  static const String dashboardScreen = '/dashboard-screen';
  static const String flashcardsScreen = '/flashcards-screen';
  static const String questionBankScreen = '/question-bank-screen';
  static const String codePlaygroundScreen = '/code-playground-screen';
  static const String performanceTrendsScreen = '/performance-trends-screen';
}

CustomTransitionPage _slidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainScreen(initialIndex: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.mainScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final index = extra?['index'] as int? ?? 0;
        return _slidePage(
          key: state.pageKey,
          child: MainScreen(initialIndex: index),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.dashboardScreen,
      pageBuilder: (context, state) =>
          _slidePage(key: state.pageKey, child: const DashboardScreen()),
    ),
    GoRoute(
      path: AppRoutes.topicsListScreen,
      pageBuilder: (context, state) =>
          _slidePage(key: state.pageKey, child: const TopicsListScreen()),
    ),
    GoRoute(
      path: AppRoutes.flashcardsScreen,
      pageBuilder: (context, state) =>
          _slidePage(key: state.pageKey, child: const FlashcardsScreen()),
    ),
    GoRoute(
      path: AppRoutes.questionBankScreen,
      pageBuilder: (context, state) =>
          _slidePage(key: state.pageKey, child: const QuestionBankScreen()),
    ),
    GoRoute(
      path: AppRoutes.codePlaygroundScreen,
      pageBuilder: (context, state) =>
          _slidePage(key: state.pageKey, child: const CodePlaygroundScreen()),
    ),
    GoRoute(
      path: AppRoutes.quizScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slidePage(
          key: state.pageKey,
          child: QuizScreen(
            topicId: extra?['topicId'] as String? ?? 'sql',
            topicName: extra?['topicName'] as String? ?? 'SQL',
            questionCount: extra?['questionCount'] as int? ?? 15,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.resultsScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slidePage(
          key: state.pageKey,
          child: ResultsScreen(
            topicName: extra?['topicName'] as String? ?? 'SQL',
            score: extra?['score'] as int? ?? 0,
            totalQuestions: extra?['totalQuestions'] as int? ?? 15,
            correctAnswers: extra?['correctAnswers'] as int? ?? 0,
            timeTakenSeconds: extra?['timeTakenSeconds'] as int? ?? 0,
            topicId: extra?['topicId'] as String? ?? 'sql',
            maxStreak: extra?['maxStreak'] as int? ?? 0,
            questions: extra?['questions'] as List<Map<String, dynamic>>? ?? [],
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.bookmarksScreen,
      pageBuilder: (context, state) =>
          _slidePage(key: state.pageKey, child: const BookmarksScreen()),
    ),
    GoRoute(
      path: AppRoutes.performanceTrendsScreen,
      pageBuilder: (context, state) => _slidePage(
        key: state.pageKey,
        child: const PerformanceTrendsScreen(),
      ),
    ),
  ],
);
