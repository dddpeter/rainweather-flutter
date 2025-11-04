import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 缓存条目
class CacheEntry {
  final String data;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.duration,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > duration;

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'duration': duration.inMilliseconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: json['data'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    duration: Duration(milliseconds: json['duration']),
  );
}

/// 请求缓存服务
/// 提供智能缓存机制，避免重复请求相同数据
class RequestCacheService {
  static final RequestCacheService _instance = RequestCacheService._internal();
  factory RequestCacheService() => _instance;
  RequestCacheService._internal();

  static const String _cachePrefix = 'request_cache_';
  static const int _maxCacheSize = 100; // 最大缓存条目数

  /// 获取缓存数据
  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final cacheData = prefs.getString(cacheKey);

      if (cacheData == null) {
        if (kDebugMode) {
          print('📭 缓存未命中 - $key');
        }
        return null;
      }

      final entry = CacheEntry.fromJson(jsonDecode(cacheData));

      if (entry.isExpired) {
        if (kDebugMode) {
          print('⏰ 缓存已过期 - $key');
        }
        await _removeCache(key);
        return null;
      }

      if (kDebugMode) {
        print('💾 缓存命中 - $key');
      }

      return fromJson(jsonDecode(entry.data));
    } catch (e) {
      if (kDebugMode) {
        print('❌ 缓存读取失败 - $key: $e');
      }
      return null;
    }
  }

  /// 设置缓存数据
  Future<void> set<T>(
    String key,
    T data,
    Duration duration, {
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';

      final entry = CacheEntry(
        data: jsonEncode(toJson(data)),
        timestamp: DateTime.now(),
        duration: duration,
      );

      await prefs.setString(cacheKey, jsonEncode(entry.toJson()));

      if (kDebugMode) {
        print('💾 缓存已设置 - $key (${duration.inMinutes}分钟)');
      }

      // 清理过期缓存
      await _cleanExpiredCache();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 缓存设置失败 - $key: $e');
      }
    }
  }

  /// 移除指定缓存
  Future<void> _removeCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      await prefs.remove(cacheKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ 缓存移除失败 - $key: $e');
      }
    }
  }

  /// 清理过期缓存
  Future<void> _cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      int removedCount = 0;
      for (final key in keys) {
        final cacheData = prefs.getString(key);
        if (cacheData != null) {
          try {
            final entry = CacheEntry.fromJson(jsonDecode(cacheData));
            if (entry.isExpired) {
              await prefs.remove(key);
              removedCount++;
            }
          } catch (e) {
            // 解析失败，直接删除
            await prefs.remove(key);
            removedCount++;
          }
        }
      }

      if (kDebugMode && removedCount > 0) {
        print('🧹 清理过期缓存: $removedCount 条');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 清理过期缓存失败: $e');
      }
    }
  }

  /// 清理所有缓存
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      if (kDebugMode) {
        print('🗑️ 所有缓存已清理');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 清理所有缓存失败: $e');
      }
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      int totalCount = 0;
      int expiredCount = 0;
      int validCount = 0;

      for (final key in keys) {
        totalCount++;
        final cacheData = prefs.getString(key);
        if (cacheData != null) {
          try {
            final entry = CacheEntry.fromJson(jsonDecode(cacheData));
            if (entry.isExpired) {
              expiredCount++;
            } else {
              validCount++;
            }
          } catch (e) {
            expiredCount++;
          }
        }
      }

      return {
        'total': totalCount,
        'valid': validCount,
        'expired': expiredCount,
        'maxSize': _maxCacheSize,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ 获取缓存统计失败: $e');
      }
      return {'total': 0, 'valid': 0, 'expired': 0, 'maxSize': _maxCacheSize};
    }
  }
}

/// 缓存配置
class CacheConfig {
  /// 天气数据缓存时间
  static const Duration weatherData = Duration(minutes: 10);

  /// AI请求缓存时间（5分钟，避免频繁重复生成）
  static const Duration aiRequest = Duration(minutes: 5);

  /// 定位数据缓存时间
  static const Duration locationData = Duration(minutes: 30);

  /// 城市数据缓存时间
  static const Duration cityData = Duration(hours: 24);

  /// 配置数据缓存时间
  static const Duration configData = Duration(hours: 12);
}
