import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/performance_service.dart';
import '../../services/statistics_repository.dart';
import '../../models/statistics_models.dart';
import '../../theme/app_theme.dart';
import '../auth_screen/auth_screen.dart';
import '../settings_screen/settings_screen.dart';

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
  List<QuizAttempt> _attempts = [];
  List<QuizUserAnswer> _userAnswers = [];
  bool _attemptsLoading = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onDataChanged);
    _service.init();
    _loadAttemptsData();
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

  Future<void> _loadAttemptsData() async {
    if (!AuthService.instance.isSignedIn) return;
    setState(() => _attemptsLoading = true);
    try {
      final attempts = await StatisticsRepository.instance.fetchAttempts();
      final answers = await StatisticsRepository.instance.fetchUserAnswers();
      if (mounted) {
        setState(() {
          _attempts = attempts;
          _userAnswers = answers;
          _attemptsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _attemptsLoading = false);
    }
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

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<void> _openAuthScreen() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));
    if (result == true && mounted) {
      setState(() {});
      _loadAttemptsData();
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.signOut();
      if (mounted) setState(() {});
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showSettingsSheet(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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

  void _showUserDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDropdownSheet(
        onSignOut: _signOut,
        onGoBack: () {
          Navigator.pop(context);
          context.go(AppRoutes.topicsListScreen);
        },
      ),
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
          if (AuthService.instance.isSignedIn)
            GestureDetector(
              onTap: () => _showUserDropdown(context),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AuthService.instance.displayName,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _openAuthScreen,
              icon: const Icon(
                Icons.login_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'Sign In',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
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
              _ProfileHeaderCard(onSignInTap: _openAuthScreen),
              const SizedBox(height: 20),

              // 2. Statistics Section Title
              _SectionTitle(title: 'Statistics', icon: Icons.bar_chart_rounded),
              const SizedBox(height: 12),

              // 3. Stats Grid
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

              // 4. Skills Progress
              _SectionTitle(
                title: 'Skills Progress',
                icon: Icons.military_tech_rounded,
              ),
              const SizedBox(height: 12),
              _SkillBadgesRow(topicAccuracy: _topicAccuracy),
              const SizedBox(height: 24),

              // 5. My Attempts (grouped by topic)
              _SectionTitle(title: 'My Attempts', icon: Icons.history_rounded),
              const SizedBox(height: 12),
              _attemptsLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : _GroupedAttemptsSection(
                      attempts: _attempts,
                      userAnswers: _userAnswers,
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Dropdown Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _UserDropdownSheet extends StatefulWidget {
  final VoidCallback onSignOut;
  final VoidCallback onGoBack;

  const _UserDropdownSheet({required this.onSignOut, required this.onGoBack});

  @override
  State<_UserDropdownSheet> createState() => _UserDropdownSheetState();
}

class _UserDropdownSheetState extends State<_UserDropdownSheet> {
  late TextEditingController _usernameController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: AuthService.instance.displayName,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Username updated!',
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final email = auth.email;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    auth.displayName.isNotEmpty
                        ? auth.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
                      auth.displayName,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 16),

          // Username edit section
          Text(
            'Username',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _usernameController,
                        autofocus: true,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          isDense: true,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          auth.displayName,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              if (_isEditing) ...[
                _isSaving
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _saveUsername,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ] else
                IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: AppTheme.primary,
                  tooltip: 'Edit username',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Go back and prepare button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onGoBack,
              icon: const Icon(Icons.quiz_rounded, size: 18),
              label: Text(
                'Go back and prepare for the interview',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sign out button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onSignOut();
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Sign Out',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFC62828)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final VoidCallback onSignInTap;
  const _ProfileHeaderCard({required this.onSignInTap});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final isSignedIn = auth.isSignedIn;
    final name = isSignedIn ? auth.displayName : 'Guest User';
    final email = isSignedIn ? auth.email : 'Sign in to save your progress';
    final avatarUrl = auth.avatarUrl;
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'DE';

    return GestureDetector(
      onTap: isSignedIn ? null : onSignInTap,
      child: Container(
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
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
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
                    name,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF666666),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isSignedIn) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap to sign in →',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSignedIn
                  ? Icons.verified_user_rounded
                  : Icons.chevron_right_rounded,
              color: isSignedIn ? AppTheme.primary : const Color(0xFF999999),
              size: 22,
            ),
          ],
        ),
      ),
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
  final Map<String, double> topicAccuracy;

  const _SkillBadgesRow({required this.topicAccuracy});

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
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _skills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final skill = _skills[i];
          final accuracy = topicAccuracy[skill.name];
          final isMastered = accuracy != null && accuracy >= 80.0;
          return _SkillBadgeCard(skill: skill, isMastered: isMastered);
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
  final bool isMastered;

  const _SkillBadgeCard({required this.skill, required this.isMastered});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMastered
            ? Border.all(color: const Color(0xFFF9A825), width: 1.5)
            : null,
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
            clipBehavior: Clip.none,
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
              if (isMastered)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9A825),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🥋', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
            ],
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
          const SizedBox(height: 4),
          if (isMastered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 8)),
                  const SizedBox(width: 2),
                  Text(
                    'Mastered',
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF9A825),
                    ),
                  ),
                ],
              ),
            )
          else ...[
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
// Grouped Attempts Section (My Attempts — grouped by topic)
// ─────────────────────────────────────────────────────────────────────────────

class _TopicAttemptGroup {
  final String topicId;
  final String topicName;
  final List<QuizAttempt> attempts;
  final List<QuizUserAnswer> incorrectAnswers;

  _TopicAttemptGroup({
    required this.topicId,
    required this.topicName,
    required this.attempts,
    required this.incorrectAnswers,
  });

  int get totalAttempts => attempts.length;

  double get bestScore {
    if (attempts.isEmpty) return 0;
    return attempts
        .map(
          (a) => a.totalQuestions > 0
              ? a.correctAnswers / a.totalQuestions * 100
              : 0.0,
        )
        .reduce(max);
  }

  DateTime get lastTried =>
      attempts.map((a) => a.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

  int get incorrectCount =>
      incorrectAnswers.map((a) => a.questionId).toSet().length;
}

class _GroupedAttemptsSection extends StatefulWidget {
  final List<QuizAttempt> attempts;
  final List<QuizUserAnswer> userAnswers;

  const _GroupedAttemptsSection({
    required this.attempts,
    required this.userAnswers,
  });

  @override
  State<_GroupedAttemptsSection> createState() =>
      _GroupedAttemptsSectionState();
}

class _GroupedAttemptsSectionState extends State<_GroupedAttemptsSection> {
  Set<String> _selectedTopicIds = {};
  bool _customPracticeMode = false;

  List<_TopicAttemptGroup> get _groups {
    final Map<String, List<QuizAttempt>> byTopic = {};
    for (final attempt in widget.attempts) {
      byTopic.putIfAbsent(attempt.topicId, () => []).add(attempt);
    }

    final attemptIds = widget.attempts.map((a) => a.id).toSet();
    final Map<String, List<QuizUserAnswer>> incorrectByTopic = {};
    for (final answer in widget.userAnswers) {
      if (!answer.isCorrect && attemptIds.contains(answer.attemptId)) {
        final attempt = widget.attempts.firstWhere(
          (a) => a.id == answer.attemptId,
          orElse: () => widget.attempts.first,
        );
        incorrectByTopic.putIfAbsent(attempt.topicId, () => []).add(answer);
      }
    }

    return byTopic.entries.map((e) {
      final topicAttempts = e.value
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final topicName = topicAttempts.first.topicName;
      final incorrect = incorrectByTopic[e.key] ?? [];
      return _TopicAttemptGroup(
        topicId: e.key,
        topicName: topicName,
        attempts: topicAttempts,
        incorrectAnswers: incorrect,
      );
    }).toList()..sort((a, b) => b.lastTried.compareTo(a.lastTried));
  }

  void _startRedoSession(BuildContext context, _TopicAttemptGroup group) {
    final uniqueIncorrectIds = group.incorrectAnswers
        .map((a) => a.questionId)
        .toSet()
        .toList();

    if (uniqueIncorrectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No incorrect questions to redo for ${group.topicName}!',
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }

    final overrideQuestions = uniqueIncorrectIds
        .map((id) => {'id': id, 'topicId': group.topicId})
        .toList();

    context.push(
      AppRoutes.quizScreen,
      extra: {
        'topicId': group.topicId,
        'topicName': '${group.topicName} (Redo)',
        'questionCount': overrideQuestions.length,
        'overrideQuestions': overrideQuestions,
      },
    );
  }

  void _startCustomPractice(BuildContext context) {
    final selectedGroups = _groups
        .where((g) => _selectedTopicIds.contains(g.topicId))
        .toList();
    final allIncorrectIds = <String>{};
    final allOverride = <Map<String, dynamic>>[];

    for (final group in selectedGroups) {
      for (final answer in group.incorrectAnswers) {
        if (!allIncorrectIds.contains(answer.questionId)) {
          allIncorrectIds.add(answer.questionId);
          allOverride.add({'id': answer.questionId, 'topicId': group.topicId});
        }
      }
    }

    if (allOverride.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No incorrect questions found in selected topics.',
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }

    final topicNames = selectedGroups.map((g) => g.topicName).join(', ');
    context.push(
      AppRoutes.quizScreen,
      extra: {
        'topicId': 'custom_practice',
        'topicName': 'Custom Practice',
        'questionCount': allOverride.length,
        'overrideQuestions': allOverride,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attempts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
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
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 36,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                'No attempts yet',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete a quiz to see your history here',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _groups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Practice Mode toggle
        Row(
          children: [
            Expanded(
              child: Text(
                _customPracticeMode
                    ? 'Select topics to mix incorrect questions'
                    : 'Grouped by topic • Tap to expand',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _customPracticeMode = !_customPracticeMode;
                if (!_customPracticeMode) _selectedTopicIds.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _customPracticeMode
                      ? AppTheme.primary
                      : AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _customPracticeMode
                          ? Icons.close_rounded
                          : Icons.playlist_add_rounded,
                      size: 14,
                      color: _customPracticeMode
                          ? Colors.white
                          : AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _customPracticeMode ? 'Cancel' : 'Custom Practice',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _customPracticeMode
                            ? Colors.white
                            : AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Topic cards
        ...groups.map(
          (group) => _TopicAttemptCard(
            group: group,
            isCustomPracticeMode: _customPracticeMode,
            isSelected: _selectedTopicIds.contains(group.topicId),
            onToggleSelect: () {
              setState(() {
                if (_selectedTopicIds.contains(group.topicId)) {
                  _selectedTopicIds.remove(group.topicId);
                } else {
                  _selectedTopicIds.add(group.topicId);
                }
              });
            },
            onRedo: () => _startRedoSession(context, group),
          ),
        ),

        // Start Custom Practice button
        if (_customPracticeMode && _selectedTopicIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startCustomPractice(context),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                'Start Custom Practice (${_selectedTopicIds.length} topic${_selectedTopicIds.length > 1 ? 's' : ''})',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topic Attempt Card (expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _TopicAttemptCard extends StatefulWidget {
  final _TopicAttemptGroup group;
  final bool isCustomPracticeMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onRedo;

  const _TopicAttemptCard({
    required this.group,
    required this.isCustomPracticeMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onRedo,
  });

  @override
  State<_TopicAttemptCard> createState() => _TopicAttemptCardState();
}

class _TopicAttemptCardState extends State<_TopicAttemptCard> {
  bool _expanded = false;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final bestScore = group.bestScore;
    final scoreColor = bestScore >= 70
        ? const Color(0xFF2E7D32)
        : bestScore >= 50
        ? const Color(0xFFE65100)
        : const Color(0xFFC62828);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: widget.isSelected
            ? Border.all(color: AppTheme.primary, width: 2)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            onTap: widget.isCustomPracticeMode
                ? widget.onToggleSelect
                : () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Checkbox in custom practice mode
                  if (widget.isCustomPracticeMode) ...[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.isSelected
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: widget.isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                  ],
                  // Topic icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Topic info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.topicName,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${group.totalAttempts} attempt${group.totalAttempts > 1 ? 's' : ''}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(group.lastTried),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Score + expand
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${bestScore.toStringAsFixed(0)}%',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'best score',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isCustomPracticeMode) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded && !widget.isCustomPracticeMode) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _AttemptStatChip(
                        icon: Icons.repeat_rounded,
                        label: '${group.totalAttempts} attempts',
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _AttemptStatChip(
                        icon: Icons.close_rounded,
                        label: '${group.incorrectCount} incorrect',
                        color: const Color(0xFFC62828),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Incorrect questions section
                  if (group.incorrectCount > 0) ...[
                    Text(
                      'Incorrect Questions',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...group.incorrectAnswers
                        .map((a) => a.questionId)
                        .toSet()
                        .take(5)
                        .map(
                          (qId) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC62828),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Question ID: $qId',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (group.incorrectCount > 5)
                      Text(
                        '+${group.incorrectCount - 5} more incorrect questions',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'All questions answered correctly!',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Redo button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onRedo,
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text(
                        group.incorrectCount > 0
                            ? 'Redo ${group.incorrectCount} Failed Question${group.incorrectCount > 1 ? 's' : ''}'
                            : 'Practice Again',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttemptStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AttemptStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}