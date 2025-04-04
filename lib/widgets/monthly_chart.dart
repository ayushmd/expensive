import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class MonthlyChart extends ConsumerWidget {
  const MonthlyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('No data to display'),
            ),
          );
        }

        // Group expenses by month
        final Map<DateTime, double> monthlyTotals = {};
        for (final expense in expenses) {
          final date = DateTime(
            expense.date.year,
            expense.date.month,
          );
          monthlyTotals[date] = (monthlyTotals[date] ?? 0) + expense.amount;
        }

        if (monthlyTotals.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('No expenses to display'),
            ),
          );
        }

        final maxAmount = monthlyTotals.values
            .reduce((value, element) => value > element ? value : element);

        return AspectRatio(
          aspectRatio: 1.7,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 24),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.1,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= monthlyTotals.length) {
                          return const SizedBox.shrink();
                        }
                        final date = monthlyTotals.keys.elementAt(value.toInt());
                        return Transform.rotate(
                          angle: -0.5, // Rotate text by -30 degrees
                          child: Text(
                            DateFormat.MMM().format(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            NumberFormat.compact().format(value),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(
                  show: false,
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: monthlyTotals.entries.map((entry) {
                  return BarChartGroupData(
                    x: monthlyTotals.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: Theme.of(context).colorScheme.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 200,
        child: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}