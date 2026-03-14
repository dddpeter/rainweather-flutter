import 'package:sqflite/sqflite.dart';
import '../../constants/app_constants.dart';
import 'database_core.dart';

/// CacheService - 通用缓存服务
///
/// 职责：
/// - 基本类型缓存（String, Boolean, Integer）
/// - 清理过期数据
/// - 清空缓存
class CacheService {
  final DatabaseCore _core;

  CacheService(this._core);

  /// Store string data
  Future<void> putString(String key, String value) async {
    final db = await _core.database;
    await db.insert('weather_cache', {
      'key': key,
      'data': value,
      'type': 'String',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(AppConstants.cacheExpiration)
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get string data
  Future<String?> getString(String key) async {
    final db = await _core.database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      return result.first['data'] as String?;
    }
    return null;
  }

  /// Store boolean data
  Future<void> putBoolean(String key, bool value) async {
    await putString(key, value.toString());
  }

  /// Get boolean data
  Future<bool> getBoolean(String key, bool defaultValue) async {
    final value = await getString(key);
    if (value != null) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  /// Store integer data
  Future<void> putInt(String key, int value) async {
    await putString(key, value.toString());
  }

  /// Get integer data
  Future<int> getInt(String key, int defaultValue) async {
    final value = await getString(key);
    if (value != null) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Delete expired data
  Future<int> cleanExpiredData() async {
    final db = await _core.database;
    return await db.delete(
      'weather_cache',
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final db = await _core.database;
      await db.delete('weather_cache');
      print('All cached data cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear only weather data, preserve cities and location
  Future<void> clearWeatherData() async {
    try {
      final db = await _core.database;

      await db.delete(
        'weather_cache',
        where:
            'key LIKE ? OR key LIKE ? OR key LIKE ? OR key LIKE ? OR key LIKE ?',
        whereArgs: [
          '%:${AppConstants.weatherAllKey}',
          '%:${AppConstants.hourlyForecastKey}',
          '%:${AppConstants.dailyForecastKey}',
          '%:${AppConstants.sunMoonIndexKey}',
          '${AppConstants.currentLocationKey}:${AppConstants.weatherAllKey}',
        ],
      );

      print('Weather data cleared successfully, cities preserved');
    } catch (e) {
      print('Error clearing weather data: $e');
    }
  }
}
