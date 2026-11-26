import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../categories/providers/category_provider.dart';
import '../providers/transaction_provider.dart';

/// Modal bottom sheet popup for filtering transactions by date period
/// and by category. Supports 4 filter modes:
/// 1. Periode Aktif (follows top period navigator)
/// 2. Bulan & Tahun (specific month + year)
/// 3. Tahun Penuh (entire year)
/// 4. Rentang Tanggal Kustom (arbitrary date range)
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

  // For month/year picker
  late int _pickerYear;
  late int _pickerMonth;

  @override
  void initState() {
    super.initState();
    _dateFilter = ref.read(dateFilterProvider);
    _selectedCategory = ref.read(categoryFilterProvider);

    final now = DateTime.now();
    _pickerYear = _dateFilter.filterYear ?? now.year;
    _pickerMonth = _dateFilter.filterMonth ?? now.month;
  }

  void _resetFilter() {
    setState(() {
      _dateFilter = const DateFilter();
      _selectedCategory = null;
      final now = DateTime.now();
      _pickerYear = now.year;
      _pickerMonth = now.month;
    });
  }

  void _applyFilter() {
    ref.read(dateFilterProvider.notifier).state = _dateFilter;
    ref.read(categoryFilterProvider.notifier).state = _selectedCategory;
    Navigator.pop(context);
  }

  Future<void> _pickCustomDateRange(Color typeColor) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateFilter.rangeStart != null &&
              _dateFilter.rangeEnd != null
          ? DateTimeRange(
              start: _dateFilter.rangeStart!, end: _dateFilter.rangeEnd!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1), end: now),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
          type: DateFilterType.customRange,
          rangeStart: picked.start,
          rangeEnd: picked.end,
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

              // Date Mode Tabs - Row 1
              Row(
                children: [
                  _PeriodModeTab(
                    label: 'Periode Aktif',
                    isActive: _dateFilter.type == DateFilterType.allMonth,
                    color: typeColor,
                    onTap: () {
                      setState(() {
                        _dateFilter =
                            const DateFilter(type: DateFilterType.allMonth);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodModeTab(
                    label: 'Bulan & Tahun',
                    isActive: _dateFilter.type == DateFilterType.monthYear,
                    color: typeColor,
                    onTap: () {
                      setState(() {
                        _dateFilter = DateFilter(
                          type: DateFilterType.monthYear,
                          filterYear: _pickerYear,
                          filterMonth: _pickerMonth,
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date Mode Tabs - Row 2
              Row(
                children: [
                  _PeriodModeTab(
                    label: 'Tahun Penuh',
                    isActive: _dateFilter.type == DateFilterType.fullYear,
                    color: typeColor,
                    onTap: () {
                      setState(() {
                        _dateFilter = DateFilter(
                          type: DateFilterType.fullYear,
                          filterYear: _pickerYear,
                        );
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodModeTab(
                    label: 'Rentang Kustom',
                    isActive: _dateFilter.type == DateFilterType.customRange,
                    color: typeColor,
                    onTap: () => _pickCustomDateRange(typeColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sub-options depending on DateFilterType
              if (_dateFilter.type == DateFilterType.monthYear) ...[
                _MonthYearPicker(
                  year: _pickerYear,
                  month: _pickerMonth,
                  color: typeColor,
                  containerColor: containerColor,
                  onChanged: (y, m) {
                    setState(() {
                      _pickerYear = y;
                      _pickerMonth = m;
                      _dateFilter = DateFilter(
                        type: DateFilterType.monthYear,
                        filterYear: y,
                        filterMonth: m,
                      );
                    });
                  },
                ),
              ] else if (_dateFilter.type == DateFilterType.fullYear) ...[
                _YearPicker(
                  year: _pickerYear,
                  color: typeColor,
                  containerColor: containerColor,
                  onChanged: (y) {
                    setState(() {
                      _pickerYear = y;
                      _dateFilter = DateFilter(
                        type: DateFilterType.fullYear,
                        filterYear: y,
                      );
                    });
                  },
                ),
              ] else if (_dateFilter.type == DateFilterType.customRange) ...[
                GestureDetector(
                  onTap: () => _pickCustomDateRange(typeColor),
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
                        Icon(Icons.date_range_rounded,
                            size: 20, color: typeColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dateFilter.rangeStart != null &&
                                    _dateFilter.rangeEnd != null
                                ? '${DateFormat('d MMM yyyy', 'id_ID').format(_dateFilter.rangeStart!)} – ${DateFormat('d MMM yyyy', 'id_ID').format(_dateFilter.rangeEnd!)}'
                                : 'Ketuk untuk memilih rentang tanggal',
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

// ── Month & Year Picker Widget ──────────────────────────────
class _MonthYearPicker extends StatelessWidget {
  final int year;
  final int month;
  final Color color;
  final Color containerColor;
  final void Function(int year, int month) onChanged;

  const _MonthYearPicker({
    required this.year,
    required this.month,
    required this.color,
    required this.containerColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) {
      final dt = DateTime(2024, i + 1);
      return DateFormat('MMM', 'id_ID').format(dt);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () => onChanged(year - 1, month),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '$year',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () => onChanged(year + 1, month),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Month grid
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(12, (i) {
            final m = i + 1;
            final isSelected = m == month;
            return GestureDetector(
              onTap: () => onChanged(year, m),
              child: Container(
                width: (MediaQuery.of(context).size.width - 40 - 30) / 4,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? containerColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  months[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Year Picker Widget ──────────────────────────────────────
class _YearPicker extends StatelessWidget {
  final int year;
  final Color color;
  final Color containerColor;
  final ValueChanged<int> onChanged;

  const _YearPicker({
    required this.year,
    required this.color,
    required this.containerColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Center a 6-year window around the selected year (minimum 2015)
    final startYear = (year - 2).clamp(2015, 2095);
    final years = List.generate(6, (i) => startYear + i);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () => onChanged(year - 1),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '$year',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () => onChanged(year + 1),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: years.map((y) {
            final isSelected = y == year;
            return GestureDetector(
              onTap: () => onChanged(y),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? containerColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '$y',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
