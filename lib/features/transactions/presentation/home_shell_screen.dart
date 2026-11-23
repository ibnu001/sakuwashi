import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/minimal_bottom_nav.dart';
import '../../settings/settings_screen.dart';
import 'expense_list_view.dart';
import 'income_list_view.dart';
import 'summary_view.dart';
import 'transaction_form_sheet.dart';

/// Shell scaffold hosting the pill-dock bottom nav and all 4 views.
class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  late int _currentIndex;
  bool _initialFormShown = false;

  @override
  void initState() {
    super.initState();
    final startup = ref.read(themeControllerProvider).startupScreen;
    // For startup=99 (form), default to tab 0 (expense)
    _currentIndex = startup == 99 ? 0 : startup;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show the form sheet on first build if startup == 99
    if (!_initialFormShown) {
      _initialFormShown = true;
      final startup = ref.read(themeControllerProvider).startupScreen;
      if (startup == 99) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openForm();
        });
      }
    }
  }

  void _openForm() {
    final defaultType = _currentIndex == 1 ? 'income' : 'expense';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(defaultType: defaultType),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const ExpenseListView();
      case 1:
        return const IncomeListView();
      case 3:
        return const SummaryView();
      case 4:
        return const SettingsScreen();
      default:
        return const ExpenseListView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: MinimalBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: (i) => setState(() => _currentIndex = i),
        onCenterTap: _openForm,
      ),
    );
  }
}
