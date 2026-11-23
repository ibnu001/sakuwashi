import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../transactions/data/transaction_db.dart';
import '../transactions/data/transaction_model.dart';

/// Handles CSV export, import, and sharing of transaction data.
class CsvService {
  CsvService._();

  static const _headers = [
    'id',
    'tanggal',
    'tipe',
    'kategori',
    'nominal',
    'catatan'
  ];

  /// Generate CSV string from all transactions.
  static Future<String> generateCSVString(
      {List<TransactionModel>? transactions}) async {
    final txns = transactions ?? await TransactionDb.getAll();
    final rows = <List<dynamic>>[_headers];
    for (final t in txns) {
      rows.add([
        t.id ?? '',
        DateFormat('yyyy-MM-dd').format(t.date),
        t.type,
        t.category,
        t.amount,
        t.note,
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  /// Export CSV to a file in the app's documents directory and return the path.
  static Future<String> exportToFile() async {
    final csv = await generateCSVString();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/sakuwashi_$timestamp.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Share CSV via system share dialog.
  static Future<void> shareCSV() async {
    final csv = await generateCSVString();
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/sakuwashi_$timestamp.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Sakuwashi - Data Transaksi',
    );
  }

  /// Import transactions from a CSV string into SQLite.
  /// Returns the count of imported records.
  static Future<int> importFromCSVString(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) return 0;

    // Skip header row
    final dataRows = rows.skip(1);
    final txns = <TransactionModel>[];

    for (final row in dataRows) {
      if (row.length < 5) continue;
      try {
        txns.add(TransactionModel(
          type: row[2].toString(),
          amount: int.tryParse(row[4].toString()) ?? 0,
          category: row[3].toString(),
          note: row.length > 5 ? row[5].toString() : '',
          date: DateTime.parse(row[1].toString()),
        ));
      } catch (_) {
        // Skip malformed rows
        continue;
      }
    }

    if (txns.isEmpty) return 0;
    return TransactionDb.bulkInsert(txns);
  }
}
