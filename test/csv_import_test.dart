import 'package:flutter_test/flutter_test.dart';
import 'package:sakuwashi/features/backup/csv_service.dart';

void main() {
  group('CsvService.parseCSV Tests', () {
    test('Parses Sakuwashi standard exported CSV correctly', () {
      const csv = '''id,tanggal,tipe,kategori,nominal,catatan
1,2026-11-20,expense,Makan & Minum,25000,Makan siang
2,2026-11-21,income,Gaji,5000000,Gaji bulan November
''';

      final result = CsvService.parseCSV(csv);
      expect(result.totalRows, 2);
      expect(result.transactions.length, 2);

      final t1 = result.transactions[0];
      expect(t1.type, 'expense');
      expect(t1.category, 'Makan & Minum');
      expect(t1.amount, 25000);
      expect(t1.note, 'Makan siang');
      expect(t1.date.year, 2026);
      expect(t1.date.month, 11);
      expect(t1.date.day, 20);

      final t2 = result.transactions[1];
      expect(t2.type, 'income');
      expect(t2.category, 'Gaji');
      expect(t2.amount, 5000000);
      expect(t2.note, 'Gaji bulan November');

      expect(result.expenseCount, 1);
      expect(result.incomeCount, 1);
      expect(result.totalExpenseAmount, 25000);
      expect(result.totalIncomeAmount, 5000000);
    });

    test('Parses CSV with semicolon delimiter and formatted currency', () {
      const csv = '''tanggal;tipe;kategori;nominal;catatan
20/11/2026;pengeluaran;Transportasi;Rp 15.000;Bensin motor
21/11/2026;pemasukan;Freelance;1.500.000,00;Desain logo
''';

      final result = CsvService.parseCSV(csv);
      expect(result.transactions.length, 2);

      final t1 = result.transactions[0];
      expect(t1.type, 'expense');
      expect(t1.category, 'Transportasi');
      expect(t1.amount, 15000);
      expect(t1.note, 'Bensin motor');

      final t2 = result.transactions[1];
      expect(t2.type, 'income');
      expect(t2.category, 'Freelance');
      expect(t2.amount, 1500000);
      expect(t2.note, 'Desain logo');
    });

    test('Parses English headers flexibly', () {
      const csv = '''Date,Type,Category,Amount,Note
2026-10-15,Expense,Groceries,75000,Supermarket
2026-10-16,Income,Bonus,250000,Year end bonus
''';

      final result = CsvService.parseCSV(csv);
      expect(result.transactions.length, 2);
      expect(result.transactions[0].category, 'Groceries');
      expect(result.transactions[0].amount, 75000);
      expect(result.transactions[1].category, 'Bonus');
      expect(result.transactions[1].amount, 250000);
    });

    test('Handles malformed or empty rows gracefully', () {
      const csv = '''tanggal,tipe,kategori,nominal,catatan
2026-11-20,expense,Makan,0,Gratis
invalid row content
2026-11-22,income,Hadiah,100000,Ulang tahun
''';

      final result = CsvService.parseCSV(csv);
      // Row 1 has amount 0 (skipped), row 2 invalid, row 3 valid
      expect(result.transactions.length, 1);
      expect(result.transactions[0].category, 'Hadiah');
      expect(result.transactions[0].amount, 100000);
      expect(result.warnings.length, greaterThanOrEqualTo(1));
    });

    test('Handles empty CSV content', () {
      final result = CsvService.parseCSV('');
      expect(result.totalRows, 0);
      expect(result.transactions, isEmpty);
    });
  });
}
