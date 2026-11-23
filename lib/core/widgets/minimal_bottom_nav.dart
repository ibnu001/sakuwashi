import 'package:flutter/material.dart';
import '../constants/app_color_defaults.dart';
import '../theme/app_theme_extension.dart';

/// 5-slot pill-dock bottom navigation bar.
/// Slot 2 (center) is an elevated circular action button that opens a callback
/// without switching tabs.
class MinimalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterTap;

  const MinimalBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final isLight = brightness == Brightness.light;

    final navSurface = Color(
        isLight ? AppColorDefaults.navSurfaceLight : AppColorDefaults.navSurfaceDark);
    final pillBg = Color(
        isLight ? AppColorDefaults.navPillLight : AppColorDefaults.navPillDark);
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: navSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavSlot(
                icon: Icons.arrow_upward_rounded,
                label: 'Pengeluaran',
                isActive: currentIndex == 0,
                activeColor: appColors.expenseColor,
                inactiveColor: inactiveColor,
                onTap: () => onTabSelected(0),
              ),
              _NavSlot(
                icon: Icons.arrow_downward_rounded,
                label: 'Pemasukan',
                isActive: currentIndex == 1,
                activeColor: appColors.incomeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTabSelected(1),
              ),
              _CenterAction(
                onTap: onCenterTap,
                accentColor: Theme.of(context).colorScheme.primary,
              ),
              _NavSlot(
                icon: Icons.bar_chart_rounded,
                label: 'Ringkasan',
                isActive: currentIndex == 3,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: inactiveColor,
                onTap: () => onTabSelected(3),
              ),
              _NavSlot(
                icon: Icons.settings_outlined,
                label: 'Pengaturan',
                isActive: currentIndex == 4,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: inactiveColor,
                onTap: () => onTabSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavSlot({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const _CenterAction({required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor,
              accentColor.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isLight ? Colors.white : Colors.white24,
            width: 2,
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
