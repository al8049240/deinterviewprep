import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/pro_service.dart';
import '../../services/supabase_service.dart';
import '../../models/flashcard_model.dart';
import '../../providers/bookmark_provider.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../performance_trends_screen/performance_trends_screen.dart';
import '../paywall_screen/paywall_screen.dart';
import '../topics_list_screen/widgets/pro_banner_widget.dart';
import '../topics_list_screen/widgets/topics_search_bar_widget.dart';

class FlashcardsScreen extends StatefulWidget {
  /// When set, the screen shows only this specific flashcard (bookmark single-item view).
  final String? initialCardId;

  const FlashcardsScreen({super.key, this.initialCardId});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  static const int _freeCardLimit = 30;
  final ProService _proService = ProService();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  // All flashcards fetched from Supabase
  List<FlashcardModel> _allCards = [];
  int _officialCardCount = 0;
  Map<int, String> _topicNames = {};
  Map<int, String> _subtopicNames = {};
  int? _selectedTopicId;
  int? _selectedSubtopicId;

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
    _proService.init();
    _proService.addListener(_onProChanged);
    _loadFlashcards();
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

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallScreen(),
    );
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

  String _displayTopicName(String databaseName) {
    if (databaseName.trim().toLowerCase() == 'ai for data engineering') {
      return 'AI Agents for Data Engineering';
    }
    return databaseName;
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isSignedIn = AuthService.instance.isSignedIn;
      final userFlashcardsFuture = isSignedIn
          ? _supabaseService.fetchUserFlashcards()
          : Future.value(<Map<String, dynamic>>[]);

      final results = await Future.wait([
        _supabaseService.fetchTopics(),
        _supabaseService.fetchSubtopics(),
        _supabaseService.fetchFlashcards(),
        userFlashcardsFuture,
      ]);

      final topicsRaw = results[0];
      final subtopicsRaw = results[1];
      final flashcardsRaw = results[2];
      final userFlashcardsRaw = results[3];

      // Build topic id -> display category map
      final Map<int, String> topicIdToCategory = {};
      final Map<int, String> topicNames = {};
      for (final t in topicsRaw) {
        final id = (t['id'] as num?)?.toInt();
        final name = t['name']?.toString() ?? '';
        if (id != null) {
          final category = _mapTopicToCategory(name);
          topicIdToCategory[id] = category;
          topicNames[id] = name;
        }
      }

      final subtopicNames = <int, String>{};
      for (final row in subtopicsRaw) {
        final id = (row['id'] as num?)?.toInt();
        final topicId = (row['topic_id'] as num?)?.toInt();
        if (id != null && topicId != null) {
          subtopicNames[id] = row['name']?.toString() ?? 'Subtopic';
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

      if (mounted) {
        setState(() {
          _allCards = cards;
          _officialCardCount = flashcardsRaw.length;
          _topicNames = topicNames;
          _subtopicNames = subtopicNames;
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
    return _allCards.where((card) {
      final matchesTopic =
          _selectedTopicId == null ||
          (_selectedTopicId == -1
              ? card.topicId == null
              : card.topicId == _selectedTopicId);
      final matchesSubtopic =
          _selectedSubtopicId == null ||
          (_selectedSubtopicId == -1
              ? card.subtopicId == null
              : card.subtopicId == _selectedSubtopicId);
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          card.front.toLowerCase().contains(query) ||
          card.back.toLowerCase().contains(query) ||
          card.category.toLowerCase().contains(query) ||
          card.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesTopic && matchesSubtopic && matchesSearch;
    }).toList();
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
            backgroundColor: AppTheme.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  if (_selectedSubtopicId != null) {
                    setState(() => _selectedSubtopicId = null);
                  } else if (_selectedTopicId != null) {
                    setState(() => _selectedTopicId = null);
                  } else {
                    context.go(AppRoutes.initial);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _selectedTopicId == null
                        ? Icons.home_rounded
                        : Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEInterviewPrep',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.initialCardId != null
                      ? 'Bookmarked Flashcard'
                      : 'Flashcards',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
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
              : widget.initialCardId == null && _selectedTopicId == null
              ? _buildTopicList()
              : widget.initialCardId == null && _selectedSubtopicId == null
              ? _buildSubtopicList()
              : Column(
                  children: [
                    // Category Filter — hidden when showing a single bookmarked card
                    if (widget.initialCardId == null) ...[
                      TopicsSearchBarWidget(
                        controller: _searchController,
                        hintText: 'Search flashcards',
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ],

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
                                : _proService.isProUnlocked
                                ? '${cards.length} flashcard${cards.length == 1 ? '' : 's'} in ${_subtopicNames[_selectedSubtopicId] ?? 'this subtopic'}'
                                : '${cards.length} cards • first $_freeCardLimit are free',
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
                                _searchQuery.isNotEmpty
                                    ? 'No flashcards match your search'
                                    : 'No cards in this category',
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
                                final globalIndex = _allCards.indexOf(card);
                                final isLocked =
                                    !_proService.isProUnlocked &&
                                    globalIndex >= _freeCardLimit &&
                                    globalIndex < _officialCardCount;
                                final isBookmarked = bookmarkProvider
                                    .isFlashcardBookmarked(card.id);
                                return _FlashcardListItem(
                                  card: card,
                                  index: index,
                                  isBookmarked: isBookmarked,
                                  initiallyExpanded:
                                      !isLocked &&
                                      widget.initialCardId == card.id,
                                  isLocked: isLocked,
                                  onLocked: _showPaywall,
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
          floatingActionButton:
              widget.initialCardId == null && AuthService.instance.isSignedIn
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

  Widget _buildTopicList() {
    final counts = <int, int>{};
    for (final card in _allCards) {
      final topicId = card.topicId ?? -1;
      counts[topicId] = (counts[topicId] ?? 0) + 1;
    }
    final topicIds = counts.keys.toList()
      ..sort((a, b) {
        final first = a == -1
            ? 'Custom'
            : _displayTopicName(_topicNames[a] ?? 'Topic');
        final second = b == -1
            ? 'Custom'
            : _displayTopicName(_topicNames[b] ?? 'Topic');
        return first.compareTo(second);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_proService.isProUnlocked) const ProBannerWidget(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            'Choose a Topic',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text(
            'Select a topic to browse its flashcard subtopics.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF777777),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: topicIds.length,
            itemBuilder: (context, index) {
              final topicId = topicIds[index];
              return _FlashcardHierarchyCard(
                icon: Icons.style_rounded,
                color: _hierarchyColor(index),
                title: topicId == -1
                    ? 'Custom'
                    : _displayTopicName(
                        _topicNames[topicId] ?? 'Topic $topicId',
                      ),
                subtitle: '${counts[topicId]} flashcards',
                onTap: () => setState(() {
                  _selectedTopicId = topicId;
                  _selectedSubtopicId = null;
                  _searchQuery = '';
                  _searchController.clear();
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubtopicList() {
    final counts = <int, int>{};
    for (final card in _allCards) {
      final belongsToTopic = _selectedTopicId == -1
          ? card.topicId == null
          : card.topicId == _selectedTopicId;
      if (!belongsToTopic) continue;
      final subtopicId = card.subtopicId ?? -1;
      counts[subtopicId] = (counts[subtopicId] ?? 0) + 1;
    }
    final subtopicIds = counts.keys.toList()
      ..sort(
        (a, b) => (_subtopicNames[a] ?? (a == -1 ? 'Custom' : 'Subtopic'))
            .compareTo(_subtopicNames[b] ?? (b == -1 ? 'Custom' : 'Subtopic')),
      );
    final topicName = _selectedTopicId == -1
        ? 'Custom'
        : _displayTopicName(_topicNames[_selectedTopicId] ?? 'Flashcards');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            'Choose a Subtopic',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text(
            '$topicName • ${counts.values.fold<int>(0, (sum, count) => sum + count)} flashcards',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF777777),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: subtopicIds.length,
            itemBuilder: (context, index) {
              final subtopicId = subtopicIds[index];
              return _FlashcardHierarchyCard(
                icon: Icons.layers_rounded,
                color: _hierarchyColor(index),
                title:
                    _subtopicNames[subtopicId] ??
                    (subtopicId == -1
                        ? 'Custom Cards'
                        : 'Subtopic $subtopicId'),
                subtitle: '${counts[subtopicId]} flashcards',
                onTap: () => setState(() {
                  _selectedSubtopicId = subtopicId;
                  _searchQuery = '';
                  _searchController.clear();
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _hierarchyColor(int index) {
    const colors = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFFE64A19),
      Color(0xFF00838F),
      Color(0xFF4527A0),
    ];
    return colors[index % colors.length];
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
          });
        },
      ),
    );
  }
}

// ── Create Flashcard Bottom Sheet ─────────────────────────────────────────────

class _FlashcardHierarchyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FlashcardHierarchyCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withAlpha(31),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primary.withAlpha(153),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    _addTag(_tagInputCtrl.text);
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
                keyboardType: TextInputType.multiline,
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
                keyboardType: TextInputType.multiline,
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
                      keyboardType: TextInputType.text,
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
  final bool isLocked;
  final VoidCallback onLocked;

  const _FlashcardListItem({
    required this.card,
    required this.index,
    required this.isBookmarked,
    this.initiallyExpanded = false,
    required this.onBookmark,
    required this.onMastered,
    required this.isLocked,
    required this.onLocked,
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
            onTap: widget.isLocked
                ? widget.onLocked
                : () => setState(() => _isExpanded = !_isExpanded),
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
                      if (widget.isLocked) ...[
                        const Icon(
                          Icons.lock_rounded,
                          size: 20,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(height: 6),
                      ],
                      GestureDetector(
                        onTap: widget.isLocked
                            ? widget.onLocked
                            : widget.onBookmark,
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
