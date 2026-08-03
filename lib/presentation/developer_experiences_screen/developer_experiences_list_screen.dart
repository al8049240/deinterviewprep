import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/developer_experience_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../theme/app_theme.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import './developer_experience_detail_screen.dart';

class DeveloperExperiencesListScreen extends StatelessWidget {
  const DeveloperExperiencesListScreen({super.key});

  Color _categoryColor(String tag) {
    switch (tag) {
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Developer's Real Experiences",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        backgroundColor: const Color(0xFF37474F),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BookmarksScreen(
                  initialFilter: BookmarkFilter.experiences,
                ),
              ),
            ),
            icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
            tooltip: 'View Bookmarks',
          ),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF37474F).withAlpha(18),
                        const Color(0xFF546E7A).withAlpha(12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF37474F).withAlpha(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🗿', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unfiltered production war stories & high-stakes trade-offs from the dev.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF37474F),
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final exp = devExperiences[index];
                  final isBookmarked = bookmarkProvider
                      .isDevExperienceBookmarked(exp.id);
                  final catColor = _categoryColor(exp.categoryTag);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: Colors.black.withAlpha(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DeveloperExperienceDetailScreen(
                                experience: exp,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              left: BorderSide(color: catColor, width: 4),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: catColor.withAlpha(18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '[ ${exp.categoryTag} ]',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '🔥',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            exp.title,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1A1A1A),
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      exp.situation,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final added = bookmarkProvider
                                          .toggleDevExperience(exp.id);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).clearSnackBars();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            added
                                                ? 'Experience saved to Bookmarks 🔖'
                                                : 'Removed from Bookmarks',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                            ),
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: added
                                              ? const Color(0xFF2E7D32)
                                              : Colors.grey.shade700,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      size: 22,
                                      color: isBookmarked
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: devExperiences.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
