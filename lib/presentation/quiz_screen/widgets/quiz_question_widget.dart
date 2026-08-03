import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuizQuestionWidget extends StatelessWidget {
  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String difficulty;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  const QuizQuestionWidget({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.difficulty,
    required this.isBookmarked,
    required this.onBookmark,
  });

  Color get _difficultyColor {
    switch (difficulty) {
      case 'easy':
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'hard':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Question $questionNumber of $totalQuestions',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _difficultyColor.withAlpha(31),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _difficultyColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onBookmark,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    key: ValueKey(isBookmarked),
                    color: isBookmarked
                        ? AppTheme.error
                        : const Color(0xFF9E9E9E),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            questionText,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
