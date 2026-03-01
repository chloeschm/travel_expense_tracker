import 'package:uuid/uuid.dart';

enum ExpenseCategory {
  food,
  transport,
  accommodation,
  activities,
  shopping,
  health,
  other
}

class Expense {
  final String id;
  String title;
  double amount;
  String currency;
  ExpenseCategory category;
  DateTime date;
  String? notes;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.notes,
  }) : id = id ?? const Uuid().v4();
}