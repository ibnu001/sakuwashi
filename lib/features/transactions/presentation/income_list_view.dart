import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../data/transaction_db.dart';
import '../providers/transaction_provider.dart';
import 'expense_list_view.dart';
import 'period_switcher.dart';

class IncomeListView extends ConsumerWidget {
  const IncomeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(incomeListProvider);
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
                label: 'Total Pemasukan',
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
                      'Belum ada pemasukan',
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
                      await refreshAllTransactions(ref);
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
                              await refreshAllTransactions(ref);
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
