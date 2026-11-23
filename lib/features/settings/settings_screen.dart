import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_color_defaults.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/theme_controller.dart';
import '../backup/backup_provider.dart';
import '../backup/csv_service.dart';
import '../backup/google_drive_service.dart';
import '../categories/presentation/manage_categories_sheet.dart';
import '../transactions/providers/transaction_provider.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Text(
            'Pengaturan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // ── Tampilan Awal Aplikasi ──────────────────────
          const _SectionHeader(title: 'Tampilan Awal Aplikasi'),
          _StartupSelector(currentValue: themeState.startupScreen),
          const SizedBox(height: 20),

          // ── Tema ───────────────────────────────────────
          const _SectionHeader(title: 'Tema Aplikasi'),
          _ThemeModeSelector(currentMode: themeState.themeMode),
          const SizedBox(height: 20),

          // ── Kustomisasi Warna ──────────────────────────
          const _SectionHeader(title: 'Kustomisasi Warna'),
          _ColorCustomizer(themeState: themeState),
          const SizedBox(height: 20),

          // ── Kategori Transaksi ─────────────────────────
          const _SectionHeader(title: 'Kategori Transaksi'),
          _buildSettingsTile(
            context: context,
            icon: Icons.category_outlined,
            title: 'Kelola Kategori',
            subtitle: 'Tambah, ubah, dan atur kategori pengeluaran & pemasukan',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ManageCategoriesSheet(),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── CSV Export ─────────────────────────────────
          const _SectionHeader(title: 'Ekspor Data'),
          _buildSettingsTile(
            context: context,
            icon: Icons.download_outlined,
            title: 'Unduh CSV',
            subtitle: 'Simpan semua transaksi ke file CSV',
            onTap: () => _exportCSV(context, ref, download: true),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.share_outlined,
            title: 'Bagikan CSV',
            subtitle: 'Bagikan file CSV ke aplikasi lain',
            onTap: () => _exportCSV(context, ref, download: false),
          ),
          const SizedBox(height: 20),

          // ── Google Drive Hide ──────────────────────────
          // const _SectionHeader(title: 'Google Drive'),
          // if (settingsState.googleEmail != null)
          //   Padding(
          //     padding: const EdgeInsets.only(bottom: 8),
          //     child: Text(
          //       'Akun: ${settingsState.googleEmail}',
          //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //         color: Theme.of(context).colorScheme.onSurfaceVariant,
          //       ),
          //     ),
          //   ),
          // if (settingsState.lastBackupTime != null)
          //   Padding(
          //     padding: const EdgeInsets.only(bottom: 8),
          //     child: Text(
          //       'Backup terakhir: ${settingsState.lastBackupTime}',
          //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //         color: Theme.of(context).colorScheme.onSurfaceVariant,
          //       ),
          //     ),
          //   ),
          // _buildSettingsTile(
          //   context: context,
          //   icon: Icons.cloud_upload_outlined,
          //   title: 'Backup ke Google Drive',
          //   subtitle: 'Upload data ke folder Sakuwashi_Backup',
          //   trailing: settingsState.isBackingUp
          //       ? const SizedBox(
          //           width: 20,
          //           height: 20,
          //           child: CircularProgressIndicator(strokeWidth: 2),
          //         )
          //       : null,
          //   onTap: settingsState.isBackingUp
          //       ? null
          //       : () => _backupToDrive(context, ref),
          // ),
          // _buildSettingsTile(
          //   context: context,
          //   icon: Icons.cloud_download_outlined,
          //   title: 'Pulihkan dari Google Drive',
          //   subtitle: 'Pilih backup untuk dipulihkan',
          //   trailing: settingsState.isRestoring
          //       ? const SizedBox(
          //           width: 20,
          //           height: 20,
          //           child: CircularProgressIndicator(strokeWidth: 2),
          //         )
          //       : null,
          //   onTap: settingsState.isRestoring
          //       ? null
          //       : () => _restoreFromDrive(context, ref),
          // ),
          // if (settingsState.googleEmail != null)
          //   _buildSettingsTile(
          //     context: context,
          //     icon: Icons.logout_outlined,
          //     title: 'Logout Google',
          //     subtitle: 'Putuskan koneksi akun Google',
          //     onTap: () => _logoutGoogle(context, ref),
          //   ),
          // const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _exportCSV(
    BuildContext context,
    WidgetRef ref, {
    required bool download,
  }) async {
    try {
      if (download) {
        final path = await CsvService.exportWithSystemFilePicker();
        if (!context.mounted) return;
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File CSV berhasil disimpan ke:\n$path'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        await CsvService.shareCSV();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _backupToDrive(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(settingsControllerProvider.notifier);
    ctrl.setBackingUp(true);
    try {
      final service = GoogleDriveService();
      final account = await service.signIn();
      if (account == null) {
        ctrl.setBackingUp(false);
        return;
      }
      await ctrl.setGoogleEmail(account.email);

      final csvContent = await CsvService.generateCSVString();
      await service.backup(csvContent);

      final now = DateTime.now();
      await ctrl.setLastBackupTime(
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup berhasil!')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup gagal: $e')));
    } finally {
      ctrl.setBackingUp(false);
    }
  }

  Future<void> _restoreFromDrive(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(settingsControllerProvider.notifier);
    ctrl.setRestoring(true);
    try {
      final service = GoogleDriveService();
      final account = await service.signIn();
      if (account == null) {
        ctrl.setRestoring(false);
        return;
      }
      await ctrl.setGoogleEmail(account.email);

      final backups = await service.listBackups();
      if (backups.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada backup ditemukan')),
        );
        ctrl.setRestoring(false);
        return;
      }

      if (!context.mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pilih Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(backups[i]['name'] ?? ''),
                onTap: () => Navigator.pop(ctx, backups[i]['id']),
              ),
            ),
          ),
        ),
      );

      if (selected == null) {
        ctrl.setRestoring(false);
        return;
      }

      final csvContent = await service.downloadBackup(selected);
      final count = await CsvService.importFromCSVString(csvContent);

      // Refresh transaction lists
      ref.invalidate(backupRefreshProvider);
      await refreshAllTransactions(ref);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$count transaksi dipulihkan!')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pulihkan gagal: $e')));
    } finally {
      ctrl.setRestoring(false);
    }
  }

  Future<void> _logoutGoogle(BuildContext context, WidgetRef ref) async {
    final service = GoogleDriveService();
    await service.signOut();
    await ref.read(settingsControllerProvider.notifier).setGoogleEmail(null);
  }
}

// ── Section header widget ───────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Startup View Selector ───────────────────────────────────
class _StartupSelector extends ConsumerWidget {
  final int currentValue;
  const _StartupSelector({required this.currentValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      (0, 'Daftar Pengeluaran'),
      (1, 'Daftar Pemasukan'),
      (3, 'Ringkasan Keuangan'),
      (99, 'Langsung Form Catat Transaksi'),
    ];

    return Column(
      children: options.map((opt) {
        final isActive = currentValue == opt.$1;
        return GestureDetector(
          onTap: () => ref
              .read(themeControllerProvider.notifier)
              .setStartupScreen(opt.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  opt.$2,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Theme Mode Selector ─────────────────────────────────────
class _ThemeModeSelector extends ConsumerWidget {
  final ThemeMode currentMode;
  const _ThemeModeSelector({required this.currentMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      (ThemeMode.system, 'Ikuti Sistem', Icons.brightness_auto),
      (ThemeMode.light, 'Mode Terang', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Mode Gelap', Icons.dark_mode_outlined),
    ];

    return Row(
      children: options.map((opt) {
        final isActive = currentMode == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                ref.read(themeControllerProvider.notifier).setThemeMode(opt.$1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    opt.$3,
                    size: 22,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Color Customizer ────────────────────────────────────────
class _ColorCustomizer extends ConsumerWidget {
  final ThemeState themeState;
  const _ColorCustomizer({required this.themeState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      children: [
        _ColorRow(
          label: 'Warna Pengeluaran',
          currentColor: appColors.expenseColor,
          onColorChanged: (c) =>
              ref.read(themeControllerProvider.notifier).setExpenseColor(c),
        ),
        _ColorRow(
          label: 'Warna Pemasukan',
          currentColor: appColors.incomeColor,
          onColorChanged: (c) =>
              ref.read(themeControllerProvider.notifier).setIncomeColor(c),
        ),
        _ColorRow(
          label: 'Warna Aksen',
          currentColor: Theme.of(context).colorScheme.primary,
          onColorChanged: (c) =>
              ref.read(themeControllerProvider.notifier).setAccentColor(c),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                ref.read(themeControllerProvider.notifier).resetColors(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset ke Default'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  const _ColorRow({
    required this.label,
    required this.currentColor,
    required this.onColorChanged,
  });

  static const _swatches = [
    Color(0xFFE11D48), // Rose
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF059669), // Emerald
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._swatches.map(
                  (c) => _SwatchCircle(
                    color: c,
                    isActive: _colorsMatch(c, currentColor),
                    onTap: () => onColorChanged(c),
                  ),
                ),
                // Custom hex picker
                _SwatchCircle(
                  color: currentColor,
                  isCustom: true,
                  isActive: !_swatches.any(
                    (s) => _colorsMatch(s, currentColor),
                  ),
                  onTap: () => _showHexPicker(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    // ignore: deprecated_member_use
    return (a.value & 0x00FFFFFF) == (b.value & 0x00FFFFFF);
  }

  void _showHexPicker(BuildContext context) {
    final ctrl = TextEditingController(
      text: AppColorDefaults.hexFromColor(currentColor),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan Kode Warna'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '#E11D48'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              try {
                final color = AppColorDefaults.colorFromHex(ctrl.text);
                onColorChanged(color);
                Navigator.pop(ctx);
              } catch (_) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Kode warna tidak valid')),
                );
              }
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }
}

class _SwatchCircle extends StatelessWidget {
  final Color color;
  final bool isActive;
  final bool isCustom;
  final VoidCallback onTap;

  const _SwatchCircle({
    required this.color,
    required this.isActive,
    this.isCustom = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: isCustom
              ? const Icon(Icons.colorize, size: 16, color: Colors.white)
              : (isActive
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null),
        ),
      ),
    );
  }
}
