import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../savings/pages/savings_page.dart';
import '../../reports/pages/reports_page.dart';
import '../../../routes/app_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.profile),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Pengguna',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white70),
                  ],
                ),
              ),
            ),

            // Uang saku
            _SectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.primary,
                  title: 'Atur Uang Saku Bulanan',
                  subtitle: (user?.monthlyAllowance ?? 0) > 0
                      ? 'Rp ${user!.monthlyAllowance.toStringAsFixed(0)}'
                      : 'Belum diatur',
                  onTap: () => _showAllowanceSheet(
                      context, ref, user?.monthlyAllowance ?? 0),
                ),
              ],
            ),

            // Fitur
            _SectionCard(
              title: 'Fitur',
              children: [
                _SettingsTile(
                  icon: Icons.savings_rounded,
                  iconColor: AppColors.info,
                  title: 'Tabungan',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SavingsPage())),
                ),
                _SettingsTile(
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.warning,
                  title: 'Rekap & Laporan',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ReportsPage())),
                ),
              ],
            ),

            // Tampilan
            _SectionCard(
              title: 'Tampilan',
              children: [
                _SettingsTileSwitch(
                  icon: Icons.dark_mode_rounded,
                  iconColor: Colors.indigo,
                  title: 'Mode Gelap',
                  subtitle: 'Ubah tampilan aplikasi',
                  value: settings.isDarkMode,
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).toggleDarkMode(),
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.info,
                  title: 'Bahasa',
                  subtitle: settings.language == 'id'
                      ? '🇮🇩 Bahasa Indonesia'
                      : '🇬🇧 English',
                  onTap: () =>
                      _showLanguageSheet(context, ref, settings.language),
                ),
              ],
            ),

            // Notifikasi
            _SectionCard(
              title: 'Notifikasi',
              children: [
                _SettingsTileSwitch(
                  icon: Icons.notifications_rounded,
                  iconColor: AppColors.warning,
                  title: 'Notifikasi',
                  subtitle: 'Budget, hutang, dan tabungan',
                  value: settings.notificationsEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setNotifications(v),
                ),
              ],
            ),

            // Akun
            _SectionCard(
              title: 'Akun',
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.primary,
                  title: 'Edit Profil',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.profile),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'Ubah Password',
                  onTap: () => _showChangePasswordSheet(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.danger,
                  title: 'Keluar',
                  titleColor: AppColors.danger,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'FinTrack v1.0.0\nKelola keuangan mahasiswa dengan cerdas',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAllowanceSheet(
      BuildContext context, WidgetRef ref, double current) {
    final controller = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur Uang Saku Bulanan',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Masukkan total uang saku per bulan untuk menghitung budget harian otomatis.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Total Uang Saku Bulanan',
                prefixText: 'Rp ',
                prefixIcon:
                    Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text
                      .replaceAll(RegExp(r'[^0-9]'), ''));
                  if (amount != null) {
                    final updatedUser = ref
                        .read(currentUserProvider)!
                        .copyWith(monthlyAllowance: amount);
                    await ref
                        .read(authProvider.notifier)
                        .updateUser(updatedUser);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Simpan',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(
      BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Bahasa',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            _LangOption(
              flag: '🇮🇩',
              label: 'Bahasa Indonesia',
              isSelected: current == 'id',
              onTap: () {
                ref.read(settingsProvider.notifier).setLanguage('id');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _LangOption(
              flag: '🇬🇧',
              label: 'English',
              isSelected: current == 'en',
              onTap: () {
                ref.read(settingsProvider.notifier).setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubah Password',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password Lama',
                  prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (newCtrl.text != confirmCtrl.text) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Password tidak cocok')));
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password berhasil diubah'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: const Text('Ubah Password',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SectionCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ),
          // ✅ Material wrapper agar ListTile ink splash terlihat
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.04),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: children.asMap().entries.map((e) {
                  return Column(
                    children: [
                      e.value,
                      if (e.key < children.length - 1)
                        const Divider(height: 1, indent: 56, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 20)
          : null,
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ─── Settings Tile Switch ─────────────────────────────────────────────────────
class _SettingsTileSwitch extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _SettingsTileSwitch({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ─── Language Option ──────────────────────────────────────────────────────────
class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}