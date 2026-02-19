import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/models/event.dart';

void main() {
  group('Event', () {
    final now = DateTime(2026, 2, 19, 10, 0, 0);

    Event createTestEvent({
      int? id,
      String name = '测试事件',
      DateTime? targetDate,
      String calendarType = 'solar',
    }) {
      return Event(
        id: id,
        name: name,
        targetDate: targetDate ?? DateTime(2026, 12, 31),
        calendarType: calendarType,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('toMap 和 fromMap 序列化往返正确', () {
      final event = createTestEvent(id: 1);
      final map = event.toMap();
      final restored = Event.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, '测试事件');
      expect(restored.calendarType, 'solar');
      expect(restored.isRepeating, false);
      expect(restored.isPinned, false);
      expect(restored.isFocus, false);
    });

    test('toJson 和 fromJson 序列化往返正确', () {
      final event = Event(
        id: 2,
        name: '妈妈生日',
        targetDate: DateTime(2026, 5, 15),
        calendarType: 'lunar',
        lunarYear: 2026,
        lunarMonth: 4,
        lunarDay: 10,
        isLeapMonth: false,
        categoryId: 1,
        note: '准备礼物',
        isRepeating: true,
        isPinned: true,
        isFocus: false,
        styleId: 3,
        createdAt: now,
        updatedAt: now,
        reminderDaysBefore: 3,
        reminderHour: 9,
        reminderMinute: 0,
      );

      final json = event.toJson();
      final restored = Event.fromJson(json);

      expect(restored.name, '妈妈生日');
      expect(restored.calendarType, 'lunar');
      expect(restored.lunarYear, 2026);
      expect(restored.lunarMonth, 4);
      expect(restored.lunarDay, 10);
      expect(restored.isLeapMonth, false);
      expect(restored.categoryId, 1);
      expect(restored.note, '准备礼物');
      expect(restored.isRepeating, true);
      expect(restored.isPinned, true);
      expect(restored.styleId, 3);
      expect(restored.reminderDaysBefore, 3);
      expect(restored.reminderHour, 9);
      expect(restored.reminderMinute, 0);
    });

    test('bool 字段序列化为 0/1', () {
      final event = Event(
        name: '测试',
        targetDate: DateTime(2026, 12, 31),
        calendarType: 'solar',
        isRepeating: true,
        isPinned: true,
        isFocus: true,
        isLeapMonth: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = event.toMap();
      expect(map['is_repeating'], 1);
      expect(map['is_pinned'], 1);
      expect(map['is_focus'], 1);
      expect(map['is_leap_month'], 1);
    });

    test('copyWith 正确复制和覆盖字段', () {
      final event = createTestEvent(id: 1);
      final copied = event.copyWith(
        name: '新名称',
        isPinned: true,
        categoryId: () => 5,
      );

      expect(copied.name, '新名称');
      expect(copied.isPinned, true);
      expect(copied.categoryId, 5);
      expect(copied.id, 1); // 未修改的字段保持不变
    });

    test('copyWith 可以设置 nullable 字段为 null', () {
      final event = Event(
        id: 1,
        name: '测试',
        targetDate: DateTime(2026, 12, 31),
        calendarType: 'solar',
        categoryId: 3,
        note: '备注',
        createdAt: now,
        updatedAt: now,
      );

      final copied = event.copyWith(
        categoryId: () => null,
        note: () => null,
      );

      expect(copied.categoryId, isNull);
      expect(copied.note, isNull);
    });

    test('相等性基于 id 判断', () {
      final a = createTestEvent(id: 1, name: 'A');
      final b = createTestEvent(id: 1, name: 'B');
      final c = createTestEvent(id: 2, name: 'A');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
