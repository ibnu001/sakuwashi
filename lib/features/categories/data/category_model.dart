import 'package:flutter/material.dart';
import 'category_icons.dart';

/// Represents a transaction category (expense or income).
class CategoryModel {
  final int? id;
  final String name;
  final String type; // 'expense' | 'income'
  final String iconKey;
  final bool isDefault;
  final int sortOrder;

  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  IconData get icon => CategoryIcons.getIcon(iconKey);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'icon_key': iconKey,
        'is_default': isDefault ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      iconKey: map['icon_key'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      sortOrder: (map['sort_order'] as int? ?? 0),
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? type,
    String? iconKey,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
