import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/developer_experience_model.dart';
import '../../models/flashcard_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../theme/app_theme.dart';
import '../code_playground_screen/code_playground_screen.dart';
import '../developer_experiences_screen/developer_experience_detail_screen.dart';
import '../flashcards_screen/flashcards_screen.dart';
import '../quiz_screen/quiz_screen.dart'
    as quiz_screen
    show QuizScreen, masterQuestionBank;

// ── Filter enum ───────────────────────────────────────────────────────────────
enum BookmarkFilter {
  all,
  scenarios,
  quizzes,
  flashcards,
  playground,
  experiences,
}

// Alias for internal use
typedef _BookmarkFilter = BookmarkFilter;

// ── Playground tip model (mirrors code_playground_screen) ────────────────────
class _PlaygroundTip {
  final String id;
  final String title;
  final String codeSnippet;
  final String language;

  const _PlaygroundTip({
    required this.id,
    required this.title,
    required this.codeSnippet,
    required this.language,
  });
}

const List<_PlaygroundTip> _allPlaygroundTips = [
  _PlaygroundTip(
    id: 'pg_sql_1',
    title: 'Window Function: Running Total',
    codeSnippet:
        'SELECT order_id, amount,\n  SUM(amount) OVER (ORDER BY order_date) AS running_total\nFROM orders;',
    language: 'SQL',
  ),
  _PlaygroundTip(
    id: 'pg_sql_2',
    title: 'CTE for Readable Queries',
    codeSnippet:
        'WITH ranked AS (\n  SELECT *, ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn\n  FROM employees\n)\nSELECT * FROM ranked WHERE rn = 1;',
    language: 'SQL',
  ),
  _PlaygroundTip(
    id: 'pg_sql_3',
    title: 'LATERAL JOIN for Row-Level Subqueries',
    codeSnippet:
        'SELECT u.user_id, recent.event_type\nFROM users u,\nLATERAL (\n  SELECT event_type FROM events e\n  WHERE e.user_id = u.user_id\n  ORDER BY event_time DESC LIMIT 1\n) recent;',
    language: 'SQL',
  ),
  _PlaygroundTip(
    id: 'pg_py_1',
    title: 'PySpark: GroupBy Aggregation',
    codeSnippet:
        'result = df.groupBy("customer_id") \\\n  .agg(\n    F.sum("amount").alias("total"),\n    F.count("order_id").alias("orders")\n  ) \\\n  .orderBy(F.desc("total"))',
    language: 'Python',
  ),
  _PlaygroundTip(
    id: 'pg_py_2',
    title: 'Pandas: Efficient Merge',
    codeSnippet:
        'result = pd.merge(\n  orders_df, customers_df,\n  on="customer_id", how="left",\n  validate="many_to_one"\n)',
    language: 'Python',
  ),
  _PlaygroundTip(
    id: 'pg_py_3',
    title: 'List Comprehension for Transformations',
    codeSnippet:
        'completed = [\n  {"id": o["id"], "revenue": o["amount"] * 1.1}\n  for o in orders\n  if o["status"] == "completed"\n]',
    language: 'Python',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class BookmarksScreen extends StatefulWidget {
  /// When set, the screen opens with this filter pre-selected.
  final BookmarkFilter initialFilter;

  const BookmarksScreen({super.key, this.initialFilter = BookmarkFilter.all});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late _BookmarkFilter _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final questionIds = bookmarkProvider.bookmarkedQuestionIds;
        final quizIds = bookmarkProvider.bookmarkedQuizIds;
        final flashcardIds = bookmarkProvider.bookmarkedFlashcardIds;
        final playgroundIds = bookmarkProvider.bookmarkedPlaygroundIds;
        final devExpIds = bookmarkProvider.bookmarkedDevExperienceIds;
        final totalCount = bookmarkProvider.totalBookmarkCount;
        final scenarioCount = questionIds.length;
        final quizCount = quizIds.length;
        final flashcardCount = flashcardIds.length;
        final playgroundCount = playgroundIds.length;
        final devExpCount = devExpIds.length;

        // Build filtered list of entries — each branch is strictly exclusive
        final List<_BookmarkEntry> entries = [];

        switch (_activeFilter) {
          case _BookmarkFilter.all:
            for (final q in sampleInterviewQuestions.where(
              (q) => questionIds.contains(q.id),
            )) {
              entries.add(_BookmarkEntry.question(q));
            }
            for (final id in quizIds) {
              entries.add(_BookmarkEntry.quiz(id));
            }
            for (final card in sampleFlashcards.where(
              (c) => flashcardIds.contains(c.id),
            )) {
              entries.add(_BookmarkEntry.flashcard(card));
            }
            for (final tip in _allPlaygroundTips.where(
              (t) => playgroundIds.contains(t.id),
            )) {
              entries.add(_BookmarkEntry.playground(tip));
            }
            for (final exp in devExperiences.where(
              (e) => devExpIds.contains(e.id),
            )) {
              entries.add(_BookmarkEntry.experience(exp));
            }
            break;
          case _BookmarkFilter.scenarios:
            for (final q in sampleInterviewQuestions.where(
              (q) => questionIds.contains(q.id),
            )) {
              entries.add(_BookmarkEntry.question(q));
            }
            break;
          case _BookmarkFilter.quizzes:
            // Strictly show ONLY quiz-type bookmarks (type == 'quiz')
            for (final id in quizIds) {
              entries.add(_BookmarkEntry.quiz(id));
            }
            break;
          case _BookmarkFilter.flashcards:
            for (final card in sampleFlashcards.where(
              (c) => flashcardIds.contains(c.id),
            )) {
              entries.add(_BookmarkEntry.flashcard(card));
            }
            break;
          case _BookmarkFilter.playground:
            for (final tip in _allPlaygroundTips.where(
              (t) => playgroundIds.contains(t.id),
            )) {
              entries.add(_BookmarkEntry.playground(tip));
            }
            break;
          case _BookmarkFilter.experiences:
            for (final exp in devExperiences.where(
              (e) => devExpIds.contains(e.id),
            )) {
              entries.add(_BookmarkEntry.experience(exp));
            }
            break;
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            title: Text(
              'Bookmarks 🔖',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              if (totalCount > 0)
                TextButton(
                  onPressed: () => _confirmClearAll(context, bookmarkProvider),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                ),
            ],
          ),
          body: totalCount == 0
              ? _buildEmptyState()
              : Column(
                  children: [
                    // ── Filter pills ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _FilterPills(
                        activeFilter: _activeFilter,
                        totalCount: totalCount,
                        scenarioCount: scenarioCount,
                        quizCount: quizCount,
                        flashcardCount: flashcardCount,
                        playgroundCount: playgroundCount,
                        devExpCount: devExpCount,
                        onChanged: (f) => setState(() => _activeFilter = f),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── List ──────────────────────────────────────────────────
                    Expanded(
                      child: entries.isEmpty
                          ? _buildFilterEmptyState(_activeFilter)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final entry = entries[i];
                                if (entry.isQuestion &&
                                    entry.question != null) {
                                  return _ScenarioBookmarkCard(
                                    question: entry.question!,
                                    onTap: () => _openQuestionDetail(
                                      context,
                                      entry.question!,
                                    ),
                                    onRemove: () {
                                      bookmarkProvider.removeQuestion(
                                        entry.question!.id,
                                      );
                                      _showRemovedSnackBar(context);
                                    },
                                  );
                                } else if (entry.isQuiz) {
                                  return _QuizBookmarkCard(
                                    quizId: entry.quizId!,
                                    onRemove: () {
                                      bookmarkProvider.removeQuiz(
                                        entry.quizId!,
                                      );
                                      _showRemovedSnackBar(context);
                                    },
                                  );
                                } else if (entry.isFlashcard &&
                                    entry.flashcard != null) {
                                  return _FlashcardBookmarkCard(
                                    card: entry.flashcard!,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FlashcardsScreen(
                                          initialCardId: entry.flashcard!.id,
                                        ),
                                      ),
                                    ),
                                    onRemove: () {
                                      bookmarkProvider.removeFlashcard(
                                        entry.flashcard!.id,
                                      );
                                      _showRemovedSnackBar(context);
                                    },
                                  );
                                } else if (entry.isPlayground &&
                                    entry.playgroundTip != null) {
                                  return _PlaygroundBookmarkCard(
                                    tip: entry.playgroundTip!,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CodePlaygroundScreen(
                                          initialTipId: entry.playgroundTip!.id,
                                        ),
                                      ),
                                    ),
                                    onRemove: () {
                                      bookmarkProvider.removePlayground(
                                        entry.playgroundTip!.id,
                                      );
                                      _showRemovedSnackBar(context);
                                    },
                                  );
                                } else if (entry.isExperience &&
                                    entry.experience != null) {
                                  return _ExperienceBookmarkCard(
                                    experience: entry.experience!,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DeveloperExperienceDetailScreen(
                                              experience: entry.experience!,
                                            ),
                                      ),
                                    ),
                                    onRemove: () {
                                      bookmarkProvider.removeDevExperience(
                                        entry.experience!.id,
                                      );
                                      _showRemovedSnackBar(context);
                                    },
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _openQuestionDetail(
    BuildContext context,
    InterviewQuestionModel question,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QuestionDetailPage(question: question),
      ),
    );
  }

  void _showRemovedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed from Bookmarks',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, BookmarkProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All Bookmarks?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove all ${provider.totalBookmarkCount} saved items. This action cannot be undone.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppTheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: AppTheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No saved items yet',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap 🔖 on any scenario, quiz, flashcard, code tip, or dev experience to save it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(_BookmarkFilter filter) {
    final labels = {
      _BookmarkFilter.scenarios: 'scenarios',
      _BookmarkFilter.quizzes: 'quizzes',
      _BookmarkFilter.flashcards: 'flashcards',
      _BookmarkFilter.playground: 'code tips',
      _BookmarkFilter.experiences: 'dev experiences',
    };
    final label = labels[filter] ?? 'items';
    return Center(
      child: Text(
        'No saved $label yet.',
        style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey.shade500),
      ),
    );
  }
}

// ── Bookmark entry data holder ────────────────────────────────────────────────
class _BookmarkEntry {
  final bool isQuestion;
  final bool isQuiz;
  final bool isFlashcard;
  final bool isPlayground;
  final bool isExperience;
  final InterviewQuestionModel? question;
  final String? quizId;
  final FlashcardModel? flashcard;
  final _PlaygroundTip? playgroundTip;
  final DeveloperExperienceModel? experience;

  _BookmarkEntry.question(this.question)
    : isQuestion = true,
      isQuiz = false,
      isFlashcard = false,
      isPlayground = false,
      isExperience = false,
      quizId = null,
      flashcard = null,
      playgroundTip = null,
      experience = null;

  _BookmarkEntry.quiz(this.quizId)
    : isQuestion = false,
      isQuiz = true,
      isFlashcard = false,
      isPlayground = false,
      isExperience = false,
      question = null,
      flashcard = null,
      playgroundTip = null,
      experience = null;

  _BookmarkEntry.flashcard(this.flashcard)
    : isQuestion = false,
      isQuiz = false,
      isFlashcard = true,
      isPlayground = false,
      isExperience = false,
      question = null,
      quizId = null,
      playgroundTip = null,
      experience = null;

  _BookmarkEntry.playground(this.playgroundTip)
    : isQuestion = false,
      isQuiz = false,
      isFlashcard = false,
      isPlayground = true,
      isExperience = false,
      question = null,
      quizId = null,
      flashcard = null,
      experience = null;

  _BookmarkEntry.experience(this.experience)
    : isQuestion = false,
      isQuiz = false,
      isFlashcard = false,
      isPlayground = false,
      isExperience = true,
      question = null,
      quizId = null,
      flashcard = null,
      playgroundTip = null;
}

// ── Filter Pills ──────────────────────────────────────────────────────────────
class _FilterPills extends StatelessWidget {
  final _BookmarkFilter activeFilter;
  final int totalCount;
  final int scenarioCount;
  final int quizCount;
  final int flashcardCount;
  final int playgroundCount;
  final int devExpCount;
  final ValueChanged<_BookmarkFilter> onChanged;

  const _FilterPills({
    required this.activeFilter,
    required this.totalCount,
    required this.scenarioCount,
    required this.quizCount,
    required this.flashcardCount,
    required this.playgroundCount,
    required this.devExpCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Pill(
            label: 'All ($totalCount)',
            isActive: activeFilter == _BookmarkFilter.all,
            onTap: () => onChanged(_BookmarkFilter.all),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Scenarios ($scenarioCount)',
            isActive: activeFilter == _BookmarkFilter.scenarios,
            onTap: () => onChanged(_BookmarkFilter.scenarios),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Quizzes ($quizCount)',
            isActive: activeFilter == _BookmarkFilter.quizzes,
            onTap: () => onChanged(_BookmarkFilter.quizzes),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Flashcards ($flashcardCount)',
            isActive: activeFilter == _BookmarkFilter.flashcards,
            onTap: () => onChanged(_BookmarkFilter.flashcards),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Playground ($playgroundCount)',
            isActive: activeFilter == _BookmarkFilter.playground,
            onTap: () => onChanged(_BookmarkFilter.playground),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: '🔥 Experiences ($devExpCount)',
            isActive: activeFilter == _BookmarkFilter.experiences,
            onTap: () => onChanged(_BookmarkFilter.experiences),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// ── Scenario Bookmark Card ────────────────────────────────────────────────────
class _ScenarioBookmarkCard extends StatelessWidget {
  final InterviewQuestionModel question;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ScenarioBookmarkCard({
    required this.question,
    required this.onTap,
    required this.onRemove,
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
    final companyTag = question.companies.isNotEmpty
        ? '[${question.companies.first[0].toUpperCase()}${question.companies.first.substring(1)}]'
        : '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeBadge(
                          label: 'Scenario',
                          color: AppTheme.primary.withAlpha(20),
                          textColor: AppTheme.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        _TypeBadge(
                          label: question.difficulty,
                          color: _difficultyColor.withAlpha(25),
                          textColor: _difficultyColor,
                        ),
                        if (companyTag.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            companyTag,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.category,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.bookmark,
                  size: 22,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quiz question text lookup ─────────────────────────────────────────────────
String _quizQuestionText(String quizId) {
  final match = quiz_screen.masterQuestionBank.firstWhere(
    (q) => q['id']?.toString() == quizId,
    orElse: () => const {},
  );

  // Use 'text' key (as defined in masterQuestionBank), fall back to 'question', 'title', 'prompt'
  final questionText =
      match['text'] ?? match['question'] ?? match['title'] ?? match['prompt'];

  return (questionText is String && questionText.trim().isNotEmpty)
      ? questionText
      : quizId;
}

// ── Quiz Bookmark Card ────────────────────────────────────────────────────────

/// Resolves the [topicId] and [topicName] for a given [quizId] by looking up
/// its category in [masterQuestionBank]. Falls back to the prefix-based mapping
/// for any IDs not found in the bank.
Map<String, String> _resolveQuizTopic(String quizId) {
  // 1. Direct lookup in masterQuestionBank by question id
  final match = quiz_screen.masterQuestionBank.firstWhere(
    (q) => q['id'] == quizId,
    orElse: () => const {},
  );

  if (match.isNotEmpty) {
    final category = match['category'] as String;
    return {'topicId': category, 'topicName': _topicNameForId(category)};
  }

  // 2. Prefix-based fallback for any future IDs not in the bank
  const prefixMap = <String, String>{
    'sql_': 'sql',
    'py_': 'python',
    'etl_': 'etl',
    'spark_': 'spark',
    'kafka_': 'kafka',
    'airflow_': 'airflow',
    'dbt_': 'dbt',
    'dm_': 'datamodeling',
    'cloud_': 'cloud',
    'docker_': 'docker',
    'nosql_': 'nosql',
    'dataops_': 'dataops',
    'meta_quiz_': 'datamodeling',
    'snow_quiz_': 'cloud',
    'dbx_quiz_': 'spark',
  };

  for (final entry in prefixMap.entries) {
    if (quizId.startsWith(entry.key)) {
      final id = entry.value;
      return {'topicId': id, 'topicName': _topicNameForId(id)};
    }
  }

  // 3. Ultimate fallback
  return {'topicId': 'sql', 'topicName': 'SQL & Query Optimization'};
}

/// Maps a topic [id] to its human-readable display name.
String _topicNameForId(String id) {
  const nameMap = <String, String>{
    'sql': 'SQL & Query Optimization',
    'python': 'Python for Data Engineering',
    'etl': 'ETL Pipelines & Workflows',
    'spark': 'Apache Spark & Big Data',
    'kafka': 'Kafka & Streaming Data',
    'airflow': 'Apache Airflow & Orchestration',
    'cloud': 'Cloud Data Platforms (AWS/GCP)',
    'dbt': 'dbt & Data Transformation',
    'datamodeling': 'Data Modeling & Warehousing',
    'docker': 'Docker & Containerization',
    'nosql': 'NoSQL Databases',
    'dataops': 'DataOps & CI/CD for Data',
  };
  return nameMap[id] ?? id;
}

class _QuizBookmarkCard extends StatelessWidget {
  final String quizId;
  final VoidCallback onRemove;

  const _QuizBookmarkCard({required this.quizId, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final topic = _resolveQuizTopic(quizId);
    final topicId = topic['topicId']!;
    final topicName = topic['topicName']!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Look up the exact bookmarked question from masterQuestionBank
          final questionMap = quiz_screen.masterQuestionBank.firstWhere(
            (q) => q['id'] == quizId,
            orElse: () => const {},
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => quiz_screen.QuizScreen(
                topicId: topicId,
                topicName: topicName,
                questionCount: 1,
                overrideQuestions: questionMap.isNotEmpty
                    ? [questionMap]
                    : null,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purple.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeBadge(
                      label: 'Quiz',
                      color: Colors.purple.shade50,
                      textColor: Colors.purple.shade700,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _quizQuestionText(quizId),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topicName,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.bookmark,
                  size: 22,
                  color: Colors.purple.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Flashcard Bookmark Card ───────────────────────────────────────────────────
class _FlashcardBookmarkCard extends StatelessWidget {
  final FlashcardModel card;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FlashcardBookmarkCard({
    required this.card,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.teal.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeBadge(
                          label: 'Flashcard',
                          color: Colors.teal.shade50,
                          textColor: Colors.teal.shade700,
                        ),
                        const SizedBox(width: 6),
                        _TypeBadge(
                          label: card.category,
                          color: AppTheme.primaryContainer,
                          textColor: AppTheme.primaryDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📖 Front',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.front,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💡 Back',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.back,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.bookmark,
                  size: 22,
                  color: Colors.teal.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Playground Bookmark Card ──────────────────────────────────────────────────
class _PlaygroundBookmarkCard extends StatelessWidget {
  final _PlaygroundTip tip;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaygroundBookmarkCard({
    required this.tip,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeBadge(
                          label: 'Code Tip',
                          color: const Color(0xFF1565C0).withAlpha(20),
                          textColor: const Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 6),
                        _TypeBadge(
                          label: tip.language,
                          color: AppTheme.primaryContainer,
                          textColor: AppTheme.primaryDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tip.codeSnippet,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: const Color(0xFFD4D4D4),
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.bookmark,
                  size: 22,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Experience Bookmark Card ──────────────────────────────────────────────────
class _ExperienceBookmarkCard extends StatelessWidget {
  final DeveloperExperienceModel experience;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ExperienceBookmarkCard({
    required this.experience,
    required this.onTap,
    required this.onRemove,
  });

  Color get _categoryColor {
    switch (experience.categoryTag) {
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 70,
                decoration: BoxDecoration(
                  color: _categoryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeBadge(
                          label: '🔥 Dev Experience',
                          color: _categoryColor.withAlpha(18),
                          textColor: _categoryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _TypeBadge(
                      label: experience.categoryTag,
                      color: _categoryColor.withAlpha(12),
                      textColor: _categoryColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      experience.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.bookmark, size: 22, color: _categoryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Type Badge ────────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _TypeBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Question Detail Page ──────────────────────────────────────────────────────
class _QuestionDetailPage extends StatelessWidget {
  final InterviewQuestionModel question;
  const _QuestionDetailPage({required this.question});

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
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final isBookmarked = bookmarkProvider.isQuestionBookmarked(question.id);
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Text(
              'Question Detail',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.difficulty,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _difficultyColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.category,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  question.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Problem Statement',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: const Color(0xFF444444),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Solution Breakdown',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                if (question.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
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
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
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
                        'Back to Bookmarks',
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
                        final added = bookmarkProvider.toggleQuestion(
                          question.id,
                        );
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Question saved to Bookmarks'
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
