import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/performance_service.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stats Hub Screen (redesigned Performance Trends)
// ─────────────────────────────────────────────────────────────────────────────

class PerformanceTrendsScreen extends StatefulWidget {
  const PerformanceTrendsScreen({super.key});

  @override
  State<PerformanceTrendsScreen> createState() =>
      _PerformanceTrendsScreenState();
}

class _PerformanceTrendsScreenState extends State<PerformanceTrendsScreen> {
  final PerformanceService _service = PerformanceService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onDataChanged);
    _service.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service.init();
  }

  @override
  void dispose() {
    _service.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  // ── Derived stats ──────────────────────────────────────────────────────────

  int get _totalXP {
    return _service.sessions.fold<int>(
      0,
      (sum, s) => sum + s.correctAnswers * 10,
    );
  }

  int get _todayXP {
    final today = DateTime.now();
    return _service.sessions
        .where(
          (s) =>
              s.timestamp.year == today.year &&
              s.timestamp.month == today.month &&
              s.timestamp.day == today.day,
        )
        .fold<int>(0, (sum, s) => sum + s.correctAnswers * 10);
  }

  String get _totalStudyTime {
    final totalSec = _service.sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get _todayStudyTime {
    final today = DateTime.now();
    final totalSec = _service.sessions
        .where(
          (s) =>
              s.timestamp.year == today.year &&
              s.timestamp.month == today.month &&
              s.timestamp.day == today.day,
        )
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  double get _overallAccuracy {
    final all = _service.sessions;
    if (all.isEmpty) return 0;
    final totalCorrect = all.fold<int>(0, (s, e) => s + e.correctAnswers);
    final totalQ = all.fold<int>(0, (s, e) => s + e.totalQuestions);
    return totalQ == 0 ? 0 : (totalCorrect / totalQ) * 100;
  }

  int get _activeTopics {
    return _service.sessions.map((s) => s.topicId).toSet().length;
  }

  int get _daysActive {
    return _service.sessions
        .map(
          (s) => '${s.timestamp.year}-${s.timestamp.month}-${s.timestamp.day}',
        )
        .toSet()
        .length;
  }

  int get _currentStreak {
    if (_service.sessions.isEmpty) return 0;
    final days =
        _service.sessions
            .map(
              (s) => DateTime(
                s.timestamp.year,
                s.timestamp.month,
                s.timestamp.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (final d in days) {
      if (d == check || d == check.subtract(const Duration(days: 1))) {
        streak++;
        check = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Chart data helpers ─────────────────────────────────────────────────────

  List<double> _xpByDay(bool weekly) {
    final days = weekly ? 7 : 30;
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      return _service.sessions
          .where(
            (s) =>
                s.timestamp.year == day.year &&
                s.timestamp.month == day.month &&
                s.timestamp.day == day.day,
          )
          .fold<double>(0, (sum, s) => sum + s.correctAnswers * 10);
    });
  }

  List<double> _timeByDay(bool weekly) {
    final days = weekly ? 7 : 30;
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      final sec = _service.sessions
          .where(
            (s) =>
                s.timestamp.year == day.year &&
                s.timestamp.month == day.month &&
                s.timestamp.day == day.day,
          )
          .fold<int>(0, (sum, s) => sum + s.durationSeconds);
      return sec / 60.0; // minutes
    });
  }

  Map<String, double> get _topicAccuracy {
    final Map<String, List<double>> grouped = {};
    for (final s in _service.sessions) {
      if (s.totalQuestions > 0) {
        grouped.putIfAbsent(s.topicName, () => []).add(s.accuracyPercent);
      }
    }
    return grouped.map((topic, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(topic, avg);
    });
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              subtitle: 'Manage reminders and alerts',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Appearance',
              subtitle: 'Theme and display settings',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_rounded,
              title: 'Privacy',
              subtitle: 'Data and privacy preferences',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'FAQs and contact us',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'App version and info',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showXpDialog() {
    showDialog(
      context: context,
      builder: (_) => _LineChartDialog(
        title: 'XP / Score',
        yLabel: 'Points',
        dataFn: _xpByDay,
      ),
    );
  }

  void _showTimeDialog() {
    showDialog(
      context: context,
      builder: (_) => _LineChartDialog(
        title: 'Study Time (minutes)',
        yLabel: 'Min',
        dataFn: _timeByDay,
      ),
    );
  }

  void _showAccuracyDialog() {
    showDialog(
      context: context,
      builder: (_) => _TopicAccuracyDialog(topicAccuracy: _topicAccuracy),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSettingsSheet(context),
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header
              _ProfileHeaderCard(),
              const SizedBox(height: 16),

              // 2. Quick Stats Row
              _QuickStatsRow(
                daysActive: _daysActive,
                streak: _currentStreak,
                totalXP: _totalXP,
                dailyGoal: 50,
              ),
              const SizedBox(height: 20),

              // 3. Statistics Section Title
              _SectionTitle(title: 'Statistics', icon: Icons.bar_chart_rounded),
              const SizedBox(height: 12),

              // 4. Stats Grid
              _StatsGrid(
                totalXP: _totalXP,
                todayXP: _todayXP,
                totalTime: _totalStudyTime,
                todayTime: _todayStudyTime,
                overallAccuracy: _overallAccuracy,
                activeTopics: _activeTopics,
                onXpTap: _showXpDialog,
                onTimeTap: _showTimeDialog,
                onAccuracyTap: _showAccuracyDialog,
              ),
              const SizedBox(height: 24),

              // 5. Skill Badges
              _SectionTitle(
                title: 'Skill Medals',
                icon: Icons.military_tech_rounded,
                actionLabel: 'View All',
              ),
              const SizedBox(height: 12),
              const _SkillBadgesRow(),
              const SizedBox(height: 24),

              // 6. Achievement Badges
              _SectionTitle(
                title: 'Achievements',
                icon: Icons.emoji_events_rounded,
                actionLabel: 'View All',
              ),
              const SizedBox(height: 12),
              const _AchievementBadgesRow(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'DE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Engineer',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'learner@deinterviewprep.com',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF999999),
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final int daysActive;
  final int streak;
  final int totalXP;
  final int dailyGoal;

  const _QuickStatsRow({
    required this.daysActive,
    required this.streak,
    required this.totalXP,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickStatItem(
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF1565C0),
            value: '$daysActive',
            label: 'Days Active',
          ),
          _Divider(),
          _QuickStatItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFE65100),
            value: '$streak',
            label: 'Streak',
          ),
          _Divider(),
          _QuickStatItem(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFF9A825),
            value: '$totalXP',
            label: 'Total XP',
          ),
          _Divider(),
          _QuickStatItem(
            icon: Icons.alarm_rounded,
            iconColor: AppTheme.primary,
            value: '$dailyGoal',
            label: 'Daily Goal',
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
  }
}

class _QuickStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _QuickStatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: const Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionLabel;

  const _SectionTitle({
    required this.title,
    required this.icon,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          Row(
            children: [
              Text(
                actionLabel!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid (2×2 tappable cards)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int totalXP;
  final int todayXP;
  final String totalTime;
  final String todayTime;
  final double overallAccuracy;
  final int activeTopics;
  final VoidCallback onXpTap;
  final VoidCallback onTimeTap;
  final VoidCallback onAccuracyTap;

  const _StatsGrid({
    required this.totalXP,
    required this.todayXP,
    required this.totalTime,
    required this.todayTime,
    required this.overallAccuracy,
    required this.activeTopics,
    required this.onXpTap,
    required this.onTimeTap,
    required this.onAccuracyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total XP',
                value: '$totalXP KN',
                subtitle: 'Today: $todayXP KN',
                subtitleTappable: true,
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFF9A825),
                bgColor: const Color(0xFFFFF8E1),
                onTap: onXpTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Today\'s XP',
                value: '$todayXP KN',
                subtitle: 'Tap for chart',
                subtitleTappable: true,
                icon: Icons.trending_up_rounded,
                iconColor: AppTheme.primary,
                bgColor: AppTheme.primaryContainer.withAlpha(80),
                onTap: onXpTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Study Time',
                value: totalTime.isEmpty ? '0m' : totalTime,
                subtitle: 'Today: $todayTime',
                subtitleTappable: true,
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                onTap: onTimeTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Topic Accuracy',
                value: '${overallAccuracy.toStringAsFixed(0)}%',
                subtitle: '$activeTopics active topics',
                subtitleTappable: true,
                icon: Icons.gps_fixed_rounded,
                iconColor: const Color(0xFFC62828),
                bgColor: const Color(0xFFFFEBEE),
                onTap: onAccuracyTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool subtitleTappable;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleTappable,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFFBBBBBB),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFF888888),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line Chart Dialog (XP & Time)
// ─────────────────────────────────────────────────────────────────────────────

class _LineChartDialog extends StatefulWidget {
  final String title;
  final String yLabel;
  final List<double> Function(bool weekly) dataFn;

  const _LineChartDialog({
    required this.title,
    required this.yLabel,
    required this.dataFn,
  });

  @override
  State<_LineChartDialog> createState() => _LineChartDialogState();
}

class _LineChartDialogState extends State<_LineChartDialog> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final data = widget.dataFn(_isWeekly);
    final maxVal = data.reduce(max);
    final labels = _isWeekly
        ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : List.generate(data.length, (i) => '${i + 1}');

    final now = DateTime.now();
    final startDay = now.subtract(Duration(days: (_isWeekly ? 7 : 30) - 1));
    final dateRange =
        '${startDay.day}/${startDay.month}/${startDay.year} - ${now.day}/${now.month}/${now.year}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '($dateRange)',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 14),
            // Toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToggleChip(
                    label: 'Weekly',
                    selected: _isWeekly,
                    onTap: () => setState(() => _isWeekly = true),
                  ),
                  _ToggleChip(
                    label: 'Monthly',
                    selected: !_isWeekly,
                    onTap: () => setState(() => _isWeekly = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: maxVal == 0
                  ? Center(
                      child: Text(
                        'No data yet — start studying!',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: const Color(0xFFEEEEEE),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: maxVal > 0 ? maxVal / 4 : 1,
                              getTitlesWidget: (v, meta) => Text(
                                v.toInt().toString(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: const Color(0xFF888888),
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: _isWeekly ? 1 : 5,
                              getTitlesWidget: (v, meta) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  labels[idx],
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: const Color(0xFF888888),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              data.length,
                              (i) => FlSpot(i.toDouble(), data[i]),
                            ),
                            isCurved: true,
                            color: AppTheme.primaryLight,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 3.5,
                                    color: AppTheme.primaryLight,
                                    strokeWidth: 1.5,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryLight.withAlpha(30),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: (data.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxVal * 1.2,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topic Accuracy Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _TopicAccuracyDialog extends StatefulWidget {
  final Map<String, double> topicAccuracy;

  const _TopicAccuracyDialog({required this.topicAccuracy});

  @override
  State<_TopicAccuracyDialog> createState() => _TopicAccuracyDialogState();
}

class _TopicAccuracyDialogState extends State<_TopicAccuracyDialog> {
  String? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    final topics = widget.topicAccuracy.keys.toList();
    final filtered = _selectedTopic == null
        ? widget.topicAccuracy
        : {_selectedTopic!: widget.topicAccuracy[_selectedTopic!]!};

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Topic Accuracy',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (topics.isNotEmpty) ...[
              // Filter dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedTopic,
                    isExpanded: true,
                    hint: Text(
                      'All Topics',
                      style: GoogleFonts.dmSans(fontSize: 13),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Topics',
                          style: GoogleFonts.dmSans(fontSize: 13),
                        ),
                      ),
                      ...topics.map(
                        (t) => DropdownMenuItem<String?>(
                          value: t,
                          child: Text(
                            t,
                            style: GoogleFonts.dmSans(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedTopic = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView(
                  shrinkWrap: true,
                  children: filtered.entries.map((e) {
                    final pct = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: pct >= 70
                                      ? AppTheme.primary
                                      : const Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 7,
                              backgroundColor: const Color(0xFFEEEEEE),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct >= 70
                                    ? AppTheme.primaryLight
                                    : const Color(0xFFFF7043),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Complete quizzes to see topic accuracy',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF888888),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skill Badges Row
// ─────────────────────────────────────────────────────────────────────────────

class _SkillBadgesRow extends StatelessWidget {
  const _SkillBadgesRow();

  static const _skills = [
    _SkillData(
      'SQL',
      Icons.storage_rounded,
      Color(0xFF1565C0),
      Color(0xFFE3F2FD),
      0.85,
    ),
    _SkillData(
      'Python',
      Icons.code_rounded,
      Color(0xFF2E7D32),
      Color(0xFFE8F5E9),
      0.70,
    ),
    _SkillData(
      'ETL',
      Icons.sync_alt_rounded,
      Color(0xFF6A1B9A),
      Color(0xFFF3E5F5),
      0.55,
    ),
    _SkillData(
      'Spark',
      Icons.bolt_rounded,
      Color(0xFFE65100),
      Color(0xFFFFF3E0),
      0.40,
    ),
    _SkillData(
      'Kafka',
      Icons.stream_rounded,
      Color(0xFF00695C),
      Color(0xFFE0F2F1),
      0.30,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _skills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final skill = _skills[i];
          return _SkillBadgeCard(skill: skill);
        },
      ),
    );
  }
}

class _SkillData {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final double progress;

  const _SkillData(
    this.name,
    this.icon,
    this.color,
    this.bgColor,
    this.progress,
  );
}

class _SkillBadgeCard extends StatelessWidget {
  final _SkillData skill;

  const _SkillBadgeCard({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: skill.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(skill.icon, color: skill.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            skill.name,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: skill.progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(skill.color),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${(skill.progress * 100).toInt()}%',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: skill.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achievement Badges Row
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementBadgesRow extends StatelessWidget {
  const _AchievementBadgesRow();

  static const _achievements = [
    _AchievementData(
      'Streak Master',
      3,
      Icons.local_fire_department_rounded,
      Color(0xFFE65100),
      Color(0xFFFFF3E0),
    ),
    _AchievementData(
      'Speed Runner',
      2,
      Icons.speed_rounded,
      Color(0xFF1565C0),
      Color(0xFFE3F2FD),
    ),
    _AchievementData(
      'Perfect Score',
      4,
      Icons.star_rounded,
      Color(0xFFF9A825),
      Color(0xFFFFF8E1),
    ),
    _AchievementData(
      'Topic Master',
      1,
      Icons.military_tech_rounded,
      Color(0xFF6A1B9A),
      Color(0xFFF3E5F5),
    ),
    _AchievementData(
      'Night Owl',
      2,
      Icons.nightlight_round,
      Color(0xFF00695C),
      Color(0xFFE0F2F1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final a = _achievements[i];
          return _AchievementCard(achievement: a);
        },
      ),
    );
  }
}

class _AchievementData {
  final String name;
  final int level;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _AchievementData(
    this.name,
    this.level,
    this.icon,
    this.color,
    this.bgColor,
  );
}

class _AchievementCard extends StatelessWidget {
  final _AchievementData achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: achievement.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.icon,
                  color: achievement.color,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: achievement.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv.${achievement.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle Chip (reused in dialogs)
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF888888)),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFBBBBBB),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
