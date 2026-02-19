import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'daysmater.db';
  static const int _databaseVersion = 2;

  Database? _database;

  // 允许注入自定义 database factory（用于测试）
  final DatabaseFactory? databaseFactory;

  // 使用内存数据库（用于测试隔离）
  final bool inMemory;

  DatabaseHelper({this.databaseFactory, this.inMemory = false});

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (databaseFactory != null) {
      final factory = databaseFactory!;
      final path = inMemory
          ? inMemoryDatabasePath
          : join(await factory.getDatabasesPath(), databaseName);
      return factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          singleInstance: !inMemory,
        ),
      );
    }
    // 默认使用 sqflite 的顶层函数
    final dbPath = join(await getDatabasesPath(), databaseName);
    return openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_preset INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE card_styles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        style_name TEXT NOT NULL,
        style_type TEXT NOT NULL,
        background_color INTEGER NOT NULL,
        gradient_colors TEXT,
        background_image_path TEXT,
        image_blur REAL NOT NULL DEFAULT 0.0,
        overlay_opacity REAL NOT NULL DEFAULT 0.0,
        text_color INTEGER NOT NULL,
        number_color INTEGER NOT NULL,
        header_color INTEGER NOT NULL DEFAULT 0xFF78909C,
        font_family TEXT NOT NULL DEFAULT 'default',
        card_border_radius REAL NOT NULL DEFAULT 16.0,
        is_preset INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_date TEXT NOT NULL,
        calendar_type TEXT NOT NULL DEFAULT 'solar',
        lunar_year INTEGER,
        lunar_month INTEGER,
        lunar_day INTEGER,
        is_leap_month INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER,
        note TEXT,
        is_repeating INTEGER NOT NULL DEFAULT 0,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_focus INTEGER NOT NULL DEFAULT 0,
        style_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        reminder_days_before INTEGER,
        reminder_hour INTEGER,
        reminder_minute INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (style_id) REFERENCES card_styles(id) ON DELETE SET NULL
      )
    ''');

    // 创建索引
    await db.execute(
      'CREATE INDEX idx_events_target_date ON events(target_date)',
    );
    await db.execute(
      'CREATE INDEX idx_events_category_id ON events(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_events_is_pinned ON events(is_pinned)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE card_styles ADD COLUMN header_color INTEGER NOT NULL DEFAULT 0xFF78909C',
      );
      // 删除旧预设，新预设将由 initPresets 重新插入
      await db.delete('card_styles', where: 'is_preset = 1');
    }
  }

  // 通用 CRUD 方法

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<Map<String, dynamic>?> queryById(String table, int id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required int id,
  }) async {
    final db = await database;
    return db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, {required int id}) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
