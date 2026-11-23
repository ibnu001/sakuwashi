import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../data/transaction_db.dart';
import '../providers/transaction_provider.dart';
import 'expense_list_view.dart';

class IncomeListView extends ConsumerWidget {
  const IncomeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final listAsync = ref.watch(incomeListProvider);
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final monthLabel = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateTime(month.year, month.month));

    return SafeArea(
      child: Column(
        children: [
          // ── Month Switcher ─────────────────────────────
          MonthSwitcher(
            label: monthLabel,
            onPrev: () {
              ref.read(dateFilterProvider.notifier).state = const DateFilter();
              ref.read(selectedMonthProvider.notifier).state = month.prev();
            },
            onNext: () {
              ref.read(dateFilterProvider.notifier).state = const DateFilter();
              ref.read(selectedMonthProvider.notifier).state = month.next();
            },
          ),
          // ── Total Card ─────────────────────────────────
          listAsync.when(
            data: (list) {
              final total = list.fold<int>(0, (s, t) => s + t.amount);
              return TotalCard(
                label: 'Total Pemasukan bulan ini',
                amount: total,
                color: appColors.incomeColor,
                containerColor: appColors.incomeContainer,
              );
            },
            loading: () => const SizedBox(height: 72),
            error: (e, st) => const SizedBox(height: 72),
          ),
          // ── Search / Filter ────────────────────────────
          const SearchFilterBar(type: 'income'),
          // ── List ───────────────────────────────────────
          Expanded(
            child: listAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada pemasukan bulan ini',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => TransactionTile(
                    txn: list[i],
                    color: appColors.incomeColor,
                    containerColor: appColors.incomeContainer,
                    onDismissed: () async {
                      final deleted = list[i];
                      await ref.read(incomeListProvider.notifier).refresh();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Transaksi dihapus'),
                          action: SnackBarAction(
                            label: 'Batalkan',
                            onPressed: () async {
                              await TransactionDb.insert(
                                deleted.copyWith(id: null),
                              );
                              ref.read(incomeListProvider.notifier).refresh();
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
