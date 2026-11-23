import 'dart:ui';

/// Single source of truth for all default color hex values.
/// Changing any value here automatically propagates across the entire app.
class AppColorDefaults {
  AppColorDefaults._();

  // ── Primary ──────────────────────────────────────────────
  static const int defaultPrimaryLight = 0xFF1E293B;
  static const int defaultPrimaryDark = 0xFFF8FAFC;

  // ── Expense (Rose / Coral-Rose) ──────────────────────────
  static const int defaultExpenseLight = 0xFFE11D48;
  static const int defaultExpenseDark = 0xFFFB7185;

  // ── Income (Emerald / Mint-Emerald) ──────────────────────
  static const int defaultIncomeLight = 0xFF059669;
  static const int defaultIncomeDark = 0xFF34D399;

  // ── Surface & Background ─────────────────────────────────
  static const int surfaceLight = 0xFFFAFAFA;
  static const int surfaceDark = 0xFF121212;

  static const int navSurfaceLight = 0xFFFFFFFF;
  static const int navSurfaceDark = 0xFF1A1A1A;

  static const int navPillLight = 0xFFF4F4F5;
  static const int navPillDark = 0xFF262626;

  // ── Helpers ──────────────────────────────────────────────
  static Color colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static String hexFromColor(Color color) {
    // ignore: deprecated_member_use
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
