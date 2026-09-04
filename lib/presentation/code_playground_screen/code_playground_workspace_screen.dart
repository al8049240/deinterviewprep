import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class CodePlaygroundWorkspaceScreen extends StatefulWidget {
  final String playgroundId;

  const CodePlaygroundWorkspaceScreen({super.key, required this.playgroundId});

  @override
  State<CodePlaygroundWorkspaceScreen> createState() =>
      _CodePlaygroundWorkspaceScreenState();
}

class _CodePlaygroundWorkspaceScreenState
    extends State<CodePlaygroundWorkspaceScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _challenge;

  bool _showSolution = false;
  bool _solutionRevealed = false;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.instance.fetchPlaygroundChallengeById(
        widget.playgroundId,
      );
      if (data == null) {
        setState(() {
          _error = 'Challenge not found.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _challenge = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load challenge. Tap to retry.';
        _loading = false;
      });
    }
  }

  void _revealSolution() {
    setState(() {
      _solutionRevealed = true;
      _showSolution = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          _loading
              ? 'Loading...'
              : (_challenge?['title'] ?? 'Challenge').toString(),
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Interview Code Library',
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildWorkspace(),
    );
  }

  Widget _buildError() {
    return Center(
      child: GestureDetector(
        onTap: _loadChallenge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    final challenge = _challenge!;
    final language = (challenge['language'] ?? 'SQL').toString();
    final difficulty = (challenge['difficulty'] ?? '').toString();
    final description = (challenge['description'] ?? '').toString();
    final useCase = (challenge['use_case'] ?? '').toString();
    final tips = challenge['tips'];
    final tipsList = tips is List
        ? tips.map((t) => t.toString()).toList()
        : <String>[];
    final solutionCode = (challenge['solution_code'] ?? '').toString();
    final solutionExplanation = (challenge['solution_explanation'] ?? '')
        .toString();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Requirement / Challenge Info Banner ───────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LanguagePill(language: language),
                    const SizedBox(width: 6),
                    _DifficultyPill(difficulty: difficulty),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                    height: 1.5,
                  ),
                ),
                if (useCase.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Use Case',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          useCase,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.primaryDark,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Tips ──────────────────────────────────────────────────────
          if (tipsList.isNotEmpty) _buildTips(tipsList),

          // ── Solution ─────────────────────────────────────────────────
          _buildSolutionSection(solutionCode, solutionExplanation),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTips(List<String> tips) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates,
                size: 15,
                color: Color(0xFFF57F17),
              ),
              const SizedBox(width: 6),
              Text(
                'Tips',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF57F17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFFF57F17))),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionSection(
    String solutionCode,
    String solutionExplanation,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_solutionRevealed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _revealSolution,
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(
                  'Show Solution',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: AppTheme.primary.withAlpha(120)),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ),
          if (_solutionRevealed) ...[
            GestureDetector(
              onTap: () => setState(() => _showSolution = !_showSolution),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reference Solution',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showSolution ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppTheme.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
            if (_showSolution) ...[
              const SizedBox(height: 8),
              if (solutionCode.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      solutionCode,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        color: const Color(0xFFD4D4D4),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              if (solutionExplanation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explanation',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        solutionExplanation,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

// ── Shared Pill Widgets ───────────────────────────────────────────────────────
class _LanguagePill extends StatelessWidget {
  final String language;
  const _LanguagePill({required this.language});

  @override
  Widget build(BuildContext context) {
    final isSQL = language.toUpperCase() == 'SQL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSQL ? const Color(0xFFE3F2FD) : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        language,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSQL ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A),
        ),
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final String difficulty;
  const _DifficultyPill({required this.difficulty});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'junior':
        return const Color(0xFF2E7D32);
      case 'middle':
        return const Color(0xFFE65100);
      case 'senior':
        return const Color(0xFFC62828);
      case 'leader':
        return const Color(0xFF6A1B9A);
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (difficulty.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
