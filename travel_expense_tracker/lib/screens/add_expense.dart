import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final String tripId;

  const AddExpenseScreen({super.key, required this.tripId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0.0;
  String _currency = 'USD';

  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime.now();
  String? _notes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (value) {
                  setState(() {
                    _title = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _amount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Currency'),
                initialValue: _currency,
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currency = value!;
                  });
                },
              ),
              DropdownButtonFormField<ExpenseCategory>(
                decoration: const InputDecoration(labelText: 'Category'),
                initialValue: _category,
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category.toString().split('.').last.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _date = pickedDate;
                    });
                  }
                },
                child: Text(
                  'Please select a date: ${DateFormat('MMM d, y').format(_date)}',
                ),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
                onChanged: (value) {
                  setState(() {
                    _notes = value;
                  });
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newExpense = Expense(
                      title: _title,
                      amount: _amount,
                      currency: _currency,
                      category: _category,
                      date: _date,
                      notes: _notes,
                    );
                    context.read<TripProvider>().addExpense(
                      widget.tripId,
                      newExpense,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
