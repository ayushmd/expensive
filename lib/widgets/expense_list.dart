import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/database_service.dart';
import '../utils/category_icons.dart';

class ExpenseList extends ConsumerWidget {
  const ExpenseList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final expensesAsync = ref.watch(expensesProvider(dateRange));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses for this period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        // Group expenses by date
        final groupedExpenses = <DateTime, List<dynamic>>{};
        for (final expense in expenses) {
          final date = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          if (!groupedExpenses.containsKey(date)) {
            groupedExpenses[date] = [];
          }
          groupedExpenses[date]!.add(expense);
        }

        final sortedDates = groupedExpenses.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayExpenses = groupedExpenses[date]!;
            final total = dayExpenses.fold<double>(
              0,
              (sum, expense) => sum + expense.amount,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat.yMMMd().format(date),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(total),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dayExpenses.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final expense = dayExpenses[index];
                      final color = expense.type == TransactionType.income
                        ? Colors.green
                        : Colors.primaries[expense.category.hashCode % Colors.primaries.length];

                      return Dismissible(
                        key: Key(expense.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                        onDismissed: (_) {
                          DatabaseService.deleteExpense(expense.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expense deleted'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(
                              expense.type == TransactionType.income
                                  ? Icons.add_circle_outline
                                  : CategoryIcons.getIcon(expense.category),
                              color: color,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            expense.category,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: expense.description?.isNotEmpty == true
                              ? Text(expense.description!)
                              : null,
                          trailing: Text(
                            '${expense.type == TransactionType.income ? '+' : '-'}\$${expense.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: expense.type == TransactionType.income ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (index < sortedDates.length - 1) const SizedBox(height: 16),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}