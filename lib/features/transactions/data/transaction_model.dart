import 'package:flutter/material.dart';
import '../../categories/data/category_icons.dart';

/// Represents a single financial transaction (expense or income).
class TransactionModel {
  final int? id;
  final String type; // 'expense' | 'income'
  final int amount;
  final String category;
  final String note;
  final DateTime date;

  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'type': type,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: map['amount'] as int,
      category: map['category'] as String,
      note: (map['note'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
    );
  }

  TransactionModel copyWith({
    int? id,
    String? type,
    int? amount,
    String? category,
    String? note,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  // ── Predefined categories ──────────────────────────────────
  static const List<String> expenseCategories = [
    'Makan & Minum',
    'Transportasi',
    'Tagihan',
    'Belanja',
    'Hiburan',
    'Lainnya',
  ];

  static const List<String> incomeCategories = [
    'Gaji',
    'Freelance',
    'Bonus',
    'Investasi',
    'Lainnya',
  ];

  static IconData iconFor(String category) {
    return _categoryIcons[category] ?? CategoryIcons.getIcon(category);
  }
}

const Map<String, IconData> _categoryIcons = {
  'Makan & Minum': Icons.restaurant,
  'Transportasi': Icons.directions_car,
  'Tagihan': Icons.receipt_long,
  'Belanja': Icons.shopping_bag,
  'Hiburan': Icons.movie,
  'Gaji': Icons.account_balance_wallet,
  'Freelance': Icons.work,
  'Bonus': Icons.card_giftcard,
  'Investasi': Icons.trending_up,
  'Lainnya': Icons.more_horiz,
};
