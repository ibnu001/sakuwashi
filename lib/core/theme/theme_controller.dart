import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Persisted keys ─────────────────────────────────────────
const _kThemeMode = 'theme_mode'; // 0=system, 1=light, 2=dark
const _kExpenseColor = 'expense_color';
const _kIncomeColor = 'income_color';
const _kAccentColor = 'accent_color';
const _kStartupScreen = 'startup_screen'; // 0,1,3,99

/// Holds all theme / preference state loaded from SharedPreferences.
class ThemeState {
  final ThemeMode themeMode;
  final Color? expenseOverride;
  final Color? incomeOverride;
  final Color? accentOverride;
  final int startupScreen; // 0=expense, 1=income, 3=summary, 99=form

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.expenseOverride,
    this.incomeOverride,
    this.accentOverride,
    this.startupScreen = 0,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? expenseOverride,
    Color? incomeOverride,
    Color? accentOverride,
    int? startupScreen,
    bool clearExpense = false,
    bool clearIncome = false,
    bool clearAccent = false,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      expenseOverride:
          clearExpense ? null : (expenseOverride ?? this.expenseOverride),
      incomeOverride:
          clearIncome ? null : (incomeOverride ?? this.incomeOverride),
      accentOverride:
          clearAccent ? null : (accentOverride ?? this.accentOverride),
      startupScreen: startupScreen ?? this.startupScreen,
    );
  }
}

/// Riverpod Notifier that manages theme state and SharedPreferences persistence.
class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() => const ThemeState();

  /// Load persisted values on startup.
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kThemeMode) ?? 0;
    final expenseVal = prefs.getInt(_kExpenseColor);
    final incomeVal = prefs.getInt(_kIncomeColor);
    final accentVal = prefs.getInt(_kAccentColor);
    final startup = prefs.getInt(_kStartupScreen) ?? 0;

    state = ThemeState(
      themeMode: ThemeMode.values[modeIndex],
      expenseOverride: expenseVal != null ? Color(expenseVal) : null,
      incomeOverride: incomeVal != null ? Color(incomeVal) : null,
      accentOverride: accentVal != null ? Color(accentVal) : null,
      startupScreen: startup,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setExpenseColor(Color color) async {
    state = state.copyWith(expenseOverride: color);
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt(_kExpenseColor, color.value);
  }

  Future<void> setIncomeColor(Color color) async {
    state = state.copyWith(incomeOverride: color);
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt(_kIncomeColor, color.value);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentOverride: color);
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt(_kAccentColor, color.value);
  }

  Future<void> setStartupScreen(int screenIndex) async {
    state = state.copyWith(startupScreen: screenIndex);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStartupScreen, screenIndex);
  }

  Future<void> resetColors() async {
    state = state.copyWith(
        clearExpense: true, clearIncome: true, clearAccent: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kExpenseColor);
    await prefs.remove(_kIncomeColor);
    await prefs.remove(_kAccentColor);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(ThemeController.new);
