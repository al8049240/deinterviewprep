import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuizOptionWidget extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool hasAnswered;
  final VoidCallback onTap;

  const QuizOptionWidget({
    super.key,
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.hasAnswered,
    required this.onTap,
  });

  Color get _bgColor {
    if (!hasAnswered) return Colors.white;
    if (isCorrect) return const Color(0xFFE8F5E9);
    if (isWrong) return const Color(0xFFFFEBEE);
    return Colors.white;
  }

  Color get _borderColor {
    if (!hasAnswered) return const Color(0xFFDDDDDD);
    if (isCorrect) return AppTheme.success;
    if (isWrong) return AppTheme.error;
    return const Color(0xFFDDDDDD);
  }

  Color get _checkboxColor {
    if (!hasAnswered) return const Color(0xFFDDDDDD);
    if (isCorrect) return AppTheme.success;
    if (isWrong) return AppTheme.error;
    return const Color(0xFFDDDDDD);
  }

  @override
  Widget build(BuildContext context) {
    final optionLetter = String.fromCharCode(65 + index); // A, B, C, D

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: isSelected && !hasAnswered
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(38),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: hasAnswered ? null : onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: AppTheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppTheme.success
                          : isWrong
                          ? AppTheme.error
                          : isSelected && !hasAnswered
                          ? AppTheme.primary
                          : Colors.transparent,
                      border: Border.all(color: _checkboxColor, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: (isCorrect || isWrong || isSelected && !hasAnswered)
                        ? Icon(
                            isCorrect
                                ? Icons.check_rounded
                                : isWrong
                                ? Icons.close_rounded
                                : Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : Center(
                            child: Text(
                              optionLetter,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF777777),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: isCorrect || isWrong
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isCorrect
                            ? AppTheme.success
                            : isWrong
                            ? AppTheme.error
                            : const Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.success,
                      size: 20,
                    ),
                  if (isWrong)
                    const Icon(
                      Icons.cancel_rounded,
                      color: AppTheme.error,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
