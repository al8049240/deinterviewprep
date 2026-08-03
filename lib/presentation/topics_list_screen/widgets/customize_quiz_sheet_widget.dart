import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../topics_list_screen.dart';

class CustomizeQuizSheetWidget extends StatefulWidget {
  final List<TopicModel> topics;
  final Function(String topicId, String topicName, int count) onStartQuiz;

  const CustomizeQuizSheetWidget({
    super.key,
    required this.topics,
    required this.onStartQuiz,
  });

  @override
  State<CustomizeQuizSheetWidget> createState() =>
      _CustomizeQuizSheetWidgetState();
}

class _CustomizeQuizSheetWidgetState extends State<CustomizeQuizSheetWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _questionCount = 10;
  String? _selectedTopicId;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _selectedTopicId = widget.topics.isNotEmpty ? widget.topics.first.id : null;
  }

  TopicModel? get _selectedTopic => widget.topics.firstWhere(
    (t) => t.id == _selectedTopicId,
    orElse: () => widget.topics.first,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_showConfirm) _buildConfirmView() else _buildCustomizeView(),
        ],
      ),
    );
  }

  Widget _buildCustomizeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Your Quiz',
          style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Select topic and question count',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Select Topic',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCCCCCC)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTopicId,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: AppTheme.primary,
              ),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF1A1A1A),
              ),
              onChanged: (val) => setState(() => _selectedTopicId = val),
              items: widget.topics
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Number of Questions',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [5, 10, 15, 20, 25].map((count) {
            final isSelected = _questionCount == count;
            return GestureDetector(
              onTap: () => setState(() => _questionCount = count),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showConfirm = true),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              'Prepare Set of $_questionCount Questions',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmView() {
    final topic = _selectedTopic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set of $_questionCount Questions is ready',
          style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Topic: ${topic?.name ?? ''}\nGo ahead and take the test?',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _showConfirm = false),
              child: Text(
                'UNDO',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                'SEE QUESTIONS',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (topic != null) {
                  widget.onStartQuiz(topic.id, topic.name, _questionCount);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'YES',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
