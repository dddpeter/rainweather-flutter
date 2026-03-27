import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/weather_service.dart';
import '../services/sun_moon_index_service.dart';
import '../services/weather_adapter.dart';
import '../services/city_data_service.dart';
import '../services/database_service.dart';
import '../constants/app_constants.dart';
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
    // 直接设置数据并通知，不做条件检查
    if (currentWeather != null) {
      _currentWeather = currentWeather;
    }
    if (hourlyForecast != null) {
      _hourlyForecast = hourlyForecast;
    }
    if (dailyForecast != null) {
      _dailyForecast = dailyForecast;
    }
    if (forecast15d != null) {
      _forecast15d = forecast15d;
    }
    if (sunMoonIndexData != null) {
      _sunMoonIndexData = sunMoonIndexData;
    }

    // 总是通知监听器
    notifyListeners();
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

        // 尝试从缓存加载生活指数数据
        final cityDataService = CityDataService.getInstance();
        cityDataService.loadCityData();
        String? cityId = cityDataService.findCityIdByName(location.district);
        cityId ??= cityDataService.findCityIdByName(location.city);
        cityId ??= cityDataService.findCityIdByName(location.province);
        final cacheKey = cityId ?? location.adcode;
        final sunMoonKey = '${AppConstants.sunMoonIndexKey}:$cacheKey';
        final cachedSunMoon = await _databaseService.getSunMoonIndexData(sunMoonKey);
        if (cachedSunMoon != null) {
          updateWeatherData(sunMoonIndexData: cachedSunMoon);
          Logger.d('从缓存加载生活指数数据', tag: 'WeatherDataProvider');
        }

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

      final weatherData = await _weatherService.getWeatherDataForLocation(location);

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

        // 异步加载生活指数数据（不阻塞主流程）
        _loadSunMoonIndexData(location, weatherData);

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
      final weatherData = await _weatherService.getWeatherDataForLocation(location);

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
      final weatherData = await _weatherService.getWeatherDataForLocation(location);

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
      final weatherData = await _weatherService.getWeatherDataForLocation(location);

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

  /// 加载生活指数数据（异步，不阻塞主流程）
  Future<void> _loadSunMoonIndexData(LocationModel location, WeatherModel weatherData) async {
    try {
      final isInternational = location.country != '中国' && location.country != 'China' && location.country != '未知';

      SunMoonIndexData? indexData;
      String cacheKey = location.adcode;

      if (isInternational) {
        // 国际城市：根据天气数据生成生活指数
        final currentWeather = weatherData.current?.current;
        if (currentWeather != null) {
          final tempStr = currentWeather.temperature ?? '20';
          final temperature = double.tryParse(tempStr) ?? 20.0;
          final weatherIndex = currentWeather.weatherIndex ?? '1';
          final weatherCode = int.tryParse(weatherIndex) ?? 1;
          double? humidity;
          if (currentWeather.humidity != null && currentWeather.humidity != '未知') {
            humidity = double.tryParse(currentWeather.humidity!.replaceAll('%', ''));
          }
          indexData = WeatherAdapter.generateLifeIndex(
            temperature: temperature,
            weatherCode: weatherCode,
            humidity: humidity,
          );
          Logger.d('为国际城市生成生活指数', tag: 'WeatherDataProvider');
        }
      } else {
        // 国内城市：通过城市名匹配获取cityId，再从API获取
        final cityDataService = CityDataService.getInstance();
        cityDataService.loadCityData();
        String? cityId = cityDataService.findCityIdByName(location.district);
        cityId ??= cityDataService.findCityIdByName(location.city);
        cityId ??= cityDataService.findCityIdByName(location.province);

        if (cityId != null && cityId.isNotEmpty) {
          cacheKey = cityId;
          final response = await SunMoonIndexService.getSunMoonAndIndex(cityId);
          if (response != null && response.data != null) {
            indexData = response.data!;
            Logger.d('从API加载生活指数数据成功, cityId: $cityId', tag: 'WeatherDataProvider');
          }
        } else {
          Logger.w('无法获取城市ID: ${location.district}/${location.city}', tag: 'WeatherDataProvider');
        }
      }

      if (indexData != null) {
        updateWeatherData(sunMoonIndexData: indexData);
        // 缓存生活指数数据
        final sunMoonKey = '${AppConstants.sunMoonIndexKey}:$cacheKey';
        await _databaseService.putSunMoonIndexData(sunMoonKey, indexData);
      }
    } catch (e) {
      Logger.e('加载生活指数数据失败', tag: 'WeatherDataProvider', error: e);
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
