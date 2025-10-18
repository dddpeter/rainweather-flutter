import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/city_model.dart';

/// 外部存储的用户城市数据库服务
/// 用于持久化保存用户自定义的主要城市列表
/// 即使app被卸载重装，也能恢复用户的城市列表
class ExternalCityStorageService {
  static ExternalCityStorageService? _instance;
  Database? _database;

  ExternalCityStorageService._();

  static ExternalCityStorageService getInstance() {
    _instance ??= ExternalCityStorageService._();
    return _instance!;
  }

  /// 获取外部存储数据库
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化外部存储数据库
  Future<Database> _initDatabase() async {
    try {
      // 请求存储权限（Android 10以下需要，10及以上访问Documents目录不需要）
      if (Platform.isAndroid) {
        try {
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final result = await Permission.storage.request();
            if (!result.isGranted) {
              print('⚠️ 外部存储权限未授予，将尝试继续（Android 10+ Documents目录不需要权限）');
            } else {
              print('✅ 外部存储权限已授予');
            }
          }
        } catch (e) {
          print('⚠️ 权限检查失败，将尝试继续: $e');
        }
      }

      // 获取真正的外部存储路径（不会在卸载时删除）
      Directory? externalDir;

      if (Platform.isAndroid) {
        // Android: 使用公共外部存储目录
        // /storage/emulated/0/Android/data/[package]/files 会在卸载时删除
        // 我们需要使用 /storage/emulated/0/Documents/ 这样的公共目录
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          // 从 /storage/emulated/0/Android/data/.../files
          // 提取 /storage/emulated/0/
          final pathParts = appDir.path.split('/');
          final baseIndex = pathParts.indexOf('Android');
          if (baseIndex > 0) {
            final basePath = pathParts.sublist(0, baseIndex).join('/');
            // 使用公共Documents目录
            externalDir = Directory('$basePath/Documents');
          }
        }

        // 如果上述方法失败，尝试直接使用固定路径
        externalDir ??= Directory('/storage/emulated/0/Documents');
      } else if (Platform.isIOS) {
        // iOS: 使用Documents目录（iCloud不会同步，但会保留）
        externalDir = await getApplicationDocumentsDirectory();
      }

      if (externalDir == null) {
        throw Exception('无法获取外部存储目录');
      }

      // 确保Documents目录存在
      if (!await externalDir.exists()) {
        await externalDir.create(recursive: true);
      }

      // 创建RainWeather子目录（更清晰的组织）
      final dbDir = Directory(join(externalDir.path, 'RainWeather'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        print('📁 创建外部存储目录: ${dbDir.path}');
      }

      // 数据库文件路径
      final dbPath = join(dbDir.path, 'user_cities.db');
      print('📁 外部存储数据库路径: $dbPath');

      // 检查数据库文件是否已存在
      final dbFile = File(dbPath);
      final dbExists = await dbFile.exists();
      print(
        '📁 数据库文件${dbExists ? "已存在" : "不存在"}，将${dbExists ? "打开" : "创建"}数据库',
      );

      // 打开数据库
      final db = await openDatabase(dbPath, version: 1, onCreate: _onCreate);

      // 打印数据库信息
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      print('✅ 外部存储数据库初始化完成，包含表: ${tables.map((t) => t['name']).join(', ')}');

      return db;
    } catch (e) {
      print('❌ 外部存储数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_cities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        addedAt INTEGER NOT NULL
      )
    ''');
    print('✅ 外部存储数据库表创建完成');
  }

  /// 保存用户添加的城市
  Future<void> saveUserCity(CityModel city) async {
    try {
      final db = await database;
      await db.insert('user_cities', {
        'id': city.id,
        'name': city.name,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      print('💾 外部存储: 保存用户城市 ${city.name}');
    } catch (e) {
      print('❌ 外部存储: 保存城市失败: $e');
    }
  }

  /// 批量保存用户城市
  Future<void> saveUserCities(List<CityModel> cities) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final city in cities) {
        batch.insert('user_cities', {
          'id': city.id,
          'name': city.name,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      print('💾 外部存储: 批量保存 ${cities.length} 个用户城市');
    } catch (e) {
      print('❌ 外部存储: 批量保存城市失败: $e');
    }
  }

  /// 删除用户城市
  Future<void> removeUserCity(String cityId) async {
    try {
      final db = await database;
      await db.delete('user_cities', where: 'id = ?', whereArgs: [cityId]);
      print('🗑️ 外部存储: 删除用户城市 $cityId');
    } catch (e) {
      print('❌ 外部存储: 删除城市失败: $e');
    }
  }

  /// 获取所有用户城市ID
  Future<List<String>> getUserCityIds() async {
    try {
      final db = await database;
      final result = await db.query(
        'user_cities',
        columns: ['id'],
        orderBy: 'addedAt ASC',
      );

      final ids = result.map((row) => row['id'] as String).toList();
      print('📦 外部存储: 读取 ${ids.length} 个用户城市ID');
      return ids;
    } catch (e) {
      print('❌ 外部存储: 读取城市ID失败: $e');
      return [];
    }
  }

  /// 获取所有用户城市信息
  Future<List<Map<String, dynamic>>> getUserCities() async {
    try {
      final db = await database;
      final result = await db.query('user_cities', orderBy: 'addedAt ASC');

      print('📦 外部存储: 读取 ${result.length} 个用户城市');

      // 详细输出每个城市的信息
      for (final city in result) {
        print(
          '   📍 城市: ${city['name']}, ID: ${city['id']}, 添加时间: ${DateTime.fromMillisecondsSinceEpoch(city['addedAt'] as int)}',
        );
      }

      return result;
    } catch (e, stackTrace) {
      print('❌ 外部存储: 读取城市失败: $e');
      print('❌ 堆栈跟踪: $stackTrace');
      return [];
    }
  }

  /// 清空所有用户城市
  Future<void> clearAllUserCities() async {
    try {
      final db = await database;
      await db.delete('user_cities');
      print('🗑️ 外部存储: 清空所有用户城市');
    } catch (e) {
      print('❌ 外部存储: 清空城市失败: $e');
    }
  }

  /// 检查城市是否已保存
  Future<bool> hasCity(String cityId) async {
    try {
      final db = await database;
      final result = await db.query(
        'user_cities',
        where: 'id = ?',
        whereArgs: [cityId],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('❌ 外部存储: 检查城市失败: $e');
      return false;
    }
  }

  // /// 获取数据库文件路径（用于调试）
  // Future<String?> getDatabasePath() async {
  //   try {
  //     Directory? externalDir;

  //     if (Platform.isAndroid) {
  //       final appDir = await getExternalStorageDirectory();
  //       if (appDir != null) {
  //         final pathParts = appDir.path.split('/');
  //         final baseIndex = pathParts.indexOf('Android');
  //         if (baseIndex > 0) {
  //           final basePath = pathParts.sublist(0, baseIndex).join('/');
  //           externalDir = Directory('$basePath/Documents');
  //         }
  //       }
  //       externalDir ??= Directory('/storage/emulated/0/Documents');
  //     } else if (Platform.isIOS) {
  //       externalDir = await getApplicationDocumentsDirectory();
  //     }

  //     if (externalDir == null) return null;

  //     final dbDir = Directory(join(externalDir.path, 'RainWeather'));
  //     return join(dbDir.path, 'user_cities.db');
  //   } catch (e) {
  //     print('❌ 获取数据库路径失败: $e');
  //     return null;
  //   }
  // }

  /// 获取统计信息
  Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM user_cities',
      );
      final countValue = result.first['count'];
      final count = countValue is int
          ? countValue
          : int.tryParse(countValue.toString()) ?? 0;

      return {'count': count, 'path': null};
    } catch (e) {
      print('❌ 获取统计信息失败: $e');
      return {'count': 0, 'path': null, 'error': e.toString()};
    }
  }
}
