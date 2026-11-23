import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakuwashi/features/transactions/providers/transaction_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('DateFilter Unit Tests', () {
    test('Default DateFilter matches all dates in the month', () {
      const filter = DateFilter();
      expect(filter.isActive, isFalse);
      expect(filter.matches(DateTime(2026, 11, 1)), isTrue);
      expect(filter.matches(DateTime(2026, 11, 15)), isTrue);
      expect(filter.matches(DateTime(2026, 11, 30)), isTrue);
    });

    test('Weekly DateFilter matches only the selected week', () {
      // Week 1: 1 - 7
      const week1 = DateFilter(type: DateFilterType.weekly, weekIndex: 1);
      expect(week1.isActive, isTrue);
      expect(week1.matches(DateTime(2026, 11, 1)), isTrue);
      expect(week1.matches(DateTime(2026, 11, 7)), isTrue);
      expect(week1.matches(DateTime(2026, 11, 8)), isFalse);

      // Week 2: 8 - 14
      const week2 = DateFilter(type: DateFilterType.weekly, weekIndex: 2);
      expect(week2.matches(DateTime(2026, 11, 7)), isFalse);
      expect(week2.matches(DateTime(2026, 11, 8)), isTrue);
      expect(week2.matches(DateTime(2026, 11, 14)), isTrue);
      expect(week2.matches(DateTime(2026, 11, 15)), isFalse);

      // Week 5: 29 - end of month
      const week5 = DateFilter(type: DateFilterType.weekly, weekIndex: 5);
      expect(week5.matches(DateTime(2026, 11, 28)), isFalse);
      expect(week5.matches(DateTime(2026, 11, 29)), isTrue);
      expect(week5.matches(DateTime(2026, 11, 30)), isTrue);
    });

    test('Specific date DateFilter matches only the exact calendar date', () {
      final specific = DateFilter(
        type: DateFilterType.specificDate,
        specificDate: DateTime(2026, 11, 23, 14, 30),
      );
      expect(specific.isActive, isTrue);
      expect(specific.matches(DateTime(2026, 11, 23, 8, 0)), isTrue);
      expect(specific.matches(DateTime(2026, 11, 23, 23, 59)), isTrue);
      expect(specific.matches(DateTime(2026, 11, 22)), isFalse);
      expect(specific.matches(DateTime(2026, 11, 24)), isFalse);
    });

    test('getLabel produces accurate human readable Indonesian strings', () {
      const allMonth = DateFilter();
      expect(allMonth.getLabel(2026, 11), 'Sebulan Penuh');

      const week2 = DateFilter(type: DateFilterType.weekly, weekIndex: 2);
      expect(week2.getLabel(2026, 11), 'Minggu 2 (Tgl 8-14)');

      final specific = DateFilter(
        type: DateFilterType.specificDate,
        specificDate: DateTime(2026, 11, 23),
      );
      expect(specific.getLabel(2026, 11), contains('23 Nov'));
    });
  });
}
