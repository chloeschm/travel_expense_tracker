import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class TripProvider extends ChangeNotifier {
  final List<Trip> _trips = [];
  List<Trip> get trips => List.unmodifiable(_trips);

  String _displayName = 'Traveler';
  String _preferredCurrency = 'USD';

  String get displayName => _displayName;
  String get preferredCurrency => _preferredCurrency;

  final _db = FirebaseFirestore.instance;
  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  Trip _parseTrip(String id, Map<String, dynamic> data) {
    final expensesData = data['expenses'] as List<dynamic>? ?? [];
    final expenses = expensesData.map((e) {
      return Expense(
        id: e['id'],
        title: e['title'],
        amount: (e['amount'] as num).toDouble(),
        currency: e['currency'],
        category: ExpenseCategory.values.firstWhere(
          (cat) => cat.toString().split('.').last == e['category'],
          orElse: () => ExpenseCategory.other,
        ),
        date: (e['date'] as Timestamp).toDate(),
        notes: e['notes'],
        addedBy: e['addedBy'] ?? 'Unknown',
      );
    }).toList();

    return Trip(
      id: id,
      name: data['name'],
      destination: data['destination'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      budget: (data['budget'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      expenses: expenses,
      joinCode: data['joinCode'],
      members: List<String>.from(data['members'] ?? []),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Future<void> loadUserProfile() async {
    final doc = await _db.collection('users').doc(_userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      _displayName = data['displayName'] as String? ?? 'Traveler';
      _preferredCurrency = data['preferredCurrency'] as String? ?? 'USD';
    } else {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      _displayName = email.split('@').first;
      _preferredCurrency = 'USD';
      await saveUserProfile(_displayName, _preferredCurrency);
    }
    notifyListeners();
  }

  Future<void> saveUserProfile(String name, String currency) async {
    _displayName = name;
    _preferredCurrency = currency;
    await _db.collection('users').doc(_userId).set({
      'displayName': name,
      'preferredCurrency': currency,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  void listenToTrips() {
    _db
        .collection('users')
        .doc(_userId)
        .collection('joinedTrips')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        _db
            .collection('trips')
            .doc(doc.id)
            .snapshots()
            .listen((tripDoc) {
          if (!tripDoc.exists) return;
          final trip = _parseTrip(tripDoc.id, tripDoc.data()!);
          final index = _trips.indexWhere((t) => t.id == tripDoc.id);
          if (index >= 0) {
            _trips[index] = trip;
          } else {
            _trips.add(trip);
          }
          notifyListeners();
        });
      }
    });
  }

  Future<void> addTrip(Trip trip) async {
    await _db.collection('trips').doc(trip.id).set({
      'name': trip.name,
      'destination': trip.destination,
      'startDate': Timestamp.fromDate(trip.startDate),
      'endDate':
          trip.endDate != null ? Timestamp.fromDate(trip.endDate!) : null,
      'budget': trip.budget,
      'currency': trip.currency,
      'expenses': [],
      'joinCode': trip.joinCode,
      'members': [_userId],
      'createdBy': _userId,
    });

    await _db
        .collection('users')
        .doc(_userId)
        .collection('joinedTrips')
        .doc(trip.id)
        .set({'joinedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteTrip(String tripId) async {
    await _db.collection('trips').doc(tripId).delete();
    await _db
        .collection('users')
        .doc(_userId)
        .collection('joinedTrips')
        .doc(tripId)
        .delete();
    _trips.removeWhere((t) => t.id == tripId);
    notifyListeners();
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    await _db.collection('trips').doc(updatedTrip.id).update({
      'name': updatedTrip.name,
      'destination': updatedTrip.destination,
      'startDate': Timestamp.fromDate(updatedTrip.startDate),
      'endDate': updatedTrip.endDate != null
          ? Timestamp.fromDate(updatedTrip.endDate!)
          : null,
      'budget': updatedTrip.budget,
      'currency': updatedTrip.currency,
    });
  }

  Future<void> addExpense(String tripId, Expense expense) async {
    await _db.collection('trips').doc(tripId).update({
      'expenses': FieldValue.arrayUnion([
        {
          'id': expense.id,
          'title': expense.title,
          'amount': expense.amount,
          'currency': expense.currency,
          'category': expense.category.toString().split('.').last,
          'date': Timestamp.fromDate(expense.date),
          'notes': expense.notes,
          'addedBy': expense.addedBy,
        },
      ]),
    });
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    final tripRef = _db.collection('trips').doc(tripId);
    final tripDoc = await tripRef.get();
    final expenses = List<Map<String, dynamic>>.from(tripDoc['expenses']);
    expenses.removeWhere((e) => e['id'] == expenseId);
    await tripRef.update({'expenses': expenses});
  }

  Future<void> updateExpense(String tripId, Expense updatedExpense) async {
    final tripRef = _db.collection('trips').doc(tripId);
    final tripDoc = await tripRef.get();
    final expenses = List<Map<String, dynamic>>.from(tripDoc['expenses']);
    final index = expenses.indexWhere((e) => e['id'] == updatedExpense.id);
    if (index != -1) {
      expenses[index] = {
        'id': updatedExpense.id,
        'title': updatedExpense.title,
        'amount': updatedExpense.amount,
        'currency': updatedExpense.currency,
        'category': updatedExpense.category.toString().split('.').last,
        'date': Timestamp.fromDate(updatedExpense.date),
        'notes': updatedExpense.notes,
        'addedBy': updatedExpense.addedBy,
      };
      await tripRef.update({'expenses': expenses});
    }
  }

  Future<void> joinTrip(String code) async {
    final query = await _db
        .collection('trips')
        .where('joinCode', isEqualTo: code.toUpperCase().trim())
        .get();

    if (query.docs.isEmpty) throw Exception('Invalid join code');

    final tripId = query.docs.first.id;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('joinedTrips')
        .doc(tripId)
        .set({'joinedAt': FieldValue.serverTimestamp()});

    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayUnion([_userId]),
    });
  }
}