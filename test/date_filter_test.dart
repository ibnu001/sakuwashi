import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakuwashi/features/transactions/providers/transaction_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('DateFilter Unit Tests', () {
    test('Default DateFilter is inactive and represents Periode Aktif', () {
      const filter = DateFilter();
      expect(filter.isActive, isFalse);
      expect(filter.isIndependentRange, isFalse);
      expect(filter.getLabel(), 'Periode Aktif');
      expect(filter.getIndependentRange(), isNull);
    });

    test('Month & Year filter builds exact calendar month bounds', () {
      const filter = DateFilter(
        type: DateFilterType.monthYear,
        filterYear: 2026,
        filterMonth: 11,
      );
      expect(filter.isActive, isTrue);
      expect(filter.isIndependentRange, isTrue);
      expect(filter.getLabel(), 'November 2026');

      final range = filter.getIndependentRange();
      expect(range, isNotNull);
      expect(range!.$1, DateTime(2026, 11, 1));
      expect(range.$2, DateTime(2026, 12, 1));
    });

    test('Full Year filter builds exact calendar year bounds', () {
      const filter = DateFilter(
        type: DateFilterType.fullYear,
        filterYear: 2026,
      );
      expect(filter.isActive, isTrue);
      expect(filter.isIndependentRange, isTrue);
      expect(filter.getLabel(), 'Tahun 2026');

      final range = filter.getIndependentRange();
      expect(range, isNotNull);
      expect(range!.$1, DateTime(2026, 1, 1));
      expect(range.$2, DateTime(2027, 1, 1));
    });

    test('Custom Range filter covers start 00:00:00 through end 23:59:59.999',
        () {
      final filter = DateFilter(
        type: DateFilterType.customRange,
        rangeStart: DateTime(2026, 11, 10, 14, 30),
        rangeEnd: DateTime(2026, 11, 26, 9, 15),
      );
      expect(filter.isActive, isTrue);
      expect(filter.isIndependentRange, isTrue);
      expect(filter.getLabel(), '10 Nov – 26 Nov 2026');

      final range = filter.getIndependentRange();
      expect(range, isNotNull);
      expect(range!.$1, DateTime(2026, 11, 10, 0, 0, 0));
      // Exclusive upper bound is 00:00:00 the next day
      expect(range.$2, DateTime(2026, 11, 27, 0, 0, 0));
    });

    test('Single-day Custom Range formats as single date', () {
      final filter = DateFilter(
        type: DateFilterType.customRange,
        rangeStart: DateTime(2026, 11, 26),
        rangeEnd: DateTime(2026, 11, 26),
      );
      expect(filter.getLabel(), '26 Nov 2026');

      final range = filter.getIndependentRange()!;
      expect(range.$1, DateTime(2026, 11, 26));
      expect(range.$2, DateTime(2026, 11, 27));
    });
  });
}
