import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/pro_service.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../performance_trends_screen/performance_trends_screen.dart';
import './widgets/category_filter_widget.dart';
import './widgets/customize_quiz_sheet_widget.dart';
import './widgets/pro_banner_widget.dart';
import './widgets/topic_card_widget.dart';
import './widgets/topics_search_bar_widget.dart';

class TopicModel {
  final String id;
  final String name;
  final String category;
  final String iconName;
  final int questionCount;
  final double accuracyPercent;
  final bool isPro;
  final Color iconColor;
  final int completedQuizzes;

  const TopicModel({
    required this.id,
    required this.name,
    required this.category,
    required this.iconName,
    required this.questionCount,
    required this.accuracyPercent,
    required this.isPro,
    required this.iconColor,
    required this.completedQuizzes,
  });

  factory TopicModel.fromMap(Map<String, dynamic> map) {
    return TopicModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      iconName: map['iconName'] as String,
      questionCount: map['questionCount'] as int,
      accuracyPercent: (map['accuracyPercent'] as num).toDouble(),
      isPro: map['isPro'] as bool,
      iconColor: Color(map['iconColor'] as int),
      completedQuizzes: map['completedQuizzes'] as int,
    );
  }
}

// ── Static topic metadata (display config only — no hardcoded question counts) ──
const List<Map<String, dynamic>> _kTopicMeta = [
  {
    'dbName': 'Apache Spark',
    'id': 'apache_spark',
    'name': 'Apache Spark',
    'category': 'Big Data',
    'iconName': 'bolt',
    'isPro': true,
    'iconColor': 0xFFE64A19,
  },
  {
    'dbName': 'SQL',
    'id': 'sql',
    'name': 'SQL',
    'category': 'Database',
    'iconName': 'storage',
    'isPro': false,
    'iconColor': 0xFF1565C0,
  },
  {
    'dbName': 'Python',
    'id': 'python',
    'name': 'Python',
    'category': 'Programming',
    'iconName': 'code',
    'isPro': false,
    'iconColor': 0xFF2E7D32,
  },
  {
    'dbName': 'Kafka',
    'id': 'kafka',
    'name': 'Kafka',
    'category': 'Streaming',
    'iconName': 'stream',
    'isPro': true,
    'iconColor': 0xFF6A1B9A,
  },
  {
    'dbName': 'Apache Airflow',
    'id': 'apache_airflow',
    'name': 'Apache Airflow',
    'category': 'Pipelines',
    'iconName': 'air',
    'isPro': false,
    'iconColor': 0xFF00838F,
  },
  {
    'dbName': 'Data Modeling',
    'id': 'data_modeling',
    'name': 'Data Modeling',
    'category': 'Database',
    'iconName': 'schema',
    'isPro': false,
    'iconColor': 0xFF4527A0,
  },
  {
    'dbName': 'Data Warehouse',
    'id': 'data_warehouse',
    'name': 'Data Warehouse',
    'category': 'Database',
    'iconName': 'warehouse',
    'isPro': true,
    'iconColor': 0xFF1976D2,
  },
  {
    'dbName': 'Cloud',
    'id': 'cloud',
    'name': 'Cloud',
    'category': 'Cloud',
    'iconName': 'cloud',
    'isPro': true,
    'iconColor': 0xFF0277BD,
  },
  {
    'dbName': 'Docker & DevOps',
    'id': 'docker_devops',
    'name': 'Docker & DevOps',
    'category': 'DevOps',
    'iconName': 'inventory_2',
    'isPro': false,
    'iconColor': 0xFF37474F,
  },
  {
    'dbName': 'Big Data Fundamentals',
    'id': 'big_data',
    'name': 'Big Data Fundamentals',
    'category': 'Big Data',
    'iconName': 'dataset',
    'isPro': false,
    'iconColor': 0xFF558B2F,
  },
];

class TopicsListScreen extends StatefulWidget {
  const TopicsListScreen({super.key});

  @override
  State<TopicsListScreen> createState() => _TopicsListScreenState();
}

class _TopicsListScreenState extends State<TopicsListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late List<TopicModel> _topics;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;
  bool _isProUnlocked = false;
  final ProService _proService = ProService();

  final List<String> _categories = [
    'All',
    'Database',
    'Programming',
    'Pipelines',
    'Big Data',
    'Streaming',
    'Cloud',
    'DevOps',
  ];

  @override
  void initState() {
    super.initState();
    // Build initial list with 0 question counts — will be updated from DB
    _topics = _kTopicMeta
        .map(
          (meta) => TopicModel.fromMap({
            ...meta,
            'questionCount': 0,
            'accuracyPercent': 0.0,
            'completedQuizzes': 0,
          }),
        )
        .toList();
    _isProUnlocked = _proService.isProUnlocked;
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeOutBack),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabAnimController.forward();
    });
    _fetchLiveCounts();
  }

  /// Fetch live question counts per topic from Supabase and update the list.
  Future<void> _fetchLiveCounts() async {
    try {
      final counts = await QuizService.instance.fetchTopicQuestionCounts();
      if (mounted && counts.isNotEmpty) {
        setState(() {
          _topics = _kTopicMeta.map((meta) {
            final dbName = meta['dbName'] as String;
            final liveCount = counts[dbName] ?? 0;
            return TopicModel.fromMap({
              ...meta,
              'questionCount': liveCount,
              'accuracyPercent': 0.0,
              'completedQuizzes': 0,
            });
          }).toList();
        });
      }
    } catch (_) {
      // Silently fall back to 0 counts
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  List<TopicModel> get _filteredTopics {
    return _topics.where((t) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || t.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onTopicTap(TopicModel topic) {
    if (topic.isPro && !_isProUnlocked) {
      _showProDialog(topic);
      return;
    }
    // All topics go to the generic subtopic screen
    _navigateToSubtopics(topic);
  }

  void _navigateToSubtopics(TopicModel topic) {
    context.push(
      AppRoutes.subtopicScreen,
      extra: {
        'topicName': _dbNameFor(topic.id),
        'topicColor': topic.iconColor.value,
        'topicIcon': _iconDataFor(topic.iconName),
      },
    );
  }

  /// Map topic id back to the canonical DB name
  String _dbNameFor(String id) {
    final meta = _kTopicMeta.firstWhere(
      (m) => m['id'] == id,
      orElse: () => _kTopicMeta.first,
    );
    return meta['dbName'] as String;
  }

  IconData _iconDataFor(String iconName) {
    const map = <String, IconData>{
      'bolt': Icons.bolt_rounded,
      'storage': Icons.storage_rounded,
      'code': Icons.code_rounded,
      'stream': Icons.stream_rounded,
      'air': Icons.air_rounded,
      'schema': Icons.schema_rounded,
      'warehouse': Icons.warehouse_rounded,
      'cloud': Icons.cloud_rounded,
      'inventory_2': Icons.inventory_2_rounded,
      'dataset': Icons.dataset_rounded,
    };
    return map[iconName] ?? Icons.quiz_rounded;
  }

  void _showProDialog(TopicModel topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopicLockedSheet(
        topicName: topic.name,
        onUnlock: () async {
          await _proService.unlockPro();
          if (mounted) {
            setState(() => _isProUnlocked = true);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🎉 Serious Mode unlocked! All topics are now accessible.',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _navigateToSubtopics(topic);
          }
        },
      ),
    );
  }

  void _showCustomizeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomizeQuizSheetWidget(
        topics: _topics.where((t) => !t.isPro).toList(),
        onStartQuiz: (topicId, topicName, count) {
          Navigator.of(ctx).pop();
          context.push(
            AppRoutes.quizScreen,
            extra: {
              'topicId': topicId,
              'topicName': topicName,
              'questionCount': count,
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final filtered = _filteredTopics;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: Column(
          children: [
            TopicsSearchBarWidget(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            CategoryFilterWidget(
              categories: _categories,
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            const ProBannerWidget(),
            _BuildCustomMockBanner(),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(theme)
                  : isTablet
                  ? _buildTabletGrid(filtered)
                  : _buildPhoneList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => context.go(AppRoutes.initial),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_rounded,
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
            'All Skills',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BookmarksScreen(
                  initialFilter: BookmarkFilter.quizzes,
                ),
              ),
            ),
            icon: const Icon(
              Icons.bookmark_rounded,
              color: AppTheme.secondary,
              size: 22,
            ),
            tooltip: 'Bookmarks',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PerformanceTrendsScreen(),
              ),
            ),
            icon: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Profile',
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneList(List<TopicModel> topics) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        await _fetchLiveCounts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: topics.length,
        itemBuilder: (ctx, i) {
          return _buildAnimatedItem(
            index: i,
            child: TopicCardWidget(
              topic: topics[i],
              onTap: () => _onTopicTap(topics[i]),
              isProUnlocked: _isProUnlocked,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabletGrid(List<TopicModel> topics) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: topics.length,
      itemBuilder: (ctx, i) => TopicCardWidget(
        topic: topics[i],
        onTap: () => _onTopicTap(topics[i]),
        isProUnlocked: _isProUnlocked,
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (ctx, val, ch) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: ch,
        ),
      ),
      child: child,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No topics found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or category filter.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Topic Locked Upgrade Sheet ────────────────────────────────────────────────

class _TopicLockedSheet extends StatefulWidget {
  final String topicName;
  final VoidCallback onUnlock;

  const _TopicLockedSheet({required this.topicName, required this.onUnlock});

  @override
  State<_TopicLockedSheet> createState() => _TopicLockedSheetState();
}

class _TopicLockedSheetState extends State<_TopicLockedSheet> {
  bool _isLoading = false;

  Future<void> _handleUnlock() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onUnlock();
  }

  @override
  Widget build(BuildContext context) {
    const tableRows = [
      ['Feature', 'Chill', 'Serious'],
      ['Core Flashcards', '10', '150+'],
      ['Interview Questions', '2 free', '150+'],
      ["Developer's Real Experiences 🗿", '✗', '✓'],
      ['Code Playground', '✗', '✓'],
      ['SQL/Python Practice', '✗', '✓'],
      ['Cheatsheets & Guides', '✗', '✓'],
      ['Offline Mode', '✗', '✓'],
      ['All Difficulty Levels', '✗', '✓'],
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF37474F).withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('🗿', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock Serious Mode 🗿',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.topicName}" is a Serious Mode topic. Unlock all questions, detailed explanations, and more.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: tableRows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  final isHeader = i == 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: isHeader
                          ? const Color(0xFFFFF8E1)
                          : i.isEven
                          ? Colors.grey.shade50
                          : Colors.white,
                      borderRadius: i == 0
                          ? const BorderRadius.vertical(
                              top: Radius.circular(12),
                            )
                          : i == tableRows.length - 1
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            )
                          : null,
                      border: i > 0
                          ? Border(top: BorderSide(color: Colors.grey.shade100))
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            row[0],
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: isHeader
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isHeader
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: isHeader
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '☕',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        row[1],
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF546E7A),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    row[1],
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: isHeader
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🗿',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        row[2],
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFFF8C00),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    row[2],
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: row[2] == '✓'
                                          ? const Color(0xFF2E7D32)
                                          : row[2] == '✗'
                                          ? Colors.red.shade400
                                          : const Color(0xFFFF8C00),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFFB300)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUnlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '\$19.99 — One-time payment • Lifetime access',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Stay in Chill Mode',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildCustomMockBanner extends StatelessWidget {
  const _BuildCustomMockBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.customQuizBuilderScreen),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF00897B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00695C).withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Custom Mock Test',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Mix skills, pick subtopics & tune counts',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(204),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
