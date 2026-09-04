import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/pro_service.dart';
import '../../providers/bookmark_provider.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../performance_trends_screen/performance_trends_screen.dart';
import '../paywall_screen/paywall_screen.dart';

class RealCaseScenario {
  final String id;
  final String title;
  final String category;
  final List<String> tags;
  final String problemStatement;
  final String solutionBreakdown;
  final bool isActive;
  final String? publishedDate;
  final bool isUserCreated;

  RealCaseScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.tags,
    required this.problemStatement,
    required this.solutionBreakdown,
    required this.isActive,
    this.publishedDate,
    this.isUserCreated = false,
  });

  factory RealCaseScenario.fromMap(
    Map<String, dynamic> map, {
    bool isUserCreated = false,
  }) {
    return RealCaseScenario(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      tags:
          (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          [],
      problemStatement: map['problem_statement']?.toString() ?? '',
      solutionBreakdown: map['solution_breakdown']?.toString() ?? '',
      isActive: map['is_active'] as bool? ?? true,
      publishedDate: map['published_date']?.toString(),
      isUserCreated: isUserCreated,
    );
  }

  /// Extract company tags (capitalised single words that look like company names)
  List<String> get companies {
    const knownCompanies = [
      'Amazon',
      'Google',
      'Meta',
      'Netflix',
      'Uber',
      'Databricks',
      'Snowflake',
      'Microsoft',
      'Apple',
      'Airbnb',
      'Twitter',
      'LinkedIn',
      'Stripe',
      'Shopify',
    ];
    return tags
        .where(
          (t) => knownCompanies.any((c) => t.toLowerCase() == c.toLowerCase()),
        )
        .toList();
  }
}

class QuestionBankScreen extends StatefulWidget {
  final bool showBookmarkedOnly;
  const QuestionBankScreen({super.key, this.showBookmarkedOnly = false});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  static const int _freeScenarioLimit = 3;
  final SupabaseService _supabase = SupabaseService.instance;
  final ProService _proService = ProService();

  List<RealCaseScenario> _allScenarios = [];
  bool _isLoading = true;
  String? _errorMessage;

  int? _expandedIndex;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedBigTopic = 'All';

  List<String> get _bigTopics {
    final topics = _allScenarios.map((s) => s.category).toSet().toList()
      ..sort();
    return ['All', ...topics];
  }

  @override
  void initState() {
    super.initState();
    _proService.init();
    _proService.addListener(_onProChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _expandedIndex = null;
      });
    });
    _loadScenarios();
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

  Future<void> _loadScenarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final isSignedIn = AuthService.instance.isSignedIn;
      final userScenariosFuture = isSignedIn
          ? _supabase.fetchUserRealCaseScenarios()
          : Future.value(<Map<String, dynamic>>[]);

      final results = await Future.wait([
        _supabase.fetchRealCaseScenarios(),
        userScenariosFuture,
      ]);

      final official = (results[0])
          .map((m) => RealCaseScenario.fromMap(m))
          .toList();
      final userCreated = (results[1])
          .map((m) => RealCaseScenario.fromMap(m, isUserCreated: true))
          .toList();

      setState(() {
        _allScenarios = [...official, ...userCreated];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load scenarios. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<RealCaseScenario> get _filteredScenarios {
    return _allScenarios.where((s) {
      final q = _searchQuery;
      final matchesSearch =
          q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.problemStatement.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q));
      final matchesTopic =
          _selectedBigTopic == 'All' || s.category == _selectedBigTopic;
      return matchesSearch && matchesTopic;
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _expandedIndex = null;
    });
  }

  void _toggleBookmark(BuildContext context, RealCaseScenario scenario) {
    final provider = context.read<BookmarkProvider>();
    final isCurrentlyBookmarked = provider.isRealCaseBookmarked(scenario.id);
    bool added;
    if (isCurrentlyBookmarked) {
      added = provider.toggleRealCaseScenario(scenario.id);
    } else {
      added = provider.toggleRealCaseScenario(
        scenario.id,
        data: BookmarkedRealCaseScenario(
          id: scenario.id,
          title: scenario.title,
          category: scenario.category,
          problemStatement: scenario.problemStatement,
          solutionBreakdown: scenario.solutionBreakdown,
          tags: scenario.tags,
        ),
      );
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Scenario saved to Bookmarks' : 'Removed from Bookmarks',
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

  void _showCreateScenarioDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateScenarioSheet(
        onCreated: (RealCaseScenario newScenario) {
          setState(() {
            _allScenarios.insert(0, newScenario);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final filtered = _filteredScenarios;
        final total = _allScenarios.length;

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  'Real Case Scenario',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (!_isLoading && total > 0) ...[
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
                      '$total',
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
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            actions: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookmarksScreen(
                      initialFilter: BookmarkFilter.scenarios,
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
          floatingActionButton: AuthService.instance.isSignedIn
              ? FloatingActionButton.extended(
                  onPressed: _showCreateScenarioDialog,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Create Scenario',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                )
              : null,
          body: Column(
            children: [
              // ── Search Bar + Big Topic Filter ───────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search scenarios by keyword...',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.primary,
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
                    const SizedBox(height: 10),
                    // Big Topic filter
                    Row(
                      children: [
                        Text(
                          'Big Topic:',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isLoading
                              ? const SizedBox.shrink()
                              : _BigTopicDropdown(
                                  topics: _bigTopics,
                                  selected: _selectedBigTopic,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedBigTopic = val;
                                      _expandedIndex = null;
                                    });
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Scenario List ───────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.dmSans(
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadScenarios,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No scenarios found',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final scenario = filtered[i];
                          final globalIndex = _allScenarios.indexOf(scenario);
                          final isLocked = !_proService.isProUnlocked &&
                              !scenario.isUserCreated &&
                              globalIndex >= _freeScenarioLimit;
                          final isExpanded = _expandedIndex == i;
                          final isBookmarked = bookmarkProvider
                              .isRealCaseBookmarked(scenario.id);
                          return _ScenarioCard(
                            scenario: scenario,
                            isExpanded: isExpanded,
                            isBookmarked: isBookmarked,
                            isLocked: isLocked,
                            onTap: isLocked
                                ? _showPaywall
                                : () => setState(() {
                                    _expandedIndex = isExpanded ? null : i;
                                  }),
                            onBookmark: isLocked
                                ? _showPaywall
                                : () => _toggleBookmark(ctx, scenario),
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

// ── Big Topic Dropdown ────────────────────────────────────────────────────────

class _BigTopicDropdown extends StatelessWidget {
  final List<String> topics;
  final String selected;
  final ValueChanged<String> onChanged;

  const _BigTopicDropdown({
    required this.topics,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Colors.grey.shade600,
          ),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: topics
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
        ),
      ),
    );
  }
}

// ── Scenario Card ─────────────────────────────────────────────────────────────

class _ScenarioCard extends StatelessWidget {
  final RealCaseScenario scenario;
  final bool isExpanded;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final bool isLocked;

  const _ScenarioCard({
    required this.scenario,
    required this.isExpanded,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmark,
    required this.isLocked,
  });

  Color get _categoryColor {
    switch (scenario.category.toLowerCase()) {
      case 'sql':
        return const Color(0xFF1565C0);
      case 'python':
        return const Color(0xFF2E7D32);
      case 'kafka':
        return const Color(0xFF6A1B9A);
      case 'airflow':
        return const Color(0xFF00838F);
      case 'spark':
        return const Color(0xFFE64A19);
      case 'system design':
        return const Color(0xFF4527A0);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: catColor, width: 4)),
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
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: catColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  scenario.category,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              if (scenario.isUserCreated) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF9A825,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'My Scenario',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF9A825),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scenario.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLocked) ...[
                      const Icon(
                        Icons.lock_rounded,
                        size: 21,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: onBookmark,
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: 22,
                        color: isBookmarked
                            ? AppTheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                if (scenario.companies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: scenario.companies
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              c,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                // Show non-company tags as badge chips
                if (scenario.tags
                    .where((t) => !scenario.companies.contains(t))
                    .isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: scenario.tags
                        .where((t) => !scenario.companies.contains(t))
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: catColor.withAlpha(50)),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: catColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (!isExpanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    scenario.problemStatement,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  _SectionBlock(
                    label: '🔍 Problem Statement',
                    content: scenario.problemStatement,
                    color: catColor,
                  ),
                  const SizedBox(height: 10),
                  _SectionBlock(
                    label: '✅ Solution Breakdown',
                    content: scenario.solutionBreakdown,
                    color: catColor,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _SectionBlock({
    required this.label,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Scenario Bottom Sheet ──────────────────────────────────────────────

class _CreateScenarioSheet extends StatefulWidget {
  final void Function(RealCaseScenario) onCreated;

  const _CreateScenarioSheet({required this.onCreated});

  @override
  State<_CreateScenarioSheet> createState() => _CreateScenarioSheetState();
}

class _CreateScenarioSheetState extends State<_CreateScenarioSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Custom');
  final _problemCtrl = TextEditingController();
  final _solutionCtrl = TextEditingController();
  final _tagInputCtrl = TextEditingController();
  bool _isSaving = false;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _problemCtrl.dispose();
    _solutionCtrl.dispose();
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
      final category = _categoryCtrl.text.trim().isEmpty
          ? 'Custom'
          : _categoryCtrl.text.trim();
      await SupabaseService.instance.createUserRealCaseScenario(
        title: _titleCtrl.text.trim(),
        category: category,
        problemStatement: _problemCtrl.text.trim(),
        solutionBreakdown: _solutionCtrl.text.trim(),
        tags: List<String>.from(_tags),
      );
      if (mounted) {
        final newScenario = RealCaseScenario(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleCtrl.text.trim(),
          category: category,
          tags: List<String>.from(_tags),
          problemStatement: _problemCtrl.text.trim(),
          solutionBreakdown: _solutionCtrl.text.trim(),
          isActive: true,
          isUserCreated: true,
        );
        Navigator.pop(context);
        widget.onCreated(newScenario);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scenario created successfully!',
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
                'Create Real Case Scenario',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share a real-world data engineering scenario',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),
              _FormField(
                label: 'Title *',
                controller: _titleCtrl,
                hint: 'e.g. Pipeline failure at 3AM on Black Friday',
                maxLines: 1,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                label: 'Category',
                controller: _categoryCtrl,
                hint: 'e.g. SQL, Spark, Kafka, Custom',
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              _FormField(
                label: 'Problem Statement *',
                controller: _problemCtrl,
                hint: 'Describe the problem or challenge...',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                label: 'Solution Breakdown *',
                controller: _solutionCtrl,
                hint: 'How was it solved? What were the key decisions?',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              // Tags input
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
                        hintText: 'e.g. Amazon, Kafka, incident',
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
                          'Save Scenario',
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

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
