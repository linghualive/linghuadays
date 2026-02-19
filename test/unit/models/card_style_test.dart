import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/models/card_style.dart';

void main() {
  group('CardStyle', () {
    test('toMap 和 fromMap 序列化往返正确', () {
      const style = CardStyle(
        id: 1,
        styleName: '浅粉',
        styleType: StyleType.simple,
        backgroundColor: 0xFFFFF0F3,
        textColor: 0xFF5D4350,
        numberColor: 0xFFB85C7A,
        headerColor: 0xFFD4869C,
        fontFamily: 'default',
        cardBorderRadius: 16.0,
        isPreset: true,
      );

      final map = style.toMap();
      final restored = CardStyle.fromMap(map);

      expect(restored.id, 1);
      expect(restored.styleName, '浅粉');
      expect(restored.styleType, StyleType.simple);
      expect(restored.backgroundColor, 0xFFFFF0F3);
      expect(restored.textColor, 0xFF5D4350);
      expect(restored.numberColor, 0xFFB85C7A);
      expect(restored.headerColor, 0xFFD4869C);
      expect(restored.fontFamily, 'default');
      expect(restored.cardBorderRadius, 16.0);
      expect(restored.isPreset, true);
    });

    test('渐变色列表序列化为逗号分隔字符串', () {
      const style = CardStyle(
        styleName: '渐变',
        styleType: StyleType.gradient,
        backgroundColor: 0xFF6A1B9A,
        gradientColors: [0xFF6A1B9A, 0xFFE91E63],
        textColor: 0xFFFFFFFF,
        numberColor: 0xFFFFFFFF,
      );

      final map = style.toMap();
      expect(map['gradient_colors'], '${0xFF6A1B9A},${0xFFE91E63}');

      final restored = CardStyle.fromMap(map);
      expect(restored.gradientColors, [0xFF6A1B9A, 0xFFE91E63]);
    });

    test('gradientColors 为 null 时序列化正确', () {
      const style = CardStyle(
        styleName: '简约',
        styleType: StyleType.simple,
        backgroundColor: 0xFFF5F5F5,
        textColor: 0xFF212121,
        numberColor: 0xFF1565C0,
      );

      final map = style.toMap();
      expect(map['gradient_colors'], isNull);

      final restored = CardStyle.fromMap(map);
      expect(restored.gradientColors, isNull);
    });

    test('预设风格包含12种', () {
      final presets = CardStyle.presets;
      expect(presets.length, 12);
    });

    test('预设风格包含 simple 和 gradient 类型', () {
      final presets = CardStyle.presets;
      final types = presets.map((s) => s.styleType).toSet();

      expect(types, contains(StyleType.simple));
      expect(types, contains(StyleType.gradient));
    });

    test('所有预设风格 isPreset 为 true', () {
      for (final preset in CardStyle.presets) {
        expect(preset.isPreset, true, reason: '${preset.styleName} 应为预设');
      }
    });

    test('所有预设风格名称不为空', () {
      for (final preset in CardStyle.presets) {
        expect(preset.styleName.isNotEmpty, true);
      }
    });

    test('StyleType 枚举值完整', () {
      expect(StyleType.values.length, 8);
      expect(StyleType.values, contains(StyleType.custom));
    });

    test('copyWith 正确复制和覆盖字段', () {
      const style = CardStyle(
        id: 1,
        styleName: '简约',
        styleType: StyleType.simple,
        backgroundColor: 0xFFF5F5F5,
        textColor: 0xFF212121,
        numberColor: 0xFF1565C0,
      );

      final copied = style.copyWith(
        styleName: '自定义简约',
        backgroundColor: 0xFFEEEEEE,
        gradientColors: () => [0xFF000000, 0xFFFFFFFF],
      );

      expect(copied.id, 1);
      expect(copied.styleName, '自定义简约');
      expect(copied.backgroundColor, 0xFFEEEEEE);
      expect(copied.gradientColors, [0xFF000000, 0xFFFFFFFF]);
      expect(copied.styleType, StyleType.simple);
    });

    test('默认值正确', () {
      const style = CardStyle(
        styleName: '测试',
        styleType: StyleType.simple,
        backgroundColor: 0xFFFFFFFF,
        textColor: 0xFF000000,
        numberColor: 0xFF000000,
      );

      expect(style.imageBlur, 0.0);
      expect(style.overlayOpacity, 0.0);
      expect(style.fontFamily, 'default');
      expect(style.cardBorderRadius, 16.0);
      expect(style.headerColor, 0xFF78909C);
      expect(style.isPreset, false);
      expect(style.backgroundImagePath, isNull);
      expect(style.gradientColors, isNull);
    });

    test('headerColor 序列化往返正确', () {
      const style = CardStyle(
        styleName: '测试',
        styleType: StyleType.simple,
        backgroundColor: 0xFFFFFFFF,
        textColor: 0xFF000000,
        numberColor: 0xFF000000,
        headerColor: 0xFFD4869C,
      );

      final map = style.toMap();
      expect(map['header_color'], 0xFFD4869C);

      final restored = CardStyle.fromMap(map);
      expect(restored.headerColor, 0xFFD4869C);
    });
  });
}
