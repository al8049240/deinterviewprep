import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_FaqItem> _questions = [
    _FaqItem(
      question: 'How do I start a practice quiz?',
      answer:
          'From Home, choose a data engineering topic, select a subtopic if available, and start a quiz. You can also adjust the number of questions before beginning.',
      keywords: 'practice topic subtopic questions home',
    ),
    _FaqItem(
      question: 'Can I build a custom quiz?',
      answer:
          'Yes. Open the custom quiz builder, choose the topics you want to practise, set the question count, and start your personalised session.',
      keywords: 'personalised customize topics question count',
    ),
    _FaqItem(
      question: 'How do bookmarks work?',
      answer:
          'Tap the bookmark icon on a question to save it. Your saved questions are collected in the Bookmarks tab so you can review them later.',
      keywords: 'save saved review question bank',
    ),
    _FaqItem(
      question: 'Where can I review my quiz performance?',
      answer:
          'Your result appears when you finish a quiz. For longer-term progress, open Stats or Performance Trends to see scores, accuracy, streaks, and topic breakdowns.',
      keywords: 'results statistics score accuracy streak progress trends',
    ),
    _FaqItem(
      question: 'Can I review answers and explanations?',
      answer:
          'Yes. After answering a question, the quiz shows whether your choice was correct and provides an explanation when one is available. You can also review the session from its results.',
      keywords: 'correct incorrect solution result explanation',
    ),
    _FaqItem(
      question: 'What are flashcards for?',
      answer:
          'Flashcards are a quick way to revise key data engineering concepts. Use them between quizzes to reinforce definitions, tools, and common interview patterns.',
      keywords: 'revision study concepts interview',
    ),
    _FaqItem(
      question: 'What is the Interview Code Library?',
      answer:
          'The Interview Code Library provides useful SQL and Python examples and patterns you can review before interviews.',
      keywords: 'coding exercise solution workspace',
    ),
    _FaqItem(
      question: 'How do I set a study reminder?',
      answer:
          'Go to Settings, tap Set Reminder, enable the daily reminder, choose a time, and save it.',
      keywords: 'notification daily time settings',
    ),
    _FaqItem(
      question: 'Why are some features locked?',
      answer:
          'Some advanced content and features are part of Serious Mode. The upgrade screen shows what is included before you make a purchase.',
      keywords: 'pro premium paywall purchase subscription serious mode',
    ),
    _FaqItem(
      question: 'How do I restore or check a purchase?',
      answer:
          'Open Settings and tap Purchase History. There you can view your current purchase status and use Restore Purchases when needed.',
      keywords: 'payment transaction premium pro subscription',
    ),
    _FaqItem(
      question: 'What should I do if content does not load?',
      answer:
          'Check your internet connection, close and reopen the app, and try again. If the issue continues, use Contact Us in Settings and include what you were trying to open.',
      keywords: 'blank offline error loading network bug support',
    ),
    _FaqItem(
      question: 'How can I report a bug or suggest a feature?',
      answer:
          'Open Settings and tap Contact Us. Choose the relevant support option and include enough detail for the team to reproduce the issue or understand your suggestion.',
      keywords: 'feedback contact support problem request',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredQuestions = _questions.where((item) {
      if (normalizedQuery.isEmpty) return true;
      return '${item.question} ${item.answer} ${item.keywords}'
          .toLowerCase()
          .contains(normalizedQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search for help',
                  hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppTheme.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
            ),
            Expanded(
              child: filteredQuestions.isEmpty
                  ? _EmptySearch(query: _query)
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                      itemCount: filteredQuestions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _FaqCard(item: filteredQuestions[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final _FaqItem item;

  const _FaqCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 44, 18),
        iconColor: AppTheme.primary,
        collapsedIconColor: Colors.grey.shade500,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          item.question,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.55,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final String query;

  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No answers found',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search or contact support for help with “${query.trim()}”.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final String keywords;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.keywords,
  });
}
