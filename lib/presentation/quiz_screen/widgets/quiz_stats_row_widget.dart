import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuizStatsRowWidget extends StatelessWidget {
  final int totalQuestions;
  final int totalAnswered;

  const QuizStatsRowWidget({
    super.key,
    required this.totalQuestions,
    required this.totalAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9F8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildStat(
            label: 'Total Questions',
            value: '$totalQuestions',
            icon: Icons.help_outline_rounded,
            color: const Color(0xFF1565C0),
          ),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFDDDDDD),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _buildStat(
            label: 'Total Answered',
            value: '$totalAnswered',
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.success,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${((totalAnswered / totalQuestions) * 100).toStringAsFixed(0)}% done',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: const Color(0xFF777777),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
