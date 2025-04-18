import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/monthly_chart.dart';
import 'add_expense_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildAmountCard(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      child: Container(
        width: fullWidth ? double.infinity : MediaQuery.of(context).size.width * 0.45,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '\$').format(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final totalExpenses = ref.watch(totalExpensesProvider(dateRange));
    final totalIncome = ref.watch(totalIncomeProvider(dateRange));
    final netBalance = ref.watch(netBalanceProvider(dateRange));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            expandedHeight: 300,
            title: Text(
              'Expense Manager',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            centerTitle: false,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  '${DateFormat('MMM d').format(dateRange.start)} - ${DateFormat('MMM d').format(dateRange.end)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final lastDate = DateTime(now.year, now.month, now.day);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: lastDate,
                    initialDateRange: dateRange.end.isAfter(lastDate) 
                      ? DateTimeRange(
                          start: dateRange.start,
                          end: lastDate,
                        )
                      : dateRange,
                  );
                  if (picked != null) {
                    ref.read(dateRangeProvider.notifier).state = picked;
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.0,
              titlePadding: EdgeInsets.zero,
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 80, 8, 0),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            child: _buildAmountCard(
                              context,
                              'Net Balance',
                              netBalance,
                              Icons.account_balance_wallet,
                              netBalance >= 0 ? Colors.green : Colors.red,
                              fullWidth: true,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _buildAmountCard(
                                      context,
                                      'Income',
                                      totalIncome,
                                      Icons.add_circle_outline,
                                      Colors.green,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _buildAmountCard(
                                      context,
                                      'Expenses',
                                      totalExpenses,
                                      Icons.remove_circle_outline,
                                      Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Spending Trends',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: MonthlyChart(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CategoryPieChart(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
                  child: const ExpenseList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}