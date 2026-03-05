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
      setState(() => _ratesLoaded = true);
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

            const Spacer(),
            if (_ratesLoaded) ...[
              Builder(
                builder: (context) {
                  final convertedSpent = currentTrip.expenses
                      .map(
                        (e) => _currencyService.convert(
                          e.amount,
                          e.currency,
                          currentTrip.currency,
                        ),
                      )
                      .fold(0.0, (sum, amt) => sum + amt);
                  final convertedRemaining =
                      currentTrip.budget - convertedSpent;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget: ${currentTrip.budget.toStringAsFixed(2)} ${currentTrip.currency}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Spent: ${convertedSpent.toStringAsFixed(2)} ${currentTrip.currency}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Remaining: ${convertedRemaining.toStringAsFixed(2)} ${currentTrip.currency}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: convertedRemaining < 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ] else
              const CircularProgressIndicator(),
            const Spacer(),

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
                  return Dismissible(
                    key: Key(expense.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      tripProvider.deleteExpense(currentTrip.id, expense.id);
                    },
                    child: ListTile(
                      title: Text(expense.title),
                      subtitle: Text(
                        DateFormat('MMM d, y').format(expense.date),
                      ),
                      leading: Text(
                        '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddExpenseScreen(
                                    tripId: currentTrip.id,
                                    existingExpense: expense,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
