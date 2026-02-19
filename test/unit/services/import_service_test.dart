import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:daysmater/models/event.dart';
import 'package:daysmater/services/import_service.dart';

void main() {
  late ImportService service;
  final now = DateTime(2026, 1, 1);

  setUp(() {
    service = ImportService();
  });

  group('ImportService.parseAndValidate', () {
    test('解析有效的导出 JSON', () {
      final json = jsonEncode({
        'version': 1,
        'events': [
          {
            'name': '妈妈生日',
            'target_date': '2026-03-15T00:00:00.000',
            'calendar_type': 'solar',
            'is_leap_month': 0,
            'is_repeating': 1,
            'is_pinned': 0,
            'is_focus': 0,
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, []);

      expect(result.events.length, 1);
      expect(result.events.first.name, '妈妈生日');
      expect(result.events.first.isRepeating, isTrue);
      expect(result.duplicates, isEmpty);
    });

    test('解析多个事件', () {
      final json = jsonEncode({
        'events': [
          {
            'name': '事件A',
            'target_date': '2026-06-01T00:00:00.000',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
          {
            'name': '事件B',
            'target_date': '2026-12-25T00:00:00.000',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, []);
      expect(result.events.length, 2);
    });

    test('解析包含分类的 JSON', () {
      final json = jsonEncode({
        'events': [],
        'categories': [
          {'name': '自定义分类', 'color_value': 0xFF123456},
        ],
      });

      final result = service.parseAndValidate(json, []);
      expect(result.categories.length, 1);
      expect(result.categories.first.name, '自定义分类');
    });

    test('检测重复事件（按名称+日期匹配）', () {
      final existing = [
        Event(
          id: 1,
          name: '妈妈生日',
          targetDate: DateTime(2026, 3, 15),
          calendarType: 'solar',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final json = jsonEncode({
        'events': [
          {
            'name': '妈妈生日',
            'target_date': '2026-03-15T00:00:00.000',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
          {
            'name': '新事件',
            'target_date': '2026-06-01T00:00:00.000',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, existing);

      expect(result.events.length, 1);
      expect(result.events.first.name, '新事件');
      expect(result.duplicates.length, 1);
      expect(result.duplicates.first.incoming.name, '妈妈生日');
      expect(result.duplicates.first.existing.id, 1);
    });

    test('同名不同日期不算重复', () {
      final existing = [
        Event(
          id: 1,
          name: '会议',
          targetDate: DateTime(2026, 3, 15),
          calendarType: 'solar',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final json = jsonEncode({
        'events': [
          {
            'name': '会议',
            'target_date': '2026-04-20T00:00:00.000',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, existing);
      expect(result.events.length, 1);
      expect(result.duplicates, isEmpty);
    });

    test('无效 JSON 抛出 FormatException', () {
      expect(
        () => service.parseAndValidate('not json', []),
        throwsA(isA<FormatException>()),
      );
    });

    test('缺少 events 字段抛出 FormatException', () {
      final json = jsonEncode({'version': 1});

      expect(
        () => service.parseAndValidate(json, []),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('events'),
          ),
        ),
      );
    });

    test('events 不是数组抛出 FormatException', () {
      final json = jsonEncode({'events': 'not an array'});

      expect(
        () => service.parseAndValidate(json, []),
        throwsA(isA<FormatException>()),
      );
    });

    test('跳过缺少名称的事件', () {
      final json = jsonEncode({
        'events': [
          {
            'name': '',
            'target_date': '2026-06-01T00:00:00.000',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
          {
            'name': '有效事件',
            'target_date': '2026-06-01T00:00:00.000',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, []);
      expect(result.events.length, 1);
      expect(result.events.first.name, '有效事件');
    });

    test('跳过缺少目标日期的事件', () {
      final json = jsonEncode({
        'events': [
          {
            'name': '无日期事件',
            'calendar_type': 'solar',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, []);
      expect(result.events, isEmpty);
    });

    test('缺少 created_at/updated_at 使用当前时间', () {
      final json = jsonEncode({
        'events': [
          {
            'name': '简单事件',
            'target_date': '2026-06-01T00:00:00.000',
            'calendar_type': 'solar',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, []);
      expect(result.events.length, 1);
      expect(result.events.first.createdAt, isNotNull);
    });

    test('缺少 calendar_type 默认为 solar', () {
      final json = jsonEncode({
        'events': [
          {
            'name': '默认类型',
            'target_date': '2026-06-01T00:00:00.000',
          },
        ],
        'categories': [],
      });

      final result = service.parseAndValidate(json, []);
      expect(result.events.first.calendarType, 'solar');
    });

    test('JSON 根元素不是对象抛出异常', () {
      expect(
        () => service.parseAndValidate('[1,2,3]', []),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
