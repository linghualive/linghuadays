import '../models/card_style.dart';
import '../services/database_helper.dart';

class StyleRepository {
  final DatabaseHelper _dbHelper;
  static const String _table = 'card_styles';

  StyleRepository(this._dbHelper);

  Future<int> insert(CardStyle style) async {
    final map = style.toMap();
    map.remove('id');
    return _dbHelper.insert(_table, map);
  }

  Future<CardStyle?> getById(int id) async {
    final map = await _dbHelper.queryById(_table, id);
    if (map == null) return null;
    return CardStyle.fromMap(map);
  }

  Future<List<CardStyle>> getAll() async {
    final results = await _dbHelper.query(
      _table,
      orderBy: 'is_preset DESC, style_name ASC',
    );
    return results.map(CardStyle.fromMap).toList();
  }

  Future<int> update(CardStyle style) async {
    if (style.id == null) {
      throw ArgumentError('Cannot update style without id');
    }
    return _dbHelper.update(_table, style.toMap(), id: style.id!);
  }

  Future<int> delete(int id) async {
    // 预设风格不可删除
    final style = await getById(id);
    if (style != null && style.isPreset) {
      throw StateError('Cannot delete preset style');
    }
    return _dbHelper.delete(_table, id: id);
  }

  Future<void> initPresets() async {
    final existing = await getAll();
    if (existing.isNotEmpty) return;

    for (final preset in CardStyle.presets) {
      await insert(preset);
    }
  }
}
