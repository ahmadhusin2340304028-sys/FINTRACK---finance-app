import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../budget/providers/budget_provider.dart';
import '../../debt/providers/debt_provider.dart';

class DashboardSummary {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double totalSavings;
  final int activeBudgets;
  final int unpaidDebts;

  const DashboardSummary({
    this.totalBalance = 0,
    this.monthlyIncome = 0,
    this.monthlyExpense = 0,
    this.totalSavings = 0,
    this.activeBudgets = 0,
    this.unpaidDebts = 0,
  });
}

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final txState = ref.watch(transactionProvider);
  final savingsState = ref.watch(savingsProvider);
  final budgetState = ref.watch(budgetProvider);
  final debtState = ref.watch(debtProvider);

  final income = txState.summary['income'] ?? 0;
  final expense = txState.summary['expense'] ?? 0;

  return DashboardSummary(
    totalBalance: income - expense,
    monthlyIncome: income,
    monthlyExpense: expense,
    totalSavings: savingsState.totalSavings,
    activeBudgets: budgetState.budgets.length,
    unpaidDebts: debtState.unpaidDebts.length,
  );
});
