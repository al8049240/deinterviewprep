import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';

/// Generic subtopic screen — works for any topic fetched from Supabase.
/// Receives [topicName] and [topicColor] via GoRouter extras.
class SubtopicScreen extends StatefulWidget {
  final String topicName;
  final int? topicId;
  final Color topicColor;
  final IconData topicIcon;

  const SubtopicScreen({
    super.key,
    required this.topicName,
    this.topicId,
    required this.topicColor,
    required this.topicIcon,
  });

  @override
  State<SubtopicScreen> createState() => _SubtopicScreenState();
}

class _SubtopicScreenState extends State<SubtopicScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int? _topicId;
  List<_SubtopicItem> _subtopics = [];
  int _totalCount = 0;

  void Function()? _unsubscribe;

  bool _isComingSoonSubtopic(String databaseName) {
    final normalized = databaseName.trim().toLowerCase();
    return normalized.contains('generative ai tools') &&
        normalized.contains('real-world data engineering');
  }

  String _displaySubtopicName(String databaseName) {
    if (widget.topicName != 'Cloud') return databaseName;
    switch (databaseName.trim().toLowerCase()) {
      case 'aws':
        return 'AWS Certified Data Engineer – Associate (DEA-C01)';
      case 'azure':
        return 'Microsoft Certified: Azure Data Engineer Associate (DP-203)';
      case 'gcp':
        return 'Google Cloud Professional Data Engineer (GCP-PDE)';
      default:
        return databaseName;
    }
  }

  String _displaySubtopicDescription(
    String databaseName,
    String databaseDescription,
  ) {
    if (widget.topicName != 'Cloud') return databaseDescription;
    switch (databaseName.trim().toLowerCase()) {
      case 'aws':
        return 'Practice for the AWS Data Engineer Associate DEA-C01 exam.';
      case 'azure':
        return 'Practice aligned with the historical Azure DP-203 exam.';
      case 'gcp':
        return 'Practice for the Google Cloud Professional Data Engineer certification.';
      default:
        return databaseDescription;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      // 1. Resolve topic ID
      final topicId =
          widget.topicId ??
          await QuizService.instance.fetchTopicId(widget.topicName);
      if (topicId == null) {
        if (mounted && !silent) {
          setState(() {
            _isLoading = false;
            _errorMessage = '${widget.topicName} topic not found in database.';
          });
        }
        return;
      }

      // 2. Load subtopics
      final subtopicRows = await QuizService.instance.fetchSubtopics(topicId);

      // 3. Fetch question count per subtopic in parallel
      final counts = await Future.wait(
        subtopicRows.map((row) async {
          final id = (row['id'] as num?)?.toInt();
          if (id == null) return 0;
          return QuizService.instance.fetchSubtopicQuestionCount(id);
        }),
      );

      if (mounted) {
        final items = <_SubtopicItem>[];
        for (int i = 0; i < subtopicRows.length; i++) {
          final row = subtopicRows[i];
          final id = (row['id'] as num?)?.toInt();
          if (id == null) continue;
          final databaseName = row['name']?.toString() ?? '';
          items.add(
            _SubtopicItem(
              id: id,
              name: _displaySubtopicName(databaseName),
              description: _displaySubtopicDescription(
                databaseName,
                row['description']?.toString() ?? '',
              ),
              questionCount: counts[i],
              isComingSoon: _isComingSoonSubtopic(databaseName),
            ),
          );
        }

        final availableQuestionCount = items
            .where((item) => !item.isComingSoon)
            .fold<int>(0, (sum, item) => sum + item.questionCount);

        final needsSubscription = _topicId != topicId;
        setState(() {
          _topicId = topicId;
          _subtopics = items;
          _totalCount = availableQuestionCount;
          _isLoading = false;
        });

        if (needsSubscription) {
          _setupRealtime(topicId);
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load subtopics. Please try again.';
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupRealtime(int topicId) async {
    _unsubscribe?.call();
    final cleanup = await QuizService.instance.subscribeToSubtopicChanges(
      topicId: topicId,
      onDataChanged: () {
        if (mounted) _loadData(silent: true);
      },
    );
    if (mounted) {
      _unsubscribe = cleanup;
    } else {
      cleanup();
    }
  }

  void _startQuiz({
    required int subtopicId,
    required String name,
    required int count,
  }) {
    if (_topicId == null) return;
    context.push(
      AppRoutes.quizScreen,
      extra: {
        'topicId': _topicId.toString(),
        'topicName': name,
        'questionCount': count > 0 ? count : 15,
        'subtopicId': subtopicId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: widget.topicColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      title: Text(
        widget.topicName,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_totalCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_totalCount Q',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Retry',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.topicColor,
                foregroundColor: Colors.white,
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose a Subtopic',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select a subtopic to start your ${widget.topicName} quiz',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          if (_subtopics.isEmpty)
            _buildEmptyState()
          else
            ...List.generate(_subtopics.length, (i) {
              final sub = _subtopics[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSubtopicCard(sub),
              );
            }),
          if (_totalCount > 0 && _topicId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  AppRoutes.quizScreen,
                  extra: {
                    'topicId': _topicId.toString(),
                    'topicName': widget.topicName,
                    'questionCount': _totalCount,
                  },
                ),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(
                  'Practice All ($_totalCount questions)',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.topicColor,
                  side: BorderSide(color: widget.topicColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 56,
              color: widget.topicColor.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No subtopics yet',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subtopics will appear here once added to the database.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtopicCard(_SubtopicItem sub) {
    final hasQuestions = sub.questionCount > 0 && !sub.isComingSoon;
    final color = widget.topicColor;
    return GestureDetector(
      onTap: hasQuestions
          ? () => _startQuiz(
              subtopicId: sub.id,
              name: sub.name,
              count: sub.questionCount,
            )
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasQuestions ? color.withAlpha(60) : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasQuestions
                    ? color.withAlpha(20)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.topicIcon,
                color: hasQuestions ? color : const Color(0xFFCCCCCC),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasQuestions
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFAAAAAA),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      sub.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: const Color(0xFF999999),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasQuestions
                          ? color.withAlpha(20)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sub.isComingSoon
                          ? 'Coming Soon'
                          : hasQuestions
                          ? '${sub.questionCount} questions'
                          : 'Coming soon',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasQuestions ? color : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: hasQuestions
                  ? const Color(0xFF888888)
                  : const Color(0xFFDDDDDD),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtopicItem {
  final int id;
  final String name;
  final String description;
  final int questionCount;
  final bool isComingSoon;

  const _SubtopicItem({
    required this.id,
    required this.name,
    required this.description,
    required this.questionCount,
    this.isComingSoon = false,
  });
}
