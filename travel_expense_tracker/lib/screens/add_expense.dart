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
import '../app_theme.dart';

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
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _aiController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime.now();
  String? _notes;
  bool _isLoading = false;

  bool get _isEditing => widget.existingExpense != null;

  static const _currencies = ['USD', 'EUR', 'AUD', 'GBP', 'JPY', 'CNY', 'INR'];

  static const _categoryMeta = {
    ExpenseCategory.food: (icon: Icons.restaurant_rounded, label: 'Food'),
    ExpenseCategory.transport: (icon: Icons.directions_car_rounded, label: 'Transport'),
    ExpenseCategory.accommodation: (icon: Icons.hotel_rounded, label: 'Hotel'),
    ExpenseCategory.activities: (icon: Icons.local_activity_rounded, label: 'Activities'),
    ExpenseCategory.shopping: (icon: Icons.shopping_bag_rounded, label: 'Shopping'),
    ExpenseCategory.health: (icon: Icons.medical_services_rounded, label: 'Health'),
    ExpenseCategory.other: (icon: Icons.category_rounded, label: 'Other'),
  };

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
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existingExpense!;
      _titleController.text = e.title;
      _title = e.title;
      _amountController.text = e.amount.toStringAsFixed(2);
      _amount = e.amount;
      _currency = e.currency;
      _category = e.category;
      _date = e.date;
      _notesController.text = e.notes ?? '';
      _notes = e.notes;
    }
  }

  void _fillFormFromParsed(Map<String, dynamic> parsed) {
    final title = parsed['title'] as String? ?? '';
    final amount = double.tryParse(parsed['amount']?.toString() ?? '') ?? 0.0;
    final currency = parsed['currency'] as String? ?? 'USD';
    final category = ExpenseCategory.values.firstWhere(
      (c) => c.toString().split('.').last == parsed['category'],
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

  Future<void> _showAiDialog() async {
    _aiController.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('AI Parse Text',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Describe your expense in plain English',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _aiController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. \$45 dinner in Paris last night',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (_aiController.text.isNotEmpty) {
                    _parseNaturalLanguage(_aiController.text);
                  }
                },
                child: const Text('Parse',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
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
      final cleaned =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      _fillFormFromParsed(jsonDecode(cleaned));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not parse: $e')));
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
                  'text': 'Extract expense details from this receipt.',
                },
              ],
            },
          ],
          'max_tokens': 300,
        }),
      );
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      final cleaned =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      _fillFormFromParsed(jsonDecode(cleaned));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt scanned — please review')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not scan receipt: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppTheme.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isEditing) {
      context.read<TripProvider>().updateExpense(
            widget.tripId,
            Expense(
              id: widget.existingExpense!.id,
              title: _title,
              amount: _amount,
              currency: _currency,
              category: _category,
              date: _date,
              notes: _notes,
              addedBy: widget.existingExpense!.addedBy,
            ),
          );
    } else {
      context.read<TripProvider>().addExpense(
            widget.tripId,
            Expense(
              title: _title,
              amount: _amount,
              currency: _currency,
              category: _category,
              date: _date,
              notes: _notes,
              addedBy: context.read<TripProvider>().displayName,
            ),
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Parse Text',
                          onTap: _isLoading ? null : _showAiDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.receipt_long_rounded,
                          label: 'Scan Receipt',
                          onTap: _isLoading ? null : _scanReceipt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _Label('Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('What did you buy?'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter a title' : null,
                    onChanged: (v) => setState(() => _title = v),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Amount'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountController,
                              decoration: _inputDecoration('\$ 0.00'),
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              onChanged: (v) => setState(
                                  () => _amount = double.tryParse(v) ?? 0.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Currency'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey(_currency),
                              value: _currency,
                              decoration: _inputDecoration(''),
                              items: _currencies
                                  .map((c) => DropdownMenuItem(
                                      value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _currency = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _Label('Date'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMM d, y').format(_date),
                            style: const TextStyle(
                                fontSize: 15, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Label('Category'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.values.map((cat) {
                      final meta = _categoryMeta[cat]!;
                      final selected = _category == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(meta.icon,
                                  size: 16,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                meta.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  _Label('Notes (Optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: _inputDecoration('Add details about this expense...'),
                    maxLines: 3,
                    onChanged: (v) => setState(() => _notes = v),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        _isEditing ? 'Save Changes' : 'Save Expense',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2B2E)));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}