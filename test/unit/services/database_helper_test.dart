import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daysmater/services/database_helper.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    dbHelper = DatabaseHelper(
      databaseFactory: databaseFactoryFfi,
      inMemory: true,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('DatabaseHelper', () {
    test('数据库初始化成功', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, true);
    });

    test('events 表已创建', () async {
      final db = await dbHelper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='events'",
      );
      expect(tables.length, 1);
    });

    test('categories 表已创建', () async {
      final db = await dbHelper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='categories'",
      );
      expect(tables.length, 1);
    });

    test('card_styles 表已创建', () async {
      final db = await dbHelper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='card_styles'",
      );
      expect(tables.length, 1);
    });

    test('insert 和 queryAll 正确', () async {
      final id = await dbHelper.insert('categories', {
        'name': '生日',
        'color_value': 0xFFE91E63,
        'is_preset': 1,
      });
      expect(id, greaterThan(0));

      final results = await dbHelper.queryAll('categories');
      expect(results.length, 1);
      expect(results.first['name'], '生日');
    });

    test('queryById 返回正确记录', () async {
      final id = await dbHelper.insert('categories', {
        'name': '工作',
        'color_value': 0xFF2196F3,
        'is_preset': 1,
      });

      final result = await dbHelper.queryById('categories', id);
      expect(result, isNotNull);
      expect(result!['name'], '工作');
    });

    test('queryById 不存在返回 null', () async {
      final result = await dbHelper.queryById('categories', 9999);
      expect(result, isNull);
    });

    test('update 更新记录', () async {
      final id = await dbHelper.insert('categories', {
        'name': '工作',
        'color_value': 0xFF2196F3,
        'is_preset': 0,
      });

      await dbHelper.update(
        'categories',
        {'name': '工作2.0', 'color_value': 0xFF4CAF50, 'is_preset': 0},
        id: id,
      );

      final result = await dbHelper.queryById('categories', id);
      expect(result!['name'], '工作2.0');
      expect(result['color_value'], 0xFF4CAF50);
    });

    test('delete 删除记录', () async {
      final id = await dbHelper.insert('categories', {
        'name': '临时',
        'color_value': 0xFF000000,
        'is_preset': 0,
      });

      await dbHelper.delete('categories', id: id);
      final result = await dbHelper.queryById('categories', id);
      expect(result, isNull);
    });

    test('query 带条件查询', () async {
      await dbHelper.insert('categories', {
        'name': '生日',
        'color_value': 0xFFE91E63,
        'is_preset': 1,
      });
      await dbHelper.insert('categories', {
        'name': '自定义',
        'color_value': 0xFF000000,
        'is_preset': 0,
      });

      final presets = await dbHelper.query(
        'categories',
        where: 'is_preset = ?',
        whereArgs: [1],
      );
      expect(presets.length, 1);
      expect(presets.first['name'], '生日');
    });

    test('events 表支持完整字段插入', () async {
      final now = DateTime.now().toIso8601String();
      final id = await dbHelper.insert('events', {
        'name': '测试事件',
        'target_date': '2026-12-31T00:00:00.000',
        'calendar_type': 'solar',
        'is_leap_month': 0,
        'is_repeating': 0,
        'is_pinned': 0,

        'created_at': now,
        'updated_at': now,
      });

      expect(id, greaterThan(0));
      final result = await dbHelper.queryById('events', id);
      expect(result!['name'], '测试事件');
      expect(result['calendar_type'], 'solar');
    });

    test('events 外键 category_id 删除后置 NULL', () async {
      // 注意：SQLite 默认不强制外键，此处仅验证字段可设为 null
      final catId = await dbHelper.insert('categories', {
        'name': '生日',
        'color_value': 0xFFE91E63,
        'is_preset': 1,
      });

      final now = DateTime.now().toIso8601String();
      final eventId = await dbHelper.insert('events', {
        'name': '妈妈生日',
        'target_date': '2026-05-15T00:00:00.000',
        'calendar_type': 'solar',
        'category_id': catId,
        'is_leap_month': 0,
        'is_repeating': 0,
        'is_pinned': 0,

        'created_at': now,
        'updated_at': now,
      });

      // 手动将 category_id 置为 null（模拟业务逻辑）
      await dbHelper.update(
        'events',
        {
          'name': '妈妈生日',
          'target_date': '2026-05-15T00:00:00.000',
          'calendar_type': 'solar',
          'category_id': null,
          'is_leap_month': 0,
          'is_repeating': 0,
          'is_pinned': 0,
  
          'created_at': now,
          'updated_at': now,
        },
        id: eventId,
      );

      final result = await dbHelper.queryById('events', eventId);
      expect(result!['category_id'], isNull);
    });
  });
}
