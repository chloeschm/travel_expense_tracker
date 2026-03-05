import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import 'add_expense.dart';
import '../services/currency.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _currencyService = CurrencyService();
  bool _ratesLoaded = false;

  @override
void initState() {
  super.initState();
  _currencyService.fetchRates(widget.trip.currency).then((_) {
      setState(() {
        _ratesLoaded = true;

        _currencyService.fetchRates(widget.trip.currency).then((_) {
          setState(() {
            _ratesLoaded = true;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final currentTrip = tripProvider.trips.firstWhere(
      (t) => t.id == widget.trip.id,
    );

    return Scaffold(
      appBar: AppBar(title: Text(currentTrip.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destination: ${currentTrip.destination}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Dates: ${DateFormat('MMM d, y').format(currentTrip.startDate)} - ${currentTrip.endDate == null ? 'Ongoing' : DateFormat('MMM d, y').format(currentTrip.endDate!)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Budget: ${currentTrip.budget.toStringAsFixed(2)} ${currentTrip.currency}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Spent: ${currentTrip.totalSpent.toStringAsFixed(2)} ${currentTrip.currency}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Remaining: ${currentTrip.remaining.toStringAsFixed(2)} ${currentTrip.currency}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: currentTrip.remaining < 0 ? Colors.red : Colors.green,
              ),
            ),
            if (_ratesLoaded)
              Text(
                'Converted Total: ${currentTrip.expenses.map((e) => _currencyService.convert(e.amount, e.currency, currentTrip.currency)).fold(0.0, (sum, amount) => sum + amount).toStringAsFixed(2)} ${currentTrip.currency}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            const Text(
              'Expenses:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: currentTrip.expenses.length,
                itemBuilder: (context, index) {
                  final expense = currentTrip.expenses[index];
                  return ListTile(
                    title: Text(expense.title),
                    subtitle: Text(DateFormat('MMM d, y').format(expense.date)),
                    trailing: Text(
                      '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(tripId: currentTrip.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
