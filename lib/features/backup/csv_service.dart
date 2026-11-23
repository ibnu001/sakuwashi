import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
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
    'catatan',
  ];

  /// Generate CSV string from all transactions.
  static Future<String> generateCSVString({
    List<TransactionModel>? transactions,
  }) async {
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

  /// Prompts the user to pick a folder/destination via the device's native
  /// file explorer (Storage Access Framework), writes the CSV file, and returns
  /// the saved path. Returns null if the user cancelled the picker.
  static Future<String?> exportWithSystemFilePicker() async {
    final csv = await generateCSVString();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'sakuwashi_transaksi_$timestamp.csv';
    final bytes = Uint8List.fromList(utf8.encode(csv));

    // 1. Primary approach: Native system "Save As" document picker
    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Pilih Lokasi untuk Menyimpan CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (savedPath != null) return savedPath;
    } catch (_) {
      // Fallback if saveFile is unavailable
    }

    // 2. Secondary approach: Let user select a destination directory
    try {
      final selectedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Folder untuk Menyimpan CSV',
      );
      if (selectedDir != null) {
        final file = File('$selectedDir/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      }
      return null;
    } catch (_) {
      // 3. Fallback to device's public Downloads directory
      final downloadsDir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  }

  /// Legacy internal export helper.
  static Future<String> exportToFile() async {
    final pickedPath = await exportWithSystemFilePicker();
    if (pickedPath != null) return pickedPath;

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

    final now = DateTime.now();
    final fileTimestamp = DateFormat('yyyyMMdd_HHmm').format(now);
    final readableDate = DateFormat('dd-MMM-yyyy_HH-mm').format(now);

    final file = File('${dir.path}/sakuwashi_$fileTimestamp.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/csv'),
    ], subject: 'sakuwashi_transaksi_$readableDate.csv');
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
        txns.add(
          TransactionModel(
            type: row[2].toString(),
            amount: int.tryParse(row[4].toString()) ?? 0,
            category: row[3].toString(),
            note: row.length > 5 ? row[5].toString() : '',
            date: DateTime.parse(row[1].toString()),
          ),
        );
      } catch (_) {
        // Skip malformed rows
        continue;
      }
    }

    if (txns.isEmpty) return 0;
    return TransactionDb.bulkInsert(txns);
  }
}
