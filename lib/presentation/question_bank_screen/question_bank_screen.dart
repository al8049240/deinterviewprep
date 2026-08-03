import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pro_service.dart';
import '../../services/cache_service.dart';
import '../../models/flashcard_model.dart';
import '../../providers/bookmark_provider.dart';
import '../paywall_screen/paywall_screen.dart';

class QuestionBankScreen extends StatefulWidget {
  /// When [showBookmarkedOnly] is true the screen opens pre-filtered to saved questions.
  final bool showBookmarkedOnly;
  const QuestionBankScreen({super.key, this.showBookmarkedOnly = false});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final ProService _proService = ProService();
  final CacheService _cacheService = CacheService();

  // Filter mode: 'topics' or 'companies'
  String _filterMode = 'topics';

  // Primary filter selections
  String _selectedTopic = 'All';
  String _selectedCompany = 'All';
  String _selectedDifficulty = 'All';
  bool _showSavedOnly = false;

  int? _expandedIndex;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _topics = [
    'All',
    'System Design',
    'PySpark',
    'Data Modeling',
    'SQL',
    'Airflow',
    'Kafka',
  ];

  static const List<String> _companies = [
    'All',
    'Meta',
    'Amazon',
    'Snowflake',
    'Databricks',
    'Uber',
    'Netflix',
  ];

  static const List<String> _difficulties = [
    'All',
    'Junior',
    'Mid',
    'Senior',
    'Lead',
  ];

  @override
  void initState() {
    super.initState();
    _showSavedOnly = widget.showBookmarkedOnly;
    _proService.addListener(_onProChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _expandedIndex = null;
      });
    });
    _cachePremiumContent();
  }

  @override
  void dispose() {
    _proService.removeListener(_onProChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProChanged() {
    if (mounted) setState(() {});
  }

  /// Cache all premium questions locally when the screen loads (if pro)
  Future<void> _cachePremiumContent() async {
    if (_proService.isProUnlocked) {
      await _cacheService.cacheQuestions(sampleInterviewQuestions);
      await _cacheService.cacheFlashcards(sampleFlashcards);
    }
  }

  List<InterviewQuestionModel> _getFilteredQuestions(
    Set<String> bookmarkedIds,
  ) {
    return sampleInterviewQuestions.where((q) {
      // ── Saved filter — only interview questions ─────────────────────────────
      if (_showSavedOnly && !bookmarkedIds.contains(q.id)) return false;

      // ── Keyword search ──────────────────────────────────────────────────────
      final searchMatch =
          _searchQuery.isEmpty ||
          q.title.toLowerCase().contains(_searchQuery) ||
          q.category.toLowerCase().contains(_searchQuery) ||
          q.tags.any((t) => t.toLowerCase().contains(_searchQuery)) ||
          q.answer.toLowerCase().contains(_searchQuery) ||
          q.description.toLowerCase().contains(_searchQuery);

      // ── Topic / Company filter ──────────────────────────────────────────────
      bool primaryMatch;
      if (_filterMode == 'topics') {
        if (_selectedTopic == 'All') {
          primaryMatch = true;
        } else {
          final topicLower = _selectedTopic.toLowerCase();
          primaryMatch =
              (q.topicId.isNotEmpty
                  ? q.topicId.toLowerCase() == topicLower
                  : q.category.toLowerCase().contains(topicLower)) ||
              q.tags.any((t) => t.toLowerCase().contains(topicLower));
        }
      } else {
        if (_selectedCompany == 'All') {
          primaryMatch = true;
        } else {
          final companyLower = _selectedCompany.toLowerCase();
          primaryMatch =
              q.companies.any((c) => c.toLowerCase() == companyLower) ||
              q.tags.any((t) => t.toLowerCase().contains(companyLower));
        }
      }

      // ── Difficulty filter ───────────────────────────────────────────────────
      final diffMatch =
          _selectedDifficulty == 'All' || q.difficulty == _selectedDifficulty;

      return searchMatch && primaryMatch && diffMatch;
    }).toList();
  }

  void _onQuestionTap(int index, InterviewQuestionModel question) {
    if (question.isPro && !_proService.isProUnlocked) {
      _showPaywall();
      return;
    }
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallScreen(),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _expandedIndex = null;
    });
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedTopic = 'All';
      _selectedCompany = 'All';
      _selectedDifficulty = 'All';
      _showSavedOnly = false;
      _expandedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bookmarkedIds = bookmarkProvider.bookmarkedQuestionIds;
    final questions = _getFilteredQuestions(bookmarkedIds);
    final isPro = _proService.isProUnlocked;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Interview Question Bank',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              )
            : null,
        actions: [
          if (!isPro)
            TextButton.icon(
              onPressed: _showPaywall,
              icon: const Icon(Icons.lock_open, color: Colors.white, size: 16),
              label: Text(
                'Unlock PRO',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText:
                    'Search questions by keyword (e.g., window function, dbt, partitioning)...',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Segmented Mode Switcher ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _ModeTab(
                    label: 'By Topic',
                    isSelected: _filterMode == 'topics',
                    onTap: () => setState(() {
                      _filterMode = 'topics';
                      _expandedIndex = null;
                    }),
                  ),
                  _ModeTab(
                    label: 'By Company',
                    isSelected: _filterMode == 'companies',
                    onTap: () => setState(() {
                      _filterMode = 'companies';
                      _expandedIndex = null;
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Primary Filter Chips (Topic or Company) ─────────────────────────
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filterMode == 'topics'
                  ? _topics.length
                  : _companies.length,
              itemBuilder: (context, i) {
                final label = _filterMode == 'topics'
                    ? _topics[i]
                    : _companies[i];
                final isSelected = _filterMode == 'topics'
                    ? label == _selectedTopic
                    : label == _selectedCompany;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (_filterMode == 'topics') {
                      _selectedTopic = label;
                    } else {
                      _selectedCompany = label;
                    }
                    _expandedIndex = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Difficulty Chips + Saved chip ───────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // Saved / Bookmarked chip
                GestureDetector(
                  onTap: () => setState(() {
                    _showSavedOnly = !_showSavedOnly;
                    _expandedIndex = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _showSavedOnly
                          ? const Color(0xFF2E7D32).withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showSavedOnly
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showSavedOnly
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 14,
                          color: _showSavedOnly
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Saved 🔖',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showSavedOnly
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Difficulty chips
                ..._difficulties.map((diff) {
                  final selected = diff == _selectedDifficulty;
                  final color = _difficultyColor(diff);
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedDifficulty = diff;
                      _expandedIndex = null;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withAlpha(30)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? color : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        diff,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? color : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Questions list / Empty state ────────────────────────────────────
          Expanded(
            child: questions.isEmpty
                ? _showSavedOnly
                      ? _EmptySavedState(onReset: _resetAllFilters)
                      : _EmptySearchState(
                          keyword: _searchQuery,
                          onReset: _resetAllFilters,
                        )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: questions.length,
                    itemBuilder: (context, i) {
                      final q = questions[i];
                      final isLocked = q.isPro && !isPro;
                      final isExpanded = _expandedIndex == i;
                      final isBookmarked = bookmarkedIds.contains(q.id);
                      return _QuestionCard(
                        question: q,
                        isLocked: isLocked,
                        isExpanded: isExpanded,
                        searchQuery: _searchQuery,
                        isBookmarked: isBookmarked,
                        onTap: () => _onQuestionTap(i, q),
                        onBookmarkToggle: () {
                          context.read<BookmarkProvider>().toggleQuestion(q.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String diff) {
    switch (diff) {
      case 'Junior':
        return Colors.green;
      case 'Mid':
        return Colors.blue;
      case 'Senior':
        return Colors.orange;
      case 'Lead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ── Mode Tab ──────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty Search State ────────────────────────────────────────────────────────

class _EmptySearchState extends StatelessWidget {
  final String keyword;
  final VoidCallback onReset;

  const _EmptySearchState({required this.keyword, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              keyword.isNotEmpty
                  ? 'No questions found matching\n"$keyword"'
                  : 'No questions match the selected filters',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for another topic or resetting filters.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Saved State ─────────────────────────────────────────────────────────

class _EmptySavedState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptySavedState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved questions yet',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap 🔖 on any interview scenario to save it for quick revision!',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text('Browse All Questions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question Card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final InterviewQuestionModel question;
  final bool isLocked;
  final bool isExpanded;
  final String searchQuery;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;

  const _QuestionCard({
    required this.question,
    required this.isLocked,
    required this.isExpanded,
    required this.searchQuery,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkToggle,
  });

  Color get _difficultyColor {
    switch (question.difficulty) {
      case 'Junior':
        return Colors.green;
      case 'Mid':
        return Colors.blue;
      case 'Senior':
        return Colors.orange;
      case 'Lead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked
              ? Colors.grey.shade200
              : AppTheme.primaryLight.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.difficulty,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _difficultyColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.category,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Bookmark toggle button
                    GestureDetector(
                      onTap: onBookmarkToggle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 22,
                          color: isBookmarked
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // PRO lock badge or expand arrow
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock,
                              size: 12,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'PRO',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _HighlightText(
                  text: question.title,
                  query: searchQuery,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isLocked
                        ? Colors.grey.shade500
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Unlock PRO to view this question and its detailed answer.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                // Tags
                if (!isLocked) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: question.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  searchQuery.isNotEmpty &&
                                      tag.toLowerCase().contains(searchQuery)
                                  ? AppTheme.secondary.withAlpha(40)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color:
                                    searchQuery.isNotEmpty &&
                                        tag.toLowerCase().contains(searchQuery)
                                    ? AppTheme.warning
                                    : Colors.grey.shade600,
                                fontWeight:
                                    searchQuery.isNotEmpty &&
                                        tag.toLowerCase().contains(searchQuery)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                // Expanded content
                if (isExpanded && !isLocked) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text(
                    'Problem Statement',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.description,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF444444),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Solution Breakdown',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryContainer),
                    ),
                    child: Text(
                      question.answer,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        color: const Color(0xFF1A1A1A),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Highlight Text (highlights matching search terms) ─────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 3,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: style.copyWith(
            backgroundColor: AppTheme.secondary.withAlpha(80),
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
    );
  }
}
