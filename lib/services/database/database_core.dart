import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseCore - 核心数据库管理服务
///
/// 职责：
/// - 数据库初始化和版本管理
/// - 数据库连接获取
/// - 数据库关闭
/// - 索引创建
class DatabaseCore {
  Database? _database;

  /// Initialize database
  Future<void> initDatabase() async {
    if (_database != null) return;

    try {
      String path = join(await getDatabasesPath(), 'weather.db');
      _database = await openDatabase(
        path,
        version: 6,
        onCreate: (db, version) async {
          await _createTables(db);
          await _createIndexes(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _upgradeDatabase(db, oldVersion);
          await _createIndexes(db);
        },
      );
    } catch (e) {
      print('Database initialization failed: $e');
      // Continue without database for web platform
    }
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database == null) {
      await initDatabase();
    }
    return _database!;
  }

  /// 创建数据库表
  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE weather_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE location_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        isMainCity INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 9999
      )
    ''');

    await db.execute('''
      CREATE TABLE city_search (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE commute_advices (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        adviceType TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        icon TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        timeSlot TEXT NOT NULL,
        level TEXT NOT NULL DEFAULT 'normal',
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  /// 升级数据库
  static Future<void> _upgradeDatabase(Database db, int oldVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE cities (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          isMainCity INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL
        )
      ''');
      debugPrint('Database upgraded to version 2: Added cities table');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE city_search (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
      debugPrint('Database upgraded to version 3: Added city_search table');
    }
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE cities ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 9999
      ''');
      debugPrint('Database upgraded to version 4: Added sortOrder column');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE commute_advices (
          id TEXT PRIMARY KEY,
          timestamp TEXT NOT NULL,
          adviceType TEXT NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          icon TEXT NOT NULL,
          isRead INTEGER NOT NULL DEFAULT 0,
          timeSlot TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
      debugPrint('Database upgraded to version 5: Added commute_advices table');
    }
    if (oldVersion < 6) {
      await db.execute('''
        ALTER TABLE commute_advices ADD COLUMN level TEXT NOT NULL DEFAULT 'normal'
      ''');
      debugPrint('Database upgraded to version 6: Added level column');
    }
  }

  /// 创建数据库索引
  ///
  /// 索引说明：
  /// - idx_weather_cache_key: 加速按 key 查询天气缓存
  /// - idx_weather_cache_expires_at: 加速清理过期缓存
  /// - idx_cities_name: 加速按城市名查询
  /// - idx_cities_sort_order: 加速城市排序
  /// - idx_commute_advices_timestamp: 加速通勤建议查询
  static Future<void> _createIndexes(Database db) async {
    try {
      // weather_cache 表索引
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_weather_cache_key ON weather_cache(key)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_weather_cache_expires_at ON weather_cache(expires_at)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_weather_cache_type ON weather_cache(type)',
      );

      // cities 表索引
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cities_name ON cities(name)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cities_sort_order ON cities(sortOrder)',
      );

      // commute_advices 表索引
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_commute_advices_timestamp ON commute_advices(timestamp)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_commute_advices_type ON commute_advices(adviceType)',
      );

      debugPrint('Database indexes created successfully');
    } catch (e) {
      debugPrint('Error creating database indexes: $e');
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
