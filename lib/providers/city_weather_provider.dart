import 'dart:async';
import 'package:flutter/material.dart';
import '../models/city_weather_data.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/weather_service.dart';
import '../services/database_service.dart';
import '../services/sun_moon_index_service.dart';
import '../providers/ai_insights_provider.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// 城市天气数据Provider
/// 
/// 专门用于管理城市天气页面的数据加载、缓存和状态管理
/// 不干扰当前定位城市的天气数据
class CityWeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();
  
  /// AI Insights Provider 引用
  AIInsightsProvider? _aiInsightsProvider;

  /// 城市天气数据缓存 `Map<cityName, CityWeatherData>`
  final Map<String, CityWeatherData> _cityWeatherDataMap = {};

  /// 城市天气数据 `Map<cityName, WeatherModel>`
  final Map<String, WeatherModel> _cityWeatherMap = {};

  /// 城市日出日落和生活指数数据 `Map<cityName, SunMoonIndexData>`
  final Map<String, SunMoonIndexData> _citySunMoonIndexMap = {};

  /// 城市AI摘要 `Map<cityName, summary>`
  final Map<String, String> _cityWeatherSummaryMap = {};
  final Map<String, String> _cityForecast15dSummaryMap = {};

  /// 正在生成AI摘要的城市集合
  final Set<String> _generatingSummaryCities = {};
  final Set<String> _generating15dSummaryCities = {};

  /// 设置 AIInsightsProvider 引用
  void setAIInsightsProvider(AIInsightsProvider provider) {
    _aiInsightsProvider = provider;
  }

  /// 获取城市的天气数据状态
  CityWeatherData? getCityWeatherData(String cityName) {
    return _cityWeatherDataMap[cityName];
  }

  /// 获取城市的天气数据
  WeatherModel? getCityWeather(String cityName) {
    return _cityWeatherMap[cityName];
  }

  /// 获取城市的日出日落和生活指数数据
  SunMoonIndexData? getCitySunMoonIndexData(String cityName) {
    return _citySunMoonIndexMap[cityName];
  }

  /// 获取城市的AI天气摘要
  String? getCityWeatherSummary(String cityName) {
    return _cityWeatherSummaryMap[cityName];
  }

  /// 获取城市的15日预报AI摘要
  String? getCityForecast15dSummary(String cityName) {
    return _cityForecast15dSummaryMap[cityName];
  }

  /// 检查城市是否正在生成AI摘要
  bool isGeneratingSummary(String cityName) {
    return _generatingSummaryCities.contains(cityName);
  }

  /// 检查城市是否正在生成15日预报AI摘要
  bool isGenerating15dSummary(String cityName) {
    return _generating15dSummaryCities.contains(cityName);
  }

  /// 加载城市天气数据
  /// 
  /// [cityName] 城市名称
  /// [cityId] 城市ID（可选，如果提供则直接使用）
  /// [forceRefresh] 是否强制刷新，忽略缓存
  Future<void> loadCityWeather(
    String cityName, {
    String? cityId,
    bool forceRefresh = false,
  }) async {
    // 标记为加载中
    _cityWeatherDataMap[cityName] = CityWeatherData.loading(
      cityName,
      cityId: cityId,
    );
    notifyListeners();

    try {
      // 检查缓存
      if (!forceRefresh) {
        final cachedWeather = await _loadFromCache(cityName);
        if (cachedWeather != null) {
          Logger.d('使用缓存的城市天气数据: $cityName', tag: 'CityWeatherProvider');
          
          _cityWeatherMap[cityName] = cachedWeather;
          _cityWeatherDataMap[cityName] = CityWeatherData(
            cityName: cityName,
            cityId: cityId,
            cacheTime: DateTime.now(),
            hasCachedData: true,
          );
          
          // 异步加载日出日落和生活指数数据
          _loadSunMoonIndexData(cityName);
          
          notifyListeners();
          return;
        }
      }

      // 从API获取数据
      Logger.d('从API获取城市天气数据: $cityName', tag: 'CityWeatherProvider');
      
      WeatherModel? weather;
      if (cityId != null && cityId.isNotEmpty) {
        // 直接使用城市ID获取
        weather = await _weatherService.getWeatherData(cityId);
      } else {
        // 通过城市名称获取
        final location = LocationModel(
          address: cityName,
          country: '中国',
          province: '未知',
          city: cityName,
          district: cityName,
          street: '未知',
          adcode: '未知',
          town: '未知',
          lat: 0.0,
          lng: 0.0,
        );
        weather = await _weatherService.getWeatherDataForLocation(location);
      }

      if (weather != null) {
        // 保存到内存缓存
        _cityWeatherMap[cityName] = weather;
        
        // 保存到数据库缓存
        await _saveToCache(cityName, weather);
        
        // 更新状态
        _cityWeatherDataMap[cityName] = CityWeatherData(
          cityName: cityName,
          cityId: cityId,
          cacheTime: DateTime.now(),
          hasCachedData: true,
        );
        
        // 异步加载日出日落和生活指数数据
        _loadSunMoonIndexData(cityName);
        
        Logger.d('成功加载城市天气数据: $cityName', tag: 'CityWeatherProvider');
      } else {
        // 获取失败
        _cityWeatherDataMap[cityName] = CityWeatherData.error(
          cityName,
          cityId: cityId,
          error: '无法获取天气数据',
        );
        Logger.e('获取城市天气数据失败: $cityName', tag: 'CityWeatherProvider');
      }
    } catch (e) {
      // 异常处理
      _cityWeatherDataMap[cityName] = CityWeatherData.error(
        cityName,
        cityId: cityId,
        error: '加载失败: $e',
      );
      Logger.e('加载城市天气数据异常: $cityName, $e', tag: 'CityWeatherProvider');
    }

    notifyListeners();
  }

  /// 从缓存加载天气数据
  Future<WeatherModel?> _loadFromCache(String cityName) async {
    try {
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';
      final cachedWeather = await _databaseService.getWeatherData(weatherKey);
      
      if (cachedWeather != null) {
        // 检查缓存时间（简单检查，实际可能需要更精确的过期判断）
        // 这里暂时不做时间检查，因为 DatabaseService 内部应该已经处理了
        return cachedWeather;
      }
    } catch (e) {
      Logger.e('从缓存加载城市天气数据失败: $cityName, $e', tag: 'CityWeatherProvider');
    }
    return null;
  }

  /// 保存天气数据到缓存
  Future<void> _saveToCache(String cityName, WeatherModel weather) async {
    try {
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';
      await _databaseService.putWeatherData(weatherKey, weather);
      Logger.d('保存城市天气数据到缓存: $cityName', tag: 'CityWeatherProvider');
    } catch (e) {
      Logger.e('保存城市天气数据到缓存失败: $cityName, $e', tag: 'CityWeatherProvider');
    }
  }

  /// 加载日出日落和生活指数数据
  Future<void> _loadSunMoonIndexData(String cityName) async {
    try {
      final weather = _cityWeatherMap[cityName];
      if (weather == null) return;

      // 尝试从缓存的城市ID获取日出日落数据
      final cityId = _cityWeatherDataMap[cityName]?.cityId;
      if (cityId != null && cityId.isNotEmpty) {
        final response = await SunMoonIndexService.getSunMoonAndIndex(cityId);
        if (response != null && response.data != null) {
          _citySunMoonIndexMap[cityName] = response.data!;
          Logger.d('成功加载城市日出日落和生活指数数据: $cityName', tag: 'CityWeatherProvider');
          notifyListeners();
          return;
        }
      }

      Logger.d('无法加载城市日出日落和生活指数数据: $cityName (没有有效的城市ID)', tag: 'CityWeatherProvider');
    } catch (e) {
      Logger.e('加载城市日出日落和生活指数数据失败: $cityName, $e', tag: 'CityWeatherProvider');
    }
  }

  /// 生成城市天气AI摘要
  Future<void> generateWeatherSummary(String cityName, {bool forceRefresh = false}) async {
    // 防止重复生成
    if (_generatingSummaryCities.contains(cityName) && !forceRefresh) {
      return;
    }

    // 检查是否已有缓存
    if (!forceRefresh && _cityWeatherSummaryMap.containsKey(cityName)) {
      return;
    }

    _generatingSummaryCities.add(cityName);
    notifyListeners();

    try {
      final weather = _cityWeatherMap[cityName];
      if (weather == null) {
        Logger.e('生成AI摘要失败: 没有天气数据 - $cityName', tag: 'CityWeatherProvider');
        return;
      }

      // 委托给 AIInsightsProvider 生成摘要
      if (_aiInsightsProvider != null) {
        Logger.d('委托给AIInsightsProvider生成每日摘要: $cityName', tag: 'CityWeatherProvider');
        final summary = await _aiInsightsProvider!.generateDailySummary(weather);
        if (summary != null && summary.isNotEmpty) {
          _cityWeatherSummaryMap[cityName] = summary;
          Logger.d('成功生成城市天气AI摘要: $cityName', tag: 'CityWeatherProvider');
          notifyListeners();
        }
      } else {
        Logger.e('AIInsightsProvider 未设置，无法生成摘要', tag: 'CityWeatherProvider');
      }
    } catch (e) {
      Logger.e('生成城市天气AI摘要失败: $cityName, $e', tag: 'CityWeatherProvider');
    } finally {
      _generatingSummaryCities.remove(cityName);
      notifyListeners();
    }
  }

  /// 生成城市15日预报AI摘要
  Future<void> generateForecast15dSummary(String cityName, {bool forceRefresh = false}) async {
    // 防止重复生成
    if (_generating15dSummaryCities.contains(cityName) && !forceRefresh) {
      return;
    }

    // 检查是否已有缓存
    if (!forceRefresh && _cityForecast15dSummaryMap.containsKey(cityName)) {
      return;
    }

    _generating15dSummaryCities.add(cityName);
    notifyListeners();

    try {
      final weather = _cityWeatherMap[cityName];
      if (weather == null || weather.forecast15d == null || weather.forecast15d!.isEmpty) {
        Logger.e('生成15日AI摘要失败: 没有15日预报数据 - $cityName', tag: 'CityWeatherProvider');
        return;
      }

      // 委托给 AIInsightsProvider 生成15日总结
      if (_aiInsightsProvider != null) {
        Logger.d('委托给AIInsightsProvider生成15日总结: $cityName', tag: 'CityWeatherProvider');
        final summary = await _aiInsightsProvider!.generate15dSummary(weather.forecast15d!);
        if (summary != null && summary.isNotEmpty) {
          _cityForecast15dSummaryMap[cityName] = summary;
          Logger.d('成功生成城市15日预报AI摘要: $cityName', tag: 'CityWeatherProvider');
          notifyListeners();
        }
      } else {
        Logger.e('AIInsightsProvider 未设置，无法生成摘要', tag: 'CityWeatherProvider');
      }
    } catch (e) {
      Logger.e('生成城市15日预报AI摘要失败: $cityName, $e', tag: 'CityWeatherProvider');
    } finally {
      _generating15dSummaryCities.remove(cityName);
      notifyListeners();
    }
  }

  /// 清空所有缓存数据
  void clearAllCache() {
    _cityWeatherDataMap.clear();
    _cityWeatherMap.clear();
    _citySunMoonIndexMap.clear();
    _cityWeatherSummaryMap.clear();
    _cityForecast15dSummaryMap.clear();
    _generatingSummaryCities.clear();
    _generating15dSummaryCities.clear();
    notifyListeners();
  }

  /// 清空指定城市的缓存数据
  void clearCityCache(String cityName) {
    _cityWeatherDataMap.remove(cityName);
    _cityWeatherMap.remove(cityName);
    _citySunMoonIndexMap.remove(cityName);
    _cityWeatherSummaryMap.remove(cityName);
    _cityForecast15dSummaryMap.remove(cityName);
    _generatingSummaryCities.remove(cityName);
    _generating15dSummaryCities.remove(cityName);
    notifyListeners();
  }

  @override
  void dispose() {
    clearAllCache();
    super.dispose();
  }
}
