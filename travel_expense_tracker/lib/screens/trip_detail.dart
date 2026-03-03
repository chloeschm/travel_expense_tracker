import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final currentTrip = tripProvider.trips.firstWhere((t) => t.id == trip.id);

    return Scaffold(
      appBar: AppBar(title: Text(currentTrip.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destination: ${currentTrip.destination}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Dates: ${DateFormat('MMM d, y').format(currentTrip.startDate)} - ${currentTrip.endDate == null ? 'Ongoing' : DateFormat('MMM d, y').format(currentTrip.endDate!)}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            const Text('Expenses:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: currentTrip.expenses.length,
                itemBuilder: (context, index) {
                  final expense = currentTrip.expenses[index];
                  return ListTile(
                    title: Text(expense.title),
                    subtitle: Text(DateFormat('MMM d, y').format(expense.date)),
                    trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
