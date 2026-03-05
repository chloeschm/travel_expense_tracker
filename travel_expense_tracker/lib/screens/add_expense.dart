import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';

class AddExpenseScreen extends StatefulWidget {
  final String tripId;
  final Expense? existingExpense;
  const AddExpenseScreen({
    super.key,
    required this.tripId,
    this.existingExpense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0.0;
  String _currency = 'USD';
  final _naturalLanguageController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime.now();
  String? _notes;
  bool _isLoading = false;

  String get _systemPrompt =>
      'Today is ${DateFormat('yyyy-MM-dd').format(DateTime.now())}. '
      'The user is inputting a travel expense. '
      'Extract the title, amount (as 0.00), currency (default USD), '
      'category (one of: food, transport, accommodation, activities, shopping, health, other), '
      'and date (as yyyy-MM-dd). '
      'Respond with raw JSON only — no markdown, no code fences, no extra text. '
      'Example: {"title":"Coffee","amount":"3.50","currency":"USD","category":"food","date":"2024-06-01"}';

  @override
  void dispose() {
    _naturalLanguageController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      _titleController.text = widget.existingExpense!.title;
      _amountController.text = widget.existingExpense!.amount.toStringAsFixed(
        2,
      );
      _currency = widget.existingExpense!.currency;
      _category = widget.existingExpense!.category;
      _date = widget.existingExpense!.date;
      _notesController.text = widget.existingExpense!.notes ?? '';
    }
  }

  void _fillFormFromParsed(Map<String, dynamic> parsed) {
    final title = parsed['title'] as String? ?? '';
    final amount = double.tryParse(parsed['amount']?.toString() ?? '') ?? 0.0;

    final currency = parsed['currency'] as String? ?? 'USD';
    final category = ExpenseCategory.values.firstWhere(
      (cat) => cat.toString().split('.').last == parsed['category'],
      orElse: () => ExpenseCategory.other,
    );
    final date = parsed['date'] != null
        ? DateTime.tryParse(parsed['date']) ?? DateTime.now()
        : DateTime.now();

    setState(() {
      _title = title;
      _amount = amount;
      _currency = currency;
      _category = category;
      _date = date;

      _titleController.text = title;
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  Future<void> _parseNaturalLanguage(String input) async {
    setState(() => _isLoading = true);
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
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': input},
          ],
        }),
      );

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      final cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      _fillFormFromParsed(parsed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not parse expense: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanReceipt() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = picked.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.openAiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
                },
                {
                  'type': 'text',
                  'text':
                      'This is a receipt. Extract the expense details from it.',
                },
              ],
            },
          ],
          'max_tokens': 300,
        }),
      );

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      final cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      _fillFormFromParsed(parsed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt scanned — please review')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not scan receipt: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _submitManual() {
    if (_formKey.currentState!.validate()) {
      if (widget.existingExpense == null) {
        final expense = Expense(
          title: _title,
          amount: _amount,
          currency: _currency,
          category: _category,
          date: _date,
          notes: _notes,
        );
        context.read<TripProvider>().addExpense(widget.tripId, expense);
      } else {
        final expense = Expense(
          id: widget.existingExpense!.id,
          title: _title,
          amount: _amount,
          currency: _currency,
          category: _category,
          date: _date,
          notes: _notes,
        );
        context.read<TripProvider>().updateExpense(widget.tripId, expense);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingExpense == null ? 'Add Expense' : 'Edit Expense',
        ),
      ),
      body: Stack(
        children: [
          Padding(
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
                        tooltip: 'Parse text',
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_naturalLanguageController
                                    .text
                                    .isNotEmpty) {
                                  _parseNaturalLanguage(
                                    _naturalLanguageController.text,
                                  );
                                }
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.receipt_long),
                        tooltip: 'Scan receipt',
                        onPressed: _isLoading ? null : _scanReceipt,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (value) => setState(() => _title = value),
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        setState(() => _amount = double.tryParse(value) ?? 0.0),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_currency),
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
                    onChanged: (value) => setState(() => _currency = value!),
                  ),
                  DropdownButtonFormField<ExpenseCategory>(
                    key: ValueKey(_category),
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: _category,
                    items: ExpenseCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.toString().split('.').last.toUpperCase(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _category = value!),
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
                        setState(() => _date = pickedDate);
                      }
                    },
                    child: Text(
                      'Date: ${DateFormat('MMM d, y').format(_date)}',
                    ),
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                    ),
                    onChanged: (value) => setState(() => _notes = value),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitManual,
                      child: Text(
                        widget.existingExpense == null
                            ? 'Add Expense'
                            : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
