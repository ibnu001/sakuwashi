import 'package:intl/intl.dart';

/// Formats numbers as Indonesian Rupiah (Rp 150.000).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _fmtCompact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Full format: Rp 1.500.000
  static String format(num value) => _fmt.format(value);

  /// Compact: Rp 1,5 jt
  static String formatCompact(num value) => _fmtCompact.format(value);

  /// Parse a formatted IDR string back to a number.
  static num? tryParse(String text) {
    try {
      final cleaned = text
          .replaceAll('Rp', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      return num.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}
