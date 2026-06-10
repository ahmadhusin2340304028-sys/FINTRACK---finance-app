import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../../budget/providers/budget_provider.dart';
import '../../debt/providers/debt_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/services/csv_export_service.dart';

class ReportExportState {
  final bool isExporting;
  final String? exportedFilePath;
  final String? error;

  const ReportExportState({
    this.isExporting = false,
    this.exportedFilePath,
    this.error,
  });

  ReportExportState copyWith({
    bool? isExporting,
    String? exportedFilePath,
    String? error,
  }) {
    return ReportExportState(
      isExporting: isExporting ?? this.isExporting,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
      error: error,
    );
  }
}

class ReportExportNotifier extends StateNotifier<ReportExportState> {
  final Ref _ref;

  ReportExportNotifier(this._ref) : super(const ReportExportState());

  Future<String?> exportPdf() async {
    state = state.copyWith(isExporting: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User tidak ditemukan');

      final transactions =
          _ref.read(transactionProvider).transactions;
      final budgets = _ref.read(budgetProvider).budgets;
      final debts = _ref.read(debtProvider).debts;
      final savings = _ref.read(savingsProvider).savings;

      final file = await PdfExportService.generateReport(
        user: user,
        transactions: transactions,
        budgets: budgets,
        debts: debts,
        savings: savings,
      );

      state = state.copyWith(
          isExporting: false, exportedFilePath: file.path);
      return file.path;
    } catch (e) {
      state =
          state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  Future<String?> exportCsv() async {
    state = state.copyWith(isExporting: true);
    try {
      final transactions =
          _ref.read(transactionProvider).transactions;
      final file =
          await CsvExportService.exportTransactions(transactions);
      state = state.copyWith(
          isExporting: false, exportedFilePath: file.path);
      return file.path;
    } catch (e) {
      state =
          state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }
}

final reportExportProvider =
    StateNotifierProvider<ReportExportNotifier, ReportExportState>((ref) {
  return ReportExportNotifier(ref);
});
