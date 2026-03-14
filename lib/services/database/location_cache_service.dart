import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/location_model.dart';
import 'database_core.dart';

/// LocationCacheService - 位置数据缓存服务
///
/// 职责：
/// - 位置数据存储
/// - 位置数据获取
/// - 位置数据删除
class LocationCacheService {
  final DatabaseCore _core;

  LocationCacheService(this._core);

  /// Store location data
  Future<void> putLocationData(String key, LocationModel locationData) async {
    final db = await _core.database;
    await db.insert('location_cache', {
      'key': key,
      'data': jsonEncode(locationData.toJson()),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get location data
  Future<LocationModel?> getLocationData(String key) async {
    final db = await _core.database;
    final result = await db.query(
      'location_cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      final data = result.first['data'] as String;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return LocationModel.fromJson(json);
      } catch (e) {
        print('Error parsing location data: $e');
      }
    }
    return null;
  }

  /// Delete location data by key
  Future<void> deleteLocationData(String key) async {
    final db = await _core.database;
    try {
      await db.delete('location_cache', where: 'key = ?', whereArgs: [key]);
      print('Location data deleted: $key');
    } catch (e) {
      print('Failed to delete location data: $e');
    }
  }
}
