import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/currency.dart';

class TripSummaryScreen extends StatefulWidget {
  final Trip trip;
  const TripSummaryScreen({super.key, required this.trip});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  final _currencyService = CurrencyService();
  bool _ratesLoaded = false;

  @override
  void initState() {
    super.initState();
    _currencyService.fetchRates(widget.trip.currency).then((_) {
      setState(() => _ratesLoaded = true);
    });
  }

  Map<ExpenseCategory, double> _getCategoryTotals() {
    final totals = <ExpenseCategory, double>{};
    for (final expense in widget.trip.expenses) {
      final converted = _currencyService.convert(
        expense.amount,
        expense.currency,
        widget.trip.currency,
      );
      totals[expense.category] = (totals[expense.category] ?? 0) + converted;
    }
    return totals;
  }

  Color _categoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.accommodation:
        return Colors.purple;
      case ExpenseCategory.activities:
        return Colors.green;
      case ExpenseCategory.shopping:
        return Colors.pink;
      case ExpenseCategory.health:
        return Colors.red;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  String _categoryName(ExpenseCategory category) {
    return category.toString().split('.').last[0].toUpperCase() +
        category.toString().split('.').last.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Summary')),
      body: _ratesLoaded ? _buildSummary() : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSummary() {
    final totals = _getCategoryTotals();

    if (totals.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }

    final grandTotal = totals.values.reduce((a, b) => a + b);

    final sections = totals.entries.map((entry) {
      final percentage = (entry.value / grandTotal) * 100;
      return PieChartSectionData(
        value: entry.value,
        color: _categoryColor(entry.key),
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget: ${widget.trip.budget.toStringAsFixed(2)} ${widget.trip.currency}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Spent: ${grandTotal.toStringAsFixed(2)} ${widget.trip.currency}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Remaining: ${(widget.trip.budget - grandTotal).toStringAsFixed(2)} ${widget.trip.currency}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: (widget.trip.budget - grandTotal) < 0 ? Colors.red : Colors.green,
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,      
                centerSpaceRadius: 40, 
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...totals.entries.map((entry) {
            final percentage = (entry.value / grandTotal) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _categoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _categoryName(entry.key),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(2)} ${widget.trip.currency}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}