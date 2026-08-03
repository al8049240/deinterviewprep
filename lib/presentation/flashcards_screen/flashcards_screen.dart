import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pro_service.dart';
import '../../models/flashcard_model.dart';
import '../../providers/bookmark_provider.dart';
import '../bookmarks_screen/bookmarks_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  /// When set, the screen shows only this specific flashcard (bookmark single-item view).
  final String? initialCardId;

  const FlashcardsScreen({super.key, this.initialCardId});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final ProService _proService = ProService();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'SQL',
    'Architecture',
    'Orchestration',
    'Cloud Data Lakes',
  ];

  List<FlashcardModel> get _filteredCards {
    // If opened from a bookmark tap, show only that specific card
    if (widget.initialCardId != null) {
      return sampleFlashcards
          .where((c) => c.id == widget.initialCardId)
          .toList();
    }
    if (_selectedCategory == 'All') return sampleFlashcards;
    return sampleFlashcards
        .where((c) => c.category == _selectedCategory)
        .toList();
  }

  void _toggleBookmark(FlashcardModel card) {
    final bookmarkProvider = context.read<BookmarkProvider>();
    final added = bookmarkProvider.toggleFlashcardBookmark(card.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Flashcard saved to Bookmarks' : 'Removed from Bookmarks',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: added ? const Color(0xFF2E7D32) : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = _filteredCards;

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Text(
              widget.initialCardId != null
                  ? 'Bookmarked Flashcard'
                  : 'Flashcards',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // View Bookmarks shortcut
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookmarksScreen(
                      initialFilter: BookmarkFilter.flashcards,
                    ),
                  ),
                ),
                icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
                tooltip: 'View Bookmarks',
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '${cards.length} cards',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Category Filter — hidden when showing a single bookmarked card
              if (widget.initialCardId == null)
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final selected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = cat;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Cards count info
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.initialCardId != null
                          ? '1 bookmarked flashcard'
                          : '${cards.length} flashcard${cards.length == 1 ? '' : 's'} in $_selectedCategory',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable list of flashcards
              Expanded(
                child: cards.isEmpty
                    ? Center(
                        child: Text(
                          'No cards in this category',
                          style: GoogleFonts.dmSans(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final isBookmarked = bookmarkProvider
                              .isFlashcardBookmarked(card.id);
                          return _FlashcardListItem(
                            card: card,
                            index: index,
                            isBookmarked: isBookmarked,
                            // Auto-expand when this is the single bookmarked card
                            initiallyExpanded: widget.initialCardId == card.id,
                            onBookmark: () => _toggleBookmark(card),
                            onMastered: () async {
                              card.isMastered = !card.isMastered;
                              if (card.isMastered) {
                                await _proService.incrementCardsMastered();
                              }
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Flashcard List Item ───────────────────────────────────────────────────────
class _FlashcardListItem extends StatefulWidget {
  final FlashcardModel card;
  final int index;
  final bool isBookmarked;
  final bool initiallyExpanded;
  final VoidCallback onBookmark;
  final VoidCallback onMastered;

  const _FlashcardListItem({
    required this.card,
    required this.index,
    required this.isBookmarked,
    this.initiallyExpanded = false,
    required this.onBookmark,
    required this.onMastered,
  });

  @override
  State<_FlashcardListItem> createState() => _FlashcardListItemState();
}

class _FlashcardListItemState extends State<_FlashcardListItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.card.isMastered
              ? AppTheme.primary.withAlpha(80)
              : Colors.grey.shade200,
          width: widget.card.isMastered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row — always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Index badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.card.category,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Front text
                        Text(
                          widget.card.front,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Actions column
                  Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onBookmark,
                        child: Icon(
                          widget.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 20,
                          color: widget.isBookmarked
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded answer section
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 14,
              endIndent: 14,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        'Answer',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.card.back,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF444444),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mastered toggle
                  GestureDetector(
                    onTap: widget.onMastered,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.card.isMastered
                            ? AppTheme.primary.withAlpha(18)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.card.isMastered
                              ? AppTheme.primary.withAlpha(80)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.card.isMastered
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: widget.card.isMastered
                                ? AppTheme.primary
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.card.isMastered
                                ? 'Mastered ✓'
                                : 'Mark as Mastered',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.card.isMastered
                                  ? AppTheme.primary
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
