import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/models/transaction_model.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';

class CsvExportService {
  static Future<File> exportTransactions(
      List<TransactionModel> transactions) async {
    final now = DateTime.now();
    final fileName =
        '${AppConstants.reportPrefix}${DateFormatter.formatFileName(now)}.csv';

    final buffer = StringBuffer();
    buffer.writeln('Tanggal,Jenis,Kategori,Nominal,Catatan');

    for (final tx in transactions) {
      final date = DateFormatter.formatShort(tx.date);
      final type = tx.isIncome ? 'Pemasukan' : 'Pengeluaran';
      final amount = tx.amount.toStringAsFixed(0);
      final note = (tx.note ?? '').replaceAll(',', ';');
      buffer.writeln('$date,$type,${tx.category},$amount,$note');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file;
  }
}
