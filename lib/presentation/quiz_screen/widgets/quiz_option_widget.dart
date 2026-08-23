import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuizOptionWidget extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isMissed; // correct answer that user did NOT select (GREY)
  final bool hasAnswered;
  final VoidCallback onTap;
  final bool isMultiSelect;

  const QuizOptionWidget({
    super.key,
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    this.isMissed = false,
    required this.hasAnswered,
    required this.onTap,
    this.isMultiSelect = false,
  });

  static const Color _greyBg = Color(0xFFF5F5F5);
  static const Color _greyBorder = Color(0xFF9E9E9E);
  static const Color _greyText = Color(0xFF757575);

  Color get _bgColor {
    if (!hasAnswered) {
      return isSelected
          ? AppTheme.primaryContainer.withAlpha(80)
          : Colors.white;
    }
    if (isCorrect) return const Color(0xFFE8F5E9);
    if (isWrong) return const Color(0xFFFFEBEE);
    if (isMissed) return _greyBg;
    return Colors.white;
  }

  Color get _borderColor {
    if (!hasAnswered) {
      return isSelected ? AppTheme.primary : const Color(0xFFDDDDDD);
    }
    if (isCorrect) return AppTheme.success;
    if (isWrong) return AppTheme.error;
    if (isMissed) return _greyBorder;
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
                  _buildIndicator(optionLetter),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: isCorrect || isWrong || isMissed
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isCorrect
                            ? AppTheme.success
                            : isWrong
                            ? AppTheme.error
                            : isMissed
                            ? _greyText
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
                  if (isMissed)
                    const Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: _greyBorder,
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

  Widget _buildIndicator(String optionLetter) {
    if (isMultiSelect) {
      // Checkbox style for mcma
      if (hasAnswered) {
        if (isCorrect) {
          // Correct + selected → GREEN checkbox with check
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          );
        } else if (isWrong) {
          // Incorrect + selected → RED checkbox with X
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 16,
            ),
          );
        } else if (isMissed) {
          // Correct + NOT selected → GREY checkbox (missed)
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _greyBorder,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          );
        } else {
          // Incorrect + NOT selected → neutral
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: const Color(0xFFDDDDDD), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                optionLetter,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF777777),
                ),
              ),
            ),
          );
        }
      } else {
        // Pre-answer checkbox
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFDDDDDD),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: isSelected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
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
        );
      }
    } else {
      // Radio style for mcq (original behavior)
      return AnimatedContainer(
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
          border: Border.all(
            color: isCorrect
                ? AppTheme.success
                : isWrong
                ? AppTheme.error
                : isSelected && !hasAnswered
                ? AppTheme.primary
                : const Color(0xFFDDDDDD),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: (isCorrect || isWrong || (isSelected && !hasAnswered))
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
      );
    }
  }
}
