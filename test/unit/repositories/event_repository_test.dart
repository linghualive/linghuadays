import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daysmater/models/event.dart';
import 'package:daysmater/repositories/event_repository.dart';
import 'package:daysmater/services/database_helper.dart';

void main() {
  late DatabaseHelper dbHelper;
  late EventRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    dbHelper = DatabaseHelper(
      databaseFactory: databaseFactoryFfi,
      inMemory: true,
    );
    repo = EventRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  Event createEvent({
    String name = '测试事件',
    DateTime? targetDate,
    bool isPinned = false,
    int? categoryId,
  }) {
    final now = DateTime.now();
    return Event(
      name: name,
      targetDate: targetDate ?? DateTime(2026, 12, 31),
      calendarType: 'solar',
      isPinned: isPinned,
      categoryId: categoryId,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('EventRepository', () {
    test('insert 和 getById', () async {
      final id = await repo.insert(createEvent(name: '新年'));
      final event = await repo.getById(id);
      expect(event, isNotNull);
      expect(event!.name, '新年');
      expect(event.id, id);
    });

    test('getById 不存在返回 null', () async {
      final event = await repo.getById(9999);
      expect(event, isNull);
    });

    test('getAll 返回所有事件', () async {
      await repo.insert(createEvent(name: 'A'));
      await repo.insert(createEvent(name: 'B'));
      await repo.insert(createEvent(name: 'C'));

      final events = await repo.getAll();
      expect(events.length, 3);
    });

    test('getAll 按天数排序（默认）', () async {
      await repo.insert(createEvent(
        name: '远',
        targetDate: DateTime(2028, 1, 1),
      ));
      await repo.insert(createEvent(
        name: '近',
        targetDate: DateTime(2026, 3, 1),
      ));

      final events =
          await repo.getAll(sortType: EventSortType.byDaysRemaining);
      expect(events.first.name, '近');
      expect(events.last.name, '远');
    });

    test('getAll 按名称排序', () async {
      await repo.insert(createEvent(name: 'Banana'));
      await repo.insert(createEvent(name: 'Apple'));

      final events = await repo.getAll(sortType: EventSortType.byName);
      expect(events.first.name, 'Apple');
    });

    test('getAll 置顶事件始终在前', () async {
      await repo.insert(createEvent(
        name: '普通',
        targetDate: DateTime(2026, 3, 1),
      ));
      await repo.insert(createEvent(
        name: '置顶',
        targetDate: DateTime(2028, 1, 1),
        isPinned: true,
      ));

      final events = await repo.getAll();
      expect(events.first.name, '置顶');
      expect(events.first.isPinned, true);
    });

    test('getAll 按分类筛选', () async {
      await repo.insert(createEvent(name: '工作1', categoryId: 1));
      await repo.insert(createEvent(name: '生活', categoryId: 2));
      await repo.insert(createEvent(name: '工作2', categoryId: 1));

      final events = await repo.getAll(categoryId: 1);
      expect(events.length, 2);
      expect(events.every((e) => e.categoryId == 1), true);
    });

    test('getAll 搜索', () async {
      await repo.insert(createEvent(name: '妈妈生日'));
      await repo.insert(createEvent(name: '爸爸生日'));
      await repo.insert(createEvent(name: '结婚纪念日'));

      final events = await repo.getAll(searchQuery: '生日');
      expect(events.length, 2);
    });

    test('getAll 筛选+搜索组合', () async {
      await repo.insert(createEvent(name: '妈妈生日', categoryId: 1));
      await repo.insert(createEvent(name: '同事生日', categoryId: 2));

      final events = await repo.getAll(categoryId: 1, searchQuery: '生日');
      expect(events.length, 1);
      expect(events.first.name, '妈妈生日');
    });

    test('update 更新事件', () async {
      final id = await repo.insert(createEvent(name: '原名称'));
      var event = await repo.getById(id);
      event = event!.copyWith(name: '新名称');
      await repo.update(event);

      final updated = await repo.getById(id);
      expect(updated!.name, '新名称');
    });

    test('update 无 id 抛异常', () async {
      final event = createEvent();
      expect(() => repo.update(event), throwsArgumentError);
    });

    test('delete 删除事件', () async {
      final id = await repo.insert(createEvent());
      await repo.delete(id);
      final event = await repo.getById(id);
      expect(event, isNull);
    });

    test('deleteMultiple 批量删除', () async {
      final id1 = await repo.insert(createEvent(name: 'A'));
      final id2 = await repo.insert(createEvent(name: 'B'));
      await repo.insert(createEvent(name: 'C'));

      await repo.deleteMultiple([id1, id2]);
      final events = await repo.getAll();
      expect(events.length, 1);
      expect(events.first.name, 'C');
    });

    test('togglePin 切换置顶', () async {
      final id = await repo.insert(createEvent());

      await repo.togglePin(id);
      var event = await repo.getById(id);
      expect(event!.isPinned, true);

      await repo.togglePin(id);
      event = await repo.getById(id);
      expect(event!.isPinned, false);
    });

    test('clearCategoryFromEvents 清除分类', () async {
      await repo.insert(createEvent(name: 'A', categoryId: 1));
      await repo.insert(createEvent(name: 'B', categoryId: 1));
      await repo.insert(createEvent(name: 'C', categoryId: 2));

      await repo.clearCategoryFromEvents(1);

      final events = await repo.getAll();
      final cat1Events = events.where((e) => e.categoryId == 1);
      expect(cat1Events, isEmpty);

      final cat2Events = events.where((e) => e.categoryId == 2);
      expect(cat2Events.length, 1);
    });
  });
}
