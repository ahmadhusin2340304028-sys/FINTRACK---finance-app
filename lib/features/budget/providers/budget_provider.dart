import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class BudgetState {
  final List<BudgetModel> budgets;
  final bool isLoading;
  final String? error;

  const BudgetState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    List<BudgetModel>? budgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository _repo;
  final String userId;
  static const _uuid = Uuid();

  BudgetNotifier(this._repo, this.userId) : super(const BudgetState()) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true);
    try {
      final budgets = await _repo.getActiveBudgets(userId);
      state = state.copyWith(budgets: budgets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addBudget({
    required String name,
    required String category,
    required double target,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    String? color,
  }) async {
    final budget = BudgetModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      category: category,
      target: target,
      period: period,
      startDate: startDate,
      endDate: endDate,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.createBudget(budget);
    await loadBudgets();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await _repo.updateBudget(budget);
    await loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _repo.deleteBudget(id);
    await loadBudgets();
  }

  List<BudgetModel> get warningBudgets =>
      state.budgets.where((b) => b.isWarning || b.isOverBudget).toList();
}

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final repo = ref.read(budgetRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return BudgetNotifier(repo, user?.id ?? '');
});
