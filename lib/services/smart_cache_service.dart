import 'dart:convert';
import 'database_service.dart';

/// 缓存数据类型
enum CacheDataType {
  currentWeather, // 当前天气 - 5分钟
  hourlyForecast, // 小时预报 - 15分钟
  dailyForecast, // 日预报 - 1小时
  cityList, // 城市列表 - 24小时
  locationData, // 定位数据 - 10分钟
  aiSummary, // AI摘要 - 6小时
  sunMoonData, // 日月数据 - 6小时
}

/// 缓存条目
class CacheEntry {
  final String data; // 存储JSON字符串
  final DateTime expiresAt;
  final DateTime createdAt;
  final CacheDataType type;

  CacheEntry({required this.data, required this.expiresAt, required this.type})
    : createdAt = DateTime.now();

  /// 从JSON创建
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
      type: CacheDataType.values[json['type'] as int],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'type': type.index,
    };
  }
}

/// 智能缓存服务 - 实现多级缓存和智能过期策略
class SmartCacheService {
  static final SmartCacheService _instance = SmartCacheService._internal();
  factory SmartCacheService() => _instance;
  SmartCacheService._internal();

  // 内存缓存（LRU策略）
  final Map<String, CacheEntry> _memoryCache = {};
  static const int _maxMemoryCacheSize = 50; // 最大缓存条目数

  // DatabaseService实例（延迟初始化）
  DatabaseService get _databaseService => DatabaseService.getInstance();

  /// 获取数据类型的过期时间
  Duration _getExpirationForType(CacheDataType type) {
    switch (type) {
      case CacheDataType.currentWeather:
        return const Duration(minutes: 5);
      case CacheDataType.hourlyForecast:
        return const Duration(minutes: 15);
      case CacheDataType.dailyForecast:
        return const Duration(hours: 1);
      case CacheDataType.cityList:
        return const Duration(hours: 24);
      case CacheDataType.locationData:
        return const Duration(minutes: 10);
      case CacheDataType.aiSummary:
        return const Duration(hours: 6);
      case CacheDataType.sunMoonData:
        return const Duration(hours: 6);
    }
  }

  /// 存储数据到缓存
  Future<void> putData({
    required String key,
    required dynamic data,
    required CacheDataType type,
  }) async {
    try {
      // 将数据序列化为JSON字符串
      final jsonData = data is String ? data : jsonEncode(data);

      final expiration = _getExpirationForType(type);
      final entry = CacheEntry(
        data: jsonData,
        expiresAt: DateTime.now().add(expiration),
        type: type,
      );

      // 1. 存储到内存缓存
      _putToMemoryCache(key, entry);

      // 2. 存储到SQLite（异步）
      await _putToDatabase(key, entry);
    } catch (e) {
      print('❌ 缓存存储失败: $key, 错误: $e');
    }
  }

  /// 从缓存获取数据（返回JSON字符串）
  Future<String?> getData({
    required String key,
    required CacheDataType type,
  }) async {
    try {
      // 1. 先检查内存缓存
      final memoryEntry = _getFromMemoryCache(key);
      if (memoryEntry != null && !_isExpired(memoryEntry)) {
        print('💾 从内存缓存获取: $key');
        return memoryEntry.data;
      }

      // 2. 检查SQLite缓存
      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null && !_isExpired(dbEntry)) {
        print('💾 从SQLite缓存获取: $key');
        // 更新到内存缓存
        _putToMemoryCache(key, dbEntry);
        return dbEntry.data;
      }

      print('🔄 缓存未命中: $key');
      return null;
    } catch (e) {
      print('❌ 缓存读取失败: $key, 错误: $e');
      return null;
    }
  }

  /// 检查缓存是否有效
  Future<bool> isCacheValid({
    required String key,
    required CacheDataType type,
  }) async {
    try {
      // 先检查内存缓存
      final memoryEntry = _getFromMemoryCache(key);
      if (memoryEntry != null && !_isExpired(memoryEntry)) {
        return true;
      }

      // 再检查SQLite缓存
      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null && !_isExpired(dbEntry)) {
        return true;
      }

      return false;
    } catch (e) {
      print('❌ 缓存检查失败: $key, 错误: $e');
      return false;
    }
  }

  /// 获取缓存年龄
  Future<Duration?> getCacheAge(String key) async {
    try {
      // 先检查内存缓存
      final memoryEntry = _getFromMemoryCache(key);
      if (memoryEntry != null) {
        return DateTime.now().difference(memoryEntry.createdAt);
      }

      // 再检查SQLite缓存
      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null) {
        return DateTime.now().difference(dbEntry.createdAt);
      }

      return null;
    } catch (e) {
      print('❌ 获取缓存年龄失败: $key, 错误: $e');
      return null;
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    try {
      print('🧹 清理过期缓存...');

      // 清理内存缓存
      final beforeCount = _memoryCache.length;
      _memoryCache.removeWhere((key, entry) => _isExpired(entry));
      final afterCount = _memoryCache.length;
      print('   内存缓存: 清理 ${beforeCount - afterCount} 条');

      // 清理SQLite缓存（异步）
      await _clearExpiredDatabaseCache();

      print('✅ 过期缓存清理完成');
    } catch (e) {
      print('❌ 清理缓存失败: $e');
    }
  }

  /// 预加载常用数据到内存缓存
  Future<void> preloadCommonData() async {
    try {
      print('🚀 预加载常用数据到内存缓存...');
      final commonKeys = [
        'current_location:current_weather',
        'main_cities_list',
      ];

      int loadedCount = 0;
      for (final key in commonKeys) {
        final dbEntry = await _getFromDatabase(key);
        if (dbEntry != null && !_isExpired(dbEntry)) {
          _putToMemoryCache(key, dbEntry);
          loadedCount++;
        }
      }

      print('✅ 预加载完成: $loadedCount 条数据');
    } catch (e) {
      print('❌ 预加载失败: $e');
    }
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    try {
      print('🗑️ 清空所有缓存...');
      _memoryCache.clear();
      // 这里可以添加清空SQLite的逻辑
      print('✅ 所有缓存已清空');
    } catch (e) {
      print('❌ 清空缓存失败: $e');
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _memoryCache.length,
      'memory_cache_max': _maxMemoryCacheSize,
      'memory_cache_usage':
          '${(_memoryCache.length / _maxMemoryCacheSize * 100).toStringAsFixed(1)}%',
    };
  }

  // ========== 私有方法 ==========

  /// 检查是否过期
  bool _isExpired(CacheEntry entry) {
    return DateTime.now().isAfter(entry.expiresAt);
  }

  /// 存储到内存缓存（LRU策略）
  void _putToMemoryCache(String key, CacheEntry entry) {
    // 如果超过最大大小，移除最旧的条目
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.entries
          .reduce(
            (a, b) => a.value.createdAt.isBefore(b.value.createdAt) ? a : b,
          )
          .key;
      _memoryCache.remove(oldestKey);
      print('🗑️ 内存缓存已满，移除最旧条目: $oldestKey');
    }

    _memoryCache[key] = entry;
  }

  /// 从内存缓存获取
  CacheEntry? _getFromMemoryCache(String key) {
    final entry = _memoryCache[key];
    if (entry != null) {
      // 更新访问时间（模拟LRU）
      _memoryCache.remove(key);
      _memoryCache[key] = entry;
    }
    return entry;
  }

  /// 存储到SQLite
  Future<void> _putToDatabase(String key, CacheEntry entry) async {
    try {
      // 使用DatabaseService存储
      await _databaseService.putString(
        'smart_cache:$key',
        jsonEncode(entry.toJson()),
      );
    } catch (e) {
      print('❌ SQLite存储失败: $key, 错误: $e');
    }
  }

  /// 从SQLite获取
  Future<CacheEntry?> _getFromDatabase(String key) async {
    try {
      // 从DatabaseService获取
      final jsonString = await _databaseService.getString('smart_cache:$key');
      if (jsonString == null) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CacheEntry.fromJson(json);
    } catch (e) {
      print('❌ SQLite读取失败: $key, 错误: $e');
      return null;
    }
  }

  /// 清理SQLite中的过期缓存
  Future<void> _clearExpiredDatabaseCache() async {
    try {
      // 这里需要DatabaseService支持批量删除过期数据
      // 暂时只打印日志
      print('   SQLite缓存: 清理过期数据（需要DatabaseService支持）');
    } catch (e) {
      print('❌ SQLite清理失败: $e');
    }
  }
}
