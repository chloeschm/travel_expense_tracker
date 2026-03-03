import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import 'add_trip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: Center(
        child: ListView.builder(
          itemCount: tripProvider.trips.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(tripProvider.trips[index].name),
              subtitle: Text(
                '${tripProvider.trips[index].destination} - ${DateFormat('MMM d, y').format(tripProvider.trips[index].startDate)}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to trip details
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTripScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
