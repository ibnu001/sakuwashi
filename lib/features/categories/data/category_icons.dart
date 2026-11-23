import 'package:flutter/material.dart';

/// Centralized repository of static Material Icons for categories.
/// Ensures 100% AOT tree-shaking compatibility for release builds.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> iconMap = {
    // ── Expense Defaults ─────────────────────────────────
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'receipt_long': Icons.receipt_long,
    'shopping_bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'more_horiz': Icons.more_horiz,

    // ── Income Defaults ──────────────────────────────────
    'account_balance_wallet': Icons.account_balance_wallet,
    'work': Icons.work,
    'card_giftcard': Icons.card_giftcard,
    'trending_up': Icons.trending_up,

    // ── Curated Common Categories ────────────────────────
    'fastfood': Icons.fastfood,
    'local_cafe': Icons.local_cafe,
    'shopping_cart': Icons.shopping_cart,
    'local_gas_station': Icons.local_gas_station,
    'two_wheeler': Icons.two_wheeler,
    'flight': Icons.flight,
    'home': Icons.home,
    'school': Icons.school,
    'fitness_center': Icons.fitness_center,
    'pets': Icons.pets,
    'sports_esports': Icons.sports_esports,
    'phone_android': Icons.phone_android,
    'healing': Icons.healing,
    'checkroom': Icons.checkroom,
    'savings': Icons.savings,
    'paid': Icons.paid,
    'payments': Icons.payments,
    'attach_money': Icons.attach_money,
    'child_care': Icons.child_care,
    'build': Icons.build,
    'electric_bolt': Icons.electric_bolt,
    'brush': Icons.brush,
    'coffee': Icons.coffee,
    'celebration': Icons.celebration,
  };

  /// Returns the corresponding [IconData] or fallback to [Icons.more_horiz].
  static IconData getIcon(String? key) {
    if (key == null) return Icons.more_horiz;
    return iconMap[key] ?? Icons.more_horiz;
  }
}
