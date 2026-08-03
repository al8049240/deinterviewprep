import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../topics_list_screen.dart';

class TopicCardWidget extends StatelessWidget {
  final TopicModel topic;
  final VoidCallback onTap;

  const TopicCardWidget({super.key, required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.primaryContainer,
          highlightColor: AppTheme.primaryContainer.withAlpha(77),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 14),
                Expanded(child: _buildContent()),
                _buildTrailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: topic.iconColor.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_getIcon(topic.iconName), color: topic.iconColor, size: 26),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                topic.name,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (topic.isPro)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '🗿',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildMetaChip(
              icon: Icons.quiz_rounded,
              label: '${topic.questionCount} Qs',
              color: const Color(0xFF555555),
            ),
            const SizedBox(width: 8),
            _buildMetaChip(
              icon: Icons.folder_outlined,
              label: topic.category,
              color: const Color(0xFF777777),
            ),
            if (topic.completedQuizzes > 0) ...[
              const SizedBox(width: 8),
              _buildMetaChip(
                icon: Icons.check_circle_outline_rounded,
                label: '${topic.completedQuizzes} done',
                color: AppTheme.success,
              ),
            ],
          ],
        ),
        if (topic.accuracyPercent > 0) ...[
          const SizedBox(height: 8),
          _buildAccuracyBar(),
        ],
      ],
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyBar() {
    final accuracy = topic.accuracyPercent / 100;
    final barColor = topic.accuracyPercent >= 70
        ? AppTheme.success
        : topic.accuracyPercent >= 50
        ? AppTheme.warning
        : AppTheme.error;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: accuracy,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${topic.accuracyPercent.toStringAsFixed(0)}%',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: barColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: topic.isPro
          ? const Icon(Icons.lock_rounded, color: AppTheme.secondary, size: 20)
          : Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primary.withAlpha(153),
              size: 22,
            ),
    );
  }

  IconData _getIcon(String name) {
    const map = {
      'storage': Icons.storage_rounded,
      'code': Icons.code_rounded,
      'swap_horiz': Icons.swap_horiz_rounded,
      'bolt': Icons.bolt_rounded,
      'stream': Icons.stream_rounded,
      'air': Icons.air_rounded,
      'cloud': Icons.cloud_rounded,
      'transform': Icons.transform_rounded,
      'schema': Icons.schema_rounded,
      'inventory_2': Icons.inventory_2_rounded,
      'dataset': Icons.dataset_rounded,
      'loop': Icons.loop_rounded,
    };
    return map[name] ?? Icons.topic_rounded;
  }
}
