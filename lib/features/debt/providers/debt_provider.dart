import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../auth/providers/auth_provider.dart';

final debtRepositoryProvider =
    Provider<DebtRepository>((ref) => DebtRepository());

class DebtState {
  final List<DebtModel> debts;
  final bool isLoading;
  final String? error;
  final Map<String, double> summary;

  const DebtState({
    this.debts = const [],
    this.isLoading = false,
    this.error,
    this.summary = const {},
  });

  DebtState copyWith({
    List<DebtModel>? debts,
    bool? isLoading,
    String? error,
    Map<String, double>? summary,
  }) {
    return DebtState(
      debts: debts ?? this.debts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
    );
  }

  List<DebtModel> get owedDebts =>
      debts.where((d) => d.isOwed).toList();

  List<DebtModel> get receivableDebts =>
      debts.where((d) => d.isReceivable).toList();

  List<DebtModel> get unpaidDebts =>
      debts.where((d) => d.isUnpaid).toList();
}

class DebtNotifier extends StateNotifier<DebtState> {
  final DebtRepository _repo;
  final String userId;
  static const _uuid = Uuid();

  DebtNotifier(this._repo, this.userId) : super(const DebtState()) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    state = state.copyWith(isLoading: true);
    try {
      final debts = await _repo.getDebts(userId);
      final summary = await _repo.getSummary(userId);
      state = state.copyWith(
        debts: debts,
        isLoading: false,
        summary: summary,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addDebt({
    required String type,
    required String personName,
    required double amount,
    DateTime? dueDate,
    String? note,
  }) async {
    final debt = DebtModel(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      personName: personName,
      amount: amount,
      dueDate: dueDate,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.createDebt(debt);
    await loadDebts();
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _repo.updateDebt(debt);
    await loadDebts();
  }

  Future<void> markAsPaid(String id) async {
    await _repo.markAsPaid(id);
    await loadDebts();
  }

  Future<void> deleteDebt(String id) async {
    await _repo.deleteDebt(id);
    await loadDebts();
  }
}

final debtProvider = StateNotifierProvider<DebtNotifier, DebtState>((ref) {
  final repo = ref.read(debtRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return DebtNotifier(repo, user?.id ?? '');
});
