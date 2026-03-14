import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/weather_model.dart';
import '../../models/sun_moon_index_model.dart';
import '../../constants/app_constants.dart';
import 'database_core.dart';

/// WeatherCacheService - 天气数据缓存服务
///
/// 职责：
/// - 天气模型缓存
/// - 日月指数缓存
/// - AI摘要缓存
/// - 删除天气数据
class WeatherCacheService {
  final DatabaseCore _core;

  WeatherCacheService(this._core);

  /// Store weather data
  Future<void> putWeatherData(String key, WeatherModel weatherData) async {
    final db = await _core.database;
    await db.insert('weather_cache', {
      'key': key,
      'data': jsonEncode(weatherData.toJson()),
      'type': 'WeatherModel',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(AppConstants.cacheExpiration)
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get weather data
  Future<WeatherModel?> getWeatherData(String key) async {
    final db = await _core.database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      final data = result.first['data'] as String;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return WeatherModel.fromJson(json);
      } catch (e) {
        print('Error parsing weather data: $e');
      }
    }
    return null;
  }

  /// Store sun/moon index data
  Future<void> putSunMoonIndexData(
    String key,
    SunMoonIndexData sunMoonIndexData,
  ) async {
    final db = await _core.database;
    await db.insert('weather_cache', {
      'key': key,
      'data': jsonEncode(sunMoonIndexData.toJson()),
      'type': 'SunMoonIndexData',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(AppConstants.sunMoonIndexCacheExpiration)
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get sun/moon index data
  Future<SunMoonIndexData?> getSunMoonIndexData(String key) async {
    final db = await _core.database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      final data = result.first['data'] as String;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return SunMoonIndexData.fromJson(json);
      } catch (e) {
        print('Error parsing sun/moon index data: $e');
      }
    }
    return null;
  }

  /// Store AI summary (24-hour weather summary)
  /// 缓存有效期：5分钟
  Future<void> putAISummary(String key, String summary) async {
    final db = await _core.database;
    await db.insert('weather_cache', {
      'key': key,
      'data': summary,
      'type': 'AISummary',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 5))
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get AI summary (24-hour weather summary)
  /// 如果缓存超过5分钟，返回null
  Future<String?> getAISummary(String key) async {
    final db = await _core.database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND type = ? AND expires_at > ?',
      whereArgs: [key, 'AISummary', DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      return result.first['data'] as String;
    }
    return null;
  }

  /// Store AI 15-day forecast summary
  /// 缓存有效期：5分钟
  Future<void> putAI15dSummary(String key, String summary) async {
    final db = await _core.database;
    await db.insert('weather_cache', {
      'key': key,
      'data': summary,
      'type': 'AI15dSummary',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 5))
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get AI 15-day forecast summary
  /// 如果缓存超过5分钟，返回null
  Future<String?> getAI15dSummary(String key) async {
    final db = await _core.database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND type = ? AND expires_at > ?',
      whereArgs: [key, 'AI15dSummary', DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      return result.first['data'] as String;
    }
    return null;
  }

  /// Delete weather data by key
  Future<void> deleteWeatherData(String key) async {
    final db = await _core.database;
    try {
      await db.delete('weather_cache', where: 'key = ?', whereArgs: [key]);
      print('Weather data deleted: $key');
    } catch (e) {
      print('Failed to delete weather data: $e');
    }
  }
}
