import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../services/performance_service.dart';
import '../../../services/pro_service.dart';
import '../../../theme/app_theme.dart';

class PerformanceGraphWidget extends StatefulWidget {
  const PerformanceGraphWidget({super.key});

  @override
  State<PerformanceGraphWidget> createState() => _PerformanceGraphWidgetState();
}

class _PerformanceGraphWidgetState extends State<PerformanceGraphWidget> {
  final ProService _proService = ProService();
  final PerformanceService _perfService = PerformanceService();
  bool _isWeekly = true;

  @override
  void initState() {
    super.initState();
    _perfService.addListener(_onDataChanged);
    _perfService.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch whenever the dashboard becomes visible (e.g. after returning from quiz)
    _perfService.init();
  }

  @override
  void dispose() {
    _perfService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final days = _isWeekly ? 7 : 30;
    final snapshot = _perfService.getSnapshot(days);

    // Fall back to ProService entries for the score line chart if PerformanceService has no data
    final proEntries = _proService.getRecentEntries(days);
    final hasNewData = snapshot.totalSessions > 0;
    final hasProData = proEntries.isNotEmpty;

    final accuracyPerTopic = hasNewData
        ? snapshot.accuracyByTopic
        : _proService.getAccuracyPerTopic(days);
    final consistency = hasNewData
        ? snapshot.daysStudied
        : _proService.getStudyConsistency(days);
    final sessionCount = hasNewData
        ? snapshot.totalSessions
        : proEntries.length;
    final avgScore = hasNewData
        ? (snapshot.totalSessions == 0
              ? '—'
              : '${snapshot.avgScore.toStringAsFixed(0)}%')
        : (proEntries.isEmpty
              ? '—'
              : '${(proEntries.map((e) => e.score).reduce((a, b) => a + b) / proEntries.length).toStringAsFixed(0)}%');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Trends',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle Weekly / Monthly
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ToggleChip(
                            label: 'Weekly',
                            selected: _isWeekly,
                            onTap: () => setState(() => _isWeekly = true),
                          ),
                          _ToggleChip(
                            label: 'Monthly',
                            selected: !_isWeekly,
                            onTap: () => setState(() => _isWeekly = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.performanceTrendsScreen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Full View',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Consistency badge row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _MiniStat(
                  icon: '📅',
                  label: 'Days Studied',
                  value: '$consistency / $days',
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  icon: '📝',
                  label: 'Sessions',
                  value: '$sessionCount',
                  color: AppTheme.secondary,
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  icon: '🎯',
                  label: 'Avg Score',
                  value: avgScore,
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Score trend line chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 140,
              child: hasNewData
                  ? _PerfScoreLineChart(
                      points: snapshot.scoreTrend,
                      isWeekly: _isWeekly,
                    )
                  : hasProData
                  ? _ScoreLineChart(entries: proEntries, isWeekly: _isWeekly)
                  : _EmptyChartPlaceholder(
                      label: 'No data yet — start studying!',
                    ),
            ),
          ),

          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Score trend (last $days days)',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 14),

          // Accuracy per topic bar chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Accuracy by Topic',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 130,
              child: accuracyPerTopic.isEmpty
                  ? _EmptyChartPlaceholder(
                      label: 'Complete quizzes to see topic accuracy',
                    )
                  : _TopicAccuracyBarChart(accuracyPerTopic: accuracyPerTopic),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Performance Service Score Line Chart ─────────────────────────────────────
class _PerfScoreLineChart extends StatelessWidget {
  final List<DailyScorePoint> points;
  final bool isWeekly;

  const _PerfScoreLineChart({required this.points, required this.isWeekly});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].avgScore.clamp(0, 100)));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: points.length > 7 ? 4 : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                final date = points[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.primary,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withAlpha(20),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF1A1A1A),
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                'Score: ${spot.y.toStringAsFixed(0)}%',
                GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Toggle Chip ───────────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ── Mini Stat Badge ───────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score Line Chart (ProService fallback) ────────────────────────────────────

class _ScoreLineChart extends StatelessWidget {
  final List<PerformanceEntry> entries;
  final bool isWeekly;

  const _ScoreLineChart({required this.entries, required this.isWeekly});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].score.clamp(0, 100)));
    }

    final accuracySpots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      accuracySpots.add(
        FlSpot(i.toDouble(), entries[i].accuracy.clamp(0, 100)),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: entries.length > 7 ? 4 : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                final date = entries[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.primary,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withAlpha(20),
            ),
          ),
          LineChartBarData(
            spots: accuracySpots,
            isCurved: true,
            color: AppTheme.secondary,
            barWidth: 2,
            dashArray: [4, 3],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF1A1A1A),
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final label = spot.barIndex == 0 ? 'Score' : 'Accuracy';
              return LineTooltipItem(
                '$label: ${spot.y.toStringAsFixed(0)}%',
                GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Topic Accuracy Bar Chart ──────────────────────────────────────────────────

class _TopicAccuracyBarChart extends StatelessWidget {
  final Map<String, double> accuracyPerTopic;

  const _TopicAccuracyBarChart({required this.accuracyPerTopic});

  @override
  Widget build(BuildContext context) {
    final topics = accuracyPerTopic.keys.toList();
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      Colors.teal,
    ];

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < topics.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: accuracyPerTopic[topics[i]]!.clamp(0, 100),
              color: colors[i % colors.length],
              width: 18,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= topics.length) {
                  return const SizedBox.shrink();
                }
                final label = topics[idx];
                final short = label.length > 6 ? label.substring(0, 6) : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    short,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: const Color(0xFF1A1A1A),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final topic = topics[group.x];
              return BarTooltipItem(
                '$topic\n${rod.toY.toStringAsFixed(0)}%',
                GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Empty Chart Placeholder ───────────────────────────────────────────────────

class _EmptyChartPlaceholder extends StatelessWidget {
  final String label;
  const _EmptyChartPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Legend Row ────────────────────────────────────────────────────────────────

class PerformanceGraphLegend extends StatelessWidget {
  const PerformanceGraphLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _LegendDot(color: AppTheme.primary, label: 'Score'),
          const SizedBox(width: 16),
          _LegendDot(
            color: AppTheme.secondary,
            label: 'Accuracy',
            dashed: true,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed ? Border.all(color: color, width: 1) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
