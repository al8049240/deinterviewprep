import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class TopicsSearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TopicsSearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: 'Search For Skill',
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF9E9E9E),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9E9E9E),
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 14,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
