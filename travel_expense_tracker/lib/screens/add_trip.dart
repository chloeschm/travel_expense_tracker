import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key, this.existingTrip});
  final Trip? existingTrip;

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
  final _budgetController = TextEditingController();
  double _budget = 0.0;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingTrip != null) {
      _nameController.text = widget.existingTrip!.name;
      _destinationController.text = widget.existingTrip!.destination;
      _startDate = widget.existingTrip!.startDate;
      _endDate = widget.existingTrip!.endDate;
      _currency = widget.existingTrip!.currency;
      _budgetController.text = widget.existingTrip!.budget.toStringAsFixed(2);
      _budget = widget.existingTrip!.budget;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTrip == null ? 'Add Trip' : 'Edit Trip'),
      ),
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
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'Budget'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    setState(() => _budget = double.tryParse(value) ?? 0.0),
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
                      value: _currency,
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
                    if (widget.existingTrip != null) {
                      final updatedTrip = Trip(
                        id: widget.existingTrip!.id,
                        name: _nameController.text,
                        destination: _destinationController.text,
                        startDate: _startDate!,
                        endDate: _endDate,
                        budget: _budget,
                        currency: _currency,
                        expenses: widget.existingTrip!.expenses,
                      );
                      context.read<TripProvider>().updateTrip(updatedTrip);
                    } else {
                      final newTrip = Trip(
                        name: _nameController.text,
                        destination: _destinationController.text,
                        startDate: _startDate!,
                        endDate: _endDate,
                        budget: _budget,
                        currency: _currency,
                      );
                      context.read<TripProvider>().addTrip(newTrip);
                    }
                    Navigator.pop(context);
                  } else if (_startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a start date'),
                      ),
                    );
                  }
                },
                child: Text(
                  widget.existingTrip == null ? 'Add Trip' : 'Save Changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
