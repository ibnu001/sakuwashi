import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/data/category_model.dart';
import '../../categories/presentation/manage_categories_sheet.dart';
import '../../categories/providers/category_provider.dart';
import '../data/transaction_db.dart';
import '../data/transaction_model.dart';
import '../providers/transaction_provider.dart';

/// Modal bottom sheet for viewing, creating, or editing a transaction.
/// When [editTransaction] is provided, it opens in View/Detail mode by default.
/// Tapping the Edit button switches into Edit mode.
class TransactionFormSheet extends ConsumerStatefulWidget {
  /// If provided, this transaction will be opened in View mode first.
  final TransactionModel? editTransaction;

  /// Default type when creating a new transaction.
  final String defaultType;

  /// Whether to start directly in edit mode if editTransaction is provided.
  final bool initialEditMode;

  const TransactionFormSheet({
    super.key,
    this.editTransaction,
    this.defaultType = 'expense',
    this.initialEditMode = false,
  });

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late bool _isViewing;
  late bool _isEditing;
  late String _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;
    _isEditing = edit != null;
    _isViewing = _isEditing && !widget.initialEditMode;

    _type = edit?.type ?? widget.defaultType;
    _amountCtrl = TextEditingController(
      text: edit != null ? edit.amount.toString() : '',
    );
    _noteCtrl = TextEditingController(text: edit?.note ?? '');
    _category = edit?.category ?? '';
    _date = edit?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _resetFieldsToOriginal() {
    final edit = widget.editTransaction;
    if (edit == null) return;
    _type = edit.type;
    _amountCtrl.text = edit.amount.toString();
    _noteCtrl.text = edit.note;
    _category = edit.category;
    _date = edit.date;
  }

  Future<void> _pickDate() async {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final typeColor = _type == 'expense'
        ? appColors.expenseColor
        : appColors.incomeColor;

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: typeColor,
              headerForegroundColor: Colors.white,
            ),
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: typeColor, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = int.tryParse(
      _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid')),
      );
      return;
    }

    final txn = TransactionModel(
      id: widget.editTransaction?.id,
      type: _type,
      amount: amount,
      category: _category,
      note: _noteCtrl.text.trim(),
      date: _date,
    );

    if (_isEditing) {
      await TransactionDb.update(txn);
    } else {
      await TransactionDb.insert(txn);
    }

    if (!mounted) return;
    await refreshAllTransactions(ref);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.editTransaction?.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(
                ctx,
              ).extension<AppColorsExtension>()!.expenseColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await TransactionDb.delete(widget.editTransaction!.id!);
      if (!mounted) return;
      await refreshAllTransactions(ref);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final typeColor = _type == 'expense'
        ? appColors.expenseColor
        : appColors.incomeColor;
    final containerColor = _type == 'expense'
        ? appColors.expenseContainer
        : appColors.incomeContainer;

    final categoriesAsync = _type == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    if (categories.isNotEmpty && !categories.any((c) => c.name == _category)) {
      _category = categories.first.name;
    }

    return PopScope(
      canPop:
          _isViewing ||
          (!_isEditing && _amountCtrl.text.isEmpty && _noteCtrl.text.isEmpty),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If currently editing an existing transaction, revert back to View mode
        if (_isEditing && !_isViewing) {
          setState(() {
            _isViewing = true;
            _resetFieldsToOriginal();
          });
          return;
        }

        // If creating a new transaction and user has input
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Batalkan Transaksi?'),
            content: const Text(
              'Data transaksi yang belum disimpan akan hilang.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Lanjut'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle bar ──────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Top Bar / Header ────────────────────────
              _buildHeader(appColors, typeColor),
              const SizedBox(height: 16),

              // ── Mode Switch: View vs Edit ────────────────
              if (_isViewing)
                _buildViewContent(appColors, typeColor, containerColor)
              else
                _buildEditContent(appColors, typeColor, categories),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension appColors, Color typeColor) {
    if (_isViewing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Edit button
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Edit Transaksi',
            onPressed: () => setState(() => _isViewing = false),
          ),
          Text(
            'Detail Transaksi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.delete_outline, color: appColors.expenseColor),
                tooltip: 'Hapus Transaksi',
                onPressed: _delete,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      );
    }

    // In Edit or Create mode
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_isEditing)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali ke Detail',
            onPressed: () {
              setState(() {
                _isViewing = true;
                _resetFieldsToOriginal();
              });
            },
          )
        else
          const SizedBox(width: 40),
        Text(
          _isEditing ? 'Edit Transaksi' : 'Catat Transaksi',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEditing)
              IconButton(
                icon: Icon(Icons.delete_outline, color: appColors.expenseColor),
                tooltip: 'Hapus Transaksi',
                onPressed: _delete,
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 22),
              tooltip: 'Tutup',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }

  // ── VIEW / DETAIL MODE (Read-only, no keyboard pop-up) ─────
  Widget _buildViewContent(
    AppColorsExtension appColors,
    Color typeColor,
    Color containerColor,
  ) {
    final iconMap = ref.watch(categoryIconMapProvider);
    final icon = iconMap[_category] ?? TransactionModel.iconFor(_category);
    final amountVal =
        int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: typeColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category & Type tag
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: typeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _category,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _type == 'expense' ? 'Pengeluaran' : 'Pemasukan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Formatted Nominal
              Text(
                'Nominal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(amountVal),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: typeColor,
                ),
              ),
              const SizedBox(height: 12),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Note Section (if present)
        if (_noteCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Catatan',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: SelectableText(
              _noteCtrl.text.trim(),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Edit button
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isViewing = false),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text(
              'Edit Transaksi Ini',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ── EDIT / CREATE MODE (Editable fields) ───────────────────
  Widget _buildEditContent(
    AppColorsExtension appColors,
    Color typeColor,
    List<CategoryModel> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Type Toggle ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: _TypeButton(
                label: 'Pengeluaran',
                isActive: _type == 'expense',
                color: appColors.expenseColor,
                onTap: () => setState(() {
                  _type = 'expense';
                  final cats =
                      ref.read(expenseCategoriesProvider).valueOrNull ?? [];
                  if (cats.isNotEmpty) _category = cats.first.name;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeButton(
                label: 'Pemasukan',
                isActive: _type == 'income',
                color: appColors.incomeColor,
                onTap: () => setState(() {
                  _type = 'income';
                  final cats =
                      ref.read(incomeCategoriesProvider).valueOrNull ?? [];
                  if (cats.isNotEmpty) _category = cats.first.name;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Nominal Field ───────────────────────────
        Text('Nominal', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: _amountCtrl,
          autofocus: false,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _IDRInputFormatter(),
          ],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: typeColor,
          ),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: typeColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: typeColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Kategori ────────────────────────────────
        Text('Kategori', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...categories.map((c) {
              final isActive = c.name == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = c.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? typeColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? typeColor
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.icon,
                        size: 15,
                        color: isActive
                            ? typeColor
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? typeColor
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // ── "+ Kelola" Chip ─────────────────────────
            GestureDetector(
              onTap: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ManageCategoriesSheet(initialType: _type),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      '+ Kelola',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Catatan (Input Biasa, Enter = New Line) ──
        Text(
          'Catatan (opsional)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _noteCtrl,
          autofocus: false,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: typeColor, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),

        // ── Tanggal ─────────────────────────────────
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Save Button ─────────────────────────────
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              _isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive
                ? color
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Formats numeric input as IDR thousands separator while typing.
class _IDRInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final number = int.parse(digits);
    final formatted = NumberFormat('#,###', 'id_ID').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
