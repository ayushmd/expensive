import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ExpenseSchema],
      directory: dir.path,
    );
  }

  static Future<void> addExpense(Expense expense) async {
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
    });
  }

  static Stream<List<Expense>> watchExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return isar.expenses
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  static Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() async {
      await isar.expenses.delete(id);
    });
  }
}