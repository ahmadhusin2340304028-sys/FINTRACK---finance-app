import 'package:fintrack/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../debt/providers/debt_provider.dart';

class AddDebtPage extends ConsumerStatefulWidget {
  final String? initialType;

  const AddDebtPage({super.key, this.initialType});

  @override
  ConsumerState<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends ConsumerState<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _type;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? AppConstants.debtTypeOwed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final raw =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.parse(raw);

    await ref.read(debtProvider.notifier).addDebt(
          type: _type,
          personName: _nameController.text.trim(),
          amount: amount,
          dueDate: _dueDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil ditambahkan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwed = _type == AppConstants.debtTypeOwed;
    final color = isOwed ? AppColors.danger : AppColors.success;
    final label = isOwed ? 'Hutang' : 'Piutang';

    return Scaffold(
      appBar: AppBar(title: Text('Tambah $label')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    _TypeToggle(
                      label: '😰 Hutang Saya',
                      isSelected: isOwed,
                      color: AppColors.danger,
                      onTap: () => setState(
                          () => _type = AppConstants.debtTypeOwed),
                    ),
                    _TypeToggle(
                      label: '💰 Piutang Saya',
                      isSelected: !isOwed,
                      color: AppColors.success,
                      onTap: () => setState(
                          () => _type = AppConstants.debtTypeReceivable),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Helper text
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isOwed
                            ? 'Hutang: uang yang kamu pinjam dari orang lain'
                            : 'Piutang: uang yang orang lain pinjam dari kamu',
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: Validators.validatePersonName,
                decoration: InputDecoration(
                  labelText: isOwed ? 'Nama Pemberi Pinjaman' : 'Nama Peminjam',
                  hintText: 'Nama orang',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.validateAmount,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  hintText: '100000',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 16),
              // Due date
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _dueDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _dueDate != null
                          ? color
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20,
                          color: _dueDate != null
                              ? color
                              : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? 'Jatuh tempo: ${DateFormatter.formatFull(_dueDate!)}'
                              : 'Jatuh tempo (opsional)',
                          style: TextStyle(
                            color: _dueDate != null
                                ? theme.textTheme.bodyLarge?.color
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _dueDate = null),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textHint),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Tambahkan keterangan...',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding:
                          const EdgeInsets.symmetric(vertical: 18)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Simpan $label',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.white : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}
