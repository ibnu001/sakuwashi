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

/// Scope for CSV export.
enum CsvExportScope {
  monthly,
  yearly,
  all,
}

/// Result summary of parsing a CSV file before importing.
class CsvImportResult {
  final int totalRows;
  final List<TransactionModel> transactions;
  final List<String> warnings;

  const CsvImportResult({
    required this.totalRows,
    required this.transactions,
    this.warnings = const [],
  });

  int get expenseCount => transactions.where((t) => t.type == 'expense').length;
  int get incomeCount => transactions.where((t) => t.type == 'income').length;
  int get totalExpenseAmount => transactions
      .where((t) => t.type == 'expense')
      .fold<int>(0, (sum, t) => sum + t.amount);
  int get totalIncomeAmount => transactions
      .where((t) => t.type == 'income')
      .fold<int>(0, (sum, t) => sum + t.amount);
}

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

  /// Generate CSV string from transactions (optionally scoped).
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

  /// Fetch transactions for a given export scope.
  static Future<List<TransactionModel>> fetchForScope({
    required CsvExportScope scope,
    int? year,
    int? month,
  }) async {
    switch (scope) {
      case CsvExportScope.monthly:
        if (year == null || month == null) return [];
        return TransactionDb.getByDateRange(
          DateTime(year, month, 1),
          DateTime(year, month + 1, 1),
        );
      case CsvExportScope.yearly:
        if (year == null) return [];
        return TransactionDb.getByYear(year);
      case CsvExportScope.all:
        return TransactionDb.getAll();
    }
  }

  /// Generate the filename for a given scope.
  static String generateFileName({
    required CsvExportScope scope,
    int? year,
    int? month,
  }) {
    final now = DateTime.now();
    final timestamp = DateFormat('dd-MMM-yyyy_HH-mm').format(now);
    switch (scope) {
      case CsvExportScope.monthly:
        final monthStr = month != null
            ? DateFormat('MMM-yyyy').format(DateTime(year ?? now.year, month))
            : 'Unknown';
        return 'SakuWashi_${monthStr}_$timestamp.csv';
      case CsvExportScope.yearly:
        return 'SakuWashi_${year ?? now.year}_$timestamp.csv';
      case CsvExportScope.all:
        return 'SakuWashi_All_$timestamp.csv';
    }
  }

  /// Count transactions for a given scope.
  static Future<int> countForScope({
    required CsvExportScope scope,
    int? year,
    int? month,
  }) async {
    switch (scope) {
      case CsvExportScope.monthly:
        if (year == null || month == null) return 0;
        return TransactionDb.countByDateRange(
          DateTime(year, month, 1),
          DateTime(year, month + 1, 1),
        );
      case CsvExportScope.yearly:
        if (year == null) return 0;
        return TransactionDb.countByDateRange(
          DateTime(year, 1, 1),
          DateTime(year + 1, 1, 1),
        );
      case CsvExportScope.all:
        return TransactionDb.countAll();
    }
  }

  /// Export with system file picker, scoped.
  static Future<String?> exportWithSystemFilePicker({
    CsvExportScope scope = CsvExportScope.all,
    int? year,
    int? month,
  }) async {
    final txns = await fetchForScope(scope: scope, year: year, month: month);
    final csv = await generateCSVString(transactions: txns);
    final fileName = generateFileName(scope: scope, year: year, month: month);
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

  /// Share CSV via system share dialog, scoped.
  static Future<void> shareCSV({
    CsvExportScope scope = CsvExportScope.all,
    int? year,
    int? month,
  }) async {
    final txns = await fetchForScope(scope: scope, year: year, month: month);
    final csv = await generateCSVString(transactions: txns);
    final dir = await getTemporaryDirectory();

    final fileName = generateFileName(scope: scope, year: year, month: month);
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/csv'),
    ], subject: fileName);
  }

  /// Prompts the user to pick a CSV file from device storage.
  /// Reads both memory bytes (SAF) or file path with UTF-8 / latin1 fallbacks.
  static Future<String?> pickCSVFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;

    // Check direct memory bytes
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      try {
        return utf8.decode(file.bytes!);
      } catch (_) {
        return latin1.decode(file.bytes!);
      }
    }

    // Check file system path
    if (file.path != null) {
      final ioFile = File(file.path!);
      final bytes = await ioFile.readAsBytes();
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return latin1.decode(bytes);
      }
    }

    return null;
  }

  /// Parses CSV content into a [CsvImportResult] without saving to the database.
  /// Supports various delimiters (comma, semicolon, tab), flexible column headers
  /// in Indonesian & English, and multiple date/currency formats.
  static CsvImportResult parseCSV(String csvContent) {
    if (csvContent.trim().isEmpty) {
      return const CsvImportResult(totalRows: 0, transactions: []);
    }

    final cleanContent = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    final firstLine = cleanContent.split('\n').first;
    final commaCount = ','.allMatches(firstLine).length;
    final semicolonCount = ';'.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;

    String fieldDelimiter = ',';
    if (semicolonCount > commaCount && semicolonCount > tabCount) {
      fieldDelimiter = ';';
    } else if (tabCount > commaCount && tabCount > semicolonCount) {
      fieldDelimiter = '\t';
    }

    final converter = CsvToListConverter(
      fieldDelimiter: fieldDelimiter,
      eol: '\n',
      shouldParseNumbers: false,
    );

    final rawRows = converter.convert(cleanContent);
    if (rawRows.isEmpty) {
      return const CsvImportResult(totalRows: 0, transactions: []);
    }

    int dateCol = -1;
    int typeCol = -1;
    int categoryCol = -1;
    int amountCol = -1;
    int noteCol = -1;
    int idCol = -1;

    final firstRow = rawRows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    bool hasHeader = false;

    for (int i = 0; i < firstRow.length; i++) {
      final h = firstRow[i];
      if (h == 'id' || h == 'no' || h.contains('transaksi_id')) {
        idCol = i;
        hasHeader = true;
      } else if (h.contains('tgl') ||
          h.contains('tanggal') ||
          h.contains('date') ||
          h.contains('waktu')) {
        dateCol = i;
        hasHeader = true;
      } else if (h == 'tipe' || h == 'type' || h == 'jenis') {
        typeCol = i;
        hasHeader = true;
      } else if (h.contains('kategori') || h.contains('category')) {
        categoryCol = i;
        hasHeader = true;
      } else if (h.contains('nominal') ||
          h.contains('amount') ||
          h.contains('jumlah') ||
          h.contains('total') ||
          h.contains('biaya')) {
        amountCol = i;
        hasHeader = true;
      } else if (h.contains('catatan') ||
          h.contains('note') ||
          h.contains('keterangan') ||
          h.contains('deskripsi') ||
          h.contains('memo')) {
        noteCol = i;
        hasHeader = true;
      }
    }

    final dataRows = hasHeader ? rawRows.skip(1).toList() : rawRows;
    if (!hasHeader) {
      if (rawRows.first.length >= 6) {
        idCol = 0;
        dateCol = 1;
        typeCol = 2;
        categoryCol = 3;
        amountCol = 4;
        noteCol = 5;
      } else if (rawRows.first.length >= 5) {
        dateCol = 0;
        typeCol = 1;
        categoryCol = 2;
        amountCol = 3;
        noteCol = 4;
      } else if (rawRows.first.length >= 4) {
        dateCol = 0;
        categoryCol = 1;
        amountCol = 2;
        noteCol = 3;
      }
    } else {
      if (dateCol == -1 && firstRow.length > 1) dateCol = 1;
      if (typeCol == -1 && firstRow.length > 2) typeCol = 2;
      if (categoryCol == -1 && firstRow.length > 3) categoryCol = 3;
      if (amountCol == -1 && firstRow.length > 4) amountCol = 4;
      if (noteCol == -1 && firstRow.length > 5) noteCol = 5;
    }

    final txns = <TransactionModel>[];
    final warnings = <String>[];

    for (int r = 0; r < dataRows.length; r++) {
      final row = dataRows[r];
      if (row.isEmpty ||
          (row.length == 1 && row[0].toString().trim().isEmpty)) {
        continue;
      }

      try {
        // Date parsing
        final dateStr = (dateCol >= 0 && dateCol < row.length)
            ? row[dateCol].toString().trim()
            : '';
        final parsedDate = _parseDate(dateStr) ?? DateTime.now();

        // Type parsing
        final rawType = (typeCol >= 0 && typeCol < row.length)
            ? row[typeCol].toString().trim().toLowerCase()
            : '';
        String parsedType = 'expense';
        if (rawType.contains('in') ||
            rawType.contains('masuk') ||
            rawType.contains('kredit') ||
            rawType.contains('credit') ||
            rawType == '+') {
          parsedType = 'income';
        } else {
          parsedType = 'expense';
        }

        // Category parsing
        String parsedCat = (categoryCol >= 0 && categoryCol < row.length)
            ? row[categoryCol].toString().trim()
            : '';
        if (parsedCat.isEmpty) {
          parsedCat = 'Lainnya';
        }

        // Amount parsing
        final rawAmount = (amountCol >= 0 && amountCol < row.length)
            ? row[amountCol]
            : 0;
        final parsedAmount = _parseAmount(rawAmount);

        // Note parsing
        final parsedNote = (noteCol >= 0 && noteCol < row.length)
            ? row[noteCol].toString().trim()
            : '';

        // ID parsing (if present)
        int? parsedId;
        if (idCol >= 0 && idCol < row.length) {
          parsedId = int.tryParse(row[idCol].toString().trim());
        }

        if (parsedAmount > 0) {
          txns.add(
            TransactionModel(
              id: parsedId,
              date: parsedDate,
              type: parsedType,
              category: parsedCat,
              amount: parsedAmount,
              note: parsedNote,
            ),
          );
        } else {
          warnings.add('Baris ${r + 1}: Nominal 0 atau tidak valid, dilewati.');
        }
      } catch (e) {
        warnings.add('Baris ${r + 1}: Gagal diproses ($e)');
      }
    }

    return CsvImportResult(
      totalRows: dataRows.length,
      transactions: txns,
      warnings: warnings,
    );
  }

  /// Executes database import of parsed transactions.
  /// If [replace] is true, deletes all existing transactions first.
  /// If [replace] is false, inserts them as new records (merging).
  /// Automatically registers any unknown categories to the categories table.
  static Future<int> executeImport({
    required List<TransactionModel> transactions,
    required bool replace,
  }) async {
    if (transactions.isEmpty) return 0;

    if (replace) {
      await TransactionDb.clearAll();
    }

    // Ensure all referenced categories exist in DB
    final seen = <String>{};
    for (final t in transactions) {
      final key = '${t.type}_${t.category.toLowerCase()}';
      if (!seen.contains(key)) {
        seen.add(key);
        await TransactionDb.ensureCategoryExists(t.category, t.type);
      }
    }

    // When merging, strip ID so SQLite auto-increments and avoids conflicts
    final prepared = transactions
        .map((t) => replace ? t : t.copyWith(id: null))
        .toList();

    return TransactionDb.bulkInsert(prepared);
  }

  /// Import transactions from a CSV string into SQLite (legacy convenience).
  /// Returns the count of imported records.
  static Future<int> importFromCSVString(String csvContent) async {
    final result = parseCSV(csvContent);
    if (result.transactions.isEmpty) return 0;
    return executeImport(transactions: result.transactions, replace: false);
  }

  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    final direct = DateTime.tryParse(dateStr);
    if (direct != null) return direct;

    final formats = [
      'yyyy/MM/dd',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'd/M/yyyy',
      'd-M-yyyy',
      'yyyy.MM.dd',
      'dd.MM.yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy/MM/dd HH:mm:ss',
      'dd/MM/yyyy HH:mm:ss',
    ];

    for (final f in formats) {
      try {
        return DateFormat(f).parseStrict(dateStr);
      } catch (_) {}
    }

    return null;
  }

  static int _parseAmount(dynamic val) {
    if (val is num) return val.abs().round();
    var s = val.toString().trim();
    if (s.isEmpty) return 0;

    // Remove negative signs, currency symbols, and spaces
    s = s.replaceAll(RegExp(r'[^\d,\.]'), '');
    if (s.isEmpty) return 0;

    if (s.contains(',') && s.contains('.')) {
      if (s.indexOf('.') < s.indexOf(',')) {
        // e.g. 150.000,00 -> 150000
        s = s.split(',')[0].replaceAll('.', '');
      } else {
        // e.g. 150,000.00 -> 150000
        s = s.split('.')[0].replaceAll(',', '');
      }
    } else if (s.contains(',')) {
      final parts = s.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Decimal comma: 150000,00
        s = parts[0];
      } else {
        // Thousands separator
        s = s.replaceAll(',', '');
      }
    } else if (s.contains('.')) {
      final parts = s.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Decimal dot: 150000.00
        s = parts[0];
      } else {
        // Thousands dot: 150.000
        s = s.replaceAll('.', '');
      }
    }

    return int.tryParse(s) ?? 0;
  }
}
