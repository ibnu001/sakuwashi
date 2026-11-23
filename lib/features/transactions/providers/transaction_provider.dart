import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    List<TransactionModel> list;
    if (q.isNotEmpty) {
      list = await TransactionDb.search(q, 'expense', m.year, m.month);
    } else {
      list = await TransactionDb.getByTypeAndMonth('expense', m.year, m.month);
    }

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
    final m = ref.watch(selectedMonthProvider);
    final q = ref.watch(searchQueryProvider);
    final cat = ref.watch(categoryFilterProvider);

    List<TransactionModel> list;
    if (q.isNotEmpty) {
      list = await TransactionDb.search(q, 'income', m.year, m.month);
    } else {
      list = await TransactionDb.getByTypeAndMonth('income', m.year, m.month);
    }

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
