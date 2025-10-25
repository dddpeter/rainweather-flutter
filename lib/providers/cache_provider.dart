import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../services/smart_cache_service.dart';
// import '../services/database_service.dart';
import '../utils/logger.dart';

/// 缓存Provider - 专门管理缓存状态
class CacheProvider extends ChangeNotifier {
  final SmartCacheService _smartCache = SmartCacheService();
  // final DatabaseService _databaseService = DatabaseService.getInstance();

  // 缓存状态
  bool _isUsingCachedData = false;
  bool _isBackgroundRefreshing = false;
  DateTime? _lastCacheTime;
  Map<String, WeatherModel> _mainCitiesWeather = {};
  bool _isLoadingCitiesWeather = false;
  bool _hasPerformedInitialMainCitiesRefresh = false;
  DateTime? _lastMainCitiesRefreshTime;

  // 定时刷新
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(hours: 1);

  // Getters
  bool get isUsingCachedData => _isUsingCachedData;
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;
  DateTime? get lastCacheTime => _lastCacheTime;
  Map<String, WeatherModel> get mainCitiesWeather => _mainCitiesWeather;
  bool get isLoadingCitiesWeather => _isLoadingCitiesWeather;
  bool get hasPerformedInitialMainCitiesRefresh =>
      _hasPerformedInitialMainCitiesRefresh;
  DateTime? get lastMainCitiesRefreshTime => _lastMainCitiesRefreshTime;

  /// 初始化缓存Provider
  void initialize() {
    _startPeriodicRefresh();
    Logger.d('CacheProvider 初始化完成', tag: 'CacheProvider');
  }

  /// 获取天气数据（优先从缓存）
  Future<WeatherModel?> getWeatherData(LocationModel location) async {
    try {
      Logger.d('获取天气数据: ${location.district}', tag: 'CacheProvider');

      // 先尝试从缓存获取
      final cacheKey = '${location.district}:weather';
      final cachedData = await _smartCache.getData(
        key: cacheKey,
        type: CacheDataType.currentWeather,
      );
      if (cachedData != null) {
        final weatherData = jsonDecode(cachedData);
        final cachedWeather = WeatherModel.fromJson(weatherData);
        _isUsingCachedData = true;
        _lastCacheTime = DateTime.now();
        Logger.d('使用缓存天气数据', tag: 'CacheProvider');
        notifyListeners();
        return cachedWeather;
      }

      return null;
    } catch (e) {
      Logger.e('获取缓存天气数据失败', tag: 'CacheProvider', error: e);
      return null;
    }
  }

  /// 缓存天气数据
  Future<void> cacheWeatherData(
    LocationModel location,
    WeatherModel weather,
  ) async {
    try {
      final cacheKey = '${location.district}:weather';
      final weatherJson = jsonEncode(weather.toJson());
      await _smartCache.putData(
        key: cacheKey,
        data: weatherJson,
        type: CacheDataType.currentWeather,
      );
      _isUsingCachedData = false;
      _lastCacheTime = DateTime.now();
      Logger.d('天气数据缓存成功', tag: 'CacheProvider');
      notifyListeners();
    } catch (e) {
      Logger.e('缓存天气数据失败', tag: 'CacheProvider', error: e);
    }
  }

  /// 获取主要城市天气数据
  Future<Map<String, WeatherModel>> getMainCitiesWeather(
    List<CityModel> cities,
  ) async {
    if (_isLoadingCitiesWeather) {
      return _mainCitiesWeather;
    }

    try {
      _isLoadingCitiesWeather = true;
      notifyListeners();

      final Map<String, WeatherModel> weatherMap = {};

      for (final city in cities) {
        try {
          // final location = LocationModel(
          //   district: city.name,
          //   city: city.name,
          //   province: city.name, // 使用城市名称作为省份
          //   lat: 0.0, // 默认值
          //   lng: 0.0, // 默认值
          //   address: city.name,
          //   country: '中国',
          //   street: '',
          //   adcode: '',
          //   town: '',
          // );

          final cacheKey = '${city.name}:weather';
          final cachedData = await _smartCache.getData(
            key: cacheKey,
            type: CacheDataType.currentWeather,
          );
          WeatherModel? weather;
          if (cachedData != null) {
            final weatherData = jsonDecode(cachedData);
            weather = WeatherModel.fromJson(weatherData);
          }
          if (weather != null) {
            weatherMap[city.name] = weather;
          }
        } catch (e) {
          Logger.e('获取城市 ${city.name} 天气数据失败', tag: 'CacheProvider', error: e);
        }
      }

      _mainCitiesWeather = weatherMap;
      _hasPerformedInitialMainCitiesRefresh = true;
      _lastMainCitiesRefreshTime = DateTime.now();

      Logger.s('主要城市天气数据获取完成，共 ${weatherMap.length} 个城市', tag: 'CacheProvider');
    } catch (e) {
      Logger.e('获取主要城市天气数据失败', tag: 'CacheProvider', error: e);
    } finally {
      _isLoadingCitiesWeather = false;
      notifyListeners();
    }

    return _mainCitiesWeather;
  }

  /// 刷新主要城市天气数据
  Future<void> refreshMainCitiesWeather(List<CityModel> cities) async {
    try {
      Logger.d('刷新主要城市天气数据', tag: 'CacheProvider');
      await getMainCitiesWeather(cities);
    } catch (e) {
      Logger.e('刷新主要城市天气数据失败', tag: 'CacheProvider', error: e);
    }
  }

  /// 获取特定城市的天气数据
  Future<WeatherModel?> getCityWeather(String cityName) async {
    return _mainCitiesWeather[cityName];
  }

  /// 缓存特定城市的天气数据
  Future<void> cacheCityWeather(String cityName, WeatherModel weather) async {
    _mainCitiesWeather[cityName] = weather;
    notifyListeners();
    Logger.d('城市 $cityName 天气数据缓存成功', tag: 'CacheProvider');
  }

  /// 启动定时刷新
  void _startPeriodicRefresh() {
    _stopPeriodicRefresh();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      Logger.d('定时刷新触发', tag: 'CacheProvider');
      _performPeriodicRefresh();
    });
    Logger.d('定时刷新已启动，间隔 ${_refreshInterval.inHours} 小时', tag: 'CacheProvider');
  }

  /// 停止定时刷新
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    Logger.d('定时刷新已停止', tag: 'CacheProvider');
  }

  /// 执行定时刷新
  void _performPeriodicRefresh() {
    // 这里可以添加定时刷新逻辑
    Logger.d('执行定时刷新', tag: 'CacheProvider');
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      await _smartCache.clearAllCache();
      _mainCitiesWeather.clear();
      _isUsingCachedData = false;
      _isBackgroundRefreshing = false;
      _lastCacheTime = null;
      _hasPerformedInitialMainCitiesRefresh = false;
      _lastMainCitiesRefreshTime = null;

      Logger.s('所有缓存已清除', tag: 'CacheProvider');
      notifyListeners();
    } catch (e) {
      Logger.e('清除缓存失败', tag: 'CacheProvider', error: e);
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    try {
      await _smartCache.clearExpiredCache();
      Logger.s('过期缓存已清除', tag: 'CacheProvider');
    } catch (e) {
      Logger.e('清除过期缓存失败', tag: 'CacheProvider', error: e);
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _smartCache.getCacheStats();
    } catch (e) {
      Logger.e('获取缓存统计信息失败', tag: 'CacheProvider', error: e);
      return {};
    }
  }

  @override
  void dispose() {
    _stopPeriodicRefresh();
    super.dispose();
  }
}
