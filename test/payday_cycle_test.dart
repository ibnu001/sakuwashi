import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakuwashi/features/backup/csv_service.dart';
import 'package:sakuwashi/features/transactions/services/payday_cycle_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('PaydayCycleService Tests', () {
    test('Empty gaji dates produces empty cycles', () {
      final cycles = PaydayCycleService.buildCyclesFromGajiDates([]);
      expect(cycles, isEmpty);
    });

    test('Groups same-day Gaji entries and calculates cycle boundaries', () {
      final cycles = PaydayCycleService.buildCyclesFromGajiDates([
        DateTime(2026, 10, 25, 9, 0),
        DateTime(2026, 10, 25, 17, 30), // same calendar day -> deduplicated
        DateTime(2026, 11, 26, 10, 0),
      ]);

      expect(cycles.length, 2);

      // Cycle 1: 25 Okt -> 26 Nov (day >= 20 => November 2026)
      expect(cycles[0].title, 'November 2026');
      expect(cycles[0].subtitle, '25 Okt – 25 Nov 2026');
      expect(cycles[0].startDate, DateTime(2026, 10, 25));
      expect(cycles[0].endDate, DateTime(2026, 11, 26));
      expect(cycles[0].isActive, isFalse);

      // Cycle 2: 26 Nov -> open-ended (day >= 20 => Desember 2026)
      expect(cycles[1].title, 'Desember 2026');
      expect(cycles[1].subtitle, '26 Nov 2026 – Sekarang');
      expect(cycles[1].startDate, DateTime(2026, 11, 26));
      expect(cycles[1].endDate, isNull);
      expect(cycles[1].isActive, isTrue);
    });

    test('Cycle starting before day 20 uses start date month name', () {
      final cycles = PaydayCycleService.buildCyclesFromGajiDates([
        DateTime(2026, 11, 5, 8, 0),
      ]);

      expect(cycles.length, 1);
      expect(cycles[0].title, 'November 2026');
      expect(cycles[0].subtitle, '5 Nov 2026 – Sekarang');
    });

    test('Cross-year cycle formats subtitle with years on both ends', () {
      final cycles = PaydayCycleService.buildCyclesFromGajiDates([
        DateTime(2025, 12, 26),
        DateTime(2026, 1, 25),
      ]);

      expect(cycles.length, 2);
      expect(cycles[0].title, 'Januari 2026');
      expect(cycles[0].subtitle, '26 Des 2025 – 24 Jan 2026');
    });

    test('Pre-Gaji transactions are grouped into calendar months', () {
      final cycles = PaydayCycleService.buildCyclesFromGajiDates(
        [DateTime(2026, 11, 26)],
        earliestPreGajiDate: DateTime(2026, 9, 12),
      );

      // Sep 2026, Okt 2026, Nov 1-25 2026, then Gaji cycle starting Nov 26
      expect(cycles.length, 4);

      expect(cycles[0].title, 'September 2026');
      expect(cycles[0].subtitle, isNull);
      expect(cycles[0].startDate, DateTime(2026, 9, 1));
      expect(cycles[0].endDate, DateTime(2026, 10, 1));

      expect(cycles[1].title, 'Oktober 2026');
      expect(cycles[1].subtitle, isNull);
      expect(cycles[1].startDate, DateTime(2026, 10, 1));
      expect(cycles[1].endDate, DateTime(2026, 11, 1));

      expect(cycles[2].title, 'November 2026');
      expect(cycles[2].subtitle, '1 Nov – 25 Nov 2026');
      expect(cycles[2].startDate, DateTime(2026, 11, 1));
      expect(cycles[2].endDate, DateTime(2026, 11, 26));

      expect(cycles[3].title, 'Desember 2026');
      expect(cycles[3].startDate, DateTime(2026, 11, 26));
      expect(cycles[3].endDate, isNull);
    });

    test('findCycleForDate and prev/next navigation work properly', () {
      final cycles = PaydayCycleService.buildCyclesFromGajiDates([
        DateTime(2026, 10, 25),
        DateTime(2026, 11, 26),
      ]);

      final foundNov =
          PaydayCycleService.findCycleForDate(cycles, DateTime(2026, 11, 10));
      expect(foundNov, cycles[0]);

      final foundDec =
          PaydayCycleService.findCycleForDate(cycles, DateTime(2026, 11, 26));
      expect(foundDec, cycles[1]);

      expect(PaydayCycleService.nextCycle(cycles, cycles[0]), cycles[1]);
      expect(PaydayCycleService.nextCycle(cycles, cycles[1]), isNull);
      expect(PaydayCycleService.prevCycle(cycles, cycles[1]), cycles[0]);
      expect(PaydayCycleService.prevCycle(cycles, cycles[0]), isNull);
    });
  });

  group('CsvService Scoped Filename Tests', () {
    test('Generates expected filename prefixes for monthly, yearly, and all',
        () {
      final monthly = CsvService.generateFileName(
        scope: CsvExportScope.monthly,
        year: 2026,
        month: 11,
      );
      expect(monthly, startsWith('SakuWashi_Nov-2026_'));
      expect(monthly, endsWith('.csv'));

      final yearly = CsvService.generateFileName(
        scope: CsvExportScope.yearly,
        year: 2026,
      );
      expect(yearly, startsWith('SakuWashi_2026_'));
      expect(yearly, endsWith('.csv'));

      final all = CsvService.generateFileName(scope: CsvExportScope.all);
      expect(all, startsWith('SakuWashi_All_'));
      expect(all, endsWith('.csv'));
    });
  });
}
