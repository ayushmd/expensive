import 'package:isar/isar.dart';

part 'expense.g.dart';

enum TransactionType {
  expense,
  income
}

@collection
class Expense {
  Id id = Isar.autoIncrement;
  
  @Index()
  double amount;

  @Index()
  String category;

  String? description;

  @Index()
  DateTime date;

  @enumerated
  TransactionType type;

  Expense({
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.type,
  });
}
