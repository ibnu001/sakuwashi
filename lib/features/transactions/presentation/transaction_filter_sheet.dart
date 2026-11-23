import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../categories/providers/category_provider.dart';
import '../providers/transaction_provider.dart';

/// Modal bottom sheet popup for filtering transactions by date period
/// (full month, weekly, or specific date) and by category.
class TransactionFilterSheet extends ConsumerStatefulWidget {
  final String type; // 'expense' | 'income'

  const TransactionFilterSheet({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late DateFilter _dateFilter;
  late String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _dateFilter = ref.read(dateFilterProvider);
    _selectedCategory = ref.read(categoryFilterProvider);
  }

  void _resetFilter() {
    setState(() {
      _dateFilter = const DateFilter();
      _selectedCategory = null;
    });
  }

  void _applyFilter() {
    ref.read(dateFilterProvider.notifier).state = _dateFilter;
    ref.read(categoryFilterProvider.notifier).state = _selectedCategory;
    Navigator.pop(context);
  }

  Future<void> _pickSpecificDate(
      int year, int month, Color typeColor) async {
    final lastDay = DateTime(year, month + 1, 0).day;
    final initial = _dateFilter.specificDate ??
        DateTime(year, month, DateTime.now().day.clamp(1, lastDay));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(year, month, 1),
      lastDate: DateTime(year, month, lastDay),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: typeColor,
              headerForegroundColor: Colors.white,
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: typeColor,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = DateFilter(
          type: DateFilterType.specificDate,
          specificDate: picked,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final typeColor = widget.type == 'expense'
        ? appColors.expenseColor
        : appColors.incomeColor;
    final containerColor = widget.type == 'expense'
        ? appColors.expenseContainer
        : appColors.incomeContainer;

    final month = ref.watch(selectedMonthProvider);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;

    final categoriesAsync = widget.type == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle Bar ─────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Top Header (Title + Reset + Close) ─────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Transaksi',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _resetFilter,
                        child: const Text('Reset'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22),
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.pop(context),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Section 1: Periode Tanggal ─────────────────────
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18, color: typeColor),
                  const SizedBox(width: 8),
                  Text(
                    'Periode Tanggal',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Date Mode Tabs
              Row(
                children: [
                  _PeriodModeTab(
                    label: 'Sebulan Penuh',
                    isActive: _dateFilter.type == DateFilterType.allMonth,
                    color: typeColor,
                    onTap: () {
                      setState(() {
                        _dateFilter = const DateFilter(
                            type: DateFilterType.allMonth);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodModeTab(
                    label: 'Mingguan',
                    isActive: _dateFilter.type == DateFilterType.weekly,
                    color: typeColor,
                    onTap: () {
                      setState(() {
                        _dateFilter = DateFilter(
                          type: DateFilterType.weekly,
                          weekIndex: _dateFilter.weekIndex ?? 1,
                        );
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodModeTab(
                    label: 'Spesifik',
                    isActive:
                        _dateFilter.type == DateFilterType.specificDate,
                    color: typeColor,
                    onTap: () {
                      _pickSpecificDate(
                          month.year, month.month, typeColor);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sub-options depending on DateFilterType
              if (_dateFilter.type == DateFilterType.weekly) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    lastDayOfMonth >= 29 ? 5 : 4,
                    (index) {
                      final weekNum = index + 1;
                      final startDay = (weekNum - 1) * 7 + 1;
                      final endDay = (weekNum * 7).clamp(1, lastDayOfMonth);
                      final isSelected = _dateFilter.weekIndex == weekNum;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _dateFilter = DateFilter(
                              type: DateFilterType.weekly,
                              weekIndex: weekNum,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? containerColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? typeColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minggu $weekNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? typeColor
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                              Text(
                                'Tgl $startDay - $endDay',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? typeColor.withValues(alpha: 0.8)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_dateFilter.type == DateFilterType.specificDate) ...[
                GestureDetector(
                  onTap: () =>
                      _pickSpecificDate(month.year, month.month, typeColor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 20, color: typeColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dateFilter.specificDate != null
                                ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                    .format(_dateFilter.specificDate!)
                                : 'Ketuk untuk memilih tanggal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ),
                        Icon(Icons.edit_calendar_outlined,
                            size: 18, color: typeColor),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),

              // ── Section 2: Filter Kategori ─────────────────────
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 18, color: typeColor),
                  const SizedBox(width: 8),
                  Text(
                    'Kategori',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Option: Semua Kategori
                  _CategoryFilterChip(
                    icon: Icons.all_inclusive_rounded,
                    label: 'Semua Kategori',
                    isSelected: _selectedCategory == null,
                    color: typeColor,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  // Categories list
                  ...categories.map((c) {
                    final isSelected = _selectedCategory == c.name;
                    return _CategoryFilterChip(
                      icon: c.icon,
                      label: c.name,
                      isSelected: isSelected,
                      color: typeColor,
                      onTap: () =>
                          setState(() => _selectedCategory = c.name),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 28),

              // ── Apply Filter Button ────────────────────────────
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Terapkan Filter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _PeriodModeTab({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? color
                  : Theme.of(context).colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
