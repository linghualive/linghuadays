import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daysmater/models/category.dart';
import 'package:daysmater/repositories/category_repository.dart';
import 'package:daysmater/services/database_helper.dart';

void main() {
  late DatabaseHelper dbHelper;
  late CategoryRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    dbHelper = DatabaseHelper(
      databaseFactory: databaseFactoryFfi,
      inMemory: true,
    );
    repo = CategoryRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CategoryRepository', () {
    test('insert 和 getById', () async {
      const category = EventCategory(
        name: '自定义',
        colorValue: 0xFF000000,
      );
      final id = await repo.insert(category);
      final result = await repo.getById(id);
      expect(result, isNotNull);
      expect(result!.name, '自定义');
    });

    test('getAll 返回所有分类', () async {
      await repo.insert(const EventCategory(
        name: 'A',
        colorValue: 0xFF000000,
      ));
      await repo.insert(const EventCategory(
        name: 'B',
        colorValue: 0xFFFFFFFF,
      ));

      final categories = await repo.getAll();
      expect(categories.length, 2);
    });

    test('update 更新分类', () async {
      final id = await repo.insert(const EventCategory(
        name: '原名',
        colorValue: 0xFF000000,
      ));

      final category = (await repo.getById(id))!;
      await repo.update(category.copyWith(
        name: '新名',
        colorValue: 0xFFFF0000,
      ));

      final updated = await repo.getById(id);
      expect(updated!.name, '新名');
      expect(updated.colorValue, 0xFFFF0000);
    });

    test('delete 删除分类', () async {
      final id = await repo.insert(const EventCategory(
        name: '临时',
        colorValue: 0xFF000000,
      ));
      await repo.delete(id);
      final result = await repo.getById(id);
      expect(result, isNull);
    });

    test('initPresets 初始化预设分类', () async {
      await repo.initPresets();
      final categories = await repo.getAll();
      expect(categories.length, 5);

      final names = categories.map((c) => c.name).toSet();
      expect(names, contains('生日'));
      expect(names, contains('纪念日'));
      expect(names, contains('节日'));
      expect(names, contains('工作'));
      expect(names, contains('考试'));
    });

    test('initPresets 不重复初始化', () async {
      await repo.initPresets();
      await repo.initPresets(); // 第二次调用
      final categories = await repo.getAll();
      expect(categories.length, 5);
    });

    test('getAll 预设分类排在前面', () async {
      await repo.initPresets();
      await repo.insert(const EventCategory(
        name: 'AAA自定义',
        colorValue: 0xFF000000,
      ));

      final categories = await repo.getAll();
      // 前5个都是预设
      for (var i = 0; i < 5; i++) {
        expect(categories[i].isPreset, true);
      }
      expect(categories.last.isPreset, false);
    });
  });
}
