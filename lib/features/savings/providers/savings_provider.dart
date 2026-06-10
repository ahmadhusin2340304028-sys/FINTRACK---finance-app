import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/savings_model.dart';
import '../../../data/repositories/savings_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/app_constants.dart';

final savingsRepositoryProvider =
    Provider<SavingsRepository>((ref) => SavingsRepository());

class SavingsState {
  final List<SavingsModel> savings;
  final bool isLoading;
  final String? error;
  final double totalSavings;

  const SavingsState({
    this.savings = const [],
    this.isLoading = false,
    this.error,
    this.totalSavings = 0,
  });

  SavingsState copyWith({
    List<SavingsModel>? savings,
    bool? isLoading,
    String? error,
    double? totalSavings,
  }) {
    return SavingsState(
      savings: savings ?? this.savings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalSavings: totalSavings ?? this.totalSavings,
    );
  }

  List<SavingsModel> get activeSavings =>
      savings.where((s) => !s.isCompleted).toList();

  List<SavingsModel> get completedSavings =>
      savings.where((s) => s.isCompleted).toList();
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  final SavingsRepository _repo;
  final NotificationService _notifService;
  final String userId;
  static const _uuid = Uuid();

  SavingsNotifier(this._repo, this._notifService, this.userId)
      : super(const SavingsState()) {
    loadSavings();
  }

  Future<void> loadSavings() async {
    state = state.copyWith(isLoading: true);
    try {
      final savings = await _repo.getSavings(userId);
      final total = await _repo.getTotalSavings(userId);
      state = state.copyWith(
        savings: savings,
        isLoading: false,
        totalSavings: total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addSavings({
    required String goalName,
    required double targetAmount,
    DateTime? deadline,
    String? icon,
    String? color,
  }) async {
    final savings = SavingsModel(
      id: _uuid.v4(),
      userId: userId,
      goalName: goalName,
      targetAmount: targetAmount,
      deadline: deadline,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.createSavings(savings);
    await loadSavings();
  }

  Future<void> addAmount(String id, double amount) async {
    final before = state.savings.firstWhere((s) => s.id == id);
    await _repo.addAmount(id, amount);

    // Check milestones
    final after = await _repo.getSavingsById(id);
    if (after != null) {
      for (final milestone in AppConstants.savingsMilestones) {
        final milestoneInt = (milestone * 100).toInt();
        if (before.percentage < milestone && after.percentage >= milestone) {
          await _notifService.showSavingsMilestone(
            goalName: after.goalName,
            milestone: milestoneInt,
          );
        }
      }
    }

    await loadSavings();
  }

  Future<void> updateSavings(SavingsModel savings) async {
    await _repo.updateSavings(savings);
    await loadSavings();
  }

  Future<void> deleteSavings(String id) async {
    await _repo.deleteSavings(id);
    await loadSavings();
  }
}

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  final repo = ref.read(savingsRepositoryProvider);
  final notifService = NotificationService();
  final user = ref.watch(currentUserProvider);
  return SavingsNotifier(repo, notifService, user?.id ?? '');
});
