import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuizNavigationButtonsWidget extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final bool isLastQuestion;
  final bool hasAnswered;

  const QuizNavigationButtonsWidget({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.isLastQuestion,
    required this.hasAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                'PREVIOUS',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: onPrevious != null
                    ? AppTheme.primary
                    : const Color(0xFFBBBBBB),
                side: BorderSide(
                  color: onPrevious != null
                      ? AppTheme.primary
                      : const Color(0xFFDDDDDD),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(
                isLastQuestion
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(
                isLastQuestion ? 'FINISH' : 'NEXT',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion
                    ? AppTheme.secondary
                    : AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
