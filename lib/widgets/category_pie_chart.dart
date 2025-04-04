import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../utils/category_icons.dart';

class CategoryPieChart extends ConsumerWidget {
  const CategoryPieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final total = categoryTotals.values.fold<double>(0, (a, b) => a + b);

    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No expenses to display'),
        ),
      );
    }

    final sections = categoryTotals.entries.map((entry) {
      final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
      return PieChartSectionData(
        value: entry.value,
        title: '${(entry.value / total * 100).toStringAsFixed(1)}%',
        titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
        color: color,
        radius: 80,
        showTitle: entry.value / total > 0.05, // Only show label if segment is >5%
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 25,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categoryTotals.entries.map((entry) {
            final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
            return Chip(
              avatar: Icon(
                CategoryIcons.getIcon(entry.key),
                color: color,
                size: 18,
              ),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(color: color),
              label: Text(
                '${entry.key}: ${(entry.value / total * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: color),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}