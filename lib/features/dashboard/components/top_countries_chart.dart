import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/config/app_theme.dart';

class TopCountriesChart extends HookWidget {
  final List<MapEntry<String, int>> countries;
  final bool showLabels;

  const TopCountriesChart({
    super.key,
    required this.countries,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    // Animation controller for chart animation
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    // Start animation when widget is built
    useEffect(() {
      animationController.forward(from: 0);
      return null;
    }, []);

    // If there's no data, show a placeholder
    if (countries.isEmpty) {
      return _buildEmptyState();
    }

    // Colors for the chart sections
    final sectionColors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    // Calculate total for percentages
    final total = countries.fold<int>(0, (sum, item) => sum + item.value);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Countries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: animationController,
            builder: (context, _) {
              return SizedBox(
                height: 220,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sections: _buildChartSections(
                            sectionColors,
                            total,
                            animationController.value,
                          ),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(enabled: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildLegend(sectionColors, total),
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

  List<PieChartSectionData> _buildChartSections(
    List<Color> colors,
    int total,
    double animationValue,
  ) {
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < countries.length; i++) {
      final item = countries[i];
      final percentage = total > 0 ? (item.value / total) * 100 : 0;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: item.value.toDouble() * animationValue,
          title: showLabels ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildLegend(List<Color> colors, int total) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          countries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            // Format country name or code properly
            final countryDisplay = _formatCountryDisplay(item.key);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      countryDisplay,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _formatCount(item.value),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors[index % colors.length],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // Helper method to format country name or code correctly
  String _formatCountryDisplay(String countryNameOrCode) {
    if (countryNameOrCode.isEmpty) {
      return 'Unknown';
    }

    // Check if it's a country code (starts with +)
    if (countryNameOrCode.contains('+')) {
      // Fix double plus signs issue
      String cleanCode = countryNameOrCode.replaceAll('+', '');
      return '+$cleanCode'; // Return with single + sign
    }

    // For country names, capitalize first letter of each word
    final words = countryNameOrCode.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalizedWords.join(' ');
  }

  // Helper method to format count number correctly
  String _formatCount(int count) {
    // Just show the number without any prefix
    return count.toString();
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Countries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No data available yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
