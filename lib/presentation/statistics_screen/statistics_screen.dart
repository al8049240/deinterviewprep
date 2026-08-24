import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/statistics_models.dart';
import '../../providers/statistics_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'Statistics',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => context.read<StatisticsProvider>().refresh(),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'This Week'),
            Tab(text: 'Topics'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (provider.hasError) {
            return _ErrorView(
              message: provider.errorMessage ?? 'Failed to load statistics',
              onRetry: () => provider.refresh(),
            );
          }

          if (!AuthService.instance.isSignedIn) {
            return _UnauthenticatedView();
          }

          final stats = provider.statistics;

          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(stats: stats),
              _ThisWeekTab(stats: stats),
              _TopicsTab(stats: stats),
              _RecentAttemptsTab(stats: stats),
            ],
          );
        },
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final UserStatistics stats;
  const _OverviewTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isEmpty = stats.totalQuizzesCompleted == 0;

    if (isEmpty) {
      return _EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'No quiz history yet',
        subtitle: 'Complete a quiz to see your statistics here.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Performance Overview'),
          const SizedBox(height: 12),
          _OverviewGrid(stats: stats),
          const SizedBox(height: 20),
          _SectionTitle('Study Time'),
          const SizedBox(height: 12),
          _StudyTimeCard(stats: stats),
          const SizedBox(height: 20),
          _SectionTitle('Streak'),
          const SizedBox(height: 12),
          _StreakCard(stats: stats),
          if (stats.weakTopics.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle('Needs Attention'),
            const SizedBox(height: 12),
            _WeakTopicsCard(weakTopics: stats.weakTopics),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final UserStatistics stats;
  const _OverviewGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final accuracy = (stats.overallAccuracy * 100).toStringAsFixed(1);
    final studyHours = (stats.totalStudyTimeSeconds / 3600).toStringAsFixed(1);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF9A825),
                label: 'Total XP',
                value: '${stats.totalXp}',
                subtitle: '+${stats.todayXp} today',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.track_changes_rounded,
                iconColor: AppTheme.primary,
                label: 'Accuracy',
                value: '$accuracy%',
                subtitle:
                    '${stats.totalCorrectAnswers}/${stats.totalQuestionsAnswered} correct',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.quiz_rounded,
                iconColor: const Color(0xFF1565C0),
                label: 'Quizzes',
                value: '${stats.totalQuizzesCompleted}',
                subtitle: '${stats.activeTopicsCount} topics',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.timer_rounded,
                iconColor: const Color(0xFF6A1B9A),
                label: 'Study Time',
                value: '${studyHours}h',
                subtitle:
                    '${_formatSeconds(stats.todayStudyTimeSeconds)} today',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StudyTimeCard extends StatelessWidget {
  final UserStatistics stats;
  const _StudyTimeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimeItem(
              label: 'Total',
              value: _formatSeconds(stats.totalStudyTimeSeconds),
              icon: Icons.access_time_rounded,
              color: AppTheme.primary,
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFEEEEEE)),
          Expanded(
            child: _TimeItem(
              label: 'Today',
              value: _formatSeconds(stats.todayStudyTimeSeconds),
              icon: Icons.today_rounded,
              color: const Color(0xFF1565C0),
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFEEEEEE)),
          Expanded(
            child: _TimeItem(
              label: 'This Week',
              value: _formatSeconds(stats.weeklyStudyTimeSeconds),
              icon: Icons.date_range_rounded,
              color: const Color(0xFF6A1B9A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _TimeItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: const Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final UserStatistics stats;
  const _StreakCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF9A825).withAlpha(30),
            const Color(0xFFFF6F00).withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF9A825).withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF6F00),
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.currentStreak} day streak',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Longest: ${stats.longestStreak} days',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          if (stats.currentStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6F00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🔥 Active',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeakTopicsCard extends StatelessWidget {
  final List<TopicPerformance> weakTopics;
  const _WeakTopicsCard({required this.weakTopics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warning,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Topics below 70% accuracy',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...weakTopics.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.topicName,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(t.accuracy * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── This Week Tab ─────────────────────────────────────────────────────────────

class _ThisWeekTab extends StatelessWidget {
  final UserStatistics stats;
  const _ThisWeekTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isEmpty = stats.weeklyQuestionsAnswered == 0;

    if (isEmpty) {
      return _EmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No activity this week',
        subtitle: 'Complete a quiz to see your weekly progress.',
      );
    }

    final weeklyAccuracy = (stats.weeklyAccuracy * 100).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Weekly Summary'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF1565C0),
                  label: 'Questions',
                  value: '${stats.weeklyQuestionsAnswered}',
                  subtitle: 'answered',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppTheme.success,
                  label: 'Correct',
                  value: '${stats.weeklyCorrectAnswers}',
                  subtitle: 'answers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.track_changes_rounded,
                  iconColor: AppTheme.primary,
                  label: 'Accuracy',
                  value: '$weeklyAccuracy%',
                  subtitle: 'this week',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_rounded,
                  iconColor: const Color(0xFF6A1B9A),
                  label: 'Study Time',
                  value: _formatSeconds(stats.weeklyStudyTimeSeconds),
                  subtitle: 'this week',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Daily Activity (Last 7 Days)'),
          const SizedBox(height: 12),
          _DailyActivityChart(activities: stats.dailyActivities),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DailyActivityChart extends StatelessWidget {
  final List<DailyActivity> activities;
  const _DailyActivityChart({required this.activities});

  @override
  Widget build(BuildContext context) {
    final maxQuestions = activities.isEmpty
        ? 1
        : activities
              .map((a) => a.questionsAnswered)
              .reduce((a, b) => a > b ? a : b);
    final maxVal = maxQuestions == 0 ? 1 : maxQuestions;

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: activities.asMap().entries.map((entry) {
                final activity = entry.value;
                final heightFraction = activity.questionsAnswered / maxVal;
                final isToday =
                    activity.date.day == DateTime.now().day &&
                    activity.date.month == DateTime.now().month;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (activity.questionsAnswered > 0)
                          Text(
                            '${activity.questionsAnswered}',
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: heightFraction * 80,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppTheme.primary
                                : activity.questionsAnswered > 0
                                ? AppTheme.primaryLight.withAlpha(180)
                                : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabels[activity.date.weekday - 1],
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isToday
                                ? AppTheme.primary
                                : const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Today',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF888888),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(180),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Active day',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Topics Tab ────────────────────────────────────────────────────────────────

class _TopicsTab extends StatelessWidget {
  final UserStatistics stats;
  const _TopicsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.topicPerformances.isEmpty) {
      return _EmptyState(
        icon: Icons.topic_rounded,
        title: 'No topic data yet',
        subtitle: 'Complete quizzes across different topics to see breakdowns.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Topic Performance'),
          const SizedBox(height: 12),
          ...stats.topicPerformances.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TopicPerformanceCard(topic: t),
            ),
          ),
          if (stats.categoryPerformances.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle('By Category'),
            const SizedBox(height: 12),
            ...stats.categoryPerformances.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryRow(category: c),
              ),
            ),
          ],
          if (stats.difficultyPerformances.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle('By Difficulty'),
            const SizedBox(height: 12),
            _DifficultyBreakdown(difficulties: stats.difficultyPerformances),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TopicPerformanceCard extends StatelessWidget {
  final TopicPerformance topic;
  const _TopicPerformanceCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final accuracy = topic.accuracy;
    final accuracyPct = (accuracy * 100).toStringAsFixed(1);
    final color = accuracy >= 0.8
        ? AppTheme.success
        : accuracy >= 0.6
        ? AppTheme.warning
        : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic.topicName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topic.isWeak)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withAlpha(60)),
                  ),
                  child: Text(
                    'Weak',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '$accuracyPct%',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: accuracy,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${topic.correctAnswers} / ${topic.totalAnswers} correct',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryPerformance category;
  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    final accuracy = category.accuracy;
    final color = accuracy >= 0.8
        ? AppTheme.success
        : accuracy >= 0.6
        ? AppTheme.warning
        : AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.category,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF333333),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${category.correctAnswers}/${category.totalAnswers}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(accuracy * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBreakdown extends StatelessWidget {
  final List<DifficultyPerformance> difficulties;
  const _DifficultyBreakdown({required this.difficulties});

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppTheme.success;
      case 'hard':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: difficulties.map((d) {
          final color = _diffColor(d.difficulty);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    d.difficulty,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: d.accuracy,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(d.accuracy * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Recent Attempts Tab ───────────────────────────────────────────────────────

class _RecentAttemptsTab extends StatelessWidget {
  final UserStatistics stats;
  const _RecentAttemptsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.recentAttempts.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        title: 'No recent attempts',
        subtitle:
            'Your quiz history will appear here after you complete quizzes.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stats.recentAttempts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final attempt = stats.recentAttempts[index];
        return _AttemptCard(attempt: attempt);
      },
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttempt attempt;
  const _AttemptCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final accuracy = attempt.accuracy;
    final color = accuracy >= 0.8
        ? AppTheme.success
        : accuracy >= 0.6
        ? AppTheme.warning
        : AppTheme.error;
    final accuracyPct = (accuracy * 100).toStringAsFixed(0);
    final date = attempt.createdAt;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final duration = _formatSeconds(attempt.durationSeconds);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$accuracyPct%',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.topicName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${attempt.correctAnswers}/${attempt.totalQuestions} correct · $duration',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+${attempt.xpEarned} XP',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF9A825),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF999999),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF888888),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load statistics',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnauthenticatedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to view statistics',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your quiz statistics are saved to your account and available across all your devices.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF888888),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatSeconds(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m < 60) return '${m}m ${s}s';
  final h = m ~/ 60;
  final rem = m % 60;
  return '${h}h ${rem}m';
}
