import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';

class SparkSubtopicScreen extends StatefulWidget {
  const SparkSubtopicScreen({super.key});

  @override
  State<SparkSubtopicScreen> createState() => _SparkSubtopicScreenState();
}

class _SparkSubtopicScreenState extends State<SparkSubtopicScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Resolved dynamically from de_mobile_app.topics
  int? _topicId;

  // Subtopic IDs resolved dynamically from de_mobile_app.subtopics
  int? _sparkCoreId;
  int? _sparkDfId;

  // Live question counts
  int _sparkCoreCount = 0;
  int _sparkDfCount = 0;
  int _totalCount = 0;

  // Real-time cleanup callback
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _fetchSubtopicsAndCounts();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  /// Set up real-time subscription after topic ID is resolved.
  Future<void> _setupRealtimeSubscription(int topicId) async {
    // Cancel any existing subscription first
    _unsubscribe?.call();

    final cleanup = await QuizService.instance.subscribeToSubtopicChanges(
      topicId: topicId,
      onDataChanged: () {
        if (mounted) {
          _fetchSubtopicsAndCounts(silent: true);
        }
      },
    );
    if (mounted) {
      _unsubscribe = cleanup;
    } else {
      cleanup();
    }
  }

  Future<void> _fetchSubtopicsAndCounts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      // Step 1: Resolve topic ID from de_mobile_app.topics where name='Apache Spark'
      final topicId = await QuizService.instance.fetchTopicId('Apache Spark');
      if (topicId == null) {
        if (mounted && !silent) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Apache Spark topic not found in database.';
          });
        }
        return;
      }

      // Step 2: Resolve subtopic IDs from de_mobile_app.subtopics where topic_id=topicId
      final ids = await QuizService.instance.fetchSparkSubtopicIds();
      final sparkCoreId = ids.coreId;
      final sparkDfId = ids.sqlDfId;

      // Step 3: Fetch live question counts using sub_topics FK
      final sparkCoreCount = sparkCoreId != null
          ? await QuizService.instance.fetchSubtopicQuestionCount(sparkCoreId)
          : 0;
      final sparkDfCount = sparkDfId != null
          ? await QuizService.instance.fetchSubtopicQuestionCount(sparkDfId)
          : 0;

      // Step 4: Fetch total count for the topic
      final totalCount = await QuizService.instance.fetchTopicQuestionCountById(
        topicId,
      );

      if (mounted) {
        final bool needsSubscription = _topicId != topicId;
        setState(() {
          _topicId = topicId;
          _sparkCoreId = sparkCoreId;
          _sparkDfId = sparkDfId;
          _sparkCoreCount = sparkCoreCount;
          _sparkDfCount = sparkDfCount;
          _totalCount = totalCount;
          _isLoading = false;
        });
        // Set up real-time subscription once we have the topic ID
        if (needsSubscription) {
          _setupRealtimeSubscription(topicId);
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load subtopics. Please try again.';
        });
      } else if (mounted && silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _launchQuizBySubtopicId({
    required int? subtopicId,
    required String subtopicName,
    required int count,
  }) {
    if (_topicId == null) return;
    if (subtopicId != null) {
      context.push(
        AppRoutes.quizScreen,
        extra: {
          'topicId': _topicId.toString(),
          'topicName': subtopicName,
          'questionCount': count > 0 ? count : 15,
          'subtopicId': subtopicId,
        },
      );
    } else {
      context.push(
        AppRoutes.quizScreen,
        extra: {
          'topicId': _topicId.toString(),
          'topicName': subtopicName,
          'questionCount': count > 0 ? count : 15,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: Text(
          'Apache Spark',
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
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
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
              onPressed: () => _fetchSubtopicsAndCounts(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Retry',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
            'Select a subtopic to start your Apache Spark quiz',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 24),
          _buildSubtopicCard(
            title: 'Spark Core',
            description:
                'RDDs, transformations, actions, partitioning, caching, and the Spark execution model.',
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFE85D04),
            count: _sparkCoreCount,
            subtopicId: _sparkCoreId,
            onTap: () => _launchQuizBySubtopicId(
              subtopicId: _sparkCoreId,
              subtopicName: 'Spark Core',
              count: _sparkCoreCount,
            ),
          ),
          const SizedBox(height: 16),
          _buildSubtopicCard(
            title: 'Spark SQL / DataFrame',
            description:
                'DataFrames, Datasets, Spark SQL queries, Catalyst optimizer, and structured data processing.',
            icon: Icons.table_chart_rounded,
            iconColor: const Color(0xFF3A86FF),
            count: _sparkDfCount,
            subtopicId: _sparkDfId,
            onTap: () => _launchQuizBySubtopicId(
              subtopicId: _sparkDfId,
              subtopicName: 'Spark SQL/DataFrame',
              count: _sparkDfCount,
            ),
          ),
          const SizedBox(height: 24),
          // Practice All button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _totalCount > 0 && _topicId != null
                  ? () => context.push(
                      AppRoutes.quizScreen,
                      extra: {
                        'topicId': _topicId.toString(),
                        'topicName': 'Apache Spark',
                        'questionCount': _totalCount,
                      },
                    )
                  : null,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: Text(
                'Practice All ($_totalCount questions)',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtopicCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required int count,
    required int? subtopicId,
    required VoidCallback onTap,
  }) {
    final bool hasQuestions = count > 0;
    return GestureDetector(
      onTap: hasQuestions ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasQuestions
                ? iconColor.withAlpha(60)
                : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: hasQuestions
                              ? iconColor.withAlpha(20)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasQuestions
                              ? '$count questions'
                              : 'No questions yet',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasQuestions
                                ? iconColor
                                : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: hasQuestions
                  ? const Color(0xFF888888)
                  : const Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}
