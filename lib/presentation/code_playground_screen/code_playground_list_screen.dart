import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/bookmark_provider.dart';
import '../performance_trends_screen/performance_trends_screen.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import './code_playground_workspace_screen.dart';

class CodePlaygroundListScreen extends StatefulWidget {
  const CodePlaygroundListScreen({super.key});

  @override
  State<CodePlaygroundListScreen> createState() =>
      _CodePlaygroundListScreenState();
}

class _CodePlaygroundListScreenState extends State<CodePlaygroundListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allChallenges = [];
  List<Map<String, dynamic>> _filtered = [];

  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = 'All';

  static const List<String> _languages = ['All', 'SQL', 'Python'];

  @override
  void initState() {
    super.initState();
    _fetchChallenges();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChallenges() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await SupabaseService.instance
          .fetchPlaygroundChallengesList();
      setState(() {
        _allChallenges = raw;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'Failed to load challenges. Tap to retry.';
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _allChallenges.where((c) {
        final title = (c['title'] ?? '').toString().toLowerCase();
        final desc = (c['description'] ?? '').toString().toLowerCase();
        final lang = (c['language'] ?? '').toString();

        final matchesSearch =
            query.isEmpty || title.contains(query) || desc.contains(query);
        final matchesLang =
            _selectedLanguage == 'All' || lang == _selectedLanguage;

        return matchesSearch && matchesLang;
      }).toList();
    });
  }

  void _openChallenge(String playgroundId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CodePlaygroundWorkspaceScreen(playgroundId: playgroundId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Code Playground',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (!_loading && _error == null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_filtered.length} challenges',
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
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
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
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search challenges...',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Language filter
          Row(
            children: [
              Text(
                'Language:',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _languages.map((lang) {
                      final selected = _selectedLanguage == lang;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedLanguage = lang);
                          _applyFilters();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            lang,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: GestureDetector(
          onTap: _fetchChallenges,
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No challenges found.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
            ),
            if (_searchController.text.isNotEmpty ||
                _selectedLanguage != 'All') ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedLanguage = 'All';
                  });
                  _applyFilters();
                },
                child: Text(
                  'Clear filters',
                  style: GoogleFonts.dmSans(color: AppTheme.primary),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        return RefreshIndicator(
          onRefresh: _fetchChallenges,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              final c = _filtered[i];
              final playgroundId = c['playground_id'].toString();
              final isBookmarked = bookmarkProvider.isPlaygroundBookmarked(
                playgroundId,
              );
              return _ChallengeListCard(
                challenge: c,
                isBookmarked: isBookmarked,
                onTap: () => _openChallenge(playgroundId),
                onBookmark: () {
                  final added = bookmarkProvider.togglePlaygroundBookmark(
                    playgroundId,
                  );
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added
                            ? 'Challenge saved to Bookmarks'
                            : 'Removed from Bookmarks',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: added
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade700,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ChallengeListCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _ChallengeListCard({
    required this.challenge,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final title = (challenge['title'] ?? '').toString();
    final description = (challenge['description'] ?? '').toString();
    final language = (challenge['language'] ?? '').toString();
    final dsMap = challenge['code_playground_datasets'];
    final datasetName = dsMap is Map ? dsMap['dataset_name']?.toString() : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LanguagePill(language: language),
                if (datasetName != null) ...[
                  const SizedBox(width: 6),
                  _DatasetPill(name: datasetName),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: onBookmark,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 22,
                      color: isBookmarked
                          ? AppTheme.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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

class _DatasetPill extends StatelessWidget {
  final String name;
  const _DatasetPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_chart, size: 9, color: Color(0xFF00695C)),
          const SizedBox(width: 3),
          Text(
            name,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00695C),
            ),
          ),
        ],
      ),
    );
  }
}
