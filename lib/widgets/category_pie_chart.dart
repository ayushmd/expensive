import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/category_icons.dart';
import '../services/currency_service.dart';

class CategoryPieChart extends ConsumerWidget {
  const CategoryPieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final expensesAsync = ref.watch(expensesProvider(dateRange));
    final selectedCurrency = ref.watch(currencyProvider);

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(
            child: Text('No expenses in this period'),
          );
        }

        // Only show expenses, not income
        final expensesList = expenses.where((e) => e.type == TransactionType.expense).toList();
        if (expensesList.isEmpty) {
          return const Center(
            child: Text('No expenses in this period'),
          );
        }

        final categoryTotals = <String, double>{};
        for (final expense in expensesList) {
          categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
        }

        final totalAmount = categoryTotals.values.reduce((a, b) => a + b);
        final sections = categoryTotals.entries.map((entry) {
          final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${(entry.value / totalAmount * 100).toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

        return Column(
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: categoryTotals.entries.map((entry) {
                final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key}: ${selectedCurrency.symbol}${entry.value.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}