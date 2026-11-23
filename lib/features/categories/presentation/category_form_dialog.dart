import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../data/category_icons.dart';
import '../data/category_model.dart';
import '../providers/category_provider.dart';

/// Modal dialog / sheet to create or edit a category.
class CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? category;
  final String defaultType;

  const CategoryFormDialog({
    super.key,
    this.category,
    required this.defaultType,
  });

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  late TextEditingController _nameCtrl;
  late String _type;
  late String _selectedIconKey;
  bool _isEditing = false;
  bool _isFallback = false;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _isEditing = cat != null;
    _isFallback = cat?.name == 'Lainnya';
    _type = cat?.type ?? widget.defaultType;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _selectedIconKey = cat?.iconKey ??
        (_type == 'expense' ? 'restaurant' : 'account_balance_wallet');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
      );
      return;
    }

    final actions = CategoryActions(ref);
    if (_isEditing) {
      final updated = widget.category!.copyWith(
        name: _isFallback ? 'Lainnya' : name,
        iconKey: _selectedIconKey,
      );
      await actions.updateCategory(updated, oldName: widget.category!.name);
    } else {
      // Check for duplicate name
      final currentList = _type == 'expense'
          ? ref.read(expenseCategoriesProvider).valueOrNull ?? []
          : ref.read(incomeCategoriesProvider).valueOrNull ?? [];

      if (currentList.any(
          (c) => c.name.toLowerCase() == name.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama kategori sudah digunakan')),
        );
        return;
      }

      final newCat = CategoryModel(
        name: name,
        type: _type,
        iconKey: _selectedIconKey,
        isDefault: false,
        sortOrder: currentList.length,
      );
      await actions.addCategory(newCat);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final typeColor =
        _type == 'expense' ? appColors.expenseColor : appColors.incomeColor;

    final icons = CategoryIcons.iconMap.entries.toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog Title ─────────────────────────────────
            Text(
              _isEditing ? 'Edit Kategori' : 'Tambah Kategori',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // ── Name Field ───────────────────────────────────
            Text('Nama Kategori',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              enabled: !_isFallback,
              decoration: InputDecoration(
                hintText: 'Contoh: Belanja Online, Kopi...',
                helperText: _isFallback
                    ? 'Nama kategori fallback sistem tidak dapat diubah'
                    : null,
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

            // ── Icon Selector Grid ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pilih Ikon',
                    style: Theme.of(context).textTheme.labelMedium),
                Row(
                  children: [
                    const Text('Pratinjau: ', style: TextStyle(fontSize: 12)),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CategoryIcons.getIcon(_selectedIconKey),
                        size: 16,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: icons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (ctx, idx) {
                    final entry = icons[idx];
                    final isSelected = entry.key == _selectedIconKey;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconKey = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? typeColor.withValues(alpha: 0.18)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? typeColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          size: 22,
                          color: isSelected
                              ? typeColor
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Action Buttons ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
