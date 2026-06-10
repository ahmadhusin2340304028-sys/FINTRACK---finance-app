import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../budget/providers/budget_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../routes/app_router.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final theme = Theme.of(context);

    final totalTarget =
        budgetState.budgets.fold<double>(0, (s, b) => s + b.target);
    final totalUsed =
        budgetState.budgets.fold<double>(0, (s, b) => s + b.used);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.addBudget),
          ),
        ],
      ),
      body: budgetState.isLoading
          ? const AppLoadingIndicator()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  ref.read(budgetProvider.notifier).loadBudgets(),
              child: budgetState.budgets.isEmpty
                  ? EmptyState(
                      title: 'Belum ada budget',
                      message:
                          'Buat budget untuk mengontrol pengeluaranmu',
                      icon: Icons.pie_chart_outline_rounded,
                      buttonText: 'Buat Budget',
                      onButtonTap: () =>
                          Navigator.pushNamed(context, AppRouter.addBudget),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Summary card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _BudgetSummaryCard(
                              totalTarget: totalTarget,
                              totalUsed: totalUsed,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 12),
                            child: Text(
                              'Budget Aktif (${budgetState.budgets.length})',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 12),
                              child: _BudgetCard(
                                budget: budgetState.budgets[i],
                                onDelete: () async {
                                  await ref
                                      .read(budgetProvider.notifier)
                                      .deleteBudget(
                                          budgetState.budgets[i].id);
                                },
                              ),
                            ),
                            childCount: budgetState.budgets.length,
                          ),
                        ),
                        const SliverToBoxAdapter(
                            child: SizedBox(height: 100)),
                      ],
                    ),
            ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final double totalTarget;
  final double totalUsed;

  const _BudgetSummaryCard(
      {required this.totalTarget, required this.totalUsed});

  @override
  Widget build(BuildContext context) {
    final pct = totalTarget > 0 ? (totalUsed / totalTarget) : 0.0;
    final remaining = totalTarget - totalUsed;

    return GradientCard(
      colors: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Budget Bulan Ini',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(totalTarget),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.25),
              color: pct > 0.8 ? AppColors.warning : Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Terpakai ${CurrencyFormatter.formatCompact(totalUsed)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Sisa ${CurrencyFormatter.formatCompact(remaining)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onDelete;

  const _BudgetCard({required this.budget, required this.onDelete});

  Color get _statusColor {
    if (budget.isOverBudget) return AppColors.danger;
    if (budget.isWarning) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = AppConstants.categoryIcons[budget.category] ?? '💰';

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hapus Budget'),
                content:
                    const Text('Yakin ingin menghapus budget ini?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Hapus',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.name,
                          style: theme.textTheme.titleMedium),
                      Text(
                        budget.category,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (budget.isOverBudget)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Melebihi Budget!',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    Text(
                      '${(budget.percentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearPercentIndicator(
              percent: budget.percentage,
              lineHeight: 8,
              backgroundColor: _statusColor.withOpacity(0.15),
              progressColor: _statusColor,
              barRadius:const Radius.circular(4),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Terpakai: ${CurrencyFormatter.formatCompact(budget.used)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  'Target: ${CurrencyFormatter.formatCompact(budget.target)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
