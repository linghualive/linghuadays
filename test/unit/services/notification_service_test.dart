import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:daysmater/services/notification_service.dart';
import 'package:daysmater/models/event.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
  });

  group('NotificationService.calculateNotificationTime', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    test('当天提醒返回目标日期当天的指定时间', () {
      final targetDate = DateTime(2026, 3, 15);
      final result = service.calculateNotificationTime(
        targetDate,
        0, // 当天
        9, // 9:00
        0,
      );

      expect(result.year, 2026);
      expect(result.month, 3);
      expect(result.day, 15);
      expect(result.hour, 9);
      expect(result.minute, 0);
    });

    test('提前1天提醒', () {
      final targetDate = DateTime(2026, 3, 15);
      final result = service.calculateNotificationTime(
        targetDate,
        1,
        8,
        30,
      );

      expect(result.year, 2026);
      expect(result.month, 3);
      expect(result.day, 14);
      expect(result.hour, 8);
      expect(result.minute, 30);
    });

    test('提前7天提醒', () {
      final targetDate = DateTime(2026, 6, 20);
      final result = service.calculateNotificationTime(
        targetDate,
        7,
        10,
        0,
      );

      expect(result.year, 2026);
      expect(result.month, 6);
      expect(result.day, 13);
      expect(result.hour, 10);
      expect(result.minute, 0);
    });

    test('提前30天跨月提醒', () {
      final targetDate = DateTime(2026, 3, 10);
      final result = service.calculateNotificationTime(
        targetDate,
        30,
        9,
        0,
      );

      expect(result.year, 2026);
      expect(result.month, 2);
      expect(result.day, 8);
      expect(result.hour, 9);
      expect(result.minute, 0);
    });

    test('提前提醒跨年', () {
      final targetDate = DateTime(2026, 1, 5);
      final result = service.calculateNotificationTime(
        targetDate,
        7,
        9,
        0,
      );

      expect(result.year, 2025);
      expect(result.month, 12);
      expect(result.day, 29);
      expect(result.hour, 9);
      expect(result.minute, 0);
    });

    test('返回的是 TZDateTime 类型', () {
      final targetDate = DateTime(2026, 5, 1);
      final result = service.calculateNotificationTime(
        targetDate,
        1,
        9,
        0,
      );

      expect(result, isA<tz.TZDateTime>());
    });

    test('自定义时间 23:59', () {
      final targetDate = DateTime(2026, 12, 25);
      final result = service.calculateNotificationTime(
        targetDate,
        0,
        23,
        59,
      );

      expect(result.hour, 23);
      expect(result.minute, 59);
    });
  });

  group('Event 提醒字段', () {
    test('创建带提醒的事件', () {
      final now = DateTime.now();
      final event = Event(
        name: '测试提醒',
        targetDate: DateTime(2026, 6, 1),
        calendarType: 'solar',
        createdAt: now,
        updatedAt: now,
        reminderDaysBefore: 3,
        reminderHour: 10,
        reminderMinute: 30,
      );

      expect(event.reminderDaysBefore, 3);
      expect(event.reminderHour, 10);
      expect(event.reminderMinute, 30);
    });

    test('创建不带提醒的事件', () {
      final now = DateTime.now();
      final event = Event(
        name: '无提醒',
        targetDate: DateTime(2026, 6, 1),
        calendarType: 'solar',
        createdAt: now,
        updatedAt: now,
      );

      expect(event.reminderDaysBefore, isNull);
      expect(event.reminderHour, isNull);
      expect(event.reminderMinute, isNull);
    });

    test('copyWith 更新提醒字段', () {
      final now = DateTime.now();
      final event = Event(
        id: 1,
        name: '测试',
        targetDate: DateTime(2026, 6, 1),
        calendarType: 'solar',
        createdAt: now,
        updatedAt: now,
      );

      final updated = event.copyWith(
        reminderDaysBefore: () => 7,
        reminderHour: () => 8,
        reminderMinute: () => 0,
      );

      expect(updated.reminderDaysBefore, 7);
      expect(updated.reminderHour, 8);
      expect(updated.reminderMinute, 0);
    });

    test('copyWith 清除提醒字段', () {
      final now = DateTime.now();
      final event = Event(
        id: 1,
        name: '测试',
        targetDate: DateTime(2026, 6, 1),
        calendarType: 'solar',
        createdAt: now,
        updatedAt: now,
        reminderDaysBefore: 3,
        reminderHour: 9,
        reminderMinute: 0,
      );

      final updated = event.copyWith(
        reminderDaysBefore: () => null,
        reminderHour: () => null,
        reminderMinute: () => null,
      );

      expect(updated.reminderDaysBefore, isNull);
      expect(updated.reminderHour, isNull);
      expect(updated.reminderMinute, isNull);
    });

    test('提醒字段序列化与反序列化', () {
      final now = DateTime(2026, 1, 1);
      final event = Event(
        id: 1,
        name: '序列化测试',
        targetDate: DateTime(2026, 6, 1),
        calendarType: 'solar',
        createdAt: now,
        updatedAt: now,
        reminderDaysBefore: 1,
        reminderHour: 14,
        reminderMinute: 30,
      );

      final map = event.toMap();
      expect(map['reminder_days_before'], 1);
      expect(map['reminder_hour'], 14);
      expect(map['reminder_minute'], 30);

      final restored = Event.fromMap(map);
      expect(restored.reminderDaysBefore, 1);
      expect(restored.reminderHour, 14);
      expect(restored.reminderMinute, 30);
    });
  });
}
