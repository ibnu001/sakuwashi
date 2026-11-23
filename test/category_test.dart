import 'package:flutter_test/flutter_test.dart';
import 'package:sakuwashi/features/categories/data/category_icons.dart';
import 'package:sakuwashi/features/categories/data/category_model.dart';

void main() {
  group('Category Model & Icons Tests', () {
    test('CategoryIcons contains valid icon mapping and fallback', () {
      expect(CategoryIcons.iconMap.length, greaterThanOrEqualTo(24));
      expect(CategoryIcons.getIcon('restaurant'), isNotNull);
      expect(CategoryIcons.getIcon('non_existent_key'), CategoryIcons.getIcon('more_horiz'));
    });

    test('CategoryModel conversion to/from map', () {
      const cat = CategoryModel(
        id: 1,
        name: 'Kopi & Teh',
        type: 'expense',
        iconKey: 'local_cafe',
        isDefault: false,
        sortOrder: 1,
      );

      final map = cat.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Kopi & Teh');
      expect(map['type'], 'expense');
      expect(map['icon_key'], 'local_cafe');
      expect(map['is_default'], 0);

      final fromMap = CategoryModel.fromMap(map);
      expect(fromMap.id, cat.id);
      expect(fromMap.name, cat.name);
      expect(fromMap.type, cat.type);
      expect(fromMap.iconKey, cat.iconKey);
      expect(fromMap.isDefault, false);
    });
  });
}
