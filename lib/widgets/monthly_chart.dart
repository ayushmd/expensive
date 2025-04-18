import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class MonthlyChart extends ConsumerWidget {
  const MonthlyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final expensesAsync = ref.watch(expensesProvider(dateRange));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(
            child: Text('No transactions in this period'),
          );
        }

        // Group by date and type
        final dailyData = <DateTime, Map<TransactionType, double>>{};
        for (final expense in expenses) {
          final date = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          dailyData[date] = dailyData[date] ?? {};
          dailyData[date]![expense.type] = (dailyData[date]![expense.type] ?? 0) + expense.amount;
        }

        // Sort dates
        final dates = dailyData.keys.toList()..sort();
        
        // Create bar groups
        final barGroups = dates.asMap().entries.map((entry) {
          final date = entry.value;
          final data = dailyData[date]!;
          
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: data[TransactionType.income] ?? 0,
                color: Colors.green,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: data[TransactionType.expense] ?? 0,
                color: Colors.red,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList();

        return AspectRatio(
          aspectRatio: 1.7,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: barGroups.fold(0.0, (maxY, group) {
                  final groupMax = group.barRods.fold(
                    0.0,
                    (max, rod) => rod.toY > max ? rod.toY : max,
                  );
                  return groupMax > maxY ? groupMax : maxY;
                }) * 1.2,
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = dates[value.toInt()];
                        final formattedDate = DateFormat('d/M').format(date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                        final formattedValue = NumberFormat.compact().format(value);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            formattedValue,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = dates[group.x];
                      final amount = rod.toY;
                      final type = rodIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$type\n${DateFormat('MMM d').format(date)}\n${NumberFormat.currency(symbol: '\$').format(amount)}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}