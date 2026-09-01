import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/developer_experience_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../performance_trends_screen/performance_trends_screen.dart';
import './developer_experience_detail_screen.dart';

// ── User-created experience model ─────────────────────────────────────────────
class UserDeveloperExperience {
  final String id;
  final String title;
  final String categoryTag;
  final String situation;
  final String task;
  final String action;
  final String result;
  final String keyTakeaway;

  const UserDeveloperExperience({
    required this.id,
    required this.title,
    required this.categoryTag,
    required this.situation,
    required this.task,
    required this.action,
    required this.result,
    required this.keyTakeaway,
  });

  factory UserDeveloperExperience.fromMap(Map<String, dynamic> map) {
    return UserDeveloperExperience(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      categoryTag: map['category_tag']?.toString() ?? 'Behavioral',
      situation: map['situation']?.toString() ?? '',
      task: map['task_description']?.toString() ?? '',
      action: map['action_taken']?.toString() ?? '',
      result: map['result_achieved']?.toString() ?? '',
      keyTakeaway: map['key_takeaway']?.toString() ?? '',
    );
  }

  DeveloperExperienceModel toModel() {
    return DeveloperExperienceModel(
      id: id,
      title: title,
      categoryTag: categoryTag,
      situation: situation,
      task: task,
      action: action,
      result: result,
      keyTakeaway: keyTakeaway,
    );
  }
}

class DeveloperExperiencesListScreen extends StatefulWidget {
  const DeveloperExperiencesListScreen({super.key});

  @override
  State<DeveloperExperiencesListScreen> createState() =>
      _DeveloperExperiencesListScreenState();
}

class _DeveloperExperiencesListScreenState
    extends State<DeveloperExperiencesListScreen> {
  List<UserDeveloperExperience> _userExperiences = [];
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserExperiences();
  }

  Future<void> _loadUserExperiences() async {
    if (!AuthService.instance.isSignedIn) {
      if (mounted) {
        setState(() {
          _userExperiences = [];
          _loadingUser = false;
        });
      }
      return;
    }

    try {
      final raw = await SupabaseService.instance
          .fetchUserDeveloperExperiences();
      if (mounted) {
        setState(() {
          _userExperiences = raw.map(UserDeveloperExperience.fromMap).toList();
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Color _categoryColor(String tag) {
    switch (tag) {
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

  void _showAddExperienceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExperienceSheet(
        onCreated: () {
          _loadUserExperiences();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = AuthService.instance.isSignedIn;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Developer's Real Experiences",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        backgroundColor: const Color(0xFF37474F),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BookmarksScreen(
                  initialFilter: BookmarkFilter.experiences,
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
      floatingActionButton: isSignedIn
          ? FloatingActionButton.extended(
              onPressed: _showAddExperienceSheet,
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Experience',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF37474F).withAlpha(18),
                        const Color(0xFF546E7A).withAlpha(12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF37474F).withAlpha(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🗿', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unfiltered production war stories & high-stakes trade-offs from the dev.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF37474F),
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Built-in experiences ──────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final exp = devExperiences[index];
                  final isBookmarked = bookmarkProvider
                      .isDevExperienceBookmarked(exp.id);
                  final catColor = _categoryColor(exp.categoryTag);
                  return _ExperienceCard(
                    id: exp.id,
                    title: exp.title,
                    categoryTag: exp.categoryTag,
                    situation: exp.situation,
                    catColor: catColor,
                    isBookmarked: isBookmarked,
                    isUserCreated: false,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DeveloperExperienceDetailScreen(experience: exp),
                        ),
                      );
                    },
                    onBookmark: () {
                      final added = bookmarkProvider.toggleDevExperience(
                        exp.id,
                      );
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            added
                                ? 'Experience saved to Bookmarks 🔖'
                                : 'Removed from Bookmarks',
                            style: GoogleFonts.dmSans(fontSize: 13),
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
                  );
                }, childCount: devExperiences.length),
              ),
              // ── User-created experiences section ─────────────────────────
              if (!_loadingUser && _userExperiences.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9A825).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF9A825).withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✍️', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              Text(
                                'My Experiences',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF9A825),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final exp = _userExperiences[index];
                    final catColor = _categoryColor(exp.categoryTag);
                    return _ExperienceCard(
                      id: exp.id,
                      title: exp.title,
                      categoryTag: exp.categoryTag,
                      situation: exp.situation,
                      catColor: catColor,
                      isBookmarked: false,
                      isUserCreated: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeveloperExperienceDetailScreen(
                              experience: exp.toModel(),
                            ),
                          ),
                        );
                      },
                      onBookmark: () {},
                    );
                  }, childCount: _userExperiences.length),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ── Experience Card ───────────────────────────────────────────────────────────

class _ExperienceCard extends StatelessWidget {
  final String id;
  final String title;
  final String categoryTag;
  final String situation;
  final Color catColor;
  final bool isBookmarked;
  final bool isUserCreated;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _ExperienceCard({
    required this.id,
    required this.title,
    required this.categoryTag,
    required this.situation,
    required this.catColor,
    required this.isBookmarked,
    required this.isUserCreated,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: catColor, width: 4)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
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
                              color: catColor.withAlpha(18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '[ $categoryTag ]',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                          if (isUserCreated) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9A825).withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Mine',
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        situation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    if (!isUserCreated)
                      GestureDetector(
                        onTap: onBookmark,
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 22,
                          color: isBookmarked
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade400,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
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

// ── Add Experience Bottom Sheet ───────────────────────────────────────────────

class _AddExperienceSheet extends StatefulWidget {
  final VoidCallback onCreated;

  const _AddExperienceSheet({required this.onCreated});

  @override
  State<_AddExperienceSheet> createState() => _AddExperienceSheetState();
}

class _AddExperienceSheetState extends State<_AddExperienceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _situationCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  final _resultCtrl = TextEditingController();
  final _takeawayCtrl = TextEditingController();
  String _selectedCategory = 'Behavioral';
  bool _isSaving = false;

  static const List<String> _categories = [
    'Behavioral',
    'Failure Lesson',
    'Architecture Trade-off',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _situationCtrl.dispose();
    _taskCtrl.dispose();
    _actionCtrl.dispose();
    _resultCtrl.dispose();
    _takeawayCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await SupabaseService.instance.createUserDeveloperExperience(
        title: _titleCtrl.text.trim(),
        categoryTag: _selectedCategory,
        situation: _situationCtrl.text.trim(),
        taskDescription: _taskCtrl.text.trim(),
        actionTaken: _actionCtrl.text.trim(),
        resultAchieved: _resultCtrl.text.trim(),
        keyTakeaway: _takeawayCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Experience added successfully!',
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
              'Failed to save. Please try again.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 3,
    bool required = true,
  }) {
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
          controller: ctrl,
          maxLines: maxLines,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          style: GoogleFonts.dmSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
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
                color: Color(0xFF37474F),
                width: 1.5,
              ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
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
                'Add Your Experience',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share a real work experience using the STAR format',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              // Category
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
              _field(
                'Title *',
                _titleCtrl,
                'e.g. When My Pipeline Silently Dropped 40% of Records',
                maxLines: 1,
              ),
              const SizedBox(height: 10),
              _field(
                'Situation *',
                _situationCtrl,
                'What was the context or background?',
              ),
              const SizedBox(height: 10),
              _field(
                'Task *',
                _taskCtrl,
                'What was your responsibility or goal?',
              ),
              const SizedBox(height: 10),
              _field(
                'Action *',
                _actionCtrl,
                'What specific steps did you take?',
              ),
              const SizedBox(height: 10),
              _field('Result *', _resultCtrl, 'What was the outcome?'),
              const SizedBox(height: 10),
              _field(
                'Key Takeaway *',
                _takeawayCtrl,
                'What did you learn from this experience?',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37474F),
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
                          'Save Experience',
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
