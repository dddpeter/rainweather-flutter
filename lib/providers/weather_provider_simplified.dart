import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/smart_cache_service.dart';
import '../utils/logger.dart';

/// 简化版WeatherProvider - 使用Selector优化重建范围
class WeatherProviderSimplified extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final LocationService _locationService = LocationService.getInstance();
  final SmartCacheService _smartCache = SmartCacheService();

  // 天气数据
  WeatherModel? _currentWeather;
  LocationModel? _currentLocation;
  List<HourlyWeather>? _hourlyForecast;
  List<DailyWeather>? _dailyForecast;
  List<DailyWeather>? _forecast15d;

  // 状态管理
  bool _isLoading = false;
  String? _error;
  bool _isUsingCachedData = false;
  bool _isBackgroundRefreshing = false;
  bool _isLocationRefreshing = false;
  bool _hasPerformedInitialLocation = false;
  int _currentTabIndex = 0;
  bool _isShowingCityWeather = false;

  // 主要城市
  List<CityModel> _mainCities = [];
  Map<String, WeatherModel> _mainCitiesWeather = {};
  bool _isLoadingCities = false;
  bool _isLoadingCitiesWeather = false;

  // 定时刷新
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(hours: 1);

  // Getters - 使用Selector优化
  WeatherModel? get currentWeather => _currentWeather;
  LocationModel? get currentLocation => _currentLocation;
  List<HourlyWeather>? get hourlyForecast => _hourlyForecast;
  List<DailyWeather>? get dailyForecast => _dailyForecast;
  List<DailyWeather>? get forecast15d => _forecast15d;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingCachedData => _isUsingCachedData;
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;
  bool get isLocationRefreshing => _isLocationRefreshing;
  bool get hasPerformedInitialLocation => _hasPerformedInitialLocation;
  int get currentTabIndex => _currentTabIndex;
  bool get isShowingCityWeather => _isShowingCityWeather;
  List<CityModel> get mainCities => _mainCities;
  bool get isLoadingCities => _isLoadingCities;
  Map<String, WeatherModel> get mainCitiesWeather => _mainCitiesWeather;
  bool get isLoadingCitiesWeather => _isLoadingCitiesWeather;

  /// 初始化
  void initialize() {
    _startPeriodicRefresh();
    Logger.d(
      'WeatherProviderSimplified 初始化完成',
      tag: 'WeatherProviderSimplified',
    );
  }

  /// 获取天气数据
  Future<void> getWeatherData(LocationModel location) async {
    try {
      _setLoading(true);
      _clearError();

      Logger.d(
        '开始获取天气数据: ${location.district}',
        tag: 'WeatherProviderSimplified',
      );

      // 先尝试从缓存获取
      final cacheKey = '${location.district}:weather';
      final cachedData = await _smartCache.getData(
        key: cacheKey,
        type: CacheDataType.weather,
      );

      if (cachedData != null) {
        final weather = WeatherModel.fromJson(cachedData);
        _updateWeatherData(weather);
        _isUsingCachedData = true;
        Logger.d('使用缓存天气数据', tag: 'WeatherProviderSimplified');
        notifyListeners();
      }

      // 异步获取最新数据
      _isBackgroundRefreshing = true;
      notifyListeners();

      final weather = await _weatherService.getWeatherData(location);
      if (weather != null) {
        _updateWeatherData(weather);
        _isUsingCachedData = false;
        _isBackgroundRefreshing = false;
        Logger.s('天气数据获取成功', tag: 'WeatherProviderSimplified');
        notifyListeners();
      }
    } catch (e) {
      _setError('获取天气数据失败: ${e.toString()}');
      Logger.e('获取天气数据失败', tag: 'WeatherProviderSimplified', error: e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 执行定位
  Future<LocationModel?> performLocation() async {
    if (_isLocationRefreshing) {
      Logger.d('定位正在进行中，跳过重复请求', tag: 'WeatherProviderSimplified');
      return _currentLocation;
    }

    try {
      _isLocationRefreshing = true;
      _clearError();
      notifyListeners();

      Logger.d('开始执行定位', tag: 'WeatherProviderSimplified');
      final location = await _locationService.getCurrentLocation();

      if (location != null) {
        _currentLocation = location;
        _hasPerformedInitialLocation = true;
        Logger.s(
          '定位成功: ${location.district}',
          tag: 'WeatherProviderSimplified',
        );
        notifyListeners();
        return location;
      } else {
        _setError('定位失败：无法获取位置信息');
        Logger.e('定位失败：无法获取位置信息', tag: 'WeatherProviderSimplified');
      }
    } catch (e) {
      _setError('定位失败：${e.toString()}');
      Logger.e('定位失败', tag: 'WeatherProviderSimplified', error: e);
    } finally {
      _isLocationRefreshing = false;
      notifyListeners();
    }

    return null;
  }

  /// 刷新天气数据
  Future<void> refreshWeatherData() async {
    if (_currentLocation == null) return;

    try {
      await getWeatherData(_currentLocation!);
    } catch (e) {
      Logger.e('刷新天气数据失败', tag: 'WeatherProviderSimplified', error: e);
    }
  }

  /// 更新天气数据
  void _updateWeatherData(WeatherModel weather) {
    _currentWeather = weather;
    _hourlyForecast = weather.forecast24h;
    _dailyForecast = weather.forecast15d?.take(7).toList();
    _forecast15d = weather.forecast15d;
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误
  void _setError(String error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// 清除错误
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// 设置当前标签页
  void setCurrentTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// 设置是否显示城市天气
  void setShowingCityWeather(bool showing) {
    if (_isShowingCityWeather != showing) {
      _isShowingCityWeather = showing;
      notifyListeners();
    }
  }

  /// 启动定时刷新
  void _startPeriodicRefresh() {
    _stopPeriodicRefresh();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_currentLocation != null) {
        refreshWeatherData();
      }
    });
    Logger.d('定时刷新已启动', tag: 'WeatherProviderSimplified');
  }

  /// 停止定时刷新
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 清除所有数据
  void clearAllData() {
    _currentWeather = null;
    _currentLocation = null;
    _hourlyForecast = null;
    _dailyForecast = null;
    _forecast15d = null;
    _error = null;
    _isUsingCachedData = false;
    _isBackgroundRefreshing = false;
    _isLocationRefreshing = false;
    _hasPerformedInitialLocation = false;
    _currentTabIndex = 0;
    _isShowingCityWeather = false;
    _mainCities.clear();
    _mainCitiesWeather.clear();
    notifyListeners();
    Logger.d('所有数据已清除', tag: 'WeatherProviderSimplified');
  }

  @override
  void dispose() {
    _stopPeriodicRefresh();
    super.dispose();
  }
}
