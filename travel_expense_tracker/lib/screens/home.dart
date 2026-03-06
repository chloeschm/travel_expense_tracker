import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import 'add_trip.dart';
import 'trip_detail.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TripProvider>().listenToTrips();
  }

  void _showJoinDialog(BuildContext context, TripProvider tripProvider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join a Trip'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter join code'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await tripProvider.joinTrip(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Join a trip',
            onPressed: () => _showJoinDialog(context, tripProvider),
          ),
        ],
      ),
      body: Center(
        child: ListView.builder(
          itemCount: tripProvider.trips.length,
          itemBuilder: (context, index) {
            final trip = tripProvider.trips[index];
            return Dismissible(
              key: Key(trip.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => tripProvider.deleteTrip(trip.id),
              child: ListTile(
                title: Text(trip.name),
                subtitle: Text(
                  '${trip.destination} - ${DateFormat('MMM d, y').format(trip.startDate)}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailScreen(trip: trip),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.ios_share),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'Join my trip "${trip.name}" on Travel Expense Tracker! Use code: ${trip.joinCode}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trip invite copied to clipboard!'),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTripScreen(existingTrip: trip),
                          ),
                        );
                      },
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
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
