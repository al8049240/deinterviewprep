import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../leaderboard_screen/leaderboard_screen.dart';
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

class TopicsListScreen extends StatefulWidget {
  const TopicsListScreen({super.key});

  @override
  State<TopicsListScreen> createState() => _TopicsListScreenState();
}

class _TopicsListScreenState extends State<TopicsListScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late List<TopicModel> _topics;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  final List<Map<String, dynamic>> _topicMaps = [
    {
      'id': 'sql',
      'name': 'SQL & Query Optimization',
      'category': 'Database',
      'iconName': 'storage',
      'questionCount': 85,
      'accuracyPercent': 72.0,
      'isPro': false,
      'iconColor': 0xFF1565C0,
      'completedQuizzes': 6,
    },
    {
      'id': 'python',
      'name': 'Python for Data Engineering',
      'category': 'Programming',
      'iconName': 'code',
      'questionCount': 110,
      'accuracyPercent': 58.5,
      'isPro': false,
      'iconColor': 0xFF2E7D32,
      'completedQuizzes': 4,
    },
    {
      'id': 'etl',
      'name': 'ETL Pipelines & Workflows',
      'category': 'Pipelines',
      'iconName': 'swap_horiz',
      'questionCount': 65,
      'accuracyPercent': 81.0,
      'isPro': false,
      'iconColor': 0xFFF57F17,
      'completedQuizzes': 8,
    },
    {
      'id': 'spark',
      'name': 'Apache Spark & Big Data',
      'category': 'Big Data',
      'iconName': 'bolt',
      'questionCount': 90,
      'accuracyPercent': 44.0,
      'isPro': true,
      'iconColor': 0xFFE64A19,
      'completedQuizzes': 2,
    },
    {
      'id': 'kafka',
      'name': 'Kafka & Streaming Data',
      'category': 'Streaming',
      'iconName': 'stream',
      'questionCount': 70,
      'accuracyPercent': 0.0,
      'isPro': true,
      'iconColor': 0xFF6A1B9A,
      'completedQuizzes': 0,
    },
    {
      'id': 'airflow',
      'name': 'Apache Airflow & Orchestration',
      'category': 'Pipelines',
      'iconName': 'air',
      'questionCount': 55,
      'accuracyPercent': 63.0,
      'isPro': false,
      'iconColor': 0xFF00838F,
      'completedQuizzes': 3,
    },
    {
      'id': 'cloud',
      'name': 'Cloud Data Platforms (AWS/GCP)',
      'category': 'Cloud',
      'iconName': 'cloud',
      'questionCount': 95,
      'accuracyPercent': 0.0,
      'isPro': true,
      'iconColor': 0xFF1976D2,
      'completedQuizzes': 0,
    },
    {
      'id': 'dbt',
      'name': 'dbt & Data Transformation',
      'category': 'Database',
      'iconName': 'transform',
      'questionCount': 48,
      'accuracyPercent': 77.5,
      'isPro': false,
      'iconColor': 0xFF558B2F,
      'completedQuizzes': 5,
    },
    {
      'id': 'datamodeling',
      'name': 'Data Modeling & Warehousing',
      'category': 'Database',
      'iconName': 'schema',
      'questionCount': 72,
      'accuracyPercent': 55.0,
      'isPro': false,
      'iconColor': 0xFF4527A0,
      'completedQuizzes': 3,
    },
    {
      'id': 'docker',
      'name': 'Docker & Containerization',
      'category': 'DevOps',
      'iconName': 'inventory_2',
      'questionCount': 40,
      'accuracyPercent': 0.0,
      'isPro': true,
      'iconColor': 0xFF0277BD,
      'completedQuizzes': 0,
    },
    {
      'id': 'nosql',
      'name': 'NoSQL Databases',
      'category': 'Database',
      'iconName': 'dataset',
      'questionCount': 60,
      'accuracyPercent': 68.0,
      'isPro': false,
      'iconColor': 0xFF00695C,
      'completedQuizzes': 4,
    },
    {
      'id': 'dataops',
      'name': 'DataOps & CI/CD for Data',
      'category': 'DevOps',
      'iconName': 'loop',
      'questionCount': 35,
      'accuracyPercent': 0.0,
      'isPro': true,
      'iconColor': 0xFF37474F,
      'completedQuizzes': 0,
    },
  ];

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
    _topics = _topicMaps.map(TopicModel.fromMap).toList();
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
    if (topic.isPro) {
      _showProDialog(topic);
      return;
    }
    context.push(
      AppRoutes.quizScreen,
      extra: {
        'topicId': topic.id,
        'topicName': topic.name,
        'questionCount': 15,
      },
    );
  }

  void _showProDialog(TopicModel topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopicLockedSheet(
        topicName: topic.name,
        onUnlock: () {
          Navigator.pop(context);
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
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: FloatingActionButton.extended(
          onPressed: _showCustomizeSheet,
          backgroundColor: AppTheme.secondary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.tune_rounded),
          label: Text(
            'Customize Quiz',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
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
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
            icon: const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.secondary,
              size: 22,
            ),
            tooltip: 'Leaderboard',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
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
        await Future.delayed(const Duration(milliseconds: 800));
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

class _TopicLockedSheet extends StatelessWidget {
  final String topicName;
  final VoidCallback onUnlock;

  const _TopicLockedSheet({required this.topicName, required this.onUnlock});

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
            // Handle bar
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
              '"$topicName" is a Serious Mode topic. Unlock all questions, detailed explanations, and more.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Comparison table
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
            // CTA button — orange/gold gradient
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
                  onPressed: onUnlock,
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
                  child: Text(
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
              onPressed: () => Navigator.pop(context),
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
