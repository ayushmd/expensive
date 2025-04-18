import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/monthly_chart.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/currency_service.dart';
import 'add_expense_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _isRetrying = false;
    });

    try {
      debugPrint('Initializing database from HomeScreen...');
      await DatabaseService.initialize();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Database initialization completed in HomeScreen');
    } catch (e) {
      debugPrint('Error initializing database in HomeScreen: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _retryInitialization() async {
    if (_isRetrying) return;
    
    setState(() {
      _isRetrying = true;
    });

    try {
      DatabaseService.dispose();
      await _initializeDatabase();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Widget _buildAmountCard(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    final currencyFormatter = ref.watch(currencyProvider.notifier);
    
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
              currencyFormatter.format(amount),
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize database',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _retryInitialization();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dateRange = ref.watch(dateRangeProvider);
    final totalExpenses = ref.watch(totalExpensesProvider(dateRange));
    final totalIncome = ref.watch(totalIncomeProvider(dateRange));
    final netBalance = ref.watch(netBalanceProvider(dateRange));
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final availableCurrencies = ref.watch(currenciesProvider);
    final selectedCurrency = ref.watch(currencyProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(''),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                ),
              ],
            ),
            leadingWidth: 48,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<Currency>(
                  value: selectedCurrency,
                  items: availableCurrencies.map((Currency currency) {
                    return DropdownMenuItem<Currency>(
                      value: currency,
                      child: Text(
                        '${currency.symbol} ${currency.code}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (Currency? newValue) {
                    if (newValue != null) {
                      ref.read(currencyProvider.notifier).setCurrency(newValue);
                    }
                  },
                  underline: Container(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                ),
              ),
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
            pinned: true,
            expandedHeight: 300,
            centerTitle: false,
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
                          // Net Balance Card (Full Width)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
                          // Income and Expense Cards (Side by Side)
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
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
                                  padding: const EdgeInsets.only(right: 4),
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
                          const SizedBox(height: 32),
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
                const SizedBox(height: 16),
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