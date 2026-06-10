import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/savings_model.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';

class PdfExportService {
  static Future<File> generateReport({
    required UserModel user,
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required List<DebtModel> debts,
    required List<SavingsModel> savings,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final fileName =
        '${AppConstants.reportPrefix}${DateFormatter.formatFileName(now)}${AppConstants.reportExtPdf}';

    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(user, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(totalIncome, totalExpense),
          pw.SizedBox(height: 24),
          _buildTransactionsSection(transactions),
          pw.SizedBox(height: 24),
          if (budgets.isNotEmpty) ...[
            _buildBudgetsSection(budgets),
            pw.SizedBox(height: 24),
          ],
          if (debts.isNotEmpty) ...[
            _buildDebtsSection(debts),
            pw.SizedBox(height: 24),
          ],
          if (savings.isNotEmpty) _buildSavingsSection(savings),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(UserModel user, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FinTrack',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#FF4D94'),
                  ),
                ),
                pw.Text(
                  'Laporan Keuangan',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(user.name,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(user.email,
                    style: const pw.TextStyle(color: PdfColors.grey600)),
                pw.Text(DateFormatter.formatFull(date),
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColor.fromHex('#FF4D94'), thickness: 2),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('FinTrack — Keuangan Mahasiswa Cerdas',
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey500)),
        pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey500)),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
      double income, double expense) {
    final balance = income - expense;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ringkasan Keuangan',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _summaryBox('Total Pemasukan',
                  CurrencyFormatter.format(income), PdfColors.green),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _summaryBox('Total Pengeluaran',
                  CurrencyFormatter.format(expense), PdfColors.red),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _summaryBox(
                'Selisih',
                CurrencyFormatter.format(balance),
                balance >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryBox(
      String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius:
            const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionsSection(
      List<TransactionModel> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Daftar Transaksi (${transactions.length})',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FF4D94')),
              children: [
                _tableHeader('Tanggal'),
                _tableHeader('Kategori'),
                _tableHeader('Jenis'),
                _tableHeader('Nominal'),
              ],
            ),
            ...transactions.take(50).map(
                  (tx) => pw.TableRow(
                    children: [
                      _tableCell(DateFormatter.formatShort(tx.date)),
                      _tableCell(tx.category),
                      _tableCell(
                          tx.isIncome ? 'Masuk' : 'Keluar'),
                      _tableCell(
                        '${tx.isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
                        color: tx.isIncome
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                    ],
                  ),
                ),
          ],
        ),
        if (transactions.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '... dan ${transactions.length - 50} transaksi lainnya',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildBudgetsSection(List<BudgetModel> budgets) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Budget (${budgets.length})',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FF4D94')),
              children: [
                _tableHeader('Nama'),
                _tableHeader('Kategori'),
                _tableHeader('Target'),
                _tableHeader('Terpakai'),
                _tableHeader('%'),
              ],
            ),
            ...budgets.map(
              (b) => pw.TableRow(
                children: [
                  _tableCell(b.name),
                  _tableCell(b.category),
                  _tableCell(CurrencyFormatter.format(b.target)),
                  _tableCell(CurrencyFormatter.format(b.used)),
                  _tableCell(
                    '${(b.percentage * 100).toStringAsFixed(0)}%',
                    color: b.isOverBudget
                        ? PdfColors.red
                        : PdfColors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDebtsSection(List<DebtModel> debts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Hutang & Piutang (${debts.length})',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FF4D94')),
              children: [
                _tableHeader('Nama'),
                _tableHeader('Jenis'),
                _tableHeader('Nominal'),
                _tableHeader('Status'),
              ],
            ),
            ...debts.map(
              (d) => pw.TableRow(
                children: [
                  _tableCell(d.personName),
                  _tableCell(
                      d.isOwed ? 'Hutang' : 'Piutang'),
                  _tableCell(
                      CurrencyFormatter.format(d.amount)),
                  _tableCell(
                    d.isPaid ? 'Lunas' : 'Belum Lunas',
                    color: d.isPaid
                        ? PdfColors.green
                        : PdfColors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSavingsSection(
      List<SavingsModel> savings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Target Tabungan (${savings.length})',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FF4D94')),
              children: [
                _tableHeader('Nama Target'),
                _tableHeader('Target'),
                _tableHeader('Terkumpul'),
                _tableHeader('%'),
              ],
            ),
            ...savings.map(
              (s) => pw.TableRow(
                children: [
                  _tableCell(s.goalName),
                  _tableCell(
                      CurrencyFormatter.format(s.targetAmount)),
                  _tableCell(
                      CurrencyFormatter.format(s.currentAmount)),
                  _tableCell(
                    '${(s.percentage * 100).toStringAsFixed(0)}%',
                    color: s.isCompleted
                        ? PdfColors.green
                        : PdfColors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
