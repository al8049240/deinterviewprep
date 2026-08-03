import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultsScoreGaugeWidget extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Animation<double> animation;
  final Color color;
  final bool isMain;

  const ResultsScoreGaugeWidget({
    super.key,
    required this.label,
    required this.value,
    required this.percent,
    required this.animation,
    required this.color,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: isMain ? 32 : 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: animation,
            builder: (ctx, _) {
              final animated = percent * animation.value;
              return SizedBox(
                height: isMain ? 160 : 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 0,
                        centerSpaceRadius: isMain ? 52 : 42,
                        sections: [
                          PieChartSectionData(
                            value: animated * 100,
                            color: color,
                            radius: 16,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (1 - animated) * 100,
                            color: const Color(0xFFEEEEEE),
                            radius: 14,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(animated * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.dmSans(
                            fontSize: isMain ? 22 : 18,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'accuracy',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
