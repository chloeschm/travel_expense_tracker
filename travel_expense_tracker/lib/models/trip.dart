import 'package:uuid/uuid.dart';
import 'expense.dart';
import 'dart:math';

String _generateJoinCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random();
  return 'TR-${List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join()}';
}

class Trip {
  final String id;
  String name;
  String destination;
  DateTime startDate;
  DateTime? endDate;
  double budget;
  String currency;
  List<Expense> expenses;
  String joinCode;
  List<String> members;
  String createdBy;

  Trip({
    List<String>? members,
    String? id,
    required this.name,
    required this.destination,
    required this.startDate,
    this.endDate,
    required this.budget,
    this.currency = 'USD',
    List<Expense>? expenses,
    String? joinCode,
    required this.createdBy,
  }) : members = members ?? [],
       joinCode = joinCode ?? _generateJoinCode(),
       id = id ?? const Uuid().v4(),
       expenses = expenses ?? [];

  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);
  double get remaining => budget - totalSpent;
}
