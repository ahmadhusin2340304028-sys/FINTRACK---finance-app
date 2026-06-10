import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  int _touchedPie = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _startOfMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _endOfMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
  DateTime get _startOfWeek {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _endOfWeek =>
      _startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap & Analisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Mingguan'),
            Tab(text: 'Bulanan'),
            Tab(text: 'Tahunan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DailyReport(userId: user?.id ?? ''),
          _WeeklyReport(userId: user?.id ?? ''),
          _MonthlyReport(
            userId: user?.id ?? '',
            selectedMonth: _selectedMonth,
            onMonthChange: (m) => setState(() => _selectedMonth = m),
            touchedPie: _touchedPie,
            onPieTouch: (i) => setState(() => _touchedPie = i),
          ),
          _YearlyReport(userId: user?.id ?? ''),
        ],
      ),
    );
  }
}

// ── Daily Report ─────────────────────────────────────────────────────
class _DailyReport extends ConsumerWidget {
  final String userId;
  const _DailyReport({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    final summaryAsync = ref.watch(monthlySummaryProvider(start));

    return summaryAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;
        final balance = income - expense;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _PeriodHeader(
                title: 'Hari Ini',
                subtitle: DateFormatter.formatFull(now),
              ),
              const SizedBox(height: 16),
              _SummaryRow(income: income, expense: expense, balance: balance),
            ],
          ),
        );
      },
    );
  }
}

// ── Weekly Report ────────────────────────────────────────────────────
class _WeeklyReport extends ConsumerWidget {
  final String userId;
  const _WeeklyReport({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final summaryAsync = ref.watch(monthlySummaryProvider(start));

    return summaryAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;
        final balance = income - expense;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _PeriodHeader(
                title: 'Minggu Ini',
                subtitle:
                    '${DateFormatter.formatDayMonth(start)} - ${DateFormatter.formatFull(end)}',
              ),
              const SizedBox(height: 16),
              _SummaryRow(income: income, expense: expense, balance: balance),
              const SizedBox(height: 20),
              _BarChartSection(userId: userId, start: start, end: end),
            ],
          ),
        );
      },
    );
  }
}

// ── Monthly Report ───────────────────────────────────────────────────
class _MonthlyReport extends ConsumerWidget {
  final String userId;
  final DateTime selectedMonth;
  final void Function(DateTime) onMonthChange;
  final int touchedPie;
  final void Function(int) onPieTouch;

  const _MonthlyReport({
    required this.userId,
    required this.selectedMonth,
    required this.onMonthChange,
    required this.touchedPie,
    required this.onPieTouch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);
    final summaryAsync = ref.watch(monthlySummaryProvider(start));
    final breakdownAsync = ref.watch(
      categoryBreakdownProvider({
        'type': AppConstants.typeExpense,
        'startDate': start,
        'endDate': end,
      }),
    );

    return summaryAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;
        final balance = income - expense;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Month navigator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => onMonthChange(
                      DateTime(selectedMonth.year, selectedMonth.month - 1),
                    ),
                  ),
                  Text(
                    DateFormatter.formatMonthYear(selectedMonth),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: selectedMonth.month < DateTime.now().month ||
                            selectedMonth.year < DateTime.now().year
                        ? () => onMonthChange(
                              DateTime(selectedMonth.year, selectedMonth.month + 1),
                            )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(income: income, expense: expense, balance: balance),
              const SizedBox(height: 20),
              // Category breakdown chart
              breakdownAsync.when(
                loading: () => const AppLoadingIndicator(),
                error: (e, _) => const SizedBox.shrink(),
                data: (breakdown) {
                  if (breakdown.isEmpty) return const SizedBox.shrink();
                  return _CategoryPieChart(
                    breakdown: breakdown,
                    touchedIndex: touchedPie,
                    onTouch: onPieTouch,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Yearly Report ────────────────────────────────────────────────────
class _YearlyReport extends ConsumerWidget {
  final String userId;
  const _YearlyReport({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    final summaryAsync = ref.watch(monthlySummaryProvider(start));

    return summaryAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;
        final balance = income - expense;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _PeriodHeader(
                title: 'Tahun $year',
                subtitle: 'Rekap Januari - Desember $year',
              ),
              const SizedBox(height: 16),
              _SummaryRow(income: income, expense: expense, balance: balance),
              const SizedBox(height: 20),
              _MonthlyBarChart(year: year, userId: userId),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────
class _PeriodHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PeriodHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const _SummaryRow({
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReportCard(
                label: 'Pemasukan',
                amount: income,
                color: AppColors.success,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportCard(
                label: 'Pengeluaran',
                amount: expense,
                color: AppColors.danger,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (balance >= 0 ? AppColors.success : AppColors.danger)
                .withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (balance >= 0 ? AppColors.success : AppColors.danger)
                  .withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                balance >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: balance >= 0 ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 12),
              Text(
                'Selisih',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(balance.abs()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: balance >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _ReportCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> breakdown;
  final int touchedIndex;
  final void Function(int) onTouch;

  const _CategoryPieChart({
    required this.breakdown,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = breakdown.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengeluaran per Kategori',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (e, res) {
                          if (e.isInterestedForInteractions &&
                              res?.touchedSection != null) {
                            onTouch(res!.touchedSection!.touchedSectionIndex);
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
                          radius: isTouched ? 72 : 60,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final pct = total > 0 ? e.value / total * 100 : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.chartColors[
                                    i % AppColors.chartColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.key,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Terbesar: ${entries.first.key} (${total > 0 ? (entries.first.value / total * 100).toStringAsFixed(0) : 0}%) — ${CurrencyFormatter.formatCompact(entries.first.value)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
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

class _BarChartSection extends ConsumerWidget {
  final String userId;
  final DateTime start;
  final DateTime end;

  const _BarChartSection(
      {required this.userId, required this.start, required this.end});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final txState = ref.watch(transactionProvider);
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // Build daily totals from transactions
    final Map<int, double> expenseByDay = {};
    for (final tx in txState.transactions) {
      if (tx.isExpense && !tx.date.isBefore(start) && !tx.date.isAfter(end)) {
        final weekday = tx.date.weekday;
        expenseByDay[weekday] = (expenseByDay[weekday] ?? 0) + tx.amount;
      }
    }

    final maxY = expenseByDay.values.isEmpty
        ? 100.0
        : expenseByDay.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengeluaran Minggu Ini', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: List.generate(7, (i) {
                  final day = i + 1;
                  final val = expenseByDay[day] ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: AppColors.primary,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.primary.withOpacity(0.06),
                        ),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        days[v.toInt()],
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends ConsumerWidget {
  final int year;
  final String userId;

  const _MonthlyBarChart({required this.year, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final txState = ref.watch(transactionProvider);

    final Map<int, double> expenseByMonth = {};
    final Map<int, double> incomeByMonth = {};
    for (final tx in txState.transactions) {
      if (tx.date.year == year) {
        final month = tx.date.month;
        if (tx.isExpense) {
          expenseByMonth[month] = (expenseByMonth[month] ?? 0) + tx.amount;
        } else {
          incomeByMonth[month] = (incomeByMonth[month] ?? 0) + tx.amount;
        }
      }
    }

    final allVals = [...expenseByMonth.values, ...incomeByMonth.values];
    final maxY = allVals.isEmpty
        ? 100.0
        : allVals.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren Bulanan $year', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: AppColors.success, label: 'Pemasukan'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.danger, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: List.generate(12, (i) {
                  final month = i + 1;
                  return BarChartGroupData(
                    x: i,
                    groupVertically: false,
                    barRods: [
                      BarChartRodData(
                        toY: incomeByMonth[month] ?? 0,
                        color: AppColors.success,
                        width: 10,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: expenseByMonth[month] ?? 0,
                        color: AppColors.danger,
                        width: 10,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = [
                          'J','F','M','A','M','J','J','A','S','O','N','D'
                        ];
                        return Text(labels[v.toInt()],
                            style: theme.textTheme.bodySmall);
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
