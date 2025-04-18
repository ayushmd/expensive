enum TransactionType {
  expense,
  income
}

class Expense {
  final int? id;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final TransactionType type;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.index,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      category: map['category'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values[map['type'] as int],
    );
  }
}
