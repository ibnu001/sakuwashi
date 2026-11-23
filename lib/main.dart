import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/settings/settings_controller.dart';
import 'features/transactions/presentation/home_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(const ProviderScope(child: SakuwashiApp()));
}

class SakuwashiApp extends ConsumerStatefulWidget {
  const SakuwashiApp({super.key});

  @override
  ConsumerState<SakuwashiApp> createState() => _SakuwashiAppState();
}

class _SakuwashiAppState extends ConsumerState<SakuwashiApp> {
  @override
  void initState() {
    super.initState();
    // Load persisted preferences on startup.
    Future.microtask(() async {
      await ref.read(themeControllerProvider.notifier).loadFromPrefs();
      await ref.read(settingsControllerProvider.notifier).loadFromPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Sakuwashi',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeState.themeMode,
      theme: AppTheme.light(
        expenseOverride: themeState.expenseOverride,
        incomeOverride: themeState.incomeOverride,
        accentOverride: themeState.accentOverride,
      ),
      darkTheme: AppTheme.dark(
        expenseOverride: themeState.expenseOverride,
        incomeOverride: themeState.incomeOverride,
        accentOverride: themeState.accentOverride,
      ),
      home: const HomeShellScreen(),
    );
  }
}
