import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../settings/settings_controller.dart';
import '../data/transaction_db.dart';
import '../data/transaction_model.dart';
import '../services/payday_cycle_service.dart';

/// Currently selected month for filtering (calendar mode).
class MonthState {
  final int year;
  final int month;
  const MonthState({required this.year, required this.month});

  MonthState next() {
    if (month == 12) return MonthState(year: year + 1, month: 1);
    return MonthState(year: year, month: month + 1);
  }

  MonthState prev() {
    if (month == 1) return MonthState(year: year - 1, month: 12);
    return MonthState(year: year, month: month - 1);
  }
}

final selectedMonthProvider = StateProvider<MonthState>((ref) {
  final now = DateTime.now();
  return MonthState(year: now.year, month: now.month);
});

// ── Payday Cycle Providers ────────────────────────────────────

/// Bump to force refresh of payday cycles after adding/editing/deleting transactions.
final _cycleRefreshProvider = StateProvider<int>((ref) => 0);

/// Cached list of all payday cycles.
final paydayCyclesProvider = FutureProvider<List<PeriodCycle>>((ref) async {
  ref.watch(
    settingsControllerProvider.select((s) => s.useDynamicPaydayCycle),
  );
  ref.watch(_cycleRefreshProvider);
  return PaydayCycleService.buildPaydayCycles();
});

/// Start date of the user-selected payday cycle (null = auto-select active/current cycle).
final selectedPaydayCycleStartProvider = StateProvider<DateTime?>((ref) => null);

/// Resolves the currently selected [PeriodCycle] from [paydayCyclesProvider].
final selectedPaydayCycleProvider = Provider<PeriodCycle?>((ref) {
  final cycles = ref.watch(paydayCyclesProvider).valueOrNull;
  if (cycles == null || cycles.isEmpty) return null;

  final selectedStart = ref.watch(selectedPaydayCycleStartProvider);
  if (selectedStart != null) {
    final matched = PaydayCycleService.findCycleByStart(cycles, selectedStart);
    if (matched != null) return matched;
  }

  return PaydayCycleService.findCycleForDate(cycles, DateTime.now()) ??
      cycles.last;
});

/// Returns the active period window (start, end) considering both
/// calendar mode and payday cycle mode.
class ActivePeriod {
  final String title;
  final String? subtitle;
  final DateTime startDate;
  final DateTime? endDate; // null means open-ended (up to now)

  const ActivePeriod({
    required this.title,
    required this.startDate,
    this.endDate,
    this.subtitle,
  });
}

ActivePeriod _buildActivePeriodFromState({
  required bool useDynamicPaydayCycle,
  required PeriodCycle? cycle,
  required MonthState month,
}) {
  if (useDynamicPaydayCycle && cycle != null) {
    return ActivePeriod(
      title: cycle.title,
      subtitle: cycle.subtitle,
      startDate: cycle.startDate,
      endDate: cycle.endDate,
    );
  }

  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  final title =
      DateFormat('MMMM yyyy', 'id_ID').format(DateTime(month.year, month.month));
  return ActivePeriod(
    title: title,
    startDate: start,
    endDate: end,
  );
}

final activePeriodProvider = Provider<ActivePeriod>((ref) {
  final useDynamic = ref.watch(
    settingsControllerProvider.select((s) => s.useDynamicPaydayCycle),
  );
  final cycle = useDynamic ? ref.watch(selectedPaydayCycleProvider) : null;
  final month = ref.watch(selectedMonthProvider);
  return _buildActivePeriodFromState(
    useDynamicPaydayCycle: useDynamic,
    cycle: cycle,
    month: month,
  );
});

// ── Advanced Date Filter ──────────────────────────────────────
enum DateFilterType {
  allMonth, // follows activePeriod
  monthYear, // specific month & year
  fullYear, // entire year
  customRange, // arbitrary date range
}

class DateFilter {
  final DateFilterType type;
  final int? filterYear; // for fullYear or monthYear
  final int? filterMonth; // for monthYear
  final DateTime? rangeStart; // for customRange
  final DateTime? rangeEnd; // for customRange

  const DateFilter({
    this.type = DateFilterType.allMonth,
    this.filterYear,
    this.filterMonth,
    this.rangeStart,
    this.rangeEnd,
  });

  bool get isActive => type != DateFilterType.allMonth;

  /// All custom filter modes replace the top period navigator with their own range.
  bool get isIndependentRange => type != DateFilterType.allMonth;

  String getLabel() {
    switch (type) {
      case DateFilterType.allMonth:
        return 'Periode Aktif';
      case DateFilterType.monthYear:
        if (filterYear == null || filterMonth == null) return 'Bulan & Tahun';
        return DateFormat('MMMM yyyy', 'id_ID')
            .format(DateTime(filterYear!, filterMonth!));
      case DateFilterType.fullYear:
        if (filterYear == null) return 'Tahun';
        return 'Tahun $filterYear';
      case DateFilterType.customRange:
        if (rangeStart == null || rangeEnd == null) return 'Rentang Kustom';
        final fullFmt = DateFormat('d MMM yyyy', 'id_ID');
        final shortFmt = DateFormat('d MMM', 'id_ID');
        final sameDay = rangeStart!.year == rangeEnd!.year &&
            rangeStart!.month == rangeEnd!.month &&
            rangeStart!.day == rangeEnd!.day;
        if (sameDay) {
          return fullFmt.format(rangeStart!);
        }
        if (rangeStart!.year == rangeEnd!.year) {
          return '${shortFmt.format(rangeStart!)} – ${fullFmt.format(rangeEnd!)}';
        }
        return '${fullFmt.format(rangeStart!)} – ${fullFmt.format(rangeEnd!)}';
    }
  }

  /// Get the date range [start, end) for independent filter modes.
  (DateTime, DateTime)? getIndependentRange() {
    switch (type) {
      case DateFilterType.allMonth:
        return null;
      case DateFilterType.monthYear:
        if (filterYear == null || filterMonth == null) return null;
        return (
          DateTime(filterYear!, filterMonth!, 1),
          DateTime(filterYear!, filterMonth! + 1, 1),
        );
      case DateFilterType.fullYear:
        if (filterYear == null) return null;
        return (
          DateTime(filterYear!, 1, 1),
          DateTime(filterYear! + 1, 1, 1),
        );
      case DateFilterType.customRange:
        if (rangeStart == null || rangeEnd == null) return null;
        return (
          DateTime(rangeStart!.year, rangeStart!.month, rangeStart!.day),
          // Exclusive upper bound at 00:00:00 the next day covers 00:00:00..23:59:59.999
          DateTime(rangeEnd!.year, rangeEnd!.month, rangeEnd!.day + 1),
        );
    }
  }
}

final dateFilterProvider =
    StateProvider<DateFilter>((ref) => const DateFilter());

/// Search query provider.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Category filter provider (null = show all).
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// ── Shared period query helper ────────────────────────────────
Future<(DateTime, DateTime?)> _resolveQueryWindow(
  Ref ref,
  DateFilter dateFilter,
) async {
  if (dateFilter.isIndependentRange) {
    final range = dateFilter.getIndependentRange();
    if (range != null) return (range.$1, range.$2);
  }

  final useDynamic = ref.watch(
    settingsControllerProvider.select((s) => s.useDynamicPaydayCycle),
  );
  if (useDynamic) {
    // Ensure payday cycles are loaded before querying so we don't flash calendar month
    await ref.watch(paydayCyclesProvider.future);
  }

  final period = ref.watch(activePeriodProvider);
  return (period.startDate, period.endDate);
}

// ── Expense list ──────────────────────────────────────────────
final expenseListProvider =
    AsyncNotifierProvider<ExpenseListNotifier, List<TransactionModel>>(
        ExpenseListNotifier.new);

class ExpenseListNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() => _fetch();

  Future<List<TransactionModel>> _fetch() async {
    final dateFilter = ref.watch(dateFilterProvider);
    final q = ref.watch(searchQueryProvider);
    final cat = ref.watch(categoryFilterProvider);

    final (start, end) = await _resolveQueryWindow(ref, dateFilter);

    var list = await TransactionDb.getByDateRange(
      start,
      end,
      type: 'expense',
      query: q,
    );

    if (cat != null) {
      list = list.where((t) => t.category == cat).toList();
    }
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetch());
  }
}

// ── Income list ───────────────────────────────────────────────
final incomeListProvider =
    AsyncNotifierProvider<IncomeListNotifier, List<TransactionModel>>(
        IncomeListNotifier.new);

class IncomeListNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() => _fetch();

  Future<List<TransactionModel>> _fetch() async {
    final dateFilter = ref.watch(dateFilterProvider);
    final q = ref.watch(searchQueryProvider);
    final cat = ref.watch(categoryFilterProvider);

    final (start, end) = await _resolveQueryWindow(ref, dateFilter);

    var list = await TransactionDb.getByDateRange(
      start,
      end,
      type: 'income',
      query: q,
    );

    if (cat != null) {
      list = list.where((t) => t.category == cat).toList();
    }
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetch());
  }
}

// ── Summary (all transactions for the active period) ──────────
final monthlySummaryProvider =
    AsyncNotifierProvider<MonthlySummaryNotifier, List<TransactionModel>>(
        MonthlySummaryNotifier.new);

class MonthlySummaryNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() => _fetch();

  Future<List<TransactionModel>> _fetch() async {
    final useDynamic = ref.watch(
      settingsControllerProvider.select((s) => s.useDynamicPaydayCycle),
    );
    if (useDynamic) {
      await ref.watch(paydayCyclesProvider.future);
    }

    final period = ref.watch(activePeriodProvider);
    return TransactionDb.getByDateRange(
      period.startDate,
      period.endDate,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetch());
  }
}

// ── Convenience helper to refresh all lists at once ───────────
Future<void> refreshAllTransactions(WidgetRef ref) async {
  ref.read(_cycleRefreshProvider.notifier).state++;
  await Future.wait([
    ref.read(expenseListProvider.notifier).refresh(),
    ref.read(incomeListProvider.notifier).refresh(),
    ref.read(monthlySummaryProvider.notifier).refresh(),
  ]);
}
