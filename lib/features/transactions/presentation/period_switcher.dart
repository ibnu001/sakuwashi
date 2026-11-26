import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../settings/settings_controller.dart';
import '../providers/transaction_provider.dart';
import '../services/payday_cycle_service.dart';

/// Shared period/cycle switcher header used by Expense, Income, and Summary views.
class PeriodSwitcher extends ConsumerWidget {
  /// Optional override label when an independent filter is active (e.g. "Tahun 2026").
  final String? filteredLabel;

  /// Optional padding override (SummaryView uses horizontal 0 inside a padded scroll view).
  final EdgeInsetsGeometry padding;

  const PeriodSwitcher({
    super.key,
    this.filteredLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filteredLabel != null) {
      return Padding(
        padding: padding,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              filteredLabel!,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final useDynamic = ref.watch(
      settingsControllerProvider.select((s) => s.useDynamicPaydayCycle),
    );

    if (!useDynamic) {
      return _CalendarSwitcher(padding: padding);
    }

    final cyclesAsync = ref.watch(paydayCyclesProvider);
    return cyclesAsync.when(
      loading: () => Padding(
        padding: padding,
        child: const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, _) => _CalendarSwitcher(padding: padding),
      data: (cycles) {
        if (cycles.isEmpty) {
          return _CalendarSwitcher(padding: padding);
        }

        final selected = ref.watch(selectedPaydayCycleProvider) ??
            PaydayCycleService.findCycleForDate(cycles, DateTime.now()) ??
            cycles.last;

        final prev = PaydayCycleService.prevCycle(cycles, selected);
        final next = PaydayCycleService.nextCycle(cycles, selected);

        return _SwitcherRow(
          padding: padding,
          title: selected.title,
          subtitle: selected.subtitle,
          onPrev: prev != null
              ? () {
                  ref.read(dateFilterProvider.notifier).state =
                      const DateFilter();
                  ref.read(selectedPaydayCycleStartProvider.notifier).state =
                      prev.startDate;
                }
              : null,
          onNext: next != null
              ? () {
                  ref.read(dateFilterProvider.notifier).state =
                      const DateFilter();
                  ref.read(selectedPaydayCycleStartProvider.notifier).state =
                      next.startDate;
                }
              : null,
        );
      },
    );
  }
}

class _CalendarSwitcher extends ConsumerWidget {
  final EdgeInsetsGeometry padding;

  const _CalendarSwitcher({required this.padding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final label = DateFormat('MMMM yyyy', 'id_ID')
        .format(DateTime(month.year, month.month));

    return _SwitcherRow(
      padding: padding,
      title: label,
      onPrev: () {
        ref.read(dateFilterProvider.notifier).state = const DateFilter();
        ref.read(selectedMonthProvider.notifier).state = month.prev();
      },
      onNext: () {
        ref.read(dateFilterProvider.notifier).state = const DateFilter();
        ref.read(selectedMonthProvider.notifier).state = month.next();
      },
    );
  }
}

class _SwitcherRow extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final String title;
  final String? subtitle;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _SwitcherRow({
    required this.padding,
    required this.title,
    this.subtitle,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: onPrev,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
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
