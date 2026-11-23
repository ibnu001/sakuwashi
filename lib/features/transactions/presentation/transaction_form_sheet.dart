import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../categories/presentation/manage_categories_sheet.dart';
import '../../categories/providers/category_provider.dart';
import '../data/transaction_db.dart';
import '../data/transaction_model.dart';
import '../providers/transaction_provider.dart';

/// Modal bottom sheet for creating or editing a transaction.
class TransactionFormSheet extends ConsumerStatefulWidget {
  /// If provided, the form is in edit mode.
  final TransactionModel? editTransaction;

  /// Default type when creating a new transaction.
  final String defaultType;

  const TransactionFormSheet({
    super.key,
    this.editTransaction,
    this.defaultType = 'expense',
  });

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late String _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late String _category;
  late DateTime _date;
  bool _isEditing = false;
  double _noteHeight = 110.0;

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;
    _isEditing = edit != null;
    _type = edit?.type ?? widget.defaultType;
    _amountCtrl = TextEditingController(
      text: edit != null ? edit.amount.toString() : '',
    );
    _noteCtrl = TextEditingController(text: edit?.note ?? '');
    _category = edit?.category ?? '';
    _date = edit?.date ?? DateTime.now();

    if (edit != null && edit.note.contains('\n')) {
      final lineCount = edit.note.split('\n').length;
      _noteHeight = (lineCount * 22.0 + 50.0).clamp(110.0, 260.0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _insertBullet() {
    final text = _noteCtrl.text;
    final selection = _noteCtrl.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    String prefix = '';
    if (start > 0 && !text.substring(0, start).endsWith('\n')) {
      prefix = '\n';
    }
    const bullet = '• ';
    final newText = text.replaceRange(start, end, '$prefix$bullet');
    setState(() {
      _noteCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: start + prefix.length + bullet.length),
      );
    });
  }

  void _insertText(String snippet) {
    final text = _noteCtrl.text;
    final selection = _noteCtrl.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    String prefix = '';
    if (start > 0 && !text.substring(0, start).endsWith('\n')) {
      prefix = '\n';
    }
    final newText = text.replaceRange(start, end, '$prefix$snippet');
    setState(() {
      _noteCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: start + prefix.length + snippet.length),
      );
    });
  }


  Future<void> _pickDate() async {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final typeColor =
        _type == 'expense' ? appColors.expenseColor : appColors.incomeColor;

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
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: typeColor,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount =
        int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
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
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
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
    final typeColor =
        _type == 'expense' ? appColors.expenseColor : appColors.incomeColor;
    final categoriesAsync = _type == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    // Ensure selected category is valid for current type
    if (categories.isNotEmpty &&
        !categories.any((c) => c.name == _category)) {
      _category = categories.first.name;
    }

    return Container(
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
            const SizedBox(height: 16),

            // ── Title + Delete ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Transaksi' : 'Catat Transaksi',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: appColors.expenseColor),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),

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

            // ── Amount ──────────────────────────────────
            Text('Nominal', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
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

            // ── Category ────────────────────────────────
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
                          horizontal: 12, vertical: 7),
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
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive
                                  ? typeColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                      builder: (_) =>
                          ManageCategoriesSheet(initialType: _type),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
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

            // ── Note / Resizable Itemized Breakdown ────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Catatan / Rincian Belanja',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(width: 6),
                    Text(
                      '(opsional)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _noteHeight = _noteHeight > 160.0 ? 110.0 : 240.0;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _noteHeight > 160.0
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          size: 16,
                          color: typeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _noteHeight > 160.0 ? 'Kecilkan' : 'Perbesar',
                          style: TextStyle(
                            fontSize: 11,
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
            const SizedBox(height: 6),

            // Quick formatting chips for easy item list logging
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NoteQuickActionChip(
                    icon: Icons.format_list_bulleted_rounded,
                    label: '+ Item List',
                    onTap: _insertBullet,
                    color: typeColor,
                  ),
                  const SizedBox(width: 6),
                  _NoteQuickActionChip(
                    icon: Icons.receipt_long_outlined,
                    label: '+ No. Struk',
                    onTap: () => _insertText('No. Struk: '),
                    color: typeColor,
                  ),
                  const SizedBox(width: 6),
                  _NoteQuickActionChip(
                    icon: Icons.sell_outlined,
                    label: '+ Diskon',
                    onTap: () => _insertText('Diskon: Rp '),
                    color: typeColor,
                  ),
                  if (_noteCtrl.text.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _NoteQuickActionChip(
                      icon: Icons.clear_rounded,
                      label: 'Hapus Teks',
                      onTap: () => setState(() => _noteCtrl.clear()),
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Resizable container with interactive bottom drag handle
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: _noteHeight,
                    child: TextField(
                      controller: _noteCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Tulis catatan atau rincian belanja…\nContoh:\n• Beras 5kg: Rp 75.000\n• Minyak 2L: Rp 34.000\n• Telur 1kg: Rp 28.000',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.55),
                          height: 1.4,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                  // Bottom drag handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _noteHeight =
                            (_noteHeight + details.delta.dy).clamp(80.0, 320.0);
                      });
                    },
                    onDoubleTap: () {
                      setState(() {
                        _noteHeight = _noteHeight > 160.0 ? 110.0 : 240.0;
                      });
                    },
                    child: Container(
                      height: 22,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Date ────────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
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
          color:
              isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
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
      TextEditingValue oldValue, TextEditingValue newValue) {
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

class _NoteQuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _NoteQuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
