import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_color_defaults.dart';
import 'app_theme_extension.dart';

/// Builds light and dark [ThemeData] with Material 3 and semantic color extensions.
class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(TextTheme base) {
    final fontTheme = GoogleFonts.plusJakartaSansTextTheme(base);
    const tabular = [FontFeature.tabularFigures()];
    return fontTheme.copyWith(
      displayLarge: fontTheme.displayLarge?.copyWith(fontFeatures: tabular),
      displayMedium: fontTheme.displayMedium?.copyWith(fontFeatures: tabular),
      displaySmall: fontTheme.displaySmall?.copyWith(fontFeatures: tabular),
      headlineLarge: fontTheme.headlineLarge?.copyWith(fontFeatures: tabular),
      headlineMedium: fontTheme.headlineMedium?.copyWith(fontFeatures: tabular),
      headlineSmall: fontTheme.headlineSmall?.copyWith(fontFeatures: tabular),
      titleLarge: fontTheme.titleLarge?.copyWith(fontFeatures: tabular),
      titleMedium: fontTheme.titleMedium?.copyWith(fontFeatures: tabular),
      titleSmall: fontTheme.titleSmall?.copyWith(fontFeatures: tabular),
      bodyLarge: fontTheme.bodyLarge?.copyWith(fontFeatures: tabular),
      bodyMedium: fontTheme.bodyMedium?.copyWith(fontFeatures: tabular),
      bodySmall: fontTheme.bodySmall?.copyWith(fontFeatures: tabular),
      labelLarge: fontTheme.labelLarge?.copyWith(fontFeatures: tabular),
      labelMedium: fontTheme.labelMedium?.copyWith(fontFeatures: tabular),
      labelSmall: fontTheme.labelSmall?.copyWith(fontFeatures: tabular),
    );
  }

  static ThemeData light({
    Color? expenseOverride,
    Color? incomeOverride,
    Color? accentOverride,
  }) {
    final expense =
        expenseOverride ?? const Color(AppColorDefaults.defaultExpenseLight);
    final income =
        incomeOverride ?? const Color(AppColorDefaults.defaultIncomeLight);
    final accent =
        accentOverride ?? const Color(AppColorDefaults.defaultPrimaryLight);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: const Color(AppColorDefaults.surfaceLight),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
      scaffoldBackgroundColor: const Color(AppColorDefaults.surfaceLight),
      dividerColor: colorScheme.outlineVariant,
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: accent,
        headerForegroundColor: Colors.white,
      ),
      extensions: [
        AppColorsExtension(expenseColor: expense, incomeColor: income),
      ],
    );
  }

  static ThemeData dark({
    Color? expenseOverride,
    Color? incomeOverride,
    Color? accentOverride,
  }) {
    final expense =
        expenseOverride ?? const Color(AppColorDefaults.defaultExpenseDark);
    final income =
        incomeOverride ?? const Color(AppColorDefaults.defaultIncomeDark);
    final accent =
        accentOverride ?? const Color(AppColorDefaults.defaultPrimaryDark);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: const Color(AppColorDefaults.surfaceDark),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(AppColorDefaults.surfaceDark),
      dividerColor: colorScheme.outlineVariant,
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: const Color(0xFF262626),
        headerForegroundColor: Colors.white,
      ),
      extensions: [
        AppColorsExtension(expenseColor: expense, incomeColor: income),
      ],
    );
  }
}
