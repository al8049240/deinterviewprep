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

  const ResultsTopicBreakdownWidget({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  List<_SubTopicResult> _getSubTopics() {
    // Mock sub-topic breakdown derived from domain knowledge
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
            ],
          ),
          const SizedBox(height: 14),
          ...subtopics.map((st) => _buildSubTopicRow(st)),
        ],
      ),
    );
  }

  Widget _buildSubTopicRow(_SubTopicResult st) {
    final pct = st.total == 0 ? 0.0 : st.correct / st.total;
    final color = pct >= 0.7
        ? AppTheme.success
        : pct >= 0.5
        ? AppTheme.warning
        : AppTheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}
