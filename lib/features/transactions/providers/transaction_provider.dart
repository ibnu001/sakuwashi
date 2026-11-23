import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/transaction_db.dart';
import '../data/transaction_model.dart';

/// Currently selected month for filtering.
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

// ── Date Filter (All Month, Weekly, or Specific Date) ────────
enum DateFilterType {
  allMonth,
  weekly,
  specificDate,
}

class DateFilter {
  final DateFilterType type;
  final int? weekIndex; // 1 to 5
  final DateTime? specificDate;

  const DateFilter({
    this.type = DateFilterType.allMonth,
    this.weekIndex,
    this.specificDate,
  });

  bool get isActive => type != DateFilterType.allMonth;

  String getLabel(int year, int month) {
    switch (type) {
      case DateFilterType.allMonth:
        return 'Sebulan Penuh';
      case DateFilterType.weekly:
        if (weekIndex == null) return 'Mingguan';
        final lastDay = DateTime(year, month + 1, 0).day;
        final startDay = (weekIndex! - 1) * 7 + 1;
        final endDay = (weekIndex! * 7).clamp(1, lastDay);
        return 'Minggu $weekIndex (Tgl $startDay-$endDay)';
      case DateFilterType.specificDate:
        if (specificDate == null) return 'Tanggal';
        return DateFormat('d MMM yyyy', 'id_ID').format(specificDate!);
    }
  }

  bool matches(DateTime date) {
    switch (type) {
      case DateFilterType.allMonth:
        return true;
      case DateFilterType.weekly:
        if (weekIndex == null) return true;
        final day = date.day;
        final startDay = (weekIndex! - 1) * 7 + 1;
        final endDay = weekIndex! == 5 ? 31 : weekIndex! * 7;
        return day >= startDay && day <= endDay;
      case DateFilterType.specificDate:
        if (specificDate == null) return true;
        return date.year == specificDate!.year &&
            date.month == specificDate!.month &&
            date.day == specificDate!.day;
    }
  }
}

final dateFilterProvider =
    StateProvider<DateFilter>((ref) => const DateFilter());

/// Search query provider.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Category filter provider (null = show all).
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// ── Expense list ──────────────────────────────────────────────
final expenseListProvider =
    AsyncNotifierProvider<ExpenseListNotifier, List<TransactionModel>>(
        ExpenseListNotifier.new);

class ExpenseListNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() => _fetch();

  Future<List<TransactionModel>> _fetch() async {
    final m = ref.watch(selectedMonthProvider);
    final q = ref.watch(searchQueryProvider);
    final cat = ref.watch(categoryFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);

    List<TransactionModel> list;
    if (q.isNotEmpty) {
      list = await TransactionDb.search(q, 'expense', m.year, m.month);
    } else {
      list = await TransactionDb.getByTypeAndMonth('expense', m.year, m.month);
    }

    if (cat != null) {
      list = list.where((t) => t.category == cat).toList();
    }
    if (dateFilter.isActive) {
      list = list.where((t) => dateFilter.matches(t.date)).toList();
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
    final m = ref.watch(selectedMonthProvider);
    final q = ref.watch(searchQueryProvider);
    final cat = ref.watch(categoryFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);

    List<TransactionModel> list;
    if (q.isNotEmpty) {
      list = await TransactionDb.search(q, 'income', m.year, m.month);
    } else {
      list = await TransactionDb.getByTypeAndMonth('income', m.year, m.month);
    }

    if (cat != null) {
      list = list.where((t) => t.category == cat).toList();
    }
    if (dateFilter.isActive) {
      list = list.where((t) => dateFilter.matches(t.date)).toList();
    }
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetch());
  }
}

// ── Summary (all transactions for the month) ──────────────────
final monthlySummaryProvider =
    AsyncNotifierProvider<MonthlySummaryNotifier, List<TransactionModel>>(
        MonthlySummaryNotifier.new);

class MonthlySummaryNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() => _fetch();

  Future<List<TransactionModel>> _fetch() async {
    final m = ref.watch(selectedMonthProvider);
    return TransactionDb.getByMonth(m.year, m.month);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetch());
  }
}

// ── Convenience helper to refresh all lists at once ───────────
Future<void> refreshAllTransactions(WidgetRef ref) async {
  await Future.wait([
    ref.read(expenseListProvider.notifier).refresh(),
    ref.read(incomeListProvider.notifier).refresh(),
    ref.read(monthlySummaryProvider.notifier).refresh(),
  ]);
}
