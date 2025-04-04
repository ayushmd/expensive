import 'package:isar/isar.dart';

part 'expense.g.dart';

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

  Expense({
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });
}
