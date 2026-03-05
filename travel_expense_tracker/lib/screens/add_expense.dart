import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

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
  final _naturalLanguageController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime.now();
  String? _notes;

  @override
  void dispose() {
    _naturalLanguageController.dispose();
    super.dispose();
  }

  Future<void> _parseNaturalLanguage(String input) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.openAiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Today is ${DateFormat('yyyy-MM-dd').format(DateTime.now())}. The users are inputting a travel expense for a specific trip. Read their message and return with an appropriate title, amount (in form of 0.00), currency (default to USD), appropriate category out of food, transport, accommodation, activities, shopping, health, other, and the date (in form of 0000-00-00). Respond in JSON only with no extra text. Respond with raw JSON only. Do not use markdown code fences or any other formatting.',
            },
            {'role': 'user', 'content': input},
          ],
        }),
      );

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      final cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final parsed = jsonDecode(cleaned);

      final newExpense = Expense(
        title: parsed['title'],
        amount: (parsed['amount'] as num).toDouble(),
        currency: parsed['currency'] ?? 'USD',
        category: ExpenseCategory.values.firstWhere(
          (cat) => cat.toString().split('.').last == parsed['category'],
          orElse: () => ExpenseCategory.other,
        ),
        date: parsed['date'] != null
            ? DateTime.parse(parsed['date'])
            : DateTime.now(),
        notes: null,
      );
      context.read<TripProvider>().addExpense(widget.tripId, newExpense);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not parse expense: $e')));
    }
  }

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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _naturalLanguageController,
                      decoration: const InputDecoration(
                        labelText: 'Quick add',
                        hintText: 'e.g. spent \$12 on coffee in Tokyo',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: () {
                      if (_naturalLanguageController.text.isNotEmpty) {
                        _parseNaturalLanguage(_naturalLanguageController.text);
                      }
                    },
                  ),
                ],
              ),

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
                key: ValueKey(_currency),
                decoration: const InputDecoration(labelText: 'Currency'),
                initialValue: _currency,
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
