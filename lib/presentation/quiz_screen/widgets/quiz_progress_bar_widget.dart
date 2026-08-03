import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizProgressBarWidget extends StatelessWidget {
  final int current;
  final int total;

  const QuizProgressBarWidget({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: current / total),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (ctx, val, _) => LinearProgressIndicator(
        value: val,
        backgroundColor: const Color(0xFFE8F5E9),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
        minHeight: 4,
      ),
    );
  }
}
