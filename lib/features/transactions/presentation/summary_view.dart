import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/transaction_provider.dart';

/// Monthly financial overview: income vs. expense balance card and category breakdown bars.
class SummaryView extends ConsumerWidget {
  const SummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID')
        .format(DateTime(month.year, month.month));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Month Switcher ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    onPressed: () => ref
                        .read(selectedMonthProvider.notifier)
                        .state = month.prev(),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    monthLabel,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    onPressed: () => ref
                        .read(selectedMonthProvider.notifier)
                        .state = month.next(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Content ──────────────────────────────────
            summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final totalIncome = list
                    .where((t) => t.type == 'income')
                    .fold<int>(0, (s, t) => s + t.amount);
                final totalExpense = list
                    .where((t) => t.type == 'expense')
                    .fold<int>(0, (s, t) => s + t.amount);
                final balance = totalIncome - totalExpense;

                // Category breakdowns
                final expByCat = <String, int>{};
                final incByCat = <String, int>{};
                for (final t in list) {
                  if (t.type == 'expense') {
                    expByCat[t.category] =
                        (expByCat[t.category] ?? 0) + t.amount;
                  } else {
                    incByCat[t.category] =
                        (incByCat[t.category] ?? 0) + t.amount;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Balance Card ─────────────────────
                    _BalanceCard(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      balance: balance,
                      appColors: appColors,
                    ),
                    const SizedBox(height: 20),

                    // ── Expense Breakdown ────────────────
                    if (expByCat.isNotEmpty) ...[
                      Text('Pengeluaran per Kategori',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ..._buildCategoryBars(context, expByCat, totalExpense,
                          appColors.expenseColor),
                      const SizedBox(height: 20),
                    ],

                    // ── Income Breakdown ─────────────────
                    if (incByCat.isNotEmpty) ...[
                      Text('Pemasukan per Kategori',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ..._buildCategoryBars(context, incByCat, totalIncome,
                          appColors.incomeColor),
                      const SizedBox(height: 20),
                    ],

                    if (list.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Text('Belum ada data bulan ini',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryBars(
    BuildContext context,
    Map<String, int> catMap,
    int total,
    Color color,
  ) {
    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500)),
                      Text(CurrencyFormatter.format(e.value),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? e.value / total : 0,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}

class _BalanceCard extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int balance;
  final AppColorsExtension appColors;

  const _BalanceCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor =
        balance >= 0 ? appColors.incomeColor : appColors.expenseColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text('Selisih Saldo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(balance.abs()),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: balanceColor,
                ),
          ),
          Text(
            balance >= 0 ? 'Surplus' : 'Defisit',
            style: TextStyle(
              color: balanceColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Pemasukan',
                  amount: totalIncome,
                  color: appColors.incomeColor,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Pengeluaran',
                  amount: totalExpense,
                  color: appColors.expenseColor,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
