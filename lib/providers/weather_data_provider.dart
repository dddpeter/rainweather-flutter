import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/weather_service.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// WeatherDataProvider - 核心天气数据 Provider
///
/// 职责：
/// - 管理当前天气数据（currentWeather, hourlyForecast, dailyForecast, forecast15d）
/// - 管理日月指数数据（sunMoonIndexData）
/// - 管理加载和错误状态（isLoading, error）
/// - 提供天气数据刷新接口
/// - 处理缓存逻辑
class WeatherDataProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();

  // ===== 核心数据 =====
  WeatherModel? _currentWeather;
  List<HourlyWeather>? _hourlyForecast;
  List<DailyWeather>? _dailyForecast;
  List<DailyWeather>? _forecast15d;
  SunMoonIndexData? _sunMoonIndexData;

  // ===== 状态标志 =====
  bool _isLoading = false;
  String? _error;
  bool _isUsingCachedData = false;
  bool _isOffline = false;

  // ===== Getters =====
  WeatherModel? get currentWeather => _currentWeather;
  List<HourlyWeather>? get hourlyForecast => _hourlyForecast;
  List<DailyWeather>? get dailyForecast => _dailyForecast;
  List<DailyWeather>? get forecast15d => _forecast15d;
  SunMoonIndexData? get sunMoonIndexData => _sunMoonIndexData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingCachedData => _isUsingCachedData;
  bool get isOffline => _isOffline;

  /// 获取当前温度
  String? get currentTemperature {
    return _currentWeather?.current?.current?.temperature;
  }

  /// 获取当前天气描述
  String? get currentWeatherDesc {
    return _currentWeather?.current?.current?.weather;
  }

  /// 更新天气数据（内部方法）
  void updateWeatherData({
    WeatherModel? currentWeather,
    List<HourlyWeather>? hourlyForecast,
    List<DailyWeather>? dailyForecast,
    List<DailyWeather>? forecast15d,
    SunMoonIndexData? sunMoonIndexData,
  }) {
    bool changed = false;

    if (currentWeather != null && currentWeather != _currentWeather) {
      _currentWeather = currentWeather;
      changed = true;
    }
    if (hourlyForecast != null && hourlyForecast != _hourlyForecast) {
      _hourlyForecast = hourlyForecast;
      changed = true;
    }
    if (dailyForecast != null && dailyForecast != _dailyForecast) {
      _dailyForecast = dailyForecast;
      changed = true;
    }
    if (forecast15d != null && forecast15d != _forecast15d) {
      _forecast15d = forecast15d;
      changed = true;
    }
    if (sunMoonIndexData != null && sunMoonIndexData != _sunMoonIndexData) {
      _sunMoonIndexData = sunMoonIndexData;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// 设置加载状态
  void setLoading(bool loading, {String? errorMessage}) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
    if (errorMessage != null && _error != errorMessage) {
      _error = errorMessage;
      notifyListeners();
    }
  }

  /// 设置缓存使用状态
  void setUsingCachedData(bool using) {
    if (_isUsingCachedData != using) {
      _isUsingCachedData = using;
      notifyListeners();
    }
  }

  /// 设置离线状态
  void setOffline(bool offline) {
    if (_isOffline != offline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// 从缓存加载天气数据
  Future<bool> loadFromCache(LocationModel location) async {
    try {
      final weatherKey = 'weather_${location.city}_${location.district}';
      final cachedWeather = await _databaseService.getWeatherData(weatherKey);

      if (cachedWeather != null) {
        // 从 forecast15d 获取前7天作为7日预报
        final dailyForecast = cachedWeather.forecast15d?.take(7).toList();
        updateWeatherData(
          currentWeather: cachedWeather,
          hourlyForecast: cachedWeather.forecast24h,
          dailyForecast: dailyForecast,
          forecast15d: cachedWeather.forecast15d,
        );
        setUsingCachedData(true);
        Logger.d('从缓存加载天气数据', tag: 'WeatherDataProvider');
        return true;
      }
      return false;
    } catch (e) {
      Logger.e('加载缓存数据失败', tag: 'WeatherDataProvider', error: e);
      return false;
    }
  }

  /// 刷新当前天气数据
  Future<bool> refreshWeatherData(LocationModel location) async {
    setLoading(true);
    clearError();

    try {
      Logger.d('开始刷新天气数据: ${location.city}', tag: 'WeatherDataProvider');

      final weatherData = await _weatherService.getWeatherData(location.city);

      if (weatherData != null) {
        // 从 forecast15d 获取前7天作为7日预报
        final dailyForecast = weatherData.forecast15d?.take(7).toList();
        updateWeatherData(
          currentWeather: weatherData,
          hourlyForecast: weatherData.forecast24h,
          dailyForecast: dailyForecast,
          forecast15d: weatherData.forecast15d,
        );
        setUsingCachedData(false);
        Logger.d('天气数据刷新成功', tag: 'WeatherDataProvider');
        return true;
      } else {
        _error = '获取天气数据失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      Logger.e('刷新天气数据失败', tag: 'WeatherDataProvider', error: e);
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 刷新24小时预报
  Future<bool> refreshHourlyForecast(LocationModel location) async {
    try {
      final weatherData = await _weatherService.getWeatherData(location.city);

      if (weatherData != null) {
        updateWeatherData(
          currentWeather: weatherData,
          hourlyForecast: weatherData.forecast24h,
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.e('刷新24小时预报失败', tag: 'WeatherDataProvider', error: e);
      return false;
    }
  }

  /// 刷新7日预报
  Future<bool> refreshDailyForecast(LocationModel location) async {
    try {
      final weatherData = await _weatherService.getWeatherData(location.city);

      if (weatherData != null) {
        // 从 forecast15d 获取前7天作为7日预报
        final dailyForecast = weatherData.forecast15d?.take(7).toList();
        updateWeatherData(
          currentWeather: weatherData,
          dailyForecast: dailyForecast,
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.e('刷新7日预报失败', tag: 'WeatherDataProvider', error: e);
      return false;
    }
  }

  /// 刷新15日预报
  Future<bool> refresh15DayForecast(LocationModel location) async {
    try {
      final weatherData = await _weatherService.getWeatherData(location.city);

      if (weatherData != null) {
        updateWeatherData(
          forecast15d: weatherData.forecast15d,
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.e('刷新15日预报失败', tag: 'WeatherDataProvider', error: e);
      return false;
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _currentWeather = null;
    _hourlyForecast = null;
    _dailyForecast = null;
    _forecast15d = null;
    _sunMoonIndexData = null;
    super.dispose();
  }
}
