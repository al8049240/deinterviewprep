import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ResultsMetricsRowWidget extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final String timeTaken;
  final double accuracyPercent;

  const ResultsMetricsRowWidget({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTaken,
    required this.accuracyPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.check_circle_rounded,
            label: 'Correct Answers',
            value: '$correctAnswers / $totalQuestions',
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.timer_rounded,
            label: 'Time Taken',
            value: timeTaken,
            color: AppTheme.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.trending_up_rounded,
            label: 'Accuracy',
            value: '${accuracyPercent.toStringAsFixed(1)}%',
            color: accuracyPercent >= 70
                ? AppTheme.success
                : accuracyPercent >= 50
                ? AppTheme.warning
                : AppTheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF777777),
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
