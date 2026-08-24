import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pro_service.dart';
import '../../services/supabase_service.dart';
import '../../models/flashcard_model.dart';
import '../../providers/bookmark_provider.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../performance_trends_screen/performance_trends_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  /// When set, the screen shows only this specific flashcard (bookmark single-item view).
  final String? initialCardId;

  const FlashcardsScreen({super.key, this.initialCardId});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final ProService _proService = ProService();
  final SupabaseService _supabaseService = SupabaseService.instance;

  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  // All flashcards fetched from Supabase
  List<FlashcardModel> _allCards = [];

  // Topic name -> topic_id mapping from Supabase
  Map<String, int> _topicNameToId = {};

  // Ordered category list (populated after fetching topics)
  List<String> _categories = ['All'];

  // Category display name -> canonical topic name mapping
  // Used to match Supabase topic names to our display categories
  static const Map<String, List<String>> _categoryKeywords = {
    'SQL': ['sql', 'snowflake', 'redshift', 'bigquery', 'database'],
    'Architecture': ['architect', 'data engineer', 'design principle'],
    'Orchestration': ['orchestrat', 'kafka', 'airflow', 'flink', 'pipeline'],
    'Cloud Data Lakes': ['cloud', 'lake', 'delta', 'iceberg', 'hudi', 's3'],
    'PySpark': ['spark', 'pyspark', 'databricks'],
    'System Design': ['system', 'design'],
  };

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  /// Maps a Supabase topic name to one of our display category names.
  String _mapTopicToCategory(String topicName) {
    final lower = topicName.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return topicName; // fallback: use topic name as-is
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch topics, flashcards, and user flashcards in parallel
      final results = await Future.wait([
        _supabaseService.fetchTopics(),
        _supabaseService.fetchFlashcards(),
        _supabaseService.fetchUserFlashcards(),
      ]);

      final topicsRaw = results[0];
      final flashcardsRaw = results[1];
      final userFlashcardsRaw = results[2];

      // Build topic id -> display category map
      final Map<int, String> topicIdToCategory = {};
      final Map<String, int> topicNameToId = {};

      for (final t in topicsRaw) {
        final id = (t['id'] as num?)?.toInt();
        final name = t['name']?.toString() ?? '';
        if (id != null) {
          final category = _mapTopicToCategory(name);
          topicIdToCategory[id] = category;
          topicNameToId[name] = id;
        }
      }

      // Build flashcard list from official flashcards
      final List<FlashcardModel> cards = [];
      for (final row in flashcardsRaw) {
        final topicId = (row['topic_id'] as num?)?.toInt();
        final category = topicId != null
            ? (topicIdToCategory[topicId] ?? 'General')
            : 'General';
        cards.add(FlashcardModel.fromSupabase(row, category: category));
      }

      // Add user-created flashcards
      for (final row in userFlashcardsRaw) {
        cards.add(
          FlashcardModel(
            id: row['id']?.toString() ?? '',
            front: row['front']?.toString() ?? '',
            back: row['back']?.toString() ?? '',
            category: row['category']?.toString() ?? 'Custom',
            tags:
                (row['tags'] as List<dynamic>?)
                    ?.map((t) => t.toString())
                    .toList() ??
                [],
          ),
        );
      }

      // Build category list from what's actually in the data
      final Set<String> categoriesInData = {};
      for (final c in cards) {
        categoriesInData.add(c.category);
      }

      // Preserve preferred order
      const preferredOrder = [
        'SQL',
        'Architecture',
        'Orchestration',
        'Cloud Data Lakes',
        'PySpark',
        'System Design',
        'Custom',
      ];
      final orderedCategories = <String>['All'];
      for (final cat in preferredOrder) {
        if (categoriesInData.contains(cat)) {
          orderedCategories.add(cat);
        }
      }
      // Add any remaining categories not in preferred order
      for (final cat in categoriesInData) {
        if (!orderedCategories.contains(cat)) {
          orderedCategories.add(cat);
        }
      }

      if (mounted) {
        setState(() {
          _allCards = cards;
          _topicNameToId = topicNameToId;
          _categories = orderedCategories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load flashcards. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  List<FlashcardModel> get _filteredCards {
    // If opened from a bookmark tap, show only that specific card
    if (widget.initialCardId != null) {
      return _allCards.where((c) => c.id == widget.initialCardId).toList();
    }
    if (_selectedCategory == 'All') return _allCards;
    return _allCards.where((c) => c.category == _selectedCategory).toList();
  }

  void _toggleBookmark(FlashcardModel card) {
    final bookmarkProvider = context.read<BookmarkProvider>();
    final isCurrentlyBookmarked = bookmarkProvider.isFlashcardBookmarked(
      card.id,
    );
    bool added;
    if (isCurrentlyBookmarked) {
      added = bookmarkProvider.toggleFlashcardBookmark(card.id);
    } else {
      added = bookmarkProvider.toggleFlashcardBookmark(
        card.id,
        data: BookmarkedFlashcard(
          id: card.id,
          front: card.front,
          back: card.back,
          category: card.category,
        ),
      );
    }
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
            title: Row(
              children: [
                Text(
                  widget.initialCardId != null
                      ? 'Bookmarked Flashcard'
                      : 'Flashcards',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (!_isLoading && widget.initialCardId == null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_allCards.length} cards',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
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
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PerformanceTrendsScreen(),
                  ),
                ),
                icon: const Icon(Icons.person_rounded, color: Colors.white),
                tooltip: 'Profile',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.dmSans(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFlashcards,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Category Filter — hidden when showing a single bookmarked card
                    if (widget.initialCardId == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Category:',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedCategory != 'All'
                                        ? AppTheme.primary
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: _selectedCategory != 'All'
                                          ? AppTheme.primary
                                          : Colors.grey.shade500,
                                    ),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedCategory != 'All'
                                          ? AppTheme.primary
                                          : const Color(0xFF444444),
                                    ),
                                    items: _categories
                                        .map(
                                          (cat) => DropdownMenuItem<String>(
                                            value: cat,
                                            child: Text(
                                              cat,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: cat == _selectedCategory
                                                    ? AppTheme.primary
                                                    : const Color(0xFF444444),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(
                                          () => _selectedCategory = value,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedCategory != 'All') ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategory = 'All'),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withAlpha(18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.primary.withAlpha(60),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                100,
                              ),
                              itemCount: cards.length,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                final isBookmarked = bookmarkProvider
                                    .isFlashcardBookmarked(card.id);
                                return _FlashcardListItem(
                                  card: card,
                                  index: index,
                                  isBookmarked: isBookmarked,
                                  initiallyExpanded:
                                      widget.initialCardId == card.id,
                                  onBookmark: () => _toggleBookmark(card),
                                  onMastered: () async {
                                    card.isMastered = !card.isMastered;
                                    if (card.isMastered) {
                                      await _proService
                                          .incrementCardsMastered();
                                    }
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: widget.initialCardId == null
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreateFlashcardDialog(context),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Create Flashcard',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showCreateFlashcardDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateFlashcardSheet(
        onCreated: (FlashcardModel newCard) {
          setState(() {
            _allCards.insert(0, newCard);
            if (!_categories.contains(newCard.category)) {
              _categories.add(newCard.category);
            }
          });
        },
      ),
    );
  }
}

// ── Create Flashcard Bottom Sheet ─────────────────────────────────────────────

class _CreateFlashcardSheet extends StatefulWidget {
  final void Function(FlashcardModel) onCreated;

  const _CreateFlashcardSheet({required this.onCreated});

  @override
  State<_CreateFlashcardSheet> createState() => _CreateFlashcardSheetState();
}

class _CreateFlashcardSheetState extends State<_CreateFlashcardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _frontCtrl = TextEditingController();
  final _backCtrl = TextEditingController();
  final _tagInputCtrl = TextEditingController();
  String _selectedCategory = 'Custom';
  bool _isSaving = false;
  final List<String> _tags = [];

  static const List<String> _categories = [
    'Custom',
    'SQL',
    'PySpark',
    'Architecture',
    'Orchestration',
    'Cloud Data Lakes',
    'System Design',
  ];

  @override
  void dispose() {
    _frontCtrl.dispose();
    _backCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputCtrl.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await SupabaseService.instance.createUserFlashcard(
        front: _frontCtrl.text.trim(),
        back: _backCtrl.text.trim(),
        category: _selectedCategory,
        tags: List<String>.from(_tags),
      );
      if (mounted) {
        final newCard = FlashcardModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          front: _frontCtrl.text.trim(),
          back: _backCtrl.text.trim(),
          category: _selectedCategory,
          tags: List<String>.from(_tags),
        );
        Navigator.pop(context);
        widget.onCreated(newCard);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Flashcard created successfully!',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save: ${e.toString()}',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create Flashcard',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add your own custom flashcard',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),
              // Category picker
              Text(
                'Category',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF1A1A1A),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Front
              Text(
                'Front (Question) *',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _frontCtrl,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. What is a window function in SQL?',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back
              Text(
                'Back (Answer) *',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _backCtrl,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'e.g. A window function performs calculations across rows related to the current row...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tags
              Text(
                'Tags (optional)',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagInputCtrl,
                      style: GoogleFonts.dmSans(fontSize: 13),
                      onFieldSubmitted: _addTag,
                      decoration: InputDecoration(
                        hintText: 'e.g. joins, performance, interview',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addTag(_tagInputCtrl.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primary.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeTag(tag),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Flashcard',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                        // Tags chips
                        if (widget.card.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: widget.card.tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withAlpha(15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.primary.withAlpha(50),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
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
