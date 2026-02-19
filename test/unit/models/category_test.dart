import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/models/category.dart';

void main() {
  group('EventCategory', () {
    test('toMap 和 fromMap 序列化往返正确', () {
      const category = EventCategory(
        id: 1,
        name: '生日',
        colorValue: 0xFFE91E63,
        isPreset: true,
      );

      final map = category.toMap();
      final restored = EventCategory.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, '生日');
      expect(restored.colorValue, 0xFFE91E63);
      expect(restored.isPreset, true);
    });

    test('color getter 返回正确的 Color', () {
      const category = EventCategory(
        name: '测试',
        colorValue: 0xFFFF5722,
      );

      expect(category.color, const Color(0xFFFF5722));
    });

    test('预设分类包含5个', () {
      final presets = EventCategory.presets;
      expect(presets.length, 5);
    });

    test('预设分类包含所有必需项', () {
      final presets = EventCategory.presets;
      final names = presets.map((c) => c.name).toList();

      expect(names, contains('生日'));
      expect(names, contains('纪念日'));
      expect(names, contains('节日'));
      expect(names, contains('工作'));
      expect(names, contains('考试'));
    });

    test('预设分类 isPreset 均为 true', () {
      for (final preset in EventCategory.presets) {
        expect(preset.isPreset, true);
      }
    });

    test('预设分类颜色值均为有效值', () {
      for (final preset in EventCategory.presets) {
        expect(preset.colorValue, greaterThan(0));
        // 确保可以正常创建 Color
        final color = Color(preset.colorValue);
        expect(color.a, greaterThan(0));
      }
    });

    test('copyWith 正确复制和覆盖字段', () {
      const category = EventCategory(
        id: 1,
        name: '生日',
        colorValue: 0xFFE91E63,
        isPreset: true,
      );

      final copied = category.copyWith(
        name: '新名称',
        colorValue: 0xFF2196F3,
      );

      expect(copied.id, 1);
      expect(copied.name, '新名称');
      expect(copied.colorValue, 0xFF2196F3);
      expect(copied.isPreset, true);
    });

    test('bool 字段序列化为 0/1', () {
      const category = EventCategory(
        name: '测试',
        colorValue: 0xFFFFFFFF,
        isPreset: true,
      );

      final map = category.toMap();
      expect(map['is_preset'], 1);

      const notPreset = EventCategory(
        name: '自定义',
        colorValue: 0xFF000000,
      );
      final map2 = notPreset.toMap();
      expect(map2['is_preset'], 0);
    });
  });
}
