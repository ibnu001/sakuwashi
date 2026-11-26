import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_color_defaults.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/currency_formatter.dart';
import '../backup/backup_provider.dart';
import '../backup/csv_service.dart';
import '../backup/google_drive_service.dart';
import '../categories/presentation/manage_categories_sheet.dart';
import '../categories/providers/category_provider.dart';
import '../transactions/providers/transaction_provider.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    // ignore: unused_local_variable
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

          // ── Siklus Gajian ────────────────────────────
          const _SectionHeader(title: 'Siklus Periode'),
          _PaydayCycleToggle(),
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

          // ── Kelola Data (CSV) ──────────────────────────
          const _SectionHeader(title: 'Kelola Data (CSV)'),
          _buildSettingsTile(
            context: context,
            icon: Icons.file_upload_outlined,
            title: 'Impor CSV',
            subtitle: 'Masukkan transaksi dari file CSV (Gabung / Timpa)',
            onTap: () => _importCSV(context, ref),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.download_outlined,
            title: 'Unduh CSV',
            subtitle: 'Simpan transaksi ke file CSV (per bulan/tahun/semua)',
            onTap: () => _showExportScopeSheet(context, ref, download: true),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.share_outlined,
            title: 'Bagikan CSV',
            subtitle: 'Bagikan file CSV ke aplikasi lain',
            onTap: () => _showExportScopeSheet(context, ref, download: false),
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

  Future<void> _importCSV(BuildContext context, WidgetRef ref) async {
    try {
      final csvString = await CsvService.pickCSVFile();
      if (!context.mounted || csvString == null) return;

      final result = CsvService.parseCSV(csvString);

      if (result.transactions.isEmpty) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Format Tidak Sesuai'),
            content: const Text(
              'Tidak ditemukan data transaksi yang valid dalam file CSV tersebut.\n\n'
              'Pastikan file CSV memiliki kolom tanggal, tipe (pengeluaran/pemasukan), '
              'kategori, dan nominal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        return;
      }

      final shouldReplace = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CsvImportConfirmSheet(result: result),
      );

      if (shouldReplace == null || !context.mounted) return;

      final count = await CsvService.executeImport(
        transactions: result.transactions,
        replace: shouldReplace,
      );

      await refreshAllTransactions(ref);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.read(backupRefreshProvider.notifier).state++;

      if (!context.mounted) return;
      final modeStr = shouldReplace ? 'ditimpa' : 'ditambahkan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil mengimpor $count transaksi ($modeStr)!'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengimpor: $e')));
    }
  }

  Future<void> _showExportScopeSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool download,
  }) async {
    final selection = await showModalBottomSheet<_ExportScopeResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportScopeSheet(download: download),
    );

    if (selection == null || !context.mounted) return;

    try {
      final count = await CsvService.countForScope(
        scope: selection.scope,
        year: selection.year,
        month: selection.month,
      );

      if (!context.mounted) return;
      if (count == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada transaksi untuk diekspor pada periode tersebut'),
          ),
        );
        return;
      }

      if (download) {
        final path = await CsvService.exportWithSystemFilePicker(
          scope: selection.scope,
          year: selection.year,
          month: selection.month,
        );
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
        await CsvService.shareCSV(
          scope: selection.scope,
          year: selection.year,
          month: selection.month,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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

class _CsvImportConfirmSheet extends StatefulWidget {
  final CsvImportResult result;

  const _CsvImportConfirmSheet({required this.result});

  @override
  State<_CsvImportConfirmSheet> createState() => _CsvImportConfirmSheetState();
}

class _CsvImportConfirmSheetState extends State<_CsvImportConfirmSheet> {
  bool _replace = false;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.file_upload_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impor Transaksi CSV',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Ditemukan ${widget.result.transactions.length} transaksi dalam file',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: appColors.expenseColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pengeluaran (${widget.result.expenseCount})',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(
                        widget.result.totalExpenseAmount,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: appColors.expenseColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: appColors.incomeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pemasukan (${widget.result.incomeCount})',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(widget.result.totalIncomeAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: appColors.incomeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Import Mode Selector
          Text(
            'Metode Impor',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          _buildModeOption(
            theme: theme,
            title: 'Gabungkan Data',
            description:
                'Menambahkan transaksi ke data yang sudah ada tanpa menghapus.',
            selected: !_replace,
            onTap: () => setState(() => _replace = false),
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            theme: theme,
            title: 'Timpa Semua Data',
            description:
                'Hapus semua transaksi saat ini dan ganti dengan data CSV ini.',
            selected: _replace,
            isDestructive: true,
            onTap: () => setState(() => _replace = true),
          ),
          const SizedBox(height: 22),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _replace),
                  style: FilledButton.styleFrom(
                    backgroundColor: _replace
                        ? appColors.expenseColor
                        : theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_replace ? 'Timpa & Impor' : 'Impor Sekarang'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required ThemeData theme,
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final borderColor = selected
        ? (isDestructive ? theme.colorScheme.error : theme.colorScheme.primary)
        : theme.colorScheme.outlineVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? (isDestructive
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.3))
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? (isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary)
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive && selected
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payday Cycle Toggle ─────────────────────────────────────
class _PaydayCycleToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.useDynamicPaydayCycle),
    );
    final theme = Theme.of(context);

    Future<void> toggle(bool value) async {
      await ref
          .read(settingsControllerProvider.notifier)
          .setUseDynamicPaydayCycle(value);
      ref.read(selectedPaydayCycleStartProvider.notifier).state = null;
      await refreshAllTransactions(ref);
    }

    return GestureDetector(
      onTap: () => toggle(!enabled),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_repeat_outlined,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siklus Otomatis Setelah Gajian',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aktifkan untuk menghitung periode baru setiap kali ada pemasukan kategori Gaji (default: kalender tanggal 1–31)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: enabled,
              onChanged: toggle,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scoped CSV Export Sheet ─────────────────────────────────
class _ExportScopeResult {
  final CsvExportScope scope;
  final int? year;
  final int? month;

  const _ExportScopeResult({
    required this.scope,
    this.year,
    this.month,
  });
}

class _ExportScopeSheet extends StatefulWidget {
  final bool download;

  const _ExportScopeSheet({required this.download});

  @override
  State<_ExportScopeSheet> createState() => _ExportScopeSheetState();
}

class _ExportScopeSheetState extends State<_ExportScopeSheet> {
  CsvExportScope _scope = CsvExportScope.monthly;
  late int _year;
  late int _month;
  int? _previewCount;
  bool _loadingCount = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    setState(() => _loadingCount = true);
    final count = await CsvService.countForScope(
      scope: _scope,
      year: _year,
      month: _month,
    );
    if (!mounted) return;
    setState(() {
      _previewCount = count;
      _loadingCount = false;
    });
  }

  void _selectScope(CsvExportScope scope) {
    setState(() => _scope = scope);
    _refreshCount();
  }

  void _changeYear(int year) {
    setState(() => _year = year);
    _refreshCount();
  }

  void _changeMonth(int month) {
    setState(() => _month = month);
    _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = List.generate(
      12,
      (i) => DateFormat('MMM', 'id_ID').format(DateTime(2024, i + 1)),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.download
                          ? Icons.download_outlined
                          : Icons.share_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.download ? 'Unduh CSV' : 'Bagikan CSV',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Pilih cakupan data yang ingin diekspor',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Option 1: Ekspor per Bulan
              _buildScopeOption(
                theme: theme,
                scope: CsvExportScope.monthly,
                title: 'Ekspor per Bulan',
                subtitle: DateFormat('MMMM yyyy', 'id_ID')
                    .format(DateTime(_year, _month)),
              ),
              if (_scope == CsvExportScope.monthly) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: () => _changeYear(_year - 1),
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            '$_year',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: () => _changeYear(_year + 1),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(12, (i) {
                          final m = i + 1;
                          final isSelected = m == _month;
                          return GestureDetector(
                            onTap: () => _changeMonth(m),
                            child: Container(
                              width:
                                  (MediaQuery.of(context).size.width - 66 - 18) /
                                      4,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                months[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Option 2: Ekspor per Tahun
              _buildScopeOption(
                theme: theme,
                scope: CsvExportScope.yearly,
                title: 'Ekspor per Tahun',
                subtitle: 'Semua transaksi di tahun $_year',
              ),
              if (_scope == CsvExportScope.yearly) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: () => _changeYear(_year - 1),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$_year',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: () => _changeYear(_year + 1),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Option 3: Ekspor Semua Data (Full Backup)
              _buildScopeOption(
                theme: theme,
                scope: CsvExportScope.all,
                title: 'Ekspor Semua Data (Full Backup)',
                subtitle: 'Seluruh riwayat transaksi untuk backup lengkap',
              ),
              const SizedBox(height: 16),

              // Preview count banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _loadingCount
                          ? Text(
                              'Menghitung transaksi…',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Text(
                              (_previewCount ?? 0) > 0
                                  ? '$_previewCount transaksi akan diekspor'
                                  : 'Tidak ada transaksi pada periode ini',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: (_previewCount ?? 0) > 0
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loadingCount
                          ? null
                          : () => Navigator.pop(
                                context,
                                _ExportScopeResult(
                                  scope: _scope,
                                  year: _scope == CsvExportScope.all
                                      ? null
                                      : _year,
                                  month: _scope == CsvExportScope.monthly
                                      ? _month
                                      : null,
                                ),
                              ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.download ? 'Simpan CSV' : 'Bagikan CSV',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeOption({
    required ThemeData theme,
    required CsvExportScope scope,
    required String title,
    required String subtitle,
  }) {
    final selected = _scope == scope;
    return GestureDetector(
      onTap: () => _selectScope(scope),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
