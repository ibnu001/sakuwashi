import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/data/transaction_db.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../data/category_model.dart';

// ── Expense Categories Notifier ──────────────────────────────
final expenseCategoriesProvider =
    AsyncNotifierProvider<ExpenseCategoriesNotifier, List<CategoryModel>>(
        ExpenseCategoriesNotifier.new);

class ExpenseCategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() =>
      TransactionDb.getCategories('expense');

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await TransactionDb.getCategories('expense'));
  }
}

// ── Income Categories Notifier ───────────────────────────────
final incomeCategoriesProvider =
    AsyncNotifierProvider<IncomeCategoriesNotifier, List<CategoryModel>>(
        IncomeCategoriesNotifier.new);

class IncomeCategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() =>
      TransactionDb.getCategories('income');

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await TransactionDb.getCategories('income'));
  }
}

// ── Fast Category Icon Lookup Map ───────────────────────────
final categoryIconMapProvider = Provider<Map<String, IconData>>((ref) {
  final expense = ref.watch(expenseCategoriesProvider).valueOrNull ?? [];
  final income = ref.watch(incomeCategoriesProvider).valueOrNull ?? [];
  final map = <String, IconData>{};
  for (final c in [...expense, ...income]) {
    map[c.name] = c.icon;
  }
  return map;
});

// ── Category Controller Actions ─────────────────────────────
class CategoryActions {
  final WidgetRef ref;
  const CategoryActions(this.ref);

  /// Add a new category and refresh providers.
  Future<int> addCategory(CategoryModel category) async {
    final id = await TransactionDb.insertCategory(category);
    await _refreshAll();
    return id;
  }

  /// Update an existing category and refresh providers.
  Future<void> updateCategory(CategoryModel category,
      {String? oldName}) async {
    await TransactionDb.updateCategory(category, oldName: oldName);
    await _refreshAll();
    await refreshAllTransactions(ref);
  }

  /// Delete a custom category, moving affected transactions to 'Lainnya'.
  Future<void> deleteCategory(CategoryModel category) async {
    if (category.id == null || category.isDefault) return;
    await TransactionDb.deleteCategory(
        category.id!, category.name, category.type);

    // If the active category filter matches the deleted category, reset it
    final currentFilter = ref.read(categoryFilterProvider);
    if (currentFilter == category.name) {
      ref.read(categoryFilterProvider.notifier).state = null;
    }

    await _refreshAll();
    await refreshAllTransactions(ref);
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(expenseCategoriesProvider.notifier).refresh(),
      ref.read(incomeCategoriesProvider.notifier).refresh(),
    ]);
  }
}
