import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/developer_experience_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../theme/app_theme.dart';

class DeveloperExperienceDetailScreen extends StatelessWidget {
  final DeveloperExperienceModel experience;

  const DeveloperExperienceDetailScreen({super.key, required this.experience});

  Color get _categoryColor {
    final categoryTag = experience.categoryTag
        .replaceAll(RegExp(r'[\[\]]'), '')
        .trim();
    switch (categoryTag) {
      case 'Behavioral':
        return const Color(0xFF1565C0);
      case 'Failure Lesson':
        return const Color(0xFFC62828);
      case 'Architecture Trade-off':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final isBookmarked = bookmarkProvider.isDevExperienceBookmarked(
          experience.id,
        );

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
            title: Text(
              "Dev's Experience 🔥",
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag + title
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _categoryColor.withAlpha(60)),
                  ),
                  child: Text(
                    experience.categoryTag
                        .replaceAll(RegExp(r'[\[\]]'), '')
                        .trim(),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _categoryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        experience.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // STAR Sections
                _StarSection(
                  letter: 'S',
                  label: 'Situation',
                  color: const Color(0xFF1565C0),
                  content: experience.situation,
                ),
                const SizedBox(height: 16),
                _StarSection(
                  letter: 'T',
                  label: 'Task',
                  color: const Color(0xFF2E7D32),
                  content: experience.task,
                ),
                const SizedBox(height: 16),
                _StarSection(
                  letter: 'A',
                  label: 'Action',
                  color: const Color(0xFFD32F2F),
                  content: experience.action,
                ),
                const SizedBox(height: 16),
                _StarSection(
                  letter: 'R',
                  label: 'Result',
                  color: const Color(0xFFFFC107),
                  content: experience.result,
                ),
                const SizedBox(height: 24),

                // Dev's Key Takeaway highlight box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF57F17).withAlpha(20),
                        const Color(0xFFF9A825).withAlpha(15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF57F17).withAlpha(80),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            "Dev's Key Takeaway",
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        experience.keyTakeaway,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFF5D4037),
                          height: 1.65,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sticky bottom return bar
          bottomNavigationBar: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        'Back',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? const Color(0xFF2E7D32).withAlpha(15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isBookmarked
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        final added = bookmarkProvider.toggleDevExperience(
                          experience.id,
                        );
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Experience saved to Bookmarks 🔖'
                                  : 'Removed from Bookmarks',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: added
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade500,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── STAR Section Widget ───────────────────────────────────────────────────────
class _StarSection extends StatelessWidget {
  final String letter;
  final String label;
  final Color color;
  final String content;

  const _StarSection({
    required this.letter,
    required this.label,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF444444),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
