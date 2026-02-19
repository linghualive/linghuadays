import '../models/category.dart';
import '../services/database_helper.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper;
  static const String _table = 'categories';

  CategoryRepository(this._dbHelper);

  Future<int> insert(EventCategory category) async {
    final map = category.toMap();
    map.remove('id');
    return _dbHelper.insert(_table, map);
  }

  Future<EventCategory?> getById(int id) async {
    final map = await _dbHelper.queryById(_table, id);
    if (map == null) return null;
    return EventCategory.fromMap(map);
  }

  Future<List<EventCategory>> getAll() async {
    final results = await _dbHelper.query(
      _table,
      orderBy: 'is_preset DESC, name ASC',
    );
    return results.map(EventCategory.fromMap).toList();
  }

  Future<int> update(EventCategory category) async {
    if (category.id == null) {
      throw ArgumentError('Cannot update category without id');
    }
    return _dbHelper.update(_table, category.toMap(), id: category.id!);
  }

  Future<int> delete(int id) async {
    return _dbHelper.delete(_table, id: id);
  }

  Future<void> initPresets() async {
    final existing = await getAll();
    if (existing.isNotEmpty) return;

    for (final preset in EventCategory.presets) {
      await insert(preset);
    }
  }
}
