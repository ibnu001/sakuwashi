import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/providers/category_provider.dart';
import '../data/transaction_db.dart';
import '../data/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'period_switcher.dart';
import 'transaction_filter_sheet.dart';
import 'transaction_form_sheet.dart';

class ExpenseListView extends ConsumerWidget {
  const ExpenseListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(expenseListProvider);
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final dateFilter = ref.watch(dateFilterProvider);

    return SafeArea(
      child: Column(
        children: [
          // ── Period Switcher ─────────────────────────────
          PeriodSwitcher(
            filteredLabel:
                dateFilter.isIndependentRange ? dateFilter.getLabel() : null,
          ),
          // ── Total Card ─────────────────────────────────
          listAsync.when(
            data: (list) {
              final total = list.fold<int>(0, (s, t) => s + t.amount);
              return TotalCard(
                label: 'Total Pengeluaran',
                amount: total,
                color: appColors.expenseColor,
                containerColor: appColors.expenseContainer,
              );
            },
            loading: () => const SizedBox(height: 72),
            error: (e, st) => const SizedBox(height: 72),
          ),
          // ── Search / Filter ────────────────────────────
          const SearchFilterBar(type: 'expense'),
          // ── List ───────────────────────────────────────
          Expanded(
            child: listAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Belum ada pengeluaran',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => TransactionTile(
                    txn: list[i],
                    color: appColors.expenseColor,
                    containerColor: appColors.expenseContainer,
                    onDismissed: () async {
                      final deleted = list[i];
                      await ref.read(expenseListProvider.notifier).refresh();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Transaksi dihapus'),
                          action: SnackBarAction(
                            label: 'Batalkan',
                            onPressed: () async {
                              await TransactionDb.insert(
                                  deleted.copyWith(id: null));
                              ref.read(expenseListProvider.notifier).refresh();
                              ref
                                  .read(monthlySummaryProvider.notifier)
                                  .refresh();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets for both list views ──────────────────────

class TotalCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final Color containerColor;

  const TotalCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                    )),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchFilterBar extends ConsumerStatefulWidget {
  final String type; // 'expense' | 'income'

  const SearchFilterBar({super.key, required this.type});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ref.read(searchQueryProvider));
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCat = ref.watch(categoryFilterProvider);
    final activeDate = ref.watch(dateFilterProvider);
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final typeColor = widget.type == 'expense'
        ? appColors.expenseColor
        : appColors.incomeColor;
    final containerColor = widget.type == 'expense'
        ? appColors.expenseContainer
        : appColors.incomeContainer;

    int activeFilterCount = 0;
    if (activeDate.isActive) activeFilterCount++;
    if (activeCat != null) activeFilterCount++;

    final hasActiveFilter = activeFilterCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        ref.read(searchQueryProvider.notifier).state = v,
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                              },
                              splashRadius: 16,
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
                        borderSide: BorderSide(
                          color: typeColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Popup Trigger Button
              Material(
                color: hasActiveFilter
                    ? containerColor
                    : Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: hasActiveFilter
                        ? typeColor
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: hasActiveFilter ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => TransactionFilterSheet(type: widget.type),
                    );
                  },
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: hasActiveFilter
                              ? typeColor
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        if (hasActiveFilter)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Active filters chips
          if (hasActiveFilter) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (activeDate.isActive)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _ActiveFilterPill(
                        icon: Icons.calendar_today_rounded,
                        label: 'Filter: ${activeDate.getLabel()}',
                        color: typeColor,
                        containerColor: containerColor,
                        onClear: () {
                          ref.read(dateFilterProvider.notifier).state =
                              const DateFilter();
                        },
                      ),
                    ),
                  if (activeCat != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _ActiveFilterPill(
                        icon: Icons.label_outline_rounded,
                        label: activeCat,
                        color: typeColor,
                        containerColor: containerColor,
                        onClear: () {
                          ref.read(categoryFilterProvider.notifier).state =
                              null;
                        },
                      ),
                    ),
                  if (activeFilterCount > 1)
                    GestureDetector(
                      onTap: () {
                        ref.read(dateFilterProvider.notifier).state =
                            const DateFilter();
                        ref.read(categoryFilterProvider.notifier).state = null;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'Hapus Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveFilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color containerColor;
  final VoidCallback onClear;

  const _ActiveFilterPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.containerColor,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4, right: 6),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionTile extends ConsumerWidget {
  final TransactionModel txn;
  final Color color;
  final Color containerColor;
  final VoidCallback onDismissed;

  const TransactionTile({
    super.key,
    required this.txn,
    required this.color,
    required this.containerColor,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('dd MMM', 'id_ID').format(txn.date);
    final iconMap = ref.watch(categoryIconMapProvider);
    final icon =
        iconMap[txn.category] ?? TransactionModel.iconFor(txn.category);

    return Dismissible(
      key: ValueKey(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: color),
      ),
      onDismissed: (_) async {
        await TransactionDb.delete(txn.id!);
        onDismissed();
      },
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransactionFormSheet(editTransaction: txn),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(txn.category,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                    if (txn.note.isNotEmpty)
                      Text(
                        txn.note.replaceAll('\n', ' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(txn.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                  ),
                  Text(dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
