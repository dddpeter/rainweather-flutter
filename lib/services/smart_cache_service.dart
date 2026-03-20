import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'database_service.dart';
import '../utils/logger.dart';

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
class SmartCacheService extends WidgetsBindingObserver {
  static final SmartCacheService _instance = SmartCacheService._internal();
  factory SmartCacheService() => _instance;
  SmartCacheService._internal() {
    // 监听应用生命周期
    WidgetsBinding.instance.addObserver(this);
  }

  // 内存缓存（LRU策略）
  final Map<String, CacheEntry> _memoryCache = {};
  static const int _maxMemoryCacheSize = 100; // 最大缓存条目数（优化：50→100）
  static const int _maxMemoryCacheSizeBytes = 50 * 1024 * 1024; // 最大内存使用50MB

  // 缓存统计
  int _hitCount = 0;
  int _missCount = 0;
  int _totalRequests = 0;
  int _totalBytes = 0;

  // 预加载任务
  Timer? _preloadTimer;
  static const Duration _preloadInterval = Duration(minutes: 5);

  // DatabaseService实例（延迟初始化）
  DatabaseService get _databaseService => DatabaseService.getInstance();

  /// 获取数据类型的过期时间
  ///
  /// 智能缓存策略（根据数据特性和使用频率优化）：
  /// - 当前天气：5分钟（高频访问，需要实时性）
  /// - 小时预报：15分钟（中等频率，平衡实时性和性能）
  /// - 日预报：2小时（低频访问，可以缓存更久）
  /// - 城市列表：24小时（静态数据，很少变化）
  /// - 定位数据：30分钟（用户位置相对稳定）
  /// - AI摘要：3小时（AI内容相对稳定，但比之前更短）
  /// - 日月数据：12小时（日出日落时间固定，但需要每日更新）
  Duration _getExpirationForType(CacheDataType type) {
    switch (type) {
      case CacheDataType.currentWeather:
        return const Duration(minutes: 5); // 优化：10→5分钟，提高实时性
      case CacheDataType.hourlyForecast:
        return const Duration(minutes: 15); // 优化：30→15分钟，平衡性能
      case CacheDataType.dailyForecast:
        return const Duration(hours: 2); // 优化：1→2小时，低频数据
      case CacheDataType.cityList:
        return const Duration(hours: 24); // 保持不变
      case CacheDataType.locationData:
        return const Duration(minutes: 30); // 优化：1小时→30分钟
      case CacheDataType.aiSummary:
        return const Duration(hours: 3); // 优化：6→3小时，提高新鲜度
      case CacheDataType.sunMoonData:
        return const Duration(hours: 12); // 优化：6→12小时，每日更新
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
      final dataBytes = utf8.encode(jsonData).length;

      // 检查内存使用限制
      if (_totalBytes + dataBytes > _maxMemoryCacheSizeBytes) {
        await _evictMemoryCache(dataBytes);
      }

      final expiration = _getExpirationForType(type);
      final entry = CacheEntry(
        data: jsonData,
        expiresAt: DateTime.now().add(expiration),
        type: type,
      );

      // 1. 存储到内存缓存
      _putToMemoryCache(key, entry, dataBytes);

      // 2. 存储到SQLite（异步）
      await _putToDatabase(key, entry);

      if (kDebugMode) {
        Logger.log('💾 缓存已存储: $key (${dataBytes} bytes, ${type.name})');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.log('❌ 缓存存储失败: $key, 错误: $e');
      }
    }
  }

  /// 从缓存获取数据（返回JSON字符串）
  Future<String?> getData({
    required String key,
    required CacheDataType type,
  }) async {
    try {
      _totalRequests++;

      // 1. 先检查内存缓存
      final memoryEntry = _getFromMemoryCache(key);
      if (memoryEntry != null && !_isExpired(memoryEntry)) {
        _hitCount++;
        if (kDebugMode) {
          Logger.log('💾 从内存缓存获取: $key (命中率: ${_getHitRate()}%)');
        }
        return memoryEntry.data;
      }

      // 2. 检查SQLite缓存
      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null && !_isExpired(dbEntry)) {
        _hitCount++;
        if (kDebugMode) {
          Logger.log('💾 从SQLite缓存获取: $key (命中率: ${_getHitRate()}%)');
        }
        // 更新到内存缓存
        final dataBytes = utf8.encode(dbEntry.data).length;
        _putToMemoryCache(key, dbEntry, dataBytes);
        return dbEntry.data;
      }

      _missCount++;
      if (kDebugMode) {
        Logger.log('🔄 缓存未命中: $key (命中率: ${_getHitRate()}%)');
      }
      return null;
    } catch (e) {
      _missCount++;
      if (kDebugMode) {
        Logger.log('❌ 缓存读取失败: $key, 错误: $e');
      }
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
      Logger.log('❌ 缓存检查失败: $key, 错误: $e');
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
      Logger.log('❌ 获取缓存年龄失败: $key, 错误: $e');
      return null;
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    try {
      Logger.log('🧹 清理过期缓存...');

      // 清理内存缓存
      final beforeCount = _memoryCache.length;
      _memoryCache.removeWhere((key, entry) => _isExpired(entry));
      final afterCount = _memoryCache.length;
      Logger.log('   内存缓存: 清理 ${beforeCount - afterCount} 条');

      // 清理SQLite缓存（异步）
      await _clearExpiredDatabaseCache();

      Logger.log('✅ 过期缓存清理完成');
    } catch (e) {
      Logger.log('❌ 清理缓存失败: $e');
    }
  }

  /// 启动智能预加载服务
  void startPreloadService() {
    _preloadTimer?.cancel();
    _preloadTimer = Timer.periodic(_preloadInterval, (_) {
      _performSmartPreload();
    });
    if (kDebugMode) {
      Logger.log('🚀 智能预加载服务已启动 (间隔: ${_preloadInterval.inMinutes}分钟)');
    }
  }

  /// 停止预加载服务
  void stopPreloadService() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
    if (kDebugMode) {
      Logger.log('🛑 智能预加载服务已停止');
    }
  }

  /// 监听应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      Logger.log('📱 SmartCacheService: 应用状态变化 - $state');
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // 应用进入后台或被终止，停止预加载服务以节省资源
        stopPreloadService();
        break;
      case AppLifecycleState.resumed:
        // 应用恢复前台，重新启动预加载服务
        startPreloadService();
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏，停止预加载服务
        stopPreloadService();
        break;
    }
  }

  /// 销毁服务
  void dispose() {
    stopPreloadService();
    WidgetsBinding.instance.removeObserver(this);
    if (kDebugMode) {
      Logger.log('🗑️ SmartCacheService: 服务已销毁');
    }
  }

  /// 执行智能预加载
  Future<void> _performSmartPreload() async {
    try {
      if (kDebugMode) {
        Logger.log('🚀 执行智能预加载...');
      }

      // 预加载策略：根据使用频率和重要性
      final preloadTasks = [
        _preloadCurrentLocationWeather(),
        _preloadMainCitiesList(),
        _preloadHourlyForecast(),
        _preloadDailyForecast(),
      ];

      // 并行执行预加载任务
      final results = await Future.wait(preloadTasks);
      final successCount = results.where((success) => success).length;

      if (kDebugMode) {
        Logger.log('✅ 智能预加载完成: $successCount/${preloadTasks.length} 个任务成功');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.log('❌ 智能预加载失败: $e');
      }
    }
  }

  /// 预加载当前定位天气
  Future<bool> _preloadCurrentLocationWeather() async {
    try {
      const key = 'current_location:current_weather';

      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null && !_isExpired(dbEntry)) {
        final dataBytes = utf8.encode(dbEntry.data).length;
        _putToMemoryCache(key, dbEntry, dataBytes);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 预加载主要城市列表
  Future<bool> _preloadMainCitiesList() async {
    try {
      const key = 'main_cities_list';

      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null && !_isExpired(dbEntry)) {
        final dataBytes = utf8.encode(dbEntry.data).length;
        _putToMemoryCache(key, dbEntry, dataBytes);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 预加载小时预报
  Future<bool> _preloadHourlyForecast() async {
    try {
      const key = 'current_location:hourly_forecast';

      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null && !_isExpired(dbEntry)) {
        final dataBytes = utf8.encode(dbEntry.data).length;
        _putToMemoryCache(key, dbEntry, dataBytes);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 预加载日预报
  Future<bool> _preloadDailyForecast() async {
    try {
      const key = 'current_location:daily_forecast';

      final dbEntry = await _getFromDatabase(key);
      if (dbEntry != null && !_isExpired(dbEntry)) {
        final dataBytes = utf8.encode(dbEntry.data).length;
        _putToMemoryCache(key, dbEntry, dataBytes);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 预加载常用数据到内存缓存（兼容旧方法）
  Future<void> preloadCommonData() async {
    await _performSmartPreload();
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    try {
      if (kDebugMode) {
        Logger.log('🗑️ 清空所有缓存...');
      }

      // 清空内存缓存
      _memoryCache.clear();
      _totalBytes = 0;

      // 重置统计信息
      resetStats();

      // 停止预加载服务
      stopPreloadService();

      // 清空SQLite缓存（这里需要DatabaseService支持）
      await _clearAllDatabaseCache();

      if (kDebugMode) {
        Logger.log('✅ 所有缓存已清空');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.log('❌ 清空缓存失败: $e');
      }
    }
  }

  /// 清空SQLite中的所有缓存
  Future<void> _clearAllDatabaseCache() async {
    try {
      // 这里需要DatabaseService支持批量删除缓存数据
      // 暂时只打印日志
      if (kDebugMode) {
        Logger.log('   SQLite缓存: 清空所有数据（需要DatabaseService支持）');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.log('❌ SQLite清空失败: $e');
      }
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final hitRate = _getHitRate();
    final memoryUsagePercent = (_totalBytes / _maxMemoryCacheSizeBytes * 100);

    return {
      'memory_cache_size': _memoryCache.length,
      'memory_cache_max': _maxMemoryCacheSize,
      'memory_cache_usage_bytes': _totalBytes,
      'memory_cache_max_bytes': _maxMemoryCacheSizeBytes,
      'memory_cache_usage_percent': '${memoryUsagePercent.toStringAsFixed(1)}%',
      'hit_count': _hitCount,
      'miss_count': _missCount,
      'total_requests': _totalRequests,
      'hit_rate': '${hitRate.toStringAsFixed(1)}%',
      'preload_service_running': _preloadTimer?.isActive ?? false,
    };
  }

  /// 获取命中率
  double _getHitRate() {
    if (_totalRequests == 0) return 0.0;
    return (_hitCount / _totalRequests) * 100;
  }

  /// 重置统计信息
  void resetStats() {
    _hitCount = 0;
    _missCount = 0;
    _totalRequests = 0;
    if (kDebugMode) {
      Logger.log('📊 缓存统计信息已重置');
    }
  }

  /// 获取缓存分析报告
  Map<String, dynamic> getCacheAnalysis() {
    final stats = getCacheStats();
    final hitRate = _getHitRate();

    String performance = '优秀';
    if (hitRate < 70) {
      performance = '需要优化';
    } else if (hitRate < 85) {
      performance = '良好';
    }

    String memoryStatus = '正常';
    final memoryUsagePercent = (_totalBytes / _maxMemoryCacheSizeBytes * 100);
    if (memoryUsagePercent > 90) {
      memoryStatus = '接近上限';
    } else if (memoryUsagePercent > 70) {
      memoryStatus = '使用较高';
    }

    return {
      'performance': performance,
      'hit_rate': hitRate,
      'memory_status': memoryStatus,
      'memory_usage_percent': memoryUsagePercent,
      'recommendations': _getRecommendations(hitRate, memoryUsagePercent),
      'stats': stats,
    };
  }

  /// 获取优化建议
  List<String> _getRecommendations(double hitRate, double memoryUsagePercent) {
    final recommendations = <String>[];

    if (hitRate < 70) {
      recommendations.add('缓存命中率较低，建议增加缓存时间或优化预加载策略');
    }

    if (memoryUsagePercent > 90) {
      recommendations.add('内存使用接近上限，建议清理过期缓存或减少缓存大小');
    }

    if (_memoryCache.length > _maxMemoryCacheSize * 0.8) {
      recommendations.add('缓存条目数量较多，建议优化LRU策略');
    }

    if (recommendations.isEmpty) {
      recommendations.add('缓存运行良好，无需特别优化');
    }

    return recommendations;
  }

  // ========== 私有方法 ==========

  /// 检查是否过期
  bool _isExpired(CacheEntry entry) {
    return DateTime.now().isAfter(entry.expiresAt);
  }

  /// 存储到内存缓存（LRU策略 + 大小限制）
  void _putToMemoryCache(String key, CacheEntry entry, int dataBytes) {
    // 如果超过最大条目数，移除最旧的条目
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.entries
          .reduce(
            (a, b) => a.value.createdAt.isBefore(b.value.createdAt) ? a : b,
          )
          .key;
      final removedEntry = _memoryCache.remove(oldestKey);
      if (removedEntry != null) {
        _totalBytes -= utf8.encode(removedEntry.data).length;
        if (kDebugMode) {
          Logger.log('🗑️ 内存缓存已满，移除最旧条目: $oldestKey');
        }
      }
    }

    _memoryCache[key] = entry;
    _totalBytes += dataBytes;
  }

  /// 内存缓存清理（当接近内存限制时）
  Future<void> _evictMemoryCache(int requiredBytes) async {
    if (kDebugMode) {
      Logger.log('🧹 内存使用接近上限，开始清理缓存...');
    }

    // 按创建时间排序，移除最旧的条目
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    int freedBytes = 0;
    for (final entry in sortedEntries) {
      if (freedBytes >= requiredBytes) break;

      final entryBytes = utf8.encode(entry.value.data).length;
      _memoryCache.remove(entry.key);
      _totalBytes -= entryBytes;
      freedBytes += entryBytes;
    }

    if (kDebugMode) {
      Logger.log('✅ 内存缓存清理完成，释放 ${freedBytes} bytes');
    }
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
      Logger.log('❌ SQLite存储失败: $key, 错误: $e');
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
      Logger.log('❌ SQLite读取失败: $key, 错误: $e');
      return null;
    }
  }

  /// 清理SQLite中的过期缓存
  Future<void> _clearExpiredDatabaseCache() async {
    try {
      // 这里需要DatabaseService支持批量删除过期数据
      // 暂时只打印日志
      Logger.log('   SQLite缓存: 清理过期数据（需要DatabaseService支持）');
    } catch (e) {
      Logger.log('❌ SQLite清理失败: $e');
    }
  }
}
