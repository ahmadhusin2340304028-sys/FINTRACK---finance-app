import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../savings/providers/savings_provider.dart';
import '../../../data/models/savings_model.dart';

// ─── Add Savings Page ──────────────────────────────────────────────
class AddSavingsPage extends ConsumerStatefulWidget {
  const AddSavingsPage({super.key});

  @override
  ConsumerState<AddSavingsPage> createState() => _AddSavingsPageState();
}

class _AddSavingsPageState extends ConsumerState<AddSavingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _deadline;
  String _selectedIcon = '🎯';
  bool _isLoading = false;

  final _icons = [
    '🎯', '💻', '📱', '🏍️', '✈️', '🎓', '🏠', '👗',
    '🎮', '📚', '🚗', '💍', '🎸', '🌏', '🏋️', '💊'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final raw =
        _targetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final target = double.parse(raw);

    await ref.read(savingsProvider.notifier).addSavings(
          goalName: _nameController.text.trim(),
          targetAmount: target,
          deadline: _deadline,
          icon: _selectedIcon,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target tabungan ditambahkan 🎯'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Target Tabungan Baru')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon selector
              Text('Pilih Ikon', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(icon,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    Validators.validateRequired(v, 'Nama target'),
                decoration: const InputDecoration(
                  labelText: 'Nama Target',
                  hintText: 'Contoh: Laptop Baru',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.validateSavingsTarget,
                decoration: const InputDecoration(
                  labelText: 'Target Nominal',
                  hintText: '5000000',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _deadline ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _deadline = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _deadline != null
                            ? AppColors.primary
                            : AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20,
                          color: _deadline != null
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _deadline != null
                              ? 'Deadline: ${DateFormatter.formatFull(_deadline!)}'
                              : 'Deadline (opsional)',
                          style: TextStyle(
                              color: _deadline != null
                                  ? null
                                  : AppColors.textHint),
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _deadline = null),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textHint),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Target',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Savings Detail Page ──────────────────────────────────────────
class SavingsDetailPage extends ConsumerStatefulWidget {
  final SavingsModel savings;

  const SavingsDetailPage({super.key, required this.savings});

  @override
  ConsumerState<SavingsDetailPage> createState() =>
      _SavingsDetailPageState();
}

class _SavingsDetailPageState extends ConsumerState<SavingsDetailPage> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _showAddAmountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tambah Tabungan',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.add_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final raw = _addController.text;
                  final amount = double.tryParse(raw);
                  if (amount != null && amount > 0) {
                    await ref
                        .read(savingsProvider.notifier)
                        .addAmount(widget.savings.id, amount);
                    _addController.clear();
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Tambahkan',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsProvider);
    final savings = savingsState.savings.firstWhere(
      (s) => s.id == widget.savings.id,
      orElse: () => widget.savings,
    );
    final theme = Theme.of(context);
    final color =
        savings.isCompleted ? AppColors.success : AppColors.info;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tabungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Target'),
                  content: const Text(
                      'Yakin ingin menghapus target tabungan ini?'),
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
              );
              if (confirm == true && context.mounted) {
                await ref
                    .read(savingsProvider.notifier)
                    .deleteSavings(savings.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main card
            GradientCard(
              colors: savings.isCompleted
                  ? [AppColors.success, AppColors.success.withGreen(180)]
                  : AppColors.savingsGradient,
              child: Column(
                children: [
                  Text(savings.icon ?? '🎯',
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(savings.goalName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  if (savings.isCompleted)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('🎉 Target Tercapai!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 24),
                  CircularPercentIndicator(
                    radius: 70,
                    lineWidth: 10,
                    percent: savings.percentage,
                    center: Text(
                      '${(savings.percentage * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    progressColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Terkumpul',
                        value: CurrencyFormatter.formatCompact(
                            savings.currentAmount),
                      ),
                      _StatItem(
                        label: 'Target',
                        value: CurrencyFormatter.formatCompact(
                            savings.targetAmount),
                      ),
                      _StatItem(
                        label: 'Sisa',
                        value: CurrencyFormatter.formatCompact(
                            savings.remaining.clamp(0, double.infinity)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Info cards
            if (savings.deadline != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deadline',
                              style: theme.textTheme.bodySmall),
                          Text(
                            DateFormatter.formatFull(savings.deadline!),
                            style: theme.textTheme.titleMedium,
                          ),
                          if (savings.daysRemaining != null)
                            Text(
                              savings.daysRemaining! > 0
                                  ? '${savings.daysRemaining} hari lagi'
                                  : 'Sudah lewat deadline!',
                              style: TextStyle(
                                fontSize: 12,
                                color: savings.daysRemaining! > 0
                                    ? AppColors.info
                                    : AppColors.danger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (savings.dailySavingsNeeded != null &&
                        !savings.isCompleted)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Perlu/hari',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint)),
                          Text(
                            CurrencyFormatter.formatCompact(
                                savings.dailySavingsNeeded!),
                            style: const TextStyle(
                                color: AppColors.info,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (!savings.isCompleted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddAmountSheet,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('Tambah Tabungan',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }
}
