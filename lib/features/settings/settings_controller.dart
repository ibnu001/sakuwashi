import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages settings-specific state (Google Drive info, etc.).
class SettingsState {
  final String? googleEmail;
  final String? lastBackupTime;
  final bool isBackingUp;
  final bool isRestoring;
  final bool useDynamicPaydayCycle;

  const SettingsState({
    this.googleEmail,
    this.lastBackupTime,
    this.isBackingUp = false,
    this.isRestoring = false,
    this.useDynamicPaydayCycle = false,
  });

  SettingsState copyWith({
    String? googleEmail,
    String? lastBackupTime,
    bool? isBackingUp,
    bool? isRestoring,
    bool? useDynamicPaydayCycle,
    bool clearEmail = false,
  }) {
    return SettingsState(
      googleEmail: clearEmail ? null : (googleEmail ?? this.googleEmail),
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      useDynamicPaydayCycle:
          useDynamicPaydayCycle ?? this.useDynamicPaydayCycle,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      googleEmail: prefs.getString('google_email'),
      lastBackupTime: prefs.getString('last_backup_time'),
      useDynamicPaydayCycle:
          prefs.getBool('use_dynamic_payday_cycle') ?? false,
    );
  }

  Future<void> setGoogleEmail(String? email) async {
    state = state.copyWith(googleEmail: email, clearEmail: email == null);
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString('google_email', email);
    } else {
      await prefs.remove('google_email');
    }
  }

  Future<void> setLastBackupTime(String time) async {
    state = state.copyWith(lastBackupTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_backup_time', time);
  }

  void setBackingUp(bool v) => state = state.copyWith(isBackingUp: v);
  void setRestoring(bool v) => state = state.copyWith(isRestoring: v);

  Future<void> setUseDynamicPaydayCycle(bool v) async {
    state = state.copyWith(useDynamicPaydayCycle: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_dynamic_payday_cycle', v);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
