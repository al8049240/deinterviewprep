import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/bookmark_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/performance_service.dart';
import '../../services/quiz_service.dart';
import '../../services/statistics_repository.dart';
import '../../theme/app_theme.dart';
import './widgets/quiz_explanation_widget.dart';
import './widgets/quiz_navigation_buttons_widget.dart';
import './widgets/quiz_option_widget.dart';
import './widgets/quiz_progress_bar_widget.dart';
import './widgets/quiz_question_widget.dart';
import './widgets/quiz_stats_row_widget.dart';
import './widgets/quiz_timer_row_widget.dart';

class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final List<int> correctIndices;
  final String explanation;
  final String difficulty;
  final String proTip;
  final String interviewTip;
  final String hint;
  final String interviewNote;
  final String category;
  final String type;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.correctIndices = const [],
    required this.explanation,
    required this.difficulty,
    required this.proTip,
    required this.interviewTip,
    this.hint = '',
    this.interviewNote = '',
    required this.category,
    this.type = 'mcq',
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as String,
      text: map['text'] as String,
      options: List<String>.from(map['options'] as List),
      correctIndex: map['correctIndex'] as int,
      correctIndices: map['correctIndices'] != null
          ? List<int>.from(map['correctIndices'] as List)
          : [],
      explanation: map['explanation'] as String,
      difficulty: map['difficulty'] as String,
      proTip: map['proTip'] as String,
      interviewTip: map['interviewTip']?.toString() ?? '',
      hint: map['hint']?.toString() ?? '',
      interviewNote: map['interviewNote']?.toString() ?? '',
      category: map['category'] as String,
      type: map['type']?.toString() ?? 'mcq',
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final int questionCount;
  final List<Map<String, dynamic>>? overrideQuestions;
  final String? subtag;
  final int? subtopicId;
  final Set<String>? questionIds;

  const QuizScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.questionCount,
    this.overrideQuestions,
    this.subtag,
    this.subtopicId,
    this.questionIds,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  // For mcma: track multiple selected indices per question
  final Map<int, Set<int>> _selectedMultiAnswers = {};
  // For mcq: track pending (unsubmitted) selection per question
  final Map<int, int> _pendingMcqAnswers = {};
  // Track which questions have had hint revealed
  final Set<int> _hintRevealed = {};
  late Timer _timer;
  int _totalSeconds = 0;
  late AnimationController _optionAnimController;
  late AnimationController _explanationAnimController;
  late Animation<double> _explanationAnim;
  int _currentStreak = 0;
  int _maxStreak = 0;
  // Guard against double-tap on submit/action buttons
  bool _isSubmitting = false;

  // Dynamic loading state
  bool _isLoading = true;
  String? _errorMessage;
  List<QuestionModel> _questions = [];
  List<Map<String, dynamic>> _filteredMaps = [];

  // Real-time subscription cleanup
  void Function()? _unsubscribeRealtime;

  @override
  void initState() {
    super.initState();

    _optionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _explanationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _explanationAnim = CurvedAnimation(
      parent: _explanationAnimController,
      curve: Curves.easeOutCubic,
    );

    _loadQuestions();
    _setupRealtimeSubscription();
  }

  /// Subscribe to real-time changes on quiz-question and quiz-answer tables.
  /// Only subscribes when loading from Supabase (not override mode).
  Future<void> _setupRealtimeSubscription() async {
    // Skip real-time for override/static question sets
    if (widget.overrideQuestions != null) return;

    final numericTopicId = int.tryParse(widget.topicId);
    final topicId = numericTopicId ?? 0;

    final cleanup = await QuizService.instance.subscribeToTopicChanges(
      topicId: topicId,
      onDataChanged: () {
        // Only reload if quiz hasn't started (still on loading/pre-quiz state)
        // or if no answers have been selected yet to avoid disrupting active quiz
        if (mounted && _selectedAnswers.isEmpty && !_isLoading) {
          _loadQuestions();
        }
      },
    );

    if (mounted) {
      _unsubscribeRealtime = cleanup;
    } else {
      cleanup();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> maps;

      if (widget.overrideQuestions != null) {
        maps = widget.overrideQuestions!;
      } else if (widget.subtopicId != null) {
        // Relational fetch by subtopic integer FK
        final supabaseQuestions = await QuizService.instance
            .fetchQuestionsBySubtopicId(widget.subtopicId!);
        maps = supabaseQuestions.map((q) => q.toLegacyMap()).toList();
      } else if (widget.subtag != null && widget.subtag!.isNotEmpty) {
        final supabaseQuestions = await QuizService.instance
            .fetchQuestionsBySubtag(widget.subtag!);
        maps = supabaseQuestions.map((q) => q.toLegacyMap()).toList();
      } else {
        final supabaseQuestions = await QuizService.instance
            .fetchQuestionsByTopic(widget.topicId);
        maps = supabaseQuestions.map((q) => q.toLegacyMap()).toList();
      }

      if (!mounted) return;

      if (widget.questionIds != null) {
        maps = maps
            .where((map) => widget.questionIds!.contains(map['id']?.toString()))
            .toList();
      }
      final count = widget.questionCount.clamp(0, maps.length);
      final questions = maps.take(count).map(QuestionModel.fromMap).toList();

      setState(() {
        _filteredMaps = maps;
        _questions = questions;
        _isLoading = false;
      });

      // Show warning if insufficient questions (skip for override mode)
      if (widget.overrideQuestions == null &&
          widget.questionIds == null &&
          questions.length < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showInsufficientQuestionsDialog(questions.length);
        });
      }

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showInsufficientQuestionsDialog(int count) {
    if (count == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'No Questions Found',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'There are no questions available for "${widget.topicName}" yet. Please choose a different topic.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF555555),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Limited Questions',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Only $count question${count == 1 ? '' : 's'} found for "${widget.topicName}". A minimum of 5 is recommended for a full quiz session.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF555555),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: Text(
                'Choose Another Topic',
                style: GoogleFonts.dmSans(color: const Color(0xFF757575)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue Anyway',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _totalSeconds++);
    });
  }

  @override
  void dispose() {
    _unsubscribeRealtime?.call();
    if (!_isLoading && _errorMessage == null) {
      _timer.cancel();
    }
    _optionAnimController.dispose();
    _explanationAnimController.dispose();
    super.dispose();
  }

  QuestionModel get _currentQuestion => _questions[_currentIndex];
  bool get _hasAnswered =>
      _selectedAnswers.containsKey(_currentIndex) ||
      (_selectedMultiAnswers[_currentIndex]?.isNotEmpty == true &&
          _isMcmaSubmitted(_currentIndex));
  int get _answeredCount {
    final answeredIndexes = <int>{..._selectedAnswers.keys};
    answeredIndexes.addAll(_pendingMcqAnswers.keys);
    for (final entry in _selectedMultiAnswers.entries) {
      if (entry.value.isNotEmpty) answeredIndexes.add(entry.key);
    }
    return answeredIndexes.length;
  }

  int get _mcmaSubmittedCount {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i].type == 'mcma' && _isMcmaSubmitted(i)) count++;
    }
    return count;
  }

  bool _isMcmaSubmitted(int questionIndex) {
    return _selectedAnswers.containsKey(questionIndex);
  }

  bool _isMcmaType(QuestionModel q) => q.type == 'mcma';

  void _selectAnswer(int optionIndex) {
    if (_hasAnswered) return;
    final q = _currentQuestion;

    if (_isMcmaType(q)) {
      // Multi-select: toggle selection (don't submit yet)
      setState(() {
        final current = _selectedMultiAnswers[_currentIndex] ?? <int>{};
        if (current.contains(optionIndex)) {
          current.remove(optionIndex);
        } else {
          current.add(optionIndex);
        }
        _selectedMultiAnswers[_currentIndex] = current;
      });
    } else {
      // Keep the choice pending until the user explicitly submits it. Pending
      // choices are still graded when the quiz is finished.
      setState(() {
        _pendingMcqAnswers[_currentIndex] = optionIndex;
      });
    }
  }

  void _submitMcqAnswer() {
    if (_isSubmitting) return;
    final q = _currentQuestion;
    if (_isMcmaType(q)) return;
    final pending = _pendingMcqAnswers[_currentIndex];
    if (pending == null) return;

    _isSubmitting = true;
    final isCorrect = pending == q.correctIndex;
    setState(() {
      _selectedAnswers[_currentIndex] = pending;
      if (isCorrect) {
        _currentStreak++;
        if (_currentStreak > _maxStreak) _maxStreak = _currentStreak;
      } else {
        _currentStreak = 0;
      }
    });
    _explanationAnimController.forward();
    Future.microtask(() => _isSubmitting = false);
  }

  void _submitMcmaAnswer() {
    if (_isSubmitting) return;
    final q = _currentQuestion;
    if (!_isMcmaType(q)) return;
    final selected = _selectedMultiAnswers[_currentIndex] ?? <int>{};
    if (selected.isEmpty) return;

    _isSubmitting = true;
    final correctSet = q.correctIndices.isNotEmpty
        ? q.correctIndices.toSet()
        : {q.correctIndex};
    final isCorrect =
        selected.length == correctSet.length &&
        selected.every((i) => correctSet.contains(i));

    setState(() {
      _selectedAnswers[_currentIndex] = isCorrect ? q.correctIndex : -1;
      if (isCorrect) {
        _currentStreak++;
        if (_currentStreak > _maxStreak) _maxStreak = _currentStreak;
      } else {
        _currentStreak = 0;
      }
    });
    _explanationAnimController.forward();
    Future.microtask(() => _isSubmitting = false);
  }

  void _toggleBookmark() {
    final q = _currentQuestion;
    final provider = context.read<BookmarkProvider>();
    final isCurrentlyBookmarked = provider.isQuizBookmarked(q.id);
    if (isCurrentlyBookmarked) {
      provider.toggleQuiz(q.id);
    } else {
      provider.toggleQuiz(
        q.id,
        data: BookmarkedQuizQuestion(
          id: q.id,
          text: q.text,
          topicId: widget.topicId,
          topicName: widget.topicName,
          category: q.category.isNotEmpty ? q.category : widget.topicName,
          difficulty: q.difficulty,
        ),
      );
    }
  }

  void _goNext() {
    if (_questions.isEmpty) return;
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _explanationAnimController.reset();
        if (_hasAnswered) _explanationAnimController.forward();
      });
    } else {
      _finishQuiz();
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _explanationAnimController.reset();
        if (_hasAnswered) _explanationAnimController.forward();
      });
    }
  }

  void _finishQuiz() {
    // Grade every selected-but-unsubmitted answer without revealing an
    // explanation. This preserves the Submit Answer interaction while still
    // counting choices when the user finishes the quiz directly.
    for (int index = 0; index < _questions.length; index++) {
      if (_selectedAnswers.containsKey(index)) continue;
      final question = _questions[index];
      if (_isMcmaType(question)) {
        final selected = _selectedMultiAnswers[index] ?? const <int>{};
        if (selected.isEmpty) continue;
        final correctSet = question.correctIndices.isNotEmpty
            ? question.correctIndices.toSet()
            : {question.correctIndex};
        final isCorrect =
            selected.length == correctSet.length &&
            selected.every(correctSet.contains);
        _selectedAnswers[index] = isCorrect ? question.correctIndex : -1;
      } else {
        final pending = _pendingMcqAnswers[index];
        if (pending != null) _selectedAnswers[index] = pending;
      }
    }
    _timer.cancel();
    int correct = 0;
    _selectedAnswers.forEach((qIdx, ansIdx) {
      final q = _questions[qIdx];
      if (_isMcmaType(q)) {
        if (ansIdx != -1) {
          correct++;
        }
      } else {
        if (ansIdx == q.correctIndex) correct++;
      }
    });

    PerformanceService().saveSession(
      topicId: widget.topicId,
      topicName: widget.topicName,
      totalQuestions: _questions.length,
      correctAnswers: correct,
      durationSeconds: _totalSeconds,
    );

    final sourceQuestions = (widget.overrideQuestions != null && widget.overrideQuestions!.isNotEmpty)
        ? widget.overrideQuestions!
        : _filteredMaps.take(widget.questionCount).toList();

    final questionsWithAnswers = sourceQuestions
        .asMap()
        .entries
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.value);
          final selectedAns = _selectedAnswers[entry.key];
          if (selectedAns != null) {
            map['selectedAnswer'] = selectedAns;
          }
          return map;
        })
        .toList();

    // Save to Supabase statistics (only if quiz was completed with at least 1 answer)
    if (_selectedAnswers.isNotEmpty) {
      StatisticsRepository.instance.saveQuizAttempt(
        topicId: widget.topicId,
        topicName: widget.topicName,
        totalQuestions: _questions.length,
        correctAnswers: correct,
        durationSeconds: _totalSeconds,
        answeredQuestions: questionsWithAnswers,
      ).then((_) {
        if (mounted) context.read<StatisticsProvider>().refresh();
      });
    }

    context.pushReplacement(
      AppRoutes.resultsScreen,
      extra: {
        'topicName': widget.topicName,
        'score': correct * 10,
        'totalQuestions': _questions.length,
        'correctAnswers': correct,
        'timeTakenSeconds': _totalSeconds,
        'topicId': widget.topicId,
        'maxStreak': _maxStreak,
        'questions': questionsWithAnswers,
        'overrideQuestions': sourceQuestions,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    // ── Loading State ──────────────────────────────────────────────────────
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading questions...',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Error State ────────────────────────────────────────────────────────
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 36,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Failed to Load Questions',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loadQuestions,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Empty State ────────────────────────────────────────────────────────
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No questions available for this topic yet.',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: const Color(0xFF555555),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Quiz Content ───────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: isTablet
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _buildBody(theme),
                ),
              )
            : _buildBody(theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        onPressed: () => _isLoading ? context.pop() : _showExitDialog(),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      title: Text(
        widget.topicName,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (!_isLoading && _errorMessage == null && _currentStreak > 0)
          Container(
            margin: const EdgeInsets.only(right: 4),
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
                  '$_currentStreak',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        if (!_isLoading && _errorMessage == null && _questions.isNotEmpty)
          IconButton(
            onPressed: _finishQuiz,
            icon: const Icon(Icons.flag_rounded, color: Colors.white),
            tooltip: 'Finish Quiz',
          ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    return Column(
      children: [
        QuizTimerRowWidget(totalSeconds: _totalSeconds),
        QuizStatsRowWidget(
          totalQuestions: _questions.length,
          totalAnswered: _answeredCount,
        ),
        QuizProgressBarWidget(
          current: _currentIndex + 1,
          total: _questions.length,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuizQuestionWidget(
                  questionNumber: _currentIndex + 1,
                  totalQuestions: _questions.length,
                  questionText: _currentQuestion.text,
                  difficulty: _currentQuestion.difficulty,
                  isBookmarked: context
                      .watch<BookmarkProvider>()
                      .isQuizBookmarked(_currentQuestion.id),
                  onBookmark: _toggleBookmark,
                ),
                const SizedBox(height: 16),
                // Hint button and card (only before answering)
                if (!_hasAnswered && _currentQuestion.hint.isNotEmpty) ...[
                  _hintRevealed.contains(_currentIndex)
                      ? _buildHintCard(_currentQuestion.hint)
                      : _buildHintButton(),
                  const SizedBox(height: 16),
                ],
                _buildOptionsLabel(theme),
                const SizedBox(height: 10),
                _isMcmaType(_currentQuestion)
                    ? _buildMcmaOptions()
                    : _buildMcqOptions(),
                if (_hasAnswered) ...[
                  const SizedBox(height: 16),
                  QuizExplanationWidget(
                    explanation: _currentQuestion.explanation,
                    proTip: _currentQuestion.proTip,
                    interviewTip: _currentQuestion.interviewTip,
                    interviewNote: _currentQuestion.interviewNote,
                    animation: _explanationAnim,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        QuizNavigationButtonsWidget(
          onPrevious: _currentIndex > 0 ? _goPrevious : null,
          onNext: _goNext,
          isLastQuestion: _currentIndex == _questions.length - 1,
          hasAnswered: _hasAnswered,
        ),
      ],
    );
  }

  Widget _buildMcqOptions() {
    final pending = _pendingMcqAnswers[_currentIndex];
    final answered = _hasAnswered;

    return Column(
      children: [
        ..._currentQuestion.options.asMap().entries.map((entry) {
          return QuizOptionWidget(
            index: entry.key,
            text: entry.value,
            isSelected: answered
                ? _selectedAnswers[_currentIndex] == entry.key
                : pending == entry.key,
            isCorrect: answered && entry.key == _currentQuestion.correctIndex,
            isWrong:
                answered &&
                _selectedAnswers[_currentIndex] == entry.key &&
                entry.key != _currentQuestion.correctIndex,
            hasAnswered: answered,
            onTap: () => _selectAnswer(entry.key),
            isMultiSelect: false,
          );
        }),
        if (!answered && pending != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitMcqAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Submit Answer',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMcmaOptions() {
    final selected = _selectedMultiAnswers[_currentIndex] ?? <int>{};
    final answered = _hasAnswered;
    final correctSet = _currentQuestion.correctIndices.isNotEmpty
        ? _currentQuestion.correctIndices.toSet()
        : {_currentQuestion.correctIndex};

    return Column(
      children: [
        // Multi-select hint
        if (!answered)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.check_box_outlined,
                  size: 14,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Select all that apply',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ..._currentQuestion.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final isChecked = selected.contains(idx);
          final isOptionCorrect = correctSet.contains(idx);
          // GREEN: correct answer AND user selected it
          final isCorrect = answered && isOptionCorrect && isChecked;
          // RED: incorrect answer AND user selected it
          final isWrong = answered && !isOptionCorrect && isChecked;
          // GREY: correct answer AND user did NOT select it (missed)
          final isMissed = answered && isOptionCorrect && !isChecked;
          return QuizOptionWidget(
            index: idx,
            text: entry.value,
            isSelected: isChecked,
            isCorrect: isCorrect,
            isWrong: isWrong,
            isMissed: isMissed,
            hasAnswered: answered,
            onTap: () => _selectAnswer(idx),
            isMultiSelect: true,
          );
        }),
        if (!answered && selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitMcmaAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Submit Answer',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsLabel(ThemeData theme) {
    final isMcma = _isMcmaType(_currentQuestion);
    return Center(
      child: Text(
        isMcma ? 'SELECT ALL THAT APPLY' : 'SELECT YOUR ANSWER',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildHintButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showHintDialog,
        icon: const Icon(
          Icons.lightbulb_outline_rounded,
          size: 18,
          color: Color(0xFFB91C1C),
        ),
        label: Text(
          'Show Hint',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB91C1C),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFB91C1C), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: const Color(0xFFFFF5F5),
        ),
      ),
    );
  }

  Widget _buildHintCard(String hint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFB91C1C).withAlpha(102),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFFB91C1C),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '💡 Hint',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF7F1D1D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showHintDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              color: Color(0xFFB91C1C),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Are You Scared? 😏',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Using a hint may make this question easier and reduce the challenge.\n\nTry solving it yourself first.\n\nDo you still want to reveal the hint for me?',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF555555),
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _hintRevealed.add(_currentIndex);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reveal Hint',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exit Quiz?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Stay',
              style: GoogleFonts.dmSans(color: AppTheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _timer.cancel();
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Exit',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
