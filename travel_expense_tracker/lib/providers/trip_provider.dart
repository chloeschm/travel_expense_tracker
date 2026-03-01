import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class TripProvider extends ChangeNotifier {
  final List<Trip> _trips = [];

  List<Trip> get trips => List.unmodifiable(_trips);

  void addTrip(Trip trip) {
    _trips.add(trip);
    notifyListeners();
  }

  void deleteTrip(String id) {
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void addExpense(String tripId, Expense expense) {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    trip.expenses.add(expense);
    notifyListeners();
  }

  void deleteExpense(String tripId, String expenseId) {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    trip.expenses.removeWhere((e) => e.id == expenseId);
    notifyListeners();
  }
}