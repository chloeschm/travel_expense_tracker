import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _currency = 'USD';

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Trip Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a trip name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a destination';
                  }
                  return null;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _startDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      _startDate == null
                          ? 'Select Start Date'
                          : 'Start: ${DateFormat('MMM d, y').format(_startDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _endDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      _endDate == null
                          ? 'Select End Date'
                          : 'End: ${DateFormat('MMM d, y').format(_endDate!)}',
                    ),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Currency'),
                      value: 'USD',
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                        DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                        DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                        DropdownMenuItem(value: 'INR', child: Text('INR')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _currency = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _startDate != null) {
                    final newTrip = Trip(
                      name: _nameController.text,
                      destination: _destinationController.text,
                      startDate: _startDate!,
                      endDate: _endDate,
                      budget: 0.0,
                      currency: _currency,
                    );
                    context.read<TripProvider>().addTrip(newTrip);
                    Navigator.pop(context);
                  } else if (_startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a start date'),
                      ),
                    );
                  }
                },
                child: const Text('Save Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
