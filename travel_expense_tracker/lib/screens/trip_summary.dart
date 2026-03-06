import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/currency.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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

  PdfColor _categoryPdfColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return PdfColors.orange;
      case ExpenseCategory.transport:
        return PdfColors.blue;
      case ExpenseCategory.accommodation:
        return PdfColors.purple;
      case ExpenseCategory.activities:
        return PdfColors.green;
      case ExpenseCategory.shopping:
        return PdfColors.pink;
      case ExpenseCategory.health:
        return PdfColors.red;
      case ExpenseCategory.other:
        return PdfColors.grey;
    }
  }

  String _categoryName(ExpenseCategory category) {
    return category.toString().split('.').last[0].toUpperCase() +
        category.toString().split('.').last.substring(1);
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final totals = _getCategoryTotals();
    final grandTotal =
        totals.isEmpty ? 0.0 : totals.values.reduce((a, b) => a + b);
    final remaining = widget.trip.budget - grandTotal;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Trip Summary: ${widget.trip.name}',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Destination: ${widget.trip.destination}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Dates: ${DateFormat('MMM d, y').format(widget.trip.startDate)} - '
            '${widget.trip.endDate == null ? 'Ongoing' : DateFormat('MMM d, y').format(widget.trip.endDate!)}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'Budget: ${widget.trip.budget.toStringAsFixed(2)} ${widget.trip.currency}',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.Text(
            'Total Spent: ${grandTotal.toStringAsFixed(2)} ${widget.trip.currency}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Remaining: ${remaining.toStringAsFixed(2)} ${widget.trip.currency}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: remaining < 0 ? PdfColors.red : PdfColors.green,
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'Breakdown by Category',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...totals.entries.map((entry) {
            final percentage =
                grandTotal > 0 ? (entry.value / grandTotal) * 100 : 0.0;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 12,
                    height: 12,
                    color: _categoryPdfColor(entry.key),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      _categoryName(entry.key),
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ),
                  pw.Text(
                    '${entry.value.toStringAsFixed(2)} ${widget.trip.currency}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 24),

          pw.Text(
            'All Expenses',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text('Title',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('Amount',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('Category',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          pw.Divider(),
          ...widget.trip.expenses.map(
            (e) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(e.title,
                        style: const pw.TextStyle(fontSize: 13)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '${e.currency} ${e.amount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 13),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _categoryName(e.category),
                      style: const pw.TextStyle(fontSize: 13),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      DateFormat('MMM d, y').format(e.date),
                      style: const pw.TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${widget.trip.name}_summary.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _ratesLoaded ? _exportPDF : null,
          ),
        ],
      ),
      body: _ratesLoaded
          ? _buildSummary()
          : const Center(child: CircularProgressIndicator()),
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
              color: (widget.trip.budget - grandTotal) < 0
                  ? Colors.red
                  : Colors.green,
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