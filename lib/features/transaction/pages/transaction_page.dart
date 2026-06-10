import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_router.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final type = _tabController.index == 0
            ? null
            : _tabController.index == 1
                ? AppConstants.typeIncome
                : AppConstants.typeExpense;
        ref.read(transactionProvider.notifier).applyFilter(
              TransactionFilter(type: type),
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextFormField(
              controller: _searchController,
              onChanged: (v) {
                ref.read(transactionProvider.notifier).applyFilter(
                      TransactionFilter(searchQuery: v.isEmpty ? null : v),
                    );
              },
              decoration: InputDecoration(
                hintText: 'Cari transaksi...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(transactionProvider.notifier)
                              .clearFilter();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Summary badges
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _SummaryBadge(
                  label: 'Masuk',
                  amount: txState.summary['income'] ?? 0,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _SummaryBadge(
                  label: 'Keluar',
                  amount: txState.summary['expense'] ?? 0,
                  color: AppColors.danger,
                ),
                const Spacer(),
                Text(
                  '${txState.transactions.length} transaksi',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: txState.isLoading
                ? const AppLoadingIndicator()
                : txState.transactions.isEmpty
                    ? EmptyState(
                        title: 'Tidak ada transaksi',
                        message: 'Tekan tombol + untuk menambah transaksi',
                        icon: Icons.receipt_long_outlined,
                      )
                    : _GroupedTransactionList(
                        transactions: txState.transactions,
                      ),
          ),
        ],
      ),
      // TIDAK ADA FAB DI SINI - sudah ada di MainShell
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(
        onApply: (category, startDate, endDate) {
          ref.read(transactionProvider.notifier).applyFilter(
                TransactionFilter(
                  category: category,
                  startDate: startDate,
                  endDate: endDate,
                ),
              );
          Navigator.pop(ctx);
        },
        onClear: () {
          ref.read(transactionProvider.notifier).clearFilter();
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryBadge(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7, height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            '$label: ${CurrencyFormatter.formatCompact(amount)}',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _GroupedTransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _GroupedTransactionList({required this.transactions});

  Map<String, List<TransactionModel>> _groupByDate() {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final key = DateFormatter.formatFull(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: dates.length,
      itemBuilder: (ctx, i) {
        final date = dates[i];
        final txs = grouped[date]!;
        final dayTotal = txs.fold<double>(
          0,
          (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(date,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    (dayTotal >= 0 ? '+' : '') +
                        CurrencyFormatter.formatCompact(dayTotal),
                    style: TextStyle(
                      fontSize: 12,
                      color: dayTotal >= 0
                          ? AppColors.success
                          : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...txs.map((tx) => _TxCard(transaction: tx)),
          ],
        );
      },
    );
  }
}

class _TxCard extends ConsumerWidget {
  final TransactionModel transaction;

  const _TxCard({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color =
        transaction.isIncome ? AppColors.success : AppColors.danger;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hapus Transaksi'),
                content:
                    const Text('Yakin ingin menghapus transaksi ini?'),
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
      onDismissed: (_) {
        ref
            .read(transactionProvider.notifier)
            .deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi dihapus')),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.transactionDetail,
          arguments: transaction,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    AppConstants.categoryIcons[transaction.category] ??
                        '📌',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.category,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontSize: 14)),
                    if (transaction.note?.isNotEmpty == true)
                      Text(transaction.note!,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.formatCompact(transaction.amount)}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  Text(DateFormatter.formatTime(transaction.date),
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final void Function(String?, DateTime?, DateTime?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({required this.onApply, required this.onClear});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _category;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final allCategories = [
      ...AppConstants.expenseCategories,
      ...AppConstants.incomeCategories,
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filter Transaksi',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                  onPressed: widget.onClear,
                  child: const Text('Reset',
                      style: TextStyle(color: AppColors.danger))),
            ],
          ),
          const SizedBox(height: 16),
          Text('Kategori',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: allCategories.map((cat) {
              final selected = _category == cat;
              return CategoryChip(
                label: cat,
                emoji: AppConstants.categoryIcons[cat],
                isSelected: selected,
                onTap: () =>
                    setState(() => _category = selected ? null : cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                  child: Text(_startDate != null
                      ? DateFormatter.formatShort(_startDate!)
                      : 'Dari Tanggal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _endDate = d);
                  },
                  child: Text(_endDate != null
                      ? DateFormatter.formatShort(_endDate!)
                      : 'Sampai Tanggal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  widget.onApply(_category, _startDate, _endDate),
              child: const Text('Terapkan Filter'),
            ),
          ),
        ],
      ),
    );
  }
}
