import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../savings/providers/savings_provider.dart';
import '../../../data/models/savings_model.dart';
import '../../../routes/app_router.dart';

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsState = ref.watch(savingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: savingsState.isLoading
          ? const AppLoadingIndicator()
          : savingsState.savings.isEmpty
              ? EmptyState(
                  title: 'Belum ada target tabungan',
                  message: 'Buat target tabungan untuk tujuanmu',
                  icon: Icons.savings_outlined,
                  buttonText: 'Buat Target',
                  onButtonTap: () =>
                      Navigator.pushNamed(context, AppRouter.addSavings),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _TotalSavingsCard(
                            total: savingsState.totalSavings),
                      ),
                    ),
                    if (savingsState.activeSavings.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Text(
                              'Target Aktif (${savingsState.activeSavings.length})',
                              style: theme.textTheme.titleMedium),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: _SavingsCard(
                                savings: savingsState.activeSavings[i]),
                          ),
                          childCount: savingsState.activeSavings.length,
                        ),
                      ),
                    ],
                    if (savingsState.completedSavings.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Text(
                              '🎉 Tercapai (${savingsState.completedSavings.length})',
                              style: theme.textTheme.titleMedium),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: _SavingsCard(
                                savings:
                                    savingsState.completedSavings[i]),
                          ),
                          childCount:
                              savingsState.completedSavings.length,
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 100)),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () =>
            Navigator.pushNamed(context, AppRouter.addSavings),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TotalSavingsCard extends StatelessWidget {
  final double total;

  const _TotalSavingsCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: AppColors.savingsGradient,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Tabungan',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Icon(Icons.savings_rounded,
              color: Colors.white70, size: 48),
        ],
      ),
    );
  }
}

class _SavingsCard extends ConsumerWidget {
  final SavingsModel savings;

  const _SavingsCard({required this.savings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = savings.isCompleted;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.savingsDetail,
        arguments: savings,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    savings.icon ?? '🎯',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(savings.goalName,
                          style: theme.textTheme.titleMedium),
                      if (savings.deadline != null)
                        Text(
                          'Target: ${DateFormatter.formatShort(savings.deadline!)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isCompleted)
                      const Text('🎉',
                          style: TextStyle(fontSize: 22))
                    else
                      Text(
                        '${(savings.percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.info,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearPercentIndicator(
              percent: savings.percentage,
              lineHeight: 8,
              backgroundColor:
                  (isCompleted ? AppColors.success : AppColors.info)
                      .withOpacity(0.15),
              progressColor:
                  isCompleted ? AppColors.success : AppColors.info,
              barRadius:const Radius.circular(4),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Terkumpul: ${CurrencyFormatter.formatCompact(savings.currentAmount)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  'Target: ${CurrencyFormatter.formatCompact(savings.targetAmount)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (!isCompleted && savings.dailySavingsNeeded != null) ...[
              const SizedBox(height: 6),
              Text(
                'Perlu nabung ~${CurrencyFormatter.formatCompact(savings.dailySavingsNeeded!)}/hari',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
