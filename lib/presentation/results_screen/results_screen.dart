import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/results_action_buttons_widget.dart';
import './widgets/results_header_widget.dart';
import './widgets/results_metrics_row_widget.dart';
import './widgets/results_score_gauge_widget.dart';

class ResultsScreen extends StatefulWidget {
  final String topicName;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeTakenSeconds;
  final String topicId;
  final int maxStreak;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> overrideQuestions;

  const ResultsScreen({
    super.key,
    required this.topicName,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeTakenSeconds,
    required this.topicId,
    this.maxStreak = 0,
    this.questions = const [],
    this.overrideQuestions = const [],
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  late AnimationController _entranceController;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  double get _accuracyPercent => widget.totalQuestions == 0
      ? 0
      : (widget.correctAnswers / widget.totalQuestions) * 100;

  String get _formattedTime {
    final m = widget.timeTakenSeconds ~/ 60;
    final s = widget.timeTakenSeconds % 60;
    return '${m}M : ${s.toString().padLeft(2, '0')}S';
  }

  String get _performanceMessage {
    if (_accuracyPercent >= 90) return '🏆 Outstanding! Interview-ready!';
    if (_accuracyPercent >= 75) return '🎯 Great work! Keep sharpening!';
    if (_accuracyPercent >= 60) return '📈 Good progress! Review weak areas.';
    if (_accuracyPercent >= 40) return '💪 Keep practicing! You\'ll get there.';
    return '📚 More practice needed. Review the concepts.';
  }

  Color get _performanceColor {
    if (_accuracyPercent >= 75) return AppTheme.success;
    if (_accuracyPercent >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  Future<void> _shareResults() async {
    final accuracy = _accuracyPercent.toStringAsFixed(0);
    final text =
        'I scored ${widget.correctAnswers}/${widget.totalQuestions} ($accuracy%) '
        'on the ${widget.topicName} quiz in DE Interview Prep. '
        'Time: $_formattedTime.';

    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: 'DE Interview Prep Quiz Result',
          subject: 'My ${widget.topicName} quiz result',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sharing is not available on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_fadeAnim);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _entranceController.forward();
        _scoreController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.go(AppRoutes.topicsListScreen),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      title: Text(
        'Quiz Results',
        style: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        if (widget.maxStreak > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 3),
                Text(
                  'Best: ${widget.maxStreak}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          onPressed: _shareResults,
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          tooltip: 'Share Results',
        ),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              ResultsHeaderWidget(
                topicName: widget.topicName,
                performanceMessage: _performanceMessage,
                performanceColor: _performanceColor,
              ),
              const SizedBox(height: 16),
              ResultsScoreGaugeWidget(
                label: 'You Scored',
                value: '${widget.correctAnswers} / ${widget.totalQuestions}',
                percent: _accuracyPercent / 100,
                animation: _scoreAnim,
                color: _performanceColor,
                isMain: true,
              ),
              const SizedBox(height: 12),
              ResultsMetricsRowWidget(
                correctAnswers: widget.correctAnswers,
                totalQuestions: widget.totalQuestions,
                timeTaken: _formattedTime,
                accuracyPercent: _accuracyPercent,
              ),
              const SizedBox(height: 12),
              _buildStreakCard(),
              const SizedBox(height: 16),
              _buildFailedQuestionsReview(),
              const SizedBox(height: 16),
              _buildUnlockQuestionsButton(),
              const SizedBox(height: 20),
              ResultsActionButtonsWidget(
                onRetry: _retakeQuiz,
                onBackToTopics: () => context.go(AppRoutes.topicsListScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                ResultsHeaderWidget(
                  topicName: widget.topicName,
                  performanceMessage: _performanceMessage,
                  performanceColor: _performanceColor,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ResultsScoreGaugeWidget(
                        label: 'You Scored',
                        value:
                            '${widget.correctAnswers} / ${widget.totalQuestions}',
                        percent: _accuracyPercent / 100,
                        animation: _scoreAnim,
                        color: _performanceColor,
                        isMain: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ResultsMetricsRowWidget(
                  correctAnswers: widget.correctAnswers,
                  totalQuestions: widget.totalQuestions,
                  timeTaken: _formattedTime,
                  accuracyPercent: _accuracyPercent,
                ),
                const SizedBox(height: 12),
                _buildStreakCard(),
                const SizedBox(height: 16),
                _buildFailedQuestionsReview(),
                const SizedBox(height: 16),
                _buildUnlockQuestionsButton(),
                const SizedBox(height: 20),
                ResultsActionButtonsWidget(
                  onRetry: _retakeQuiz,
                  onBackToTopics: () => context.go(AppRoutes.topicsListScreen),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _retakeQuiz() {
    final retryQuestions = widget.overrideQuestions.isNotEmpty
        ? widget.overrideQuestions
        : null;

    context.pushReplacement(
      AppRoutes.quizScreen,
      extra: {
        'topicId': widget.topicId,
        'topicName': widget.topicName,
        'questionCount': retryQuestions?.length ?? widget.totalQuestions,
        if (retryQuestions != null) 'overrideQuestions': retryQuestions,
      },
    );
  }

  Widget _buildFailedQuestionsReview() {
    final failed = <Map<String, dynamic>>[];
    for (final q in widget.questions) {
      final selected = q['selectedAnswer'];
      final correctIndex = q['correctIndex'] as int? ?? 0;
      final hasFailed = selected == null || selected != correctIndex;
      if (hasFailed) {
        failed.add(q);
      }
    }

    if (failed.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showFailedQuestionsSheet(failed),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFCB3A3A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Review ${failed.length} Failed Questions',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  void _showFailedQuestionsSheet(List<Map<String, dynamic>> failedQuestions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FailedQuestionsBottomSheet(
        topicName: widget.topicName,
        failedQuestions: failedQuestions,
        topicId: widget.topicId,
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Max Streak',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.maxStreak > 0
                      ? '${widget.maxStreak} consecutive correct answer${widget.maxStreak == 1 ? '' : 's'}'
                      : 'No streak this round — keep going!',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.maxStreak}',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockQuestionsButton() {
    return GestureDetector(
      onTap: () => _showQuestionsListSheet(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.list_alt_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse All Questions',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  Text(
                    'Review & choose specific questions to practice',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionsListSheet() {
    if (widget.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No questions available.',
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionsListSheet(
        topicName: widget.topicName,
        questions: widget.questions,
        topicId: widget.topicId,
      ),
    );
  }
}

class _FailedQuestionsBottomSheet extends StatefulWidget {
  final String topicName;
  final List<Map<String, dynamic>> failedQuestions;
  final String topicId;

  const _FailedQuestionsBottomSheet({
    required this.topicName,
    required this.failedQuestions,
    required this.topicId,
  });

  @override
  State<_FailedQuestionsBottomSheet> createState() => _FailedQuestionsBottomSheetState();
}

class _FailedQuestionsBottomSheetState extends State<_FailedQuestionsBottomSheet> {
  final Set<int> _selectedIndices = {};
  final Set<int> _expandedIndices = {};

  List<Map<String, dynamic>> get _selectedQuestions => _selectedIndices
      .map((index) => widget.failedQuestions[index])
      .toList();

  void _toggleSelected(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  void _retakeQuestions() {
    final questions = _selectedIndices.isEmpty
        ? widget.failedQuestions
        : _selectedQuestions;

    Navigator.of(context).pop();

    context.pushReplacement(
      AppRoutes.quizScreen,
      extra: {
        'topicId': widget.topicId,
        'topicName': widget.topicName,
        'questionCount': questions.length,
        'overrideQuestions': questions,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIndices.isNotEmpty;
    final buttonLabel = hasSelection
        ? 'Retake Selected (${_selectedIndices.length})'
        : 'Retake All Questions';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.52,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFCB3A3A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.topicName,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${widget.failedQuestions.length} questions failed',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.failedQuestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final q = widget.failedQuestions[index];
                      final questionText = q['text'] as String? ?? 'Question';
                      final options = (q['options'] as List<dynamic>? ?? const [])
                          .map((e) => e.toString())
                          .toList();
                      final selected = q['selectedAnswer'];
                      final selectedText = selected is int
                          ? (selected >= 0 && selected < options.length
                              ? options[selected]
                              : 'No answer selected')
                          : 'No answer selected';
                      final correctIndex = q['correctIndex'] as int? ?? 0;
                      final correctAnswerText = options.isNotEmpty && correctIndex < options.length
                          ? options[correctIndex]
                          : 'N/A';
                      final explanation = q['explanation'] as String? ?? '';
                      final isExpanded = _expandedIndices.contains(index);
                      final isSelected = _selectedIndices.contains(index);
                      final difficulty = (q['difficulty'] as String? ?? q['level'] as String? ?? 'JUNIOR').toUpperCase();

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3CFCF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 14, 0, 0),
                              child: GestureDetector(
                                onTap: () => _toggleSelected(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFCB3A3A) : Colors.white,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFCB3A3A) : const Color(0xFFDBDBDB),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  iconColor: const Color(0xFF303030),
                                  collapsedIconColor: const Color(0xFF303030),
                                  onExpansionChanged: (expanded) {
                                    if (expanded) {
                                      _toggleExpanded(index);
                                    } else {
                                      _expandedIndices.remove(index);
                                    }
                                  },
                                  initiallyExpanded: isExpanded,
                                  title: Row(
                                    children: [
                                      Text(
                                        'Q${index + 1}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE1E1),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          difficulty,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFB42318),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Text(
                                      questionText,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your answer: $selectedText',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: const Color(0xFFB71C1C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Correct answer: $correctAnswerText',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (explanation.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'Explanation:',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF37474F),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        explanation,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: const Color(0xFF455A64),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE9E9E9))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _retakeQuestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E9D5A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        buttonLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Questions List Bottom Sheet ─────────────────────────────────────────────

class _QuestionsListSheet extends StatefulWidget {
  final String topicName;
  final List<Map<String, dynamic>> questions;
  final String topicId;

  const _QuestionsListSheet({
    required this.topicName,
    required this.questions,
    required this.topicId,
  });

  @override
  State<_QuestionsListSheet> createState() => _QuestionsListSheetState();
}

class _QuestionsListSheetState extends State<_QuestionsListSheet> {
  final Set<int> _selectedIndices = {};
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildSheetHeader(context),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: widget.questions.length,
                  itemBuilder: (_, i) => _buildQuestionTile(i),
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.topicName,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.questions.length} questions unlocked',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTile(int index) {
    final q = widget.questions[index];
    final isSelected = _selectedIndices.contains(index);
    final isExpanded = _expandedIndex == index;
    final difficulty = q['difficulty'] as String? ?? 'medium';
    final diffColor = difficulty == 'easy'
        ? AppTheme.success
        : difficulty == 'hard'
        ? AppTheme.error
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withAlpha(13)
            : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primary : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _expandedIndex = isExpanded ? null : index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedIndices.remove(index);
                        } else {
                          _selectedIndices.add(index);
                        }
                      });
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1, right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Q${index + 1}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: diffColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                difficulty.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: diffColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q['text'] as String? ?? '',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryDark,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryDark,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Answer Options:',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...(q['options'] as List<dynamic>? ?? []).asMap().entries.map(
                    (e) {
                      final isCorrect =
                          e.key == (q['correctIndex'] as int? ?? 0);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppTheme.success.withAlpha(26)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCorrect
                                ? AppTheme.success.withAlpha(77)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isCorrect)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.success,
                                size: 14,
                              )
                            else
                              const Icon(
                                Icons.radio_button_unchecked_rounded,
                                color: Colors.grey,
                                size: 14,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: isCorrect
                                      ? AppTheme.success
                                      : AppTheme.primaryDark,
                                  fontWeight: isCorrect
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.blue.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            q['proTip'] as String? ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBottomBar(BuildContext context) {
    final count = _selectedIndices.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (count > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    AppRoutes.quizScreen,
                    extra: {
                      'topicId': widget.topicId,
                      'topicName': widget.topicName,
                      'questionCount': count,
                    },
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  'Practice $count Selected',
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
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    AppRoutes.quizScreen,
                    extra: {
                      'topicId': widget.topicId,
                      'topicName': widget.topicName,
                      'questionCount': widget.questions.length,
                    },
                  );
                },
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(
                  'Retake All Questions',
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
          if (count > 0) ...[
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => setState(() => _selectedIndices.clear()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Clear',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
