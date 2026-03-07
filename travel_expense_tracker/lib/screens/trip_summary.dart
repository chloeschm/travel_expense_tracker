import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/currency.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class TripSummaryScreen extends StatefulWidget {
  final Trip trip;
  const TripSummaryScreen({super.key, required this.trip});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  final _currencyService = CurrencyService();
  bool _ratesLoaded = false;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _currencyService.fetchRates(widget.trip.currency).then((_) {
      if (mounted) setState(() => _ratesLoaded = true);
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
      case ExpenseCategory.food: return const Color(0xFFF97316);
      case ExpenseCategory.transport: return const Color(0xFF3B82F6);
      case ExpenseCategory.accommodation: return const Color(0xFF8B5CF6);
      case ExpenseCategory.activities: return const Color(0xFF10B981);
      case ExpenseCategory.shopping: return const Color(0xFFEC4899);
      case ExpenseCategory.health: return const Color(0xFFEF4444);
      case ExpenseCategory.other: return const Color(0xFF9CA3AF);
    }
  }

  PdfColor _categoryPdfColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food: return PdfColors.orange;
      case ExpenseCategory.transport: return PdfColors.blue;
      case ExpenseCategory.accommodation: return PdfColors.purple;
      case ExpenseCategory.activities: return PdfColors.green;
      case ExpenseCategory.shopping: return PdfColors.pink;
      case ExpenseCategory.health: return PdfColors.red;
      case ExpenseCategory.other: return PdfColors.grey;
    }
  }

  String _categoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food: return 'Food & Dining';
      case ExpenseCategory.transport: return 'Transportation';
      case ExpenseCategory.accommodation: return 'Accommodation';
      case ExpenseCategory.activities: return 'Activities';
      case ExpenseCategory.shopping: return 'Shopping';
      case ExpenseCategory.health: return 'Health';
      case ExpenseCategory.other: return 'Other';
    }
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
          pw.Text('Trip Summary: ${widget.trip.name}',
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Destination: ${widget.trip.destination}',
              style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            'Dates: ${DateFormat('MMM d, y').format(widget.trip.startDate)} - '
            '${widget.trip.endDate == null ? 'Ongoing' : DateFormat('MMM d, y').format(widget.trip.endDate!)}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
              'Budget: ${widget.trip.budget.toStringAsFixed(2)} ${widget.trip.currency}',
              style: const pw.TextStyle(fontSize: 16)),
          pw.Text(
              'Total Spent: ${grandTotal.toStringAsFixed(2)} ${widget.trip.currency}',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              'Remaining: ${remaining.toStringAsFixed(2)} ${widget.trip.currency}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: remaining < 0 ? PdfColors.red : PdfColors.green,
              )),
          pw.SizedBox(height: 24),
          pw.Text('Breakdown by Category',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...totals.entries.map((entry) {
            final percentage =
                grandTotal > 0 ? (entry.value / grandTotal) * 100 : 0.0;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(children: [
                pw.Container(
                    width: 12,
                    height: 12,
                    color: _categoryPdfColor(entry.key)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                    child: pw.Text(_categoryName(entry.key),
                        style: const pw.TextStyle(fontSize: 14))),
                pw.Text(
                    '${entry.value.toStringAsFixed(2)} ${widget.trip.currency}',
                    style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(width: 12),
                pw.Text('${percentage.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey)),
              ]),
            );
          }),
          pw.SizedBox(height: 24),
          pw.Text('All Expenses',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(
                flex: 3,
                child: pw.Text('Title',
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(
                flex: 2,
                child: pw.Text('Amount',
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(
                flex: 2,
                child: pw.Text('Category',
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(
                flex: 2,
                child: pw.Text('Date',
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ]),
          pw.Divider(),
          ...widget.trip.expenses.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(children: [
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text(e.title,
                          style: const pw.TextStyle(fontSize: 13))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          '${e.currency} ${e.amount.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 13))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(_categoryName(e.category),
                          style: const pw.TextStyle(fontSize: 13))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          DateFormat('MMM d, y').format(e.date),
                          style: const pw.TextStyle(fontSize: 13))),
                ]),
              )),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Trip Summary',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: _ratesLoaded
          ? _buildSummary()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSummary() {
    final totals = _getCategoryTotals();

    if (totals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 30, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text('No expenses yet',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ],
        ),
      );
    }

    final grandTotal = totals.values.reduce((a, b) => a + b);
    final remaining = widget.trip.budget - grandTotal;
    final isOverBudget = remaining < 0;

    final sections = totals.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value.key;
      final value = entry.value.value;
      final isTouched = i == _touchedIndex;

      return PieChartSectionData(
        value: value,
        color: _categoryColor(cat),
        title: '',
        radius: isTouched ? 60 : 50,
        badgeWidget: null,
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.trip.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Expense Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                const Text('Expenses by Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 3,
                          centerSpaceRadius: 70,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.trip.currency} ${grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'TOTAL SPENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: totals.entries.map((entry) {
                    final percentage =
                        (entry.value / grandTotal * 100).toStringAsFixed(0);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _categoryColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_categoryName(entry.key)} ($percentage%)',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Spent',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.trip.currency} ${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Remaining Budget',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.trip.currency} ${remaining.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isOverBudget
                              ? AppTheme.error
                              : AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _exportPDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text('Download PDF Report',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}