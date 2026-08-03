import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CategoryFilterWidget extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => onSelected(cat),
                backgroundColor: const Color(0xFFF0F0F0),
                selectedColor: AppTheme.primaryContainer,
                checkmarkColor: AppTheme.primary,
                labelStyle: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.primaryDark
                      : const Color(0xFF555555),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
