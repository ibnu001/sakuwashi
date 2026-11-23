import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../transactions/data/transaction_db.dart';
import '../data/category_model.dart';
import '../providers/category_provider.dart';
import 'category_form_dialog.dart';

/// Modal bottom sheet to manage (view, add, edit, delete) categories.
class ManageCategoriesSheet extends ConsumerStatefulWidget {
  final String initialType;

  const ManageCategoriesSheet({
    super.key,
    this.initialType = 'expense',
  });

  @override
  ConsumerState<ManageCategoriesSheet> createState() =>
      _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends ConsumerState<ManageCategoriesSheet> {
  late String _activeType;

  @override
  void initState() {
    super.initState();
    _activeType = widget.initialType;
  }

  Future<void> _openFormDialog([CategoryModel? category]) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => CategoryFormDialog(
        category: category,
        defaultType: _activeType,
      ),
    );
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final count = await TransactionDb.countTransactionsByCategory(
        category.name, category.type);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori?'),
        content: Text(
          count > 0
              ? 'Kategori "${category.name}" digunakan oleh $count transaksi.\n\nMenghapus kategori ini akan memindahkan semua transaksi tersebut ke kategori "Lainnya". Lanjutkan?'
              : 'Yakin ingin menghapus kategori "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(ctx).extension<AppColorsExtension>()!.expenseColor,
            ),
            child: Text(count > 0 ? 'Hapus & Pindahkan' : 'Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final actions = CategoryActions(ref);
      await actions.deleteCategory(category);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? 'Kategori dihapus. $count transaksi dipindahkan ke Lainnya.'
                  : 'Kategori "${category.name}" dihapus.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final activeColor = _activeType == 'expense'
        ? appColors.expenseColor
        : appColors.incomeColor;
    final containerColor = _activeType == 'expense'
        ? appColors.expenseContainer
        : appColors.incomeContainer;

    final categoriesAsync = _activeType == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle Bar ─────────────────────────────────────
          const SizedBox(height: 12),
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

          // ── Header Title & Close ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kelola Kategori',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Segmented Type Toggle ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _TypeTab(
                    label: 'Pengeluaran',
                    isActive: _activeType == 'expense',
                    color: appColors.expenseColor,
                    onTap: () => setState(() => _activeType = 'expense'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeTab(
                    label: 'Pemasukan',
                    isActive: _activeType == 'income',
                    color: appColors.incomeColor,
                    onTap: () => setState(() => _activeType = 'income'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Add Category Button ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _openFormDialog(),
                icon: Icon(Icons.add, size: 18, color: activeColor),
                label: Text(
                  'Tambah Kategori $_activeLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: activeColor.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Category List ──────────────────────────────────
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Belum ada kategori',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final cat = list[i];
                    final isFallback = cat.name == 'Lainnya';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                          // Leading Icon
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: containerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              cat.icon,
                              size: 20,
                              color: activeColor,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name & Badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                if (cat.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isFallback ? 'Fallback' : 'Bawaan',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Actions
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit Kategori',
                            onPressed: () => _openFormDialog(cat),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (!cat.isDefault)
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: appColors.expenseColor),
                              tooltip: 'Hapus Kategori',
                              onPressed: () => _confirmDelete(cat),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String get _activeLabel =>
      _activeType == 'expense' ? 'Pengeluaran' : 'Pemasukan';
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
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
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
            fontSize: 13,
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
