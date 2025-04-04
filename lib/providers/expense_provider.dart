import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/expense.dart';

final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month, 1);
  return DateTimeRange(
    start: startOfMonth,
    end: today,
  );
});

final expensesProvider = StreamProvider.family<List<Expense>, DateTimeRange>((ref, dateRange) {
  return DatabaseService.watchExpensesByDateRange(dateRange.start, dateRange.end);
});

final totalExpensesProvider = Provider.family<double, DateTimeRange>((ref, dateRange) {
  final expensesAsync = ref.watch(expensesProvider(dateRange));
  return expensesAsync.when(
    data: (expenses) => expenses
        .where((e) => e.type == TransactionType.expense)
        .fold(0.0, (sum, expense) => sum + expense.amount),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final totalIncomeProvider = Provider.family<double, DateTimeRange>((ref, dateRange) {
  final expensesAsync = ref.watch(expensesProvider(dateRange));
  return expensesAsync.when(
    data: (expenses) => expenses
        .where((e) => e.type == TransactionType.income)
        .fold(0.0, (sum, expense) => sum + expense.amount),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final netBalanceProvider = Provider.family<double, DateTimeRange>((ref, dateRange) {
  final totalIncome = ref.watch(totalIncomeProvider(dateRange));
  final totalExpenses = ref.watch(totalExpensesProvider(dateRange));
  return totalIncome - totalExpenses;
});

final categoryTotalsProvider = Provider.family<Map<String, double>, DateTimeRange>((ref, dateRange) {
  final expensesAsync = ref.watch(expensesProvider(dateRange));
  return expensesAsync.when(
    data: (expenses) {
      final totals = <String, double>{};
      for (final expense in expenses) {
        if (expense.type == TransactionType.expense) {
          totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
        }
      }
      return totals;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});