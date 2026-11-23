import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/providers/category_provider.dart';
import '../data/transaction_db.dart';
import '../data/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'transaction_form_sheet.dart';

class ExpenseListView extends ConsumerWidget {
  const ExpenseListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final listAsync = ref.watch(expenseListProvider);
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID')
        .format(DateTime(month.year, month.month));

    return SafeArea(
      child: Column(
        children: [
          // ── Month Switcher ─────────────────────────────
          MonthSwitcher(
            label: monthLabel,
            onPrev: () =>
                ref.read(selectedMonthProvider.notifier).state = month.prev(),
            onNext: () =>
                ref.read(selectedMonthProvider.notifier).state = month.next(),
          ),
          // ── Total Card ─────────────────────────────────
          listAsync.when(
            data: (list) {
              final total = list.fold<int>(0, (s, t) => s + t.amount);
              return TotalCard(
                label: 'Total Pengeluaran bulan ini',
                amount: total,
                color: appColors.expenseColor,
                containerColor: appColors.expenseContainer,
              );
            },
            loading: () => const SizedBox(height: 72),
            error: (e, st) => const SizedBox(height: 72),
          ),
          // ── Search / Filter ────────────────────────────
          ref.watch(expenseCategoriesProvider).when(
                data: (cats) => SearchFilterBar(
                  categories: cats.map((c) => c.name).toList(),
                ),
                loading: () => const SizedBox(height: 72),
                error: (e, st) => const SizedBox(height: 72),
              ),
          // ── List ───────────────────────────────────────
          Expanded(
            child: listAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Belum ada pengeluaran bulan ini',
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

class MonthSwitcher extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const MonthSwitcher({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: onPrev,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: onNext,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

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

class SearchFilterBar extends ConsumerWidget {
  final List<String> categories;

  const SearchFilterBar({super.key, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCat = ref.watch(categoryFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: TextField(
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Cari transaksi…',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChipWidget(
                  label: 'Semua',
                  isActive: activeCat == null,
                  onTap: () =>
                      ref.read(categoryFilterProvider.notifier).state = null,
                ),
                ...categories.map((c) => FilterChipWidget(
                      label: c,
                      isActive: activeCat == c,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state = c,
                    )),
              ],
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
