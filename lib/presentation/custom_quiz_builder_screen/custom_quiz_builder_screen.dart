import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';

// ── Data models ───────────────────────────────────────────────────────────────

/// Describes a slice of questions to fetch for the chunked quiz loader.
class _QuizChunk {
  final int? topicId;
  final int? subtopicId;
  final String mode; // 'all', 'count', 'range'
  final int count;
  final int startIndex;
  final int endIndex;

  const _QuizChunk({
    required this.topicId,
    required this.subtopicId,
    required this.mode,
    required this.count,
    required this.startIndex,
    required this.endIndex,
  });
}

class _SkillData {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  int totalQuestions;
  bool isSelected = false;
  bool isExpanded = false;
  List<_SubtopicData> subtopics = [];
  bool subtopicsLoaded = false;

  _SkillData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.totalQuestions = 0,
  });
}

class _SubtopicData {
  final int id;
  final String name;
  final int totalQuestions;
  bool isSelected = false;
  // mode: 'all', 'count', 'range'
  String mode = 'all';
  int questionCount;
  int startIndex = 1;
  int endIndex;

  _SubtopicData({
    required this.id,
    required this.name,
    required this.totalQuestions,
    int? questionCount,
    int? endIndex,
  }) : questionCount = questionCount ?? totalQuestions,
       endIndex = endIndex ?? totalQuestions;

  int get effectiveCount {
    if (mode == 'all') return totalQuestions;
    if (mode == 'count') return questionCount.clamp(1, totalQuestions);
    if (mode == 'range') {
      final s = startIndex.clamp(1, totalQuestions);
      final e = endIndex.clamp(s, totalQuestions);
      return e - s + 1;
    }
    return totalQuestions;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CustomQuizBuilderScreen extends StatefulWidget {
  const CustomQuizBuilderScreen({super.key});

  @override
  State<CustomQuizBuilderScreen> createState() =>
      _CustomQuizBuilderScreenState();
}

class _CustomQuizBuilderScreenState extends State<CustomQuizBuilderScreen> {
  final QuizService _quizService = QuizService.instance;

  bool _isLoadingSkills = true;
  bool _isStartingQuiz = false;
  String? _errorMessage;

  final List<_SkillData> _skills = [];

  // Predefined skill metadata (emoji + color)
  static const Map<String, Map<String, dynamic>> _skillMeta = {
    'SQL': {'emoji': '🗄️', 'color': 0xFF1565C0},
    'Python': {'emoji': '🐍', 'color': 0xFF2E7D32},
    'Apache Kafka': {'emoji': '📨', 'color': 0xFF6A1B9A},
    'Apache Spark': {'emoji': '⚡', 'color': 0xFFE65100},
    'Airflow': {'emoji': '🌬️', 'color': 0xFF00838F},
    'dbt': {'emoji': '🔧', 'color': 0xFFAD1457},
    'Data Modeling': {'emoji': '📐', 'color': 0xFF37474F},
    'Cloud': {'emoji': '☁️', 'color': 0xFF0277BD},
    'Kafka': {'emoji': '📨', 'color': 0xFF6A1B9A},
    'Spark': {'emoji': '⚡', 'color': 0xFFE65100},
  };

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoadingSkills = true;
      _errorMessage = null;
    });
    try {
      final counts = await _quizService.fetchTopicQuestionCounts();
      final skills = <_SkillData>[];
      for (final entry in counts.entries) {
        if (entry.value == 0) continue;
        // Skip alias entries
        if (entry.key == 'spark') continue;
        final meta =
            _skillMeta[entry.key] ??
            _skillMeta.entries
                .firstWhere(
                  (e) => entry.key.toLowerCase().contains(e.key.toLowerCase()),
                  orElse: () => const MapEntry('', {}),
                )
                .value;
        skills.add(
          _SkillData(
            id: entry.key,
            name: entry.key,
            emoji: meta['emoji']?.toString() ?? '📚',
            color: Color(meta['color'] as int? ?? 0xFF2E7D32),
            totalQuestions: entry.value,
          ),
        );
      }
      skills.sort((a, b) => b.totalQuestions.compareTo(a.totalQuestions));
      setState(() {
        _skills.clear();
        _skills.addAll(skills);
        _isLoadingSkills = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSkills = false;
        _errorMessage = 'Failed to load topics. Please try again.';
      });
    }
  }

  Future<void> _loadSubtopics(_SkillData skill) async {
    if (skill.subtopicsLoaded) return;
    try {
      final topicId = await _quizService.fetchTopicId(skill.name);
      if (topicId == null) {
        setState(() {
          skill.subtopicsLoaded = true;
        });
        return;
      }
      final rows = await _quizService.fetchSubtopics(topicId);
      final subtopics = <_SubtopicData>[];
      for (final row in rows) {
        final subId = (row['id'] as num?)?.toInt();
        final subName = row['name']?.toString() ?? '';
        if (subId == null || subName.isEmpty) continue;
        final count = await _quizService.fetchSubtopicQuestionCount(subId);
        if (count == 0) continue;
        subtopics.add(
          _SubtopicData(id: subId, name: subName, totalQuestions: count),
        );
      }
      setState(() {
        skill.subtopics = subtopics;
        skill.subtopicsLoaded = true;
      });
    } catch (_) {
      setState(() {
        skill.subtopicsLoaded = true;
      });
    }
  }

  void _toggleSkill(_SkillData skill) async {
    setState(() {
      skill.isSelected = !skill.isSelected;
      if (skill.isSelected) {
        skill.isExpanded = true;
      } else {
        skill.isExpanded = false;
        // Deselect all subtopics
        for (final s in skill.subtopics) {
          s.isSelected = false;
        }
      }
    });
    if (skill.isSelected && !skill.subtopicsLoaded) {
      await _loadSubtopics(skill);
    }
  }

  void _toggleExpand(_SkillData skill) async {
    setState(() {
      skill.isExpanded = !skill.isExpanded;
    });
    if (skill.isExpanded && !skill.subtopicsLoaded) {
      await _loadSubtopics(skill);
    }
  }

  void _toggleSubtopic(_SkillData skill, _SubtopicData sub) {
    setState(() {
      sub.isSelected = !sub.isSelected;
    });
  }

  // ── Summary computations ──────────────────────────────────────────────────

  int get _selectedSkillsCount => _skills.where((s) => s.isSelected).length;

  int get _selectedSubtopicsCount =>
      _skills.expand((s) => s.subtopics).where((sub) => sub.isSelected).length;

  int get _totalSelectedQuestions {
    int total = 0;
    for (final skill in _skills.where((s) => s.isSelected)) {
      final selectedSubs = skill.subtopics.where((s) => s.isSelected).toList();
      if (selectedSubs.isEmpty) {
        // No subtopics selected → use full skill count
        total += skill.totalQuestions;
      } else {
        for (final sub in selectedSubs) {
          total += sub.effectiveCount;
        }
      }
    }
    return total;
  }

  bool get _canStart => _selectedSkillsCount > 0 && _totalSelectedQuestions > 0;

  // ── Chunked quiz loading (Improvement 3: batch pagination) ────────────────

  static const int _kFirstBatchSize = 5;
  static const int _kPrefetchBatchSize = 20;

  /// Collects question IDs/specs for each selected subtopic/skill,
  /// then loads the first [_kFirstBatchSize] questions immediately and
  /// pre-fetches the rest in the background so the quiz starts fast.
  Future<void> _startQuiz() async {
    if (!_canStart || _isStartingQuiz) return;
    setState(() => _isStartingQuiz = true);

    try {
      // ── Step 1: Resolve topic IDs for selected skills ──────────────────
      final List<_QuizChunk> chunks = [];

      for (final skill in _skills.where((s) => s.isSelected)) {
        final selectedSubs = skill.subtopics
            .where((s) => s.isSelected)
            .toList();

        if (selectedSubs.isEmpty) {
          final topicId = await _quizService.fetchTopicId(skill.id);
          if (topicId != null) {
            chunks.add(
              _QuizChunk(
                topicId: topicId,
                subtopicId: null,
                mode: 'all',
                count: skill.totalQuestions,
                startIndex: 0,
                endIndex: skill.totalQuestions,
              ),
            );
          }
        } else {
          for (final sub in selectedSubs) {
            chunks.add(
              _QuizChunk(
                topicId: null,
                subtopicId: sub.id,
                mode: sub.mode,
                count: sub.questionCount,
                startIndex: sub.startIndex - 1,
                endIndex: sub.endIndex,
              ),
            );
          }
        }
      }

      if (chunks.isEmpty) {
        if (mounted) setState(() => _isStartingQuiz = false);
        return;
      }

      // ── Step 2: load enough questions to satisfy the requested set size ─
      final firstBatch = <Map<String, dynamic>>[];
      var remainingNeeded = _totalSelectedQuestions;
      for (final chunk in chunks) {
        if (remainingNeeded <= 0) break;

        final questions = await _fetchChunkPaged(
          chunk,
          offset: 0,
          batchSize: remainingNeeded,
        );
        final accepted = questions.take(remainingNeeded).toList();
        firstBatch.addAll(accepted);
        remainingNeeded -= accepted.length;
      }

      firstBatch.shuffle(Random());

      if (!mounted) return;

      if (firstBatch.isEmpty) {
        setState(() => _isStartingQuiz = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No questions found for the selected topics.'),
          ),
        );
        return;
      }

      final skillNames = _skills
          .where((s) => s.isSelected)
          .map((s) => s.name)
          .join(' + ');

      // ── Step 3: Launch quiz with first batch, prefetch rest in background ─
      // We pass the first batch immediately so the quiz starts without delay.
      // The background prefetch populates the cache so subsequent questions
      // load from memory rather than making new network requests.
      unawaited(_prefetchRemainingChunks(chunks));

      context.push(
        AppRoutes.quizScreen,
        extra: {
          'topicId': 'custom_mixed',
          'topicName': skillNames,
          'questionCount': firstBatch.length,
          'overrideQuestions': firstBatch,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
      }
    } finally {
      if (mounted) setState(() => _isStartingQuiz = false);
    }
  }

  /// Fetches a paged slice of questions for a chunk spec.
  Future<List<Map<String, dynamic>>> _fetchChunkPaged(
    _QuizChunk chunk, {
    required int offset,
    required int batchSize,
  }) async {
    List<QuizQuestionModel> questions;
    if (chunk.subtopicId != null) {
      questions = await _quizService.fetchQuestionsBySubtopicIdPaged(
        subtopicId: chunk.subtopicId!,
        offset: offset,
        batchSize: batchSize,
      );
    } else if (chunk.topicId != null) {
      questions = await _quizService.fetchQuestionsByTopicIdPaged(
        topicId: chunk.topicId!,
        offset: offset,
        batchSize: batchSize,
      );
    } else {
      return [];
    }

    List<Map<String, dynamic>> maps = questions
        .map((q) => q.toLegacyMap())
        .toList();

    if (chunk.mode == 'count') {
      maps = maps.take(chunk.count).toList();
    } else if (chunk.mode == 'range') {
      final s = chunk.startIndex.clamp(0, maps.length);
      final e = chunk.endIndex.clamp(s, maps.length);
      maps = maps.sublist(s, e);
    }
    return maps;
  }

  /// Background prefetch: loads remaining questions into the service cache
  /// so they are ready when the quiz screen requests them.
  Future<void> _prefetchRemainingChunks(List<_QuizChunk> chunks) async {
    for (final chunk in chunks) {
      try {
        if (chunk.subtopicId != null) {
          // Warm the full subtopic cache in background
          await _quizService.fetchQuestionsBySubtopicId(chunk.subtopicId!);
        } else if (chunk.topicId != null) {
          await _quizService.fetchQuestionsByTopicId(chunk.topicId!);
        }
        // Small yield between prefetches to avoid blocking the UI thread
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (_) {
        // Prefetch failures are silent — quiz still works with cached first batch
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Build Custom Mock Test',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header hint bar
          Container(
            width: double.infinity,
            color: AppTheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select skills → pick subtopics → tune question counts',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _isLoadingSkills
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _errorMessage != null
                ? _ErrorView(message: _errorMessage!, onRetry: _loadSkills)
                : _skills.isEmpty
                ? _EmptyView()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _skills.length,
                    itemBuilder: (context, index) {
                      return _SkillCard(
                        skill: _skills[index],
                        onToggleSkill: () => _toggleSkill(_skills[index]),
                        onToggleExpand: () => _toggleExpand(_skills[index]),
                        onToggleSubtopic: (sub) =>
                            _toggleSubtopic(_skills[index], sub),
                        onSubtopicChanged: () => setState(() {}),
                      );
                    },
                  ),
          ),

          // Sticky summary footer
          _SummaryFooter(
            skillsCount: _selectedSkillsCount,
            subtopicsCount: _selectedSubtopicsCount,
            totalQuestions: _totalSelectedQuestions,
            canStart: _canStart,
            isLoading: _isStartingQuiz,
            onStart: _startQuiz,
          ),
        ],
      ),
    );
  }
}

// ── Skill Card ────────────────────────────────────────────────────────────────

class _SkillCard extends StatelessWidget {
  final _SkillData skill;
  final VoidCallback onToggleSkill;
  final VoidCallback onToggleExpand;
  final void Function(_SubtopicData) onToggleSubtopic;
  final VoidCallback onSubtopicChanged;

  const _SkillCard({
    required this.skill,
    required this.onToggleSkill,
    required this.onToggleExpand,
    required this.onToggleSubtopic,
    required this.onSubtopicChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: skill.isSelected
              ? skill.color.withAlpha(180)
              : const Color(0xFFEEEEEE),
          width: skill.isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Skill header row
          InkWell(
            onTap: onToggleSkill,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: skill.isSelected ? skill.color : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: skill.isSelected
                            ? skill.color
                            : const Color(0xFFCCCCCC),
                        width: 1.5,
                      ),
                    ),
                    child: skill.isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  // Emoji + name
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: skill.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        skill.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '${skill.totalQuestions} questions',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand toggle
                  GestureDetector(
                    onTap: onToggleExpand,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedRotation(
                        turns: skill.isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: skill.isSelected
                              ? skill.color
                              : const Color(0xFF999999),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subtopics expansion
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: skill.isExpanded
                ? _SubtopicsSection(
                    skill: skill,
                    onToggleSubtopic: onToggleSubtopic,
                    onSubtopicChanged: onSubtopicChanged,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Subtopics Section ─────────────────────────────────────────────────────────

class _SubtopicsSection extends StatelessWidget {
  final _SkillData skill;
  final void Function(_SubtopicData) onToggleSubtopic;
  final VoidCallback onSubtopicChanged;

  const _SubtopicsSection({
    required this.skill,
    required this.onToggleSubtopic,
    required this.onSubtopicChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!skill.subtopicsLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
        ),
      );
    }

    if (skill.subtopics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'No subtopics available — all ${skill.totalQuestions} questions will be included.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF777777),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Divider(
          height: 1,
          color: skill.color.withAlpha(40),
          indent: 14,
          endIndent: 14,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Subtopics',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${skill.subtopics.where((s) => s.isSelected).length}/${skill.subtopics.length} selected',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...skill.subtopics.map(
                (sub) => _SubtopicRow(
                  sub: sub,
                  skillColor: skill.color,
                  onToggle: () => onToggleSubtopic(sub),
                  onChanged: onSubtopicChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Subtopic Row ──────────────────────────────────────────────────────────────

class _SubtopicRow extends StatefulWidget {
  final _SubtopicData sub;
  final Color skillColor;
  final VoidCallback onToggle;
  final VoidCallback onChanged;

  const _SubtopicRow({
    required this.sub,
    required this.skillColor,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  State<_SubtopicRow> createState() => _SubtopicRowState();
}

class _SubtopicRowState extends State<_SubtopicRow> {
  late TextEditingController _countController;
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(
      text: widget.sub.questionCount.toString(),
    );
    _startController = TextEditingController(
      text: widget.sub.startIndex.toString(),
    );
    _endController = TextEditingController(
      text: widget.sub.endIndex.toString(),
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _setMode(String mode) {
    setState(() {
      widget.sub.mode = mode;
    });
    widget.onChanged();
  }

  String? _validateRange() {
    if (widget.sub.mode != 'range') return null;
    if (widget.sub.startIndex > widget.sub.endIndex) {
      return 'Start must be ≤ End';
    }
    if (widget.sub.endIndex > widget.sub.totalQuestions) {
      return 'End exceeds ${widget.sub.totalQuestions} available';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rangeError = _validateRange();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.sub.isSelected
            ? widget.skillColor.withAlpha(12)
            : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.sub.isSelected
              ? widget.skillColor.withAlpha(100)
              : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        children: [
          // Subtopic header
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: widget.sub.isSelected
                          ? widget.skillColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: widget.sub.isSelected
                            ? widget.skillColor
                            : const Color(0xFFCCCCCC),
                        width: 1.5,
                      ),
                    ),
                    child: widget.sub.isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.sub.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.skillColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.sub.totalQuestions}Q',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.skillColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tuning controls (only when selected)
          if (widget.sub.isSelected) ...[
            Divider(
              height: 1,
              color: widget.skillColor.withAlpha(30),
              indent: 10,
              endIndent: 10,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode pills
                  Row(
                    children: [
                      _ModePill(
                        label: 'All',
                        isActive: widget.sub.mode == 'all',
                        color: widget.skillColor,
                        onTap: () => _setMode('all'),
                      ),
                      const SizedBox(width: 6),
                      _ModePill(
                        label: 'Count',
                        isActive: widget.sub.mode == 'count',
                        color: widget.skillColor,
                        onTap: () => _setMode('count'),
                      ),
                      const SizedBox(width: 6),
                      _ModePill(
                        label: 'Range',
                        isActive: widget.sub.mode == 'range',
                        color: widget.skillColor,
                        onTap: () => _setMode('range'),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.sub.effectiveCount} selected',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.skillColor,
                        ),
                      ),
                    ],
                  ),

                  // Count input
                  if (widget.sub.mode == 'count') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Questions:',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _NumberInput(
                          controller: _countController,
                          min: 1,
                          max: widget.sub.totalQuestions,
                          color: widget.skillColor,
                          onChanged: (v) {
                            setState(() {
                              widget.sub.questionCount = v.clamp(
                                1,
                                widget.sub.totalQuestions,
                              );
                            });
                            widget.onChanged();
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'of ${widget.sub.totalQuestions}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Range input
                  if (widget.sub.mode == 'range') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Q',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _NumberInput(
                          controller: _startController,
                          min: 1,
                          max: widget.sub.totalQuestions,
                          color: widget.skillColor,
                          onChanged: (v) {
                            setState(() {
                              widget.sub.startIndex = v.clamp(
                                1,
                                widget.sub.totalQuestions,
                              );
                              if (widget.sub.startIndex > widget.sub.endIndex) {
                                widget.sub.endIndex = widget.sub.startIndex;
                                _endController.text = widget.sub.endIndex
                                    .toString();
                              }
                            });
                            widget.onChanged();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '→',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),
                        Text(
                          'Q',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _NumberInput(
                          controller: _endController,
                          min: widget.sub.startIndex,
                          max: widget.sub.totalQuestions,
                          color: widget.skillColor,
                          onChanged: (v) {
                            setState(() {
                              widget.sub.endIndex = v.clamp(
                                widget.sub.startIndex,
                                widget.sub.totalQuestions,
                              );
                            });
                            widget.onChanged();
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'of ${widget.sub.totalQuestions}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                    if (rangeError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        rangeError,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Mode Pill ─────────────────────────────────────────────────────────────────

class _ModePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : const Color(0xFFCCCCCC)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

// ── Number Input ──────────────────────────────────────────────────────────────

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final int min;
  final int max;
  final Color color;
  final void Function(int) onChanged;

  const _NumberInput({
    required this.controller,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 30,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: color.withAlpha(100)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: color.withAlpha(80)),
          ),
          filled: true,
          fillColor: color.withAlpha(10),
        ),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null) {
            onChanged(parsed.clamp(min, max));
          }
        },
        onSubmitted: (v) {
          final parsed = int.tryParse(v) ?? min;
          final clamped = parsed.clamp(min, max);
          controller.text = clamped.toString();
          onChanged(clamped);
        },
      ),
    );
  }
}

// ── Summary Footer ────────────────────────────────────────────────────────────

class _SummaryFooter extends StatelessWidget {
  final int skillsCount;
  final int subtopicsCount;
  final int totalQuestions;
  final bool canStart;
  final bool isLoading;
  final VoidCallback onStart;

  const _SummaryFooter({
    required this.skillsCount,
    required this.subtopicsCount,
    required this.totalQuestions,
    required this.canStart,
    required this.isLoading,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryStatItem(
                label: 'Skills',
                value: skillsCount.toString(),
                icon: Icons.layers_rounded,
              ),
              Container(width: 1, height: 28, color: const Color(0xFFEEEEEE)),
              _SummaryStatItem(
                label: 'Subtopics',
                value: subtopicsCount.toString(),
                icon: Icons.account_tree_rounded,
              ),
              Container(width: 1, height: 28, color: const Color(0xFFEEEEEE)),
              _SummaryStatItem(
                label: 'Questions',
                value: totalQuestions.toString(),
                icon: Icons.quiz_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canStart && !isLoading ? onStart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canStart ? AppTheme.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: canStart ? 2 : 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      canStart
                          ? 'Start Mixed Quiz ($totalQuestions Questions)'
                          : 'Select at least one skill',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: const Color(0xFF777777),
          ),
        ),
      ],
    );
  }
}

// ── Error / Empty views ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No topics found.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
