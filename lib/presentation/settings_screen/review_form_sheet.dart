import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/review_repository.dart';
import '../../services/review_prompt_service.dart';
import '../../theme/app_theme.dart';

class ReviewFormSheet extends StatefulWidget {
  final Future<void> Function() onOpenPlayStore;

  const ReviewFormSheet({super.key, required this.onOpenPlayStore});

  @override
  State<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<ReviewFormSheet> {
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (_rating == 0) {
      setState(() => _error = 'Choose a rating from 1 to 5 stars.');
      return;
    }
    if (comment.length < 20 || comment.length > 1000) {
      setState(() => _error = 'Feedback must be 20–1000 characters.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ReviewRepository.instance.createReview(
        rating: _rating,
        title: _titleController.text,
        comment: comment,
      );
      await ReviewPromptService.instance.markCompleted();
      if (!mounted) return;
      setState(() => _submitting = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Thank you!'),
          content: const Text(
            'Your feedback was saved. You may also leave an optional Google Play review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ReviewPromptService.instance.markCompleted();
                await widget.onOpenPlayStore();
              },
              child: const Text('Google Play'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share your feedback',
              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  tooltip: '$value star${value == 1 ? '' : 's'}',
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFFFB300),
                    size: 36,
                  ),
                );
              }),
            ),
            TextField(
              controller: _titleController,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'Minimum 20 characters',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Feedback'),
              ),
            ),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      await ReviewPromptService.instance.markCompleted();
                      await widget.onOpenPlayStore();
                      if (mounted) Navigator.pop(context);
                    },
              child: const Text('Review on Google Play instead'),
            ),
          ],
        ),
      ),
    );
  }
}
