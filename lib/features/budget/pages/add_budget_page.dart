import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../budget/providers/budget_provider.dart';

class AddBudgetPage extends ConsumerStatefulWidget {
  const AddBudgetPage({super.key});

  @override
  ConsumerState<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends ConsumerState<AddBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedCategory = AppConstants.expenseCategories.first;
  String _period = AppConstants.periodMonthly;
  DateTime _startDate = DateTime.now();
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

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

    await ref.read(budgetProvider.notifier).addBudget(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          target: target,
          period: _period,
          startDate: _startDate,
          endDate: _endDate,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget berhasil ditambahkan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Budget')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                validator: Validators.validateBudgetName,
                decoration: const InputDecoration(
                  labelText: 'Nama Budget',
                  hintText: 'Contoh: Budget Makan',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              // Target amount
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.validateAmount,
                decoration: const InputDecoration(
                  labelText: 'Target Budget',
                  hintText: '500000',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 20),
              Text('Kategori', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.expenseCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return CategoryChip(
                    label: cat,
                    emoji: AppConstants.categoryIcons[cat],
                    isSelected: isSelected,
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Periode', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  _PeriodChip(
                    label: 'Harian',
                    value: AppConstants.periodDaily,
                    selected: _period,
                    onTap: (v) => setState(() => _period = v),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Mingguan',
                    value: AppConstants.periodWeekly,
                    selected: _period,
                    onTap: (v) => setState(() => _period = v),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Bulanan',
                    value: AppConstants.periodMonthly,
                    selected: _period,
                    onTap: (v) => setState(() => _period = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DateSelector(
                      label: 'Mulai',
                      date: _startDate,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _startDate = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateSelector(
                      label: 'Selesai',
                      date: _endDate,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _endDate = d);
                      },
                    ),
                  ),
                ],
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
                      : const Text('Simpan Budget',
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

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatShort(date),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
