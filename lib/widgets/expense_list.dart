import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/currency_service.dart';
import '../utils/category_icons.dart';
import '../utils/income_icons.dart';
import '../services/database_service.dart';

class ExpenseList extends ConsumerWidget {
  const ExpenseList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final expenses = ref.watch(expensesProvider(dateRange));
    final currencyFormatter = ref.watch(currencyProvider.notifier);

    return expenses.when(
      data: (expenseList) {
        if (expenseList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        // Group expenses by date
        final groupedExpenses = <DateTime, List<Expense>>{};
        for (final expense in expenseList) {
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
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
                      final isIncome = expense.type == TransactionType.income;
                      final color = isIncome ? Colors.green : Colors.red;
                      
                      return Dismissible(
                        key: Key('expense_${expense.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Transaction'),
                              content: Text(
                                'Are you sure you want to delete this ${isIncome ? 'income' : 'expense'}?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          DatabaseService.deleteExpense(expense.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${isIncome ? 'Income' : 'Expense'} deleted',
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  DatabaseService.addExpense(expense);
                                },
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(
                              isIncome 
                                ? IncomeIcons.getIcon(expense.category)
                                : CategoryIcons.getIcon(expense.category),
                              color: color,
                            ),
                          ),
                          title: Text(
                            expense.category,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: expense.description?.isNotEmpty == true
                              ? Text(expense.description!)
                              : null,
                          trailing: Text(
                            isIncome 
                                ? '+${currencyFormatter.format(expense.amount)}'
                                : '-${currencyFormatter.format(expense.amount)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year != now.year ? date.year : ''}';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }
}