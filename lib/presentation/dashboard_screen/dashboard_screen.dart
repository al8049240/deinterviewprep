import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/pro_service.dart';
import '../../theme/app_theme.dart';
import '../../models/flashcard_model.dart';
import '../../providers/bookmark_provider.dart';
import '../paywall_screen/paywall_screen.dart';
import '../question_bank_screen/question_bank_screen.dart';
import '../developer_experiences_screen/developer_experiences_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProService _proService = ProService();
  bool _isSeriousMode = false;

  @override
  void initState() {
    super.initState();
    _proService.addListener(_onProChanged);
    _proService.init();
  }

  @override
  void dispose() {
    _proService.removeListener(_onProChanged);
    super.dispose();
  }

  void _onProChanged() {
    if (mounted) setState(() {});
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallScreen(),
    );
  }

  void _navigateToSavedQuestions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QuestionBankScreen(showBookmarkedOnly: true),
      ),
    );
  }

  void _showUnlockSeriousModeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnlockSeriousModeSheet(
        onUnlock: () {
          Navigator.pop(context);
          setState(() => _isSeriousMode = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mastered = _proService.cardsMastered;
    final isPro = _proService.isProUnlocked;
    final bookmarkProvider = context.watch<BookmarkProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DE Interview Prep',
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                if (_isSeriousMode) ...[
                                  // Serious Mode: show single gold badge only
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9A825),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '🗿 Serious Mode',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Chill Mode: show ☕ pill + ⚡ Upgrade button
                                  GestureDetector(
                                    onTap: _showUnlockSeriousModeSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(30),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(80),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '☕ Chill Mode',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _showUnlockSeriousModeSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9A825),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '⚡ Upgrade',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                // Profile icon removed — accessible via bottom nav Profile tab
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatBadge(
                              icon: '🔥',
                              label: '$mastered Mastered',
                              color: AppTheme.primaryContainer,
                              textColor: AppTheme.primaryDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upgrade Banner
                  if (!isPro) ...[
                    _UpgradeBanner(onTap: _showPaywall),
                    const SizedBox(height: 20),
                  ],

                  // Performance Graph - removed, moved to Stats Hub
                  // ── Quick Actions ───────────────────────────────────────────
                  Text(
                    '🛠️ Preparation Tools',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionCard(
                    icon: Icons.style_rounded,
                    title: 'Continue Flashcards',
                    subtitle: '$sampleFlashcardsCount cards available',
                    color: AppTheme.primary,
                    onTap: () => context.push(AppRoutes.flashcardsScreen),
                  ),
                  const SizedBox(height: 10),
                  _QuickActionCard(
                    icon: Icons.quiz_rounded,
                    title: 'Real Case Scenario',
                    subtitle: 'Real-world data engineering cases',
                    color: AppTheme.secondary,
                    onTap: () => context.push(AppRoutes.questionBankScreen),
                  ),
                  const SizedBox(height: 10),
                  _QuickActionCard(
                    icon: Icons.code_rounded,
                    title: 'Code Playground',
                    subtitle: isPro
                        ? 'SQL & Python practice'
                        : 'Serious Mode feature — unlock to access',
                    color: isPro ? const Color(0xFF1565C0) : Colors.grey,
                    onTap: isPro
                        ? () => context.push(AppRoutes.codePlaygroundScreen)
                        : _showPaywall,
                  ),
                  const SizedBox(height: 10),
                  _QuickActionCard(
                    icon: Icons.list_alt_rounded,
                    title: 'Explore Topics',
                    subtitle: 'All quiz topics',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => context.go(AppRoutes.topicsListScreen),
                  ),
                  const SizedBox(height: 24),

                  // Free tier info
                  if (!isPro) ...[
                    Text(
                      'Chill Mode Includes',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FreeTierCard(),
                    const SizedBox(height: 20),
                  ],

                  // ── Developer's Real Experiences Banner ─────────────────────
                  _DevExperiencesBannerCard(
                    isSeriousMode: _isSeriousMode,
                    onUnlockTap: _showUnlockSeriousModeSheet,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const int sampleFlashcardsCount = 10;

// ── Unlock Serious Mode Bottom Sheet ─────────────────────────────────────────

class _UnlockSeriousModeSheet extends StatelessWidget {
  final VoidCallback onUnlock;

  const _UnlockSeriousModeSheet({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF37474F).withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('🗿', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock Serious Mode 🗿',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Access unfiltered production war stories, high-stakes trade-offs, and real engineering failures.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Feature comparison table
          _UpgradeComparisonTable(),
          const SizedBox(height: 24),
          // CTA button — orange/gold gradient
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFFB300)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C00).withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onUnlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '\$19.99 — One-time payment • Lifetime access',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Stay in Chill Mode',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeComparisonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Feature', 'Chill', 'Serious'],
      ['Core Flashcards', '10', '150+'],
      ['Interview Questions', '2 free', '150+'],
      ["Developer's Real Experiences 🗿", '✗', '✓'],
      ['Code Playground', '✗', '✓'],
      ['SQL/Python Practice', '✗', '✓'],
      ['Cheatsheets & Guides', '✗', '✓'],
      ['Offline Mode', '✗', '✓'],
      ['All Difficulty Levels', '✗', '✓'],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final isHeader = i == 0;
          return Container(
            decoration: BoxDecoration(
              color: isHeader
                  ? const Color(0xFFFFF8E1)
                  : i.isEven
                  ? Colors.grey.shade50
                  : Colors.white,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : i == rows.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : null,
              border: i > 0
                  ? Border(top: BorderSide(color: Colors.grey.shade100))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    row[0],
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                      color: isHeader
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
                // Chill column header with ☕ icon
                Expanded(
                  child: Center(
                    child: isHeader
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('☕', style: TextStyle(fontSize: 14)),
                              Text(
                                row[1],
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF546E7A),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            row[1],
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                  ),
                ),
                // Serious column header with 🗿 icon
                Expanded(
                  child: Center(
                    child: isHeader
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🗿', style: TextStyle(fontSize: 14)),
                              Text(
                                row[2],
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF8C00),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            row[2],
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: row[2] == '✓'
                                  ? const Color(0xFF2E7D32)
                                  : row[2] == '✗'
                                  ? Colors.red.shade400
                                  : const Color(0xFFFF8C00),
                            ),
                          ),
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

// ── Developer's Real Experiences Banner Card ──────────────────────────────────

class _DevExperiencesBannerCard extends StatelessWidget {
  final bool isSeriousMode;
  final VoidCallback onUnlockTap;

  const _DevExperiencesBannerCard({
    required this.isSeriousMode,
    required this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!isSeriousMode) {
            onUnlockTap();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DeveloperExperiencesListScreen(),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF37474F).withAlpha(22),
                const Color(0xFF546E7A).withAlpha(14),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF37474F).withAlpha(70)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: emoji icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF37474F).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🗿', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              // Center: header + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Developer's Real Experiences 🗿",
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unfiltered production war stories & high-stakes trade-offs...',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF546E7A),
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isSeriousMode) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF37474F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🔒 Serious Mode Only',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right: chevron
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF546E7A),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Minimal Question Detail Page (opened from saved card) ─────────────────────

class _QuestionDetailPage extends StatelessWidget {
  final InterviewQuestionModel question;
  const _QuestionDetailPage({required this.question});

  Color get _difficultyColor {
    switch (question.difficulty) {
      case 'Junior':
        return Colors.green;
      case 'Mid':
        return Colors.blue;
      case 'Senior':
        return Colors.orange;
      case 'Lead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final isBookmarked = bookmarkProvider.isQuestionBookmarked(question.id);
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Text(
              'Question Detail',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.difficulty,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _difficultyColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.category,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  question.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Problem Statement',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: const Color(0xFF444444),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Solution Breakdown',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryContainer),
                  ),
                  child: Text(
                    question.answer,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      color: const Color(0xFF1A1A1A),
                      height: 1.6,
                    ),
                  ),
                ),
                if (question.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: question.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        'Back to Questions',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? const Color(0xFF2E7D32).withAlpha(15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isBookmarked
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        final added = bookmarkProvider.toggleQuestion(
                          question.id,
                        );
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Question saved to Bookmarks'
                                  : 'Removed from Bookmarks',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: added
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade500,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final Color textColor;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$icon $label',
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9A825), Color(0xFFF57F17)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Serious Mode — \$19.99',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'One-time unlock. No subscriptions.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreeTierCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      '10 Core Data Engineering Flashcards',
      'SQL basics, ETL vs ELT, ACID compliance',
      'Daily Streak & Habit Tracker',
      '5 System Design Walkthroughs',
      'Quiz topics with explanations & Pro Tips',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(80)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.primaryDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
