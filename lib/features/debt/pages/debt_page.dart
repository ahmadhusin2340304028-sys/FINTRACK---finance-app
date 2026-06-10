import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../debt/providers/debt_provider.dart';
import '../../../data/models/debt_model.dart';
import '../../../routes/app_router.dart';

class DebtPage extends ConsumerStatefulWidget {
  const DebtPage({super.key});

  @override
  ConsumerState<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends ConsumerState<DebtPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final debtState = ref.watch(debtProvider);
    final theme = Theme.of(context);

    final totalOwed = debtState.summary['owed'] ?? 0;
    final totalReceivable = debtState.summary['receivable'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutang & Piutang'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '😰 Hutang Saya'),
            Tab(text: '💰 Piutang Saya'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _DebtSummaryCard(
                    label: 'Total Hutang',
                    amount: totalOwed,
                    color: AppColors.danger,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DebtSummaryCard(
                    label: 'Total Piutang',
                    amount: totalReceivable,
                    color: AppColors.success,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DebtList(
                  debts: debtState.owedDebts,
                  isLoading: debtState.isLoading,
                  emptyTitle: 'Tidak ada hutang',
                  emptyMsg: 'Kamu tidak punya hutang 🎉',
                  type: AppConstants.debtTypeOwed,
                ),
                _DebtList(
                  debts: debtState.receivableDebts,
                  isLoading: debtState.isLoading,
                  emptyTitle: 'Tidak ada piutang',
                  emptyMsg: 'Belum ada yang berhutang kepadamu',
                  type: AppConstants.debtTypeReceivable,
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tambah Apa?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.addDebt,
                          arguments: {'type': AppConstants.debtTypeOwed});
                    },
                    icon: const Icon(Icons.arrow_upward_rounded,
                        color: AppColors.danger),
                    label: const Text('Hutang',
                        style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.addDebt,
                          arguments: {
                            'type': AppConstants.debtTypeReceivable
                          });
                    },
                    icon: const Icon(Icons.arrow_downward_rounded,
                        color: AppColors.success),
                    label: const Text('Piutang',
                        style: TextStyle(color: AppColors.success)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _DebtSummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: color)),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtList extends ConsumerWidget {
  final List<DebtModel> debts;
  final bool isLoading;
  final String emptyTitle;
  final String emptyMsg;
  final String type;

  const _DebtList({
    required this.debts,
    required this.isLoading,
    required this.emptyTitle,
    required this.emptyMsg,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) return const AppLoadingIndicator();
    if (debts.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        message: emptyMsg,
        icon: Icons.handshake_outlined,
      );
    }

    final unpaid = debts.where((d) => d.isUnpaid).toList();
    final paid = debts.where((d) => d.isPaid).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (unpaid.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum Lunas (${unpaid.length})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
          ...unpaid.map((d) => _DebtCard(debt: d)),
        ],
        if (paid.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Lunas (${paid.length})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
          ...paid.map((d) => _DebtCard(debt: d)),
        ],
      ],
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final DebtModel debt;

  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOwed = debt.isOwed;
    final color = isOwed ? AppColors.danger : AppColors.success;
    final isPaid = debt.isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: debt.isOverdue
            ? Border.all(color: AppColors.danger, width: 1.5)
            : null,
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
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Text(
                  debt.personName.isNotEmpty
                      ? debt.personName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.personName,
                        style: theme.textTheme.titleMedium),
                    if (debt.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: debt.isOverdue
                                ? AppColors.danger
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Jatuh tempo: ${DateFormatter.formatShort(debt.dueDate!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: debt.isOverdue
                                  ? AppColors.danger
                                  : AppColors.textHint,
                              fontWeight: debt.isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (debt.isOverdue)
                            const Text(' ⚠️',
                                style: TextStyle(fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCompact(debt.amount),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.success.withOpacity(0.1)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? 'Lunas' : 'Belum Lunas',
                      style: TextStyle(
                        fontSize: 10,
                        color: isPaid ? AppColors.success : color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(height: 12),
            LinearPercentIndicator(
              percent: debt.percentage,
              lineHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              progressColor: color,
              barRadius:const Radius.circular(3),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Tandai Lunas'),
                          content: Text(
                              'Tandai ${isOwed ? 'hutang' : 'piutang'} ini sebagai lunas?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Batal')),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Ya, Lunas!',
                                  style: TextStyle(
                                      color: AppColors.success)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(debtProvider.notifier)
                            .markAsPaid(debt.id);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('✓ Tandai Lunas',
                        style: TextStyle(
                            color: AppColors.success, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(debtProvider.notifier)
                        .deleteDebt(debt.id);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger, size: 16),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
