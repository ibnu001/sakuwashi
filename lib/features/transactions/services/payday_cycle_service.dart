import 'package:intl/intl.dart';

import '../data/transaction_db.dart';
import '../data/transaction_model.dart';

/// Represents a single period cycle (either calendar month or payday-based).
class PeriodCycle {
  /// Display title (e.g., "Desember 2026" or "November 2026").
  final String title;

  /// Muted subtitle showing exact date span (e.g., "26 Nov – 24 Des 2026").
  final String? subtitle;

  /// Inclusive start of this cycle (00:00:00 of the start date).
  final DateTime startDate;

  /// Exclusive end of this cycle (00:00:00 of the next cycle's start date).
  /// Null means open-ended (up to end of today / now).
  final DateTime? endDate;

  /// Whether this is the currently active (open-ended) cycle.
  bool get isActive => endDate == null;

  const PeriodCycle({
    required this.title,
    this.subtitle,
    required this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeriodCycle &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(title, subtitle, startDate, endDate);

  @override
  String toString() =>
      'PeriodCycle($title, $startDate – ${endDate ?? "now"})';
}

/// Service for calculating period cycles based on payday or calendar months.
class PaydayCycleService {
  PaydayCycleService._();

  static final _monthFmt = DateFormat('MMMM yyyy', 'id_ID');
  static final _dayMonthFmt = DateFormat('d MMM', 'id_ID');
  static final _dayMonthYearFmt = DateFormat('d MMM yyyy', 'id_ID');

  /// Build a standard calendar month cycle for [year]/[month].
  static PeriodCycle calendarMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return PeriodCycle(
      title: _monthFmt.format(start),
      subtitle: null,
      startDate: start,
      endDate: end,
    );
  }

  /// Fetch all payday cycles derived from 'Gaji' income transactions.
  /// Returns cycles sorted chronologically. Transactions before the first
  /// Gaji are grouped into standard calendar months.
  static Future<List<PeriodCycle>> buildPaydayCycles() async {
    final allGaji = await _fetchGajiTransactions();
    if (allGaji.isEmpty) return [];

    // Normalize earliest Gaji date before querying pre-Gaji transactions
    final earliestGajiDay = DateTime(
      allGaji.first.date.year,
      allGaji.first.date.month,
      allGaji.first.date.day,
    );
    final earliestPreGaji = await _fetchEarliestDateBefore(earliestGajiDay);

    return buildCyclesFromGajiDates(
      allGaji.map((t) => t.date).toList(),
      earliestPreGajiDate: earliestPreGaji,
    );
  }

  /// Pure cycle builder for given [rawGajiDates] and optional [earliestPreGajiDate].
  /// Groups same-day entries, prefixes calendar months before the first Gaji,
  /// and applies day >= 20 target-month naming.
  static List<PeriodCycle> buildCyclesFromGajiDates(
    List<DateTime> rawGajiDates, {
    DateTime? earliestPreGajiDate,
  }) {
    if (rawGajiDates.isEmpty) return [];

    // Deduplicate: keep only one boundary per calendar day (00:00:00)
    final uniqueDays = <String, DateTime>{};
    for (final d in rawGajiDates) {
      final key = '${d.year}-${d.month}-${d.day}';
      uniqueDays.putIfAbsent(key, () => DateTime(d.year, d.month, d.day));
    }

    final gajiDates = uniqueDays.values.toList()..sort();
    final cycles = <PeriodCycle>[];

    // Pre-Gaji calendar months
    final firstGaji = gajiDates.first;
    if (earliestPreGajiDate != null && earliestPreGajiDate.isBefore(firstGaji)) {
      var current =
          DateTime(earliestPreGajiDate.year, earliestPreGajiDate.month, 1);
      final limit = DateTime(firstGaji.year, firstGaji.month, 1);

      while (!current.isAfter(limit)) {
        final end = DateTime(current.year, current.month + 1, 1);
        final isTruncated = end.isAfter(firstGaji);
        final effectiveEnd = isTruncated ? firstGaji : end;

        if (effectiveEnd.isAfter(current)) {
          cycles.add(PeriodCycle(
            title: _monthFmt.format(current),
            subtitle:
                isTruncated ? _cycleSubtitle(current, effectiveEnd) : null,
            startDate: current,
            endDate: effectiveEnd,
          ));
        }

        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    // Gaji-based cycles
    for (int i = 0; i < gajiDates.length; i++) {
      final startDate = gajiDates[i];
      final endDate = i + 1 < gajiDates.length ? gajiDates[i + 1] : null;

      cycles.add(PeriodCycle(
        title: _cycleTitle(startDate),
        subtitle: _cycleSubtitle(startDate, endDate),
        startDate: startDate,
        endDate: endDate,
      ));
    }

    return cycles;
  }

  /// Find the cycle that contains [date]. If no cycle contains the date,
  /// returns null.
  static PeriodCycle? findCycleForDate(
      List<PeriodCycle> cycles, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (final cycle in cycles) {
      final start = DateTime(
          cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);

      if (cycle.endDate != null) {
        final end = DateTime(
            cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day);
        if (!d.isBefore(start) && d.isBefore(end)) return cycle;
      } else {
        if (!d.isBefore(start)) return cycle;
      }
    }
    return null;
  }

  /// Find a cycle by its [startDate] (ignoring time-of-day).
  static PeriodCycle? findCycleByStart(
      List<PeriodCycle> cycles, DateTime startDate) {
    for (final cycle in cycles) {
      if (cycle.startDate.year == startDate.year &&
          cycle.startDate.month == startDate.month &&
          cycle.startDate.day == startDate.day) {
        return cycle;
      }
    }
    return null;
  }

  /// Get the next cycle after [current], or null if at the end.
  static PeriodCycle? nextCycle(
      List<PeriodCycle> cycles, PeriodCycle current) {
    final idx = cycles.indexOf(current);
    if (idx < 0 || idx + 1 >= cycles.length) return null;
    return cycles[idx + 1];
  }

  /// Get the previous cycle before [current], or null if at the start.
  static PeriodCycle? prevCycle(
      List<PeriodCycle> cycles, PeriodCycle current) {
    final idx = cycles.indexOf(current);
    if (idx <= 0) return null;
    return cycles[idx - 1];
  }

  // ── Private helpers ───────────────────────────────────────────

  static Future<List<TransactionModel>> _fetchGajiTransactions() async {
    final db = await TransactionDb.database;
    final maps = await db.query(
      'transactions',
      where: "type = 'income' AND category = 'Gaji'",
      orderBy: 'date ASC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  static Future<DateTime?> _fetchEarliestDateBefore(
      DateTime firstGajiDate) async {
    final db = await TransactionDb.database;
    final maps = await db.query(
      'transactions',
      where: 'date < ?',
      whereArgs: [firstGajiDate.toIso8601String()],
      orderBy: 'date ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first).date;
  }

  /// Determine display title based on cycle start day.
  /// If start day >= 20, the title is the NEXT month's name.
  static String _cycleTitle(DateTime startDate) {
    if (startDate.day >= 20) {
      final nextMonth = DateTime(startDate.year, startDate.month + 1, 1);
      return _monthFmt.format(nextMonth);
    }
    return _monthFmt.format(startDate);
  }

  /// Build the subtitle showing exact date span.
  static String _cycleSubtitle(DateTime startDate, DateTime? endDate) {
    final startStr = _dayMonthFmt.format(startDate);
    if (endDate == null) {
      return '$startStr ${startDate.year} – Sekarang';
    }

    final lastDay = endDate.subtract(const Duration(days: 1));
    final sameYear = startDate.year == lastDay.year;
    if (sameYear) {
      final endStr = _dayMonthFmt.format(lastDay);
      return '$startStr – $endStr ${lastDay.year}';
    } else {
      final startFull = _dayMonthYearFmt.format(startDate);
      final endFull = _dayMonthYearFmt.format(lastDay);
      return '$startFull – $endFull';
    }
  }
}
