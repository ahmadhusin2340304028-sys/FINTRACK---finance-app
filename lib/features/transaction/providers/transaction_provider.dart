import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) => TransactionRepository());

final budgetRepositoryProvider =
    Provider<BudgetRepository>((ref) => BudgetRepository());

class TransactionFilter {
  final String? type;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const TransactionFilter({
    this.type,
    this.category,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  TransactionFilter copyWith({
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool clearType = false,
    bool clearCategory = false,
  }) {
    return TransactionFilter(
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;
  final TransactionFilter filter;
  final Map<String, double> summary;
  final Map<String, double> categoryBreakdown;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.filter = const TransactionFilter(),
    this.summary = const {},
    this.categoryBreakdown = const {},
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
    TransactionFilter? filter,
    Map<String, double>? summary,
    Map<String, double>? categoryBreakdown,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository _repo;
  final BudgetRepository _budgetRepo;
  final String userId;
  static const _uuid = Uuid();

  TransactionNotifier(this._repo, this._budgetRepo, this.userId)
      : super(const TransactionState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await _repo.getTransactions(
        userId,
        type: state.filter.type,
        category: state.filter.category,
        startDate: state.filter.startDate,
        endDate: state.filter.endDate,
        searchQuery: state.filter.searchQuery,
      );

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final summary = await _repo.getSummary(
        userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      final breakdown = await _repo.getCategoryBreakdown(
        userId,
        AppConstants.typeExpense,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        summary: summary,
        categoryBreakdown: breakdown,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    String? note,
    String? imagePath,
    String? accountId,
    DateTime? date,
  }) async {
    final transaction = TransactionModel(
      id: _uuid.v4(),
      userId: userId,
      accountId: accountId,
      type: type,
      amount: amount,
      category: category,
      note: note,
      imagePath: imagePath,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.createTransaction(transaction);

    // Update budget if expense
    if (type == AppConstants.typeExpense) {
      await _updateBudgetUsed(category, amount);
    }

    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repo.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> _updateBudgetUsed(String category, double amount) async {
    final budgets = await _budgetRepo.getActiveBudgets(userId);
    for (final budget in budgets) {
      if (budget.category == category) {
        await _budgetRepo.updateBudgetUsed(budget.id, budget.used + amount);
      }
    }
  }

  void applyFilter(TransactionFilter filter) {
    state = state.copyWith(filter: filter);
    loadTransactions();
  }

  void clearFilter() {
    state = state.copyWith(filter: const TransactionFilter());
    loadTransactions();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final repo = ref.read(transactionRepositoryProvider);
  final budgetRepo = ref.read(budgetRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return TransactionNotifier(repo, budgetRepo, user?.id ?? '');
});

// Monthly summary
final monthlySummaryProvider = FutureProvider.family<Map<String, double>, DateTime>(
  (ref, month) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    final repo = ref.read(transactionRepositoryProvider);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return await repo.getSummary(user.id, startDate: start, endDate: end);
  },
);

// Category breakdown provider
final categoryBreakdownProvider =
    FutureProvider.family<Map<String, double>, Map<String, dynamic>>(
  (ref, params) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    final repo = ref.read(transactionRepositoryProvider);
    return await repo.getCategoryBreakdown(
      user.id,
      params['type'] as String,
      startDate: params['startDate'] as DateTime?,
      endDate: params['endDate'] as DateTime?,
    );
  },
);
