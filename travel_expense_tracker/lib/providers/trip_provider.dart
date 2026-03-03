import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class TripProvider extends ChangeNotifier {
  final List<Trip> _trips = [];
  List<Trip> get trips => List.unmodifiable(_trips);

  final _db = FirebaseFirestore.instance;
  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  void listenToTrips() {
    _db
        .collection('users')
        .doc(_userId)
        .collection('trips')
        .snapshots()
        .listen((snapshot) {
      _trips.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final expensesData = data['expenses'] as List<dynamic>? ?? [];
        final expenses = expensesData.map((e) {
          return Expense(
            id: e['id'],
            title: e['title'],
            amount: (e['amount'] as num).toDouble(),
            currency: e['currency'],
            category: ExpenseCategory.values.firstWhere(
              (cat) => cat.toString().split('.').last == e['category'],
            ),
            date: (e['date'] as Timestamp).toDate(),
            notes: e['notes'],
          );
        }).toList();

        _trips.add(Trip(
          id: doc.id,
          name: data['name'],
          destination: data['destination'],
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate()
              : null,
          budget: (data['budget'] ?? 0.0).toDouble(),
          currency: data['currency'] ?? 'USD',
          expenses: expenses,
        ));
      }
      notifyListeners();
    });
  }

  Future<void> addTrip(Trip trip) async {
    await _db
        .collection('users')
        .doc(_userId)
        .collection('trips')
        .doc(trip.id)
        .set({
      'name': trip.name,
      'destination': trip.destination,
      'startDate': trip.startDate,
      'endDate': trip.endDate,
      'budget': trip.budget,
      'currency': trip.currency,
      'expenses': [],
    });
  }

  Future<void> deleteTrip(String id) async {
    await _db
        .collection('users')
        .doc(_userId)
        .collection('trips')
        .doc(id)
        .delete();
  }

  Future<void> addExpense(String tripId, Expense expense) async {
    final tripRef = _db
        .collection('users')
        .doc(_userId)
        .collection('trips')
        .doc(tripId);

    await tripRef.update({
      'expenses': FieldValue.arrayUnion([{
        'id': expense.id,
        'title': expense.title,
        'amount': expense.amount,
        'currency': expense.currency,
        'category': expense.category.toString().split('.').last,
        'date': expense.date,
        'notes': expense.notes,
      }])
    });
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    final tripRef = _db
        .collection('users')
        .doc(_userId)
        .collection('trips')
        .doc(tripId);

    final tripDoc = await tripRef.get();
    final expenses = List<Map<String, dynamic>>.from(tripDoc['expenses']);
    expenses.removeWhere((e) => e['id'] == expenseId);
    await tripRef.update({'expenses': expenses});
  }
}