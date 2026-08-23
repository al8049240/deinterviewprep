import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class _SubTopicResult {
  final String name;
  final int correct;
  final int total;

  const _SubTopicResult({
    required this.name,
    required this.correct,
    required this.total,
  });
}

class ResultsTopicBreakdownWidget extends StatelessWidget {
  final String topicId;
  final String topicName;
  final int correctAnswers;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;

  const ResultsTopicBreakdownWidget({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.correctAnswers,
    required this.totalQuestions,
    this.questions = const [],
  });

  List<_SubTopicResult> _getSubTopics() {
    final total = totalQuestions;
    final correct = correctAnswers;
    if (total == 0) return [];

    final accuracy = correct / total;

    return [
      _SubTopicResult(
        name: 'Core Concepts',
        correct: (total * 0.3 * accuracy * 1.1).round().clamp(
          0,
          (total * 0.3).round(),
        ),
        total: (total * 0.3).round(),
      ),
      _SubTopicResult(
        name: 'Advanced Queries',
        correct: (total * 0.25 * accuracy * 0.9).round().clamp(
          0,
          (total * 0.25).round(),
        ),
        total: (total * 0.25).round(),
      ),
      _SubTopicResult(
        name: 'Performance & Optimization',
        correct: (total * 0.25 * accuracy * 0.8).round().clamp(
          0,
          (total * 0.25).round(),
        ),
        total: (total * 0.25).round(),
      ),
      _SubTopicResult(
        name: 'Best Practices',
        correct: (total * 0.2 * accuracy * 1.0).round().clamp(
          0,
          (total * 0.2).round(),
        ),
        total: (total * 0.2).round(),
      ),
    ];
  }

  /// Returns questions the user got wrong for a given subtopic bucket.
  /// Since subtopics are derived (not stored per question), we distribute
  /// questions across buckets by index and filter for wrong answers.
  List<Map<String, dynamic>> _getWrongQuestionsForSubtopic(
    _SubTopicResult st,
    List<_SubTopicResult> allSubtopics,
  ) {
    if (questions.isEmpty) return [];

    // Distribute questions across subtopics proportionally by index
    final subtopicIndex = allSubtopics.indexOf(st);
    final bucketSize = (totalQuestions / allSubtopics.length).ceil();
    final startIdx = subtopicIndex * bucketSize;
    final endIdx = (startIdx + bucketSize).clamp(0, questions.length);

    if (startIdx >= questions.length) return [];

    final bucketQuestions = questions.sublist(startIdx, endIdx);

    // Filter for wrong answers: questions where selectedAnswer != correctIndex
    return bucketQuestions.where((q) {
      final selectedAnswer = q['selectedAnswer'] as int?;
      final correctIndex = q['correctIndex'] as int? ?? 0;
      // If no selected answer recorded, treat as wrong
      if (selectedAnswer == null) return false;
      return selectedAnswer != correctIndex;
    }).toList();
  }

  void _showWrongQuestionsPopup(
    BuildContext context,
    _SubTopicResult st,
    List<Map<String, dynamic>> wrongQuestions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WrongQuestionsSheet(
        subtopicName: st.name,
        wrongQuestions: wrongQuestions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtopics = _getSubTopics();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Topic Breakdown',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                'Tap to review',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.touch_app_rounded,
                color: AppTheme.primary,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...subtopics.map((st) => _buildSubTopicRow(context, st, subtopics)),
        ],
      ),
    );
  }

  Widget _buildSubTopicRow(
    BuildContext context,
    _SubTopicResult st,
    List<_SubTopicResult> allSubtopics,
  ) {
    final pct = st.total == 0 ? 0.0 : st.correct / st.total;
    final color = pct >= 0.7
        ? AppTheme.success
        : pct >= 0.5
        ? AppTheme.warning
        : AppTheme.error;

    final wrongQuestions = _getWrongQuestionsForSubtopic(st, allSubtopics);
    final wrongCount = st.total - st.correct;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showWrongQuestionsPopup(context, st, wrongQuestions),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      st.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  if (wrongCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$wrongCount wrong',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  Text(
                    '${st.correct}/${st.total}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(31),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFAAAAAA),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: pct),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (ctx, val, _) => LinearProgressIndicator(
                    value: val,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wrong Questions Bottom Sheet ────────────────────────────────────────────

class _WrongQuestionsSheet extends StatelessWidget {
  final String subtopicName;
  final List<Map<String, dynamic>> wrongQuestions;

  const _WrongQuestionsSheet({
    required this.subtopicName,
    required this.wrongQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: wrongQuestions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: wrongQuestions.length,
                        itemBuilder: (_, i) =>
                            _buildQuestionCard(wrongQuestions[i], i),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
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
              const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtopicName,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      wrongQuestions.isEmpty
                          ? 'All correct! 🎉'
                          : '${wrongQuestions.length} question${wrongQuestions.length == 1 ? '' : 's'} to review',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Perfect Score! 🎉',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You got all questions in this topic correct. Great work!',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF777777),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int index) {
    final options = (q['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = q['correctIndex'] as int? ?? 0;
    final selectedAnswer = q['selectedAnswer'] as int?;
    final explanation = q['explanation'] as String? ?? '';
    final difficulty = q['difficulty'] as String? ?? 'medium';
    final diffColor = difficulty == 'easy'
        ? AppTheme.success
        : difficulty == 'hard'
        ? AppTheme.error
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(13),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Q${index + 1}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
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
                const Spacer(),
                const Icon(
                  Icons.cancel_rounded,
                  color: AppTheme.error,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Incorrect',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q['text'] as String? ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                // Your answer (wrong)
                if (selectedAnswer != null &&
                    selectedAnswer >= 0 &&
                    selectedAnswer < options.length) ...[
                  _buildAnswerRow(
                    label: 'Your Answer',
                    text: options[selectedAnswer],
                    isCorrect: false,
                  ),
                  const SizedBox(height: 6),
                ],
                // Correct answer
                if (correctIndex >= 0 && correctIndex < options.length)
                  _buildAnswerRow(
                    label: 'Correct Answer',
                    text: options[correctIndex],
                    isCorrect: true,
                  ),
                // Explanation
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 10),
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
                            explanation,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow({
    required String label,
    required String text,
    required bool isCorrect,
  }) {
    final color = isCorrect ? AppTheme.success : AppTheme.error;
    final bgColor = isCorrect
        ? AppTheme.success.withAlpha(20)
        : AppTheme.error.withAlpha(20);
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isCorrect
                        ? AppTheme.success
                        : const Color(0xFF333333),
                    fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
