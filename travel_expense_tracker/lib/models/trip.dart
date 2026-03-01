import 'package:uuid/uuid.dart';
import 'expense.dart';

class Trip {
  final String id;
  String name;
  String destination;
  DateTime startDate;
  DateTime? endDate;
  double budget;
  String currency;
  List<Expense> expenses;

  Trip({
    String? id,
    required this.name,
    required this.destination,
    required this.startDate,
    this.endDate,
    required this.budget,
    this.currency = 'USD',
    List<Expense>? expenses,
  })  : id = id ?? const Uuid().v4(),
        expenses = expenses ?? [];

  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);
  double get remaining => budget - totalSpent;
}