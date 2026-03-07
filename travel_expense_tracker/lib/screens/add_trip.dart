import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';

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
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _currency = 'USD';
  double _budget = 0.0;

  bool get _isEditing => widget.existingTrip != null;

  static const _currencies = [
    ('USD', 'USD (\$)'),
    ('EUR', 'EUR (€)'),
    ('AUD', 'AUD (A\$)'),
    ('GBP', 'GBP (£)'),
    ('JPY', 'JPY (¥)'),
    ('CNY', 'CNY (¥)'),
    ('INR', 'INR (₹)'),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
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
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (_isEditing) {
      context.read<TripProvider>().updateTrip(
        Trip(
          id: widget.existingTrip!.id,
          name: _nameController.text.trim(),
          destination: _destinationController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate,
          budget: _budget,
          currency: _currency,
          expenses: widget.existingTrip!.expenses,
          joinCode: widget.existingTrip!.joinCode,
          members: widget.existingTrip!.members,
          createdBy: uid,
        ),
      );
    } else {
      context.read<TripProvider>().addTrip(
        Trip(
          name: _nameController.text.trim(),
          destination: _destinationController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate,
          budget: _budget,
          currency: _currency,
          createdBy: uid,
        ),
      );
    }
    Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        prefixIcon: prefixIcon,
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
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Trip' : 'Add Trip',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing) ...[
                const Text(
                  'Plan your next\nadventure',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2B2E),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in the details to start your journey.',
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
              ] else
                const SizedBox(height: 16),

              const _Label('Trip Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g. Roadtrip to California'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter a trip name' : null,
              ),
              const SizedBox(height: 20),

              const _Label('Destination'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destinationController,
                decoration: _inputDecoration(
                  'Where are you going?',
                  prefixIcon: const Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.isEmpty
                    ? 'Please enter a destination'
                    : null,
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'YYYY-MM-DD',
                      date: _startDate,
                      onTap: () => _pickDate(isStart: true),
                      labelText: 'Start Date',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: 'YYYY-MM-DD',
                      date: _endDate,
                      onTap: () => _pickDate(isStart: false),
                      labelText: 'End Date',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Budget'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          child: TextFormField(
                            controller: _budgetController,
                            decoration: _inputDecoration(
                              '0.00',
                              prefixIcon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(
                              () => _budget = double.tryParse(v) ?? 0.0,
                            ),
                          ),
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
                        const _Label('Currency'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          child: DropdownButtonFormField<String>(
                            value: _currency,
                            isDense: true,
                            decoration: _inputDecoration(''),
                            items: _currencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.$1,
                                    child: Text(c.$2),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _currency = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.flight_takeoff_rounded, size: 20),
                  label: Text(
                    _isEditing ? 'Save Changes' : 'Create Trip',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F2B2E),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String? labelText;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2B2E),
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date == null ? label : DateFormat('MMM d, y').format(date!),
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight: date != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
