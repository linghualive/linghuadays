import '../models/event.dart';
import '../services/database_helper.dart';

enum EventSortType {
  byDaysRemaining,
  byCreatedAt,
  byName,
}

class EventRepository {
  final DatabaseHelper _dbHelper;
  static const String _table = 'events';

  EventRepository(this._dbHelper);

  Future<int> insert(Event event) async {
    final map = event.toMap();
    map.remove('id');
    return _dbHelper.insert(_table, map);
  }

  Future<Event?> getById(int id) async {
    final map = await _dbHelper.queryById(_table, id);
    if (map == null) return null;
    return Event.fromMap(map);
  }

  Future<List<Event>> getAll({
    EventSortType sortType = EventSortType.byDaysRemaining,
    int? categoryId,
    String? searchQuery,
  }) async {
    String? where;
    List<Object?>? whereArgs;

    final conditions = <String>[];
    final args = <Object?>[];

    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('name LIKE ?');
      args.add('%$searchQuery%');
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
      whereArgs = args;
    }

    String orderBy;
    switch (sortType) {
      case EventSortType.byDaysRemaining:
        orderBy = 'is_pinned DESC, target_date ASC';
      case EventSortType.byCreatedAt:
        orderBy = 'is_pinned DESC, created_at DESC';
      case EventSortType.byName:
        orderBy = 'is_pinned DESC, name ASC';
    }

    final results = await _dbHelper.query(
      _table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return results.map(Event.fromMap).toList();
  }

  Future<int> update(Event event) async {
    if (event.id == null) {
      throw ArgumentError('Cannot update event without id');
    }
    return _dbHelper.update(_table, event.toMap(), id: event.id!);
  }

  Future<int> delete(int id) async {
    return _dbHelper.delete(_table, id: id);
  }

  Future<void> deleteMultiple(List<int> ids) async {
    for (final id in ids) {
      await _dbHelper.delete(_table, id: id);
    }
  }

  Future<void> togglePin(int eventId) async {
    final event = await getById(eventId);
    if (event != null) {
      await update(event.copyWith(
        isPinned: !event.isPinned,
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> clearCategoryFromEvents(int categoryId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE $_table SET category_id = NULL WHERE category_id = ?',
      [categoryId],
    );
  }
}
