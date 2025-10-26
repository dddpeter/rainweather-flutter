import 'dart:convert';
import '../models/weather_model.dart';
import '../services/database_service.dart';
import '../services/smart_cache_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';

/// 天气缓存管理器
/// 统一管理天气数据的缓存逻辑（智能缓存 + 数据库缓存）
class WeatherCacheManager {
  final DatabaseService _databaseService;
  final SmartCacheService _smartCache;

  WeatherCacheManager({
    required DatabaseService databaseService,
    required SmartCacheService smartCache,
  }) : _databaseService = databaseService,
       _smartCache = smartCache;

  /// 获取天气数据（优先智能缓存，然后是数据库缓存）
  Future<WeatherModel?> getWeather(String cityName) async {
    try {
      // 1. 优先使用智能缓存
      final smartCacheData = await _getFromSmartCache(cityName);
      if (smartCacheData != null) {
        Logger.d('智能缓存命中: $cityName', tag: 'CacheManager');
        return smartCacheData;
      }

      // 2. 尝试数据库缓存
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';
      final dbCacheData = await _databaseService.getWeatherData(weatherKey);
      if (dbCacheData != null) {
        Logger.d('数据库缓存命中: $cityName', tag: 'CacheManager');
        return dbCacheData;
      }

      Logger.d('缓存未命中: $cityName', tag: 'CacheManager');
      return null;
    } catch (e, stackTrace) {
      Logger.e(
        '获取缓存失败: $cityName',
        tag: 'CacheManager',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'WeatherCacheManager.getWeather',
        type: AppErrorType.cache,
      );
      return null;
    }
  }

  /// 保存天气数据（同时保存到智能缓存和数据库）
  Future<void> saveWeather(String cityName, WeatherModel weather) async {
    try {
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';

      // 1. 保存到数据库缓存
      await _databaseService.putWeatherData(weatherKey, weather);

      // 2. 保存到智能缓存
      await _saveToSmartCache(cityName, weather);

      Logger.d('天气数据已缓存: $cityName', tag: 'CacheManager');
    } catch (e, stackTrace) {
      Logger.e(
        '保存缓存失败: $cityName',
        tag: 'CacheManager',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'WeatherCacheManager.saveWeather',
        type: AppErrorType.cache,
      );
    }
  }

  /// 从智能缓存获取数据
  Future<WeatherModel?> _getFromSmartCache(String cityName) async {
    try {
      final cacheKey = '$cityName:weather';
      final cachedJson = await _smartCache.getData(
        key: cacheKey,
        type: CacheDataType.currentWeather,
      );

      if (cachedJson != null) {
        return WeatherModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(cachedJson) as Map),
        );
      }
      return null;
    } catch (e) {
      Logger.e('智能缓存读取失败', tag: 'CacheManager', error: e);
      return null;
    }
  }

  /// 保存到智能缓存
  Future<void> _saveToSmartCache(String cityName, WeatherModel weather) async {
    try {
      final cacheKey = '$cityName:weather';
      await _smartCache.putData(
        key: cacheKey,
        data: weather.toJson(),
        type: CacheDataType.currentWeather,
      );
    } catch (e) {
      Logger.e('智能缓存存储失败', tag: 'CacheManager', error: e);
    }
  }

  /// 删除缓存数据
  Future<void> deleteWeather(String cityName) async {
    try {
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';
      await _databaseService.deleteWeatherData(weatherKey);
      // 注意：SmartCacheService 没有 deleteData 方法，智能缓存会自动过期
      Logger.d('缓存已删除: $cityName', tag: 'CacheManager');
    } catch (e) {
      Logger.e('删除缓存失败: $cityName', tag: 'CacheManager', error: e);
    }
  }

  /// 检查缓存是否存在
  Future<bool> hasWeather(String cityName) async {
    final data = await getWeather(cityName);
    return data != null;
  }
}
