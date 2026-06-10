import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../budget/providers/budget_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_router.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final txState = ref.watch(transactionProvider);
    final savingsState = ref.watch(savingsProvider);
    final theme = Theme.of(context);

    final income = txState.summary['income'] ?? 0;
    final expense = txState.summary['expense'] ?? 0;
    final balance = income - expense;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.refresh(transactionProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user?.name.split(' ').first ?? 'Pengguna'} 👋',
                            style: theme.textTheme.headlineSmall,
                          ),
                          Text(
                            'Kelola keuanganmu hari ini',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.profile),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: Text(
                            (user?.name.isNotEmpty == true)
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Balance card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _BalanceCard(
                    balance: balance,
                    income: income,
                    expense: expense,
                  ),
                ),
              ),
              // Summary cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      SummaryCard(
                        title: 'Pemasukan',
                        amount: CurrencyFormatter.formatCompact(income),
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.success,
                      ),
                      SummaryCard(
                        title: 'Pengeluaran',
                        amount: CurrencyFormatter.formatCompact(expense),
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.danger,
                      ),
                      SummaryCard(
                        title: 'Tabungan',
                        amount: CurrencyFormatter.formatCompact(
                            savingsState.totalSavings),
                        icon: Icons.savings_rounded,
                        color: AppColors.info,
                      ),
                      SummaryCard(
                        title: 'Budget Aktif',
                        amount:
                            '${ref.watch(budgetProvider).budgets.length} item',
                        icon: Icons.pie_chart_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ),
              // Budget warning
              if (ref.watch(budgetProvider).budgets.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _BudgetWarningBanner(
                      budgets: ref.watch(budgetProvider).budgets,
                    ),
                  ),
                ),
              // Daily budget info
              if (user != null && user.monthlyAllowance > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _DailyBudgetCard(user: user),
                  ),
                ),
              // Spending chart
              if (txState.categoryBreakdown.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _SpendingChart(
                      breakdown: txState.categoryBreakdown,
                      touchedIndex: _touchedPieIndex,
                      onTouch: (i) => setState(() => _touchedPieIndex = i),
                    ),
                  ),
                ),
              // Recent transactions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: SectionHeader(
                    title: 'Transaksi Terbaru',
                    action: 'Lihat Semua',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRouter.transactions),
                  ),
                ),
              ),
              if (txState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: AppLoadingIndicator(),
                  ),
                )
              else if (txState.transactions.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Belum ada transaksi',
                    message: 'Mulai catat pemasukan dan pengeluaranmu',
                    icon: Icons.receipt_long_outlined,
                    buttonText: 'Tambah Transaksi',
                    onButtonTap: () =>
                        Navigator.pushNamed(context, AppRouter.addTransaction),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final tx = txState.transactions
                          .take(5)
                          .toList()[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: _TransactionItem(transaction: tx),
                      );
                    },
                    childCount:
                        txState.transactions.take(5).length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Total Saldo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Bulan Ini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _CardStat(
                  label: 'Pemasukan',
                  amount: income,
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.white,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _CardStat(
                  label: 'Pengeluaran',
                  amount: expense,
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.white,
                  isRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isRight;

  const _CardStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isRight ? 16 : 0, right: isRight ? 0 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBudgetCard extends StatelessWidget {
  final dynamic user;

  const _DailyBudgetCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Harian',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(user.dailyBudget),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Mingguan',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              Text(
                CurrencyFormatter.formatCompact(user.weeklyBudget),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetWarningBanner extends StatelessWidget {
  final List budgets;

  const _BudgetWarningBanner({required this.budgets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${budgets.length} budget hampir habis! Gunakan uangmu lebih bijak.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  final Map<String, double> breakdown;
  final int touchedIndex;
  final void Function(int) onTouch;

  const _SpendingChart({
    required this.breakdown,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = breakdown.entries.toList();
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengeluaran Bulan Ini', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event.isInterestedForInteractions &&
                              response?.touchedSection != null) {
                            onTouch(response!
                                .touchedSection!.touchedSectionIndex);
                          } else {
                            onTouch(-1);
                          }
                        },
                      ),
                      sections: entries.asMap().entries.map((e) {
                        final isTouched = e.key == touchedIndex;
                        final pct = total > 0 ? e.value.value / total : 0;
                        return PieChartSectionData(
                          color: AppColors.chartColors[
                              e.key % AppColors.chartColors.length],
                          value: e.value.value,
                          title: isTouched
                              ? '${(pct * 100).toStringAsFixed(1)}%'
                              : '',
                          radius: isTouched ? 70 : 58,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ListView(
                    children: entries.asMap().entries.take(5).map((e) {
                      final pct = total > 0 ? e.value.value / total * 100 : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.chartColors[
                                    e.key % AppColors.chartColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value.key,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pengeluaran terbesar: ${entries.first.key} (${total > 0 ? (entries.first.value / total * 100).toStringAsFixed(0) : 0}%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                AppConstants.categoryIcons[transaction.category] ?? '📌',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  Text(
                    transaction.note!,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    DateFormatter.formatRelative(transaction.date),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatCompact(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
