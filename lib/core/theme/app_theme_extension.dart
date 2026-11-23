import 'package:flutter/material.dart';

/// Semantic color extension for expense / income indicators.
/// Widgets MUST reference this instead of hardcoding colors.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color expenseColor;
  final Color incomeColor;

  /// Auto-generated low-opacity container tints for badges / pills.
  Color get expenseContainer => expenseColor.withValues(alpha: 0.12);
  Color get incomeContainer => incomeColor.withValues(alpha: 0.12);

  const AppColorsExtension({
    required this.expenseColor,
    required this.incomeColor,
  });

  @override
  AppColorsExtension copyWith({Color? expenseColor, Color? incomeColor}) {
    return AppColorsExtension(
      expenseColor: expenseColor ?? this.expenseColor,
      incomeColor: incomeColor ?? this.incomeColor,
    );
  }

  @override
  AppColorsExtension lerp(
      covariant ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
    );
  }
}
