import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/expense.dart';

final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0),
  );
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final dateRange = ref.watch(dateRangeProvider);
  return DatabaseService.watchExpensesByDateRange(
    dateRange.start,
    dateRange.end,
  );
});

final totalExpensesProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.when(
    data: (expenses) {
      return expenses.fold<double>(
        0,
        (total, expense) => total + expense.amount,
      );
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.when(
    data: (expenses) {
      final totals = <String, double>{};
      for (final expense in expenses) {
        totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
      }
      return totals;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});