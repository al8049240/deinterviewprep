import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuizExplanationWidget extends StatelessWidget {
  final String explanation;
  final String proTip;
  final String interviewTip;
  final String interviewNote;
  final Animation<double> animation;

  const QuizExplanationWidget({
    super.key,
    required this.explanation,
    required this.proTip,
    required this.interviewTip,
    this.interviewNote = '',
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: Column(
          children: [
            if (explanation.isNotEmpty) ...[
              _buildExplanationCard(),
              const SizedBox(height: 10),
            ],
            if (interviewNote.isNotEmpty) ...[
              _buildInterviewNoteCard(),
              const SizedBox(height: 10),
            ],
            if (proTip.isNotEmpty) _buildProTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.success.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.success,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Explanation',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF2A4A2A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewNoteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1976D2).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                color: Color(0xFF1976D2),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Interview Note',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            interviewNote,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF0D2A4A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.secondary.withAlpha(102)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppTheme.secondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Pro Tip',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            proTip,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF5D4000),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
