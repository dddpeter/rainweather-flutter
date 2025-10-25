import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
// import '../services/weather_service.dart';
import '../services/weather_widget_service.dart';
import '../services/city_service.dart';
// import '../services/city_data_service.dart';
import '../utils/logger.dart';
import 'weather_data_provider.dart';
import 'location_provider.dart';
import 'cache_provider.dart';
import 'ui_state_provider.dart';

/// 重构后的WeatherProvider - 整合所有专门的Provider
class WeatherProviderRefactored extends ChangeNotifier {
  // 专门的Provider实例
  late final WeatherDataProvider _weatherDataProvider;
  late final LocationProvider _locationProvider;
  late final CacheProvider _cacheProvider;
  late final UIStateProvider _uiStateProvider;

  // 服务实例
  // final WeatherService _weatherService = WeatherService.getInstance();
  final WeatherWidgetService _widgetService =
      WeatherWidgetService.getInstance();
  final CityService _cityService = CityService.getInstance();
  // final CityDataService _cityDataService = CityDataService.getInstance();

  // 主要城市列表
  List<CityModel> _mainCities = [];
  bool _isLoadingCities = false;

  // 定时刷新
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(hours: 1);

  // Getters - 代理到各个专门的Provider
  WeatherModel? get currentWeather => _weatherDataProvider.currentWeather;
  LocationModel? get currentLocation => _locationProvider.currentLocation;
  LocationModel? get originalLocation => _locationProvider.originalLocation;
  List<HourlyWeather>? get hourlyForecast =>
      _weatherDataProvider.hourlyForecast;
  List<DailyWeather>? get dailyForecast => _weatherDataProvider.dailyForecast;
  List<DailyWeather>? get forecast15d => _weatherDataProvider.forecast15d;
  bool get isLoading => _uiStateProvider.isLoading;
  String? get error => _uiStateProvider.error;
  bool get isUsingCachedData => _cacheProvider.isUsingCachedData;
  bool get isBackgroundRefreshing => _cacheProvider.isBackgroundRefreshing;
  bool get isLocationRefreshing => _locationProvider.isLocationRefreshing;
  bool get hasPerformedInitialLocation =>
      _locationProvider.hasPerformedInitialLocation;
  int get currentTabIndex => _uiStateProvider.currentTabIndex;
  bool get isShowingCityWeather => _uiStateProvider.isShowingCityWeather;
  List<CityModel> get mainCities => _mainCities;
  bool get isLoadingCities => _isLoadingCities;
  Map<String, WeatherModel> get mainCitiesWeather =>
      _cacheProvider.mainCitiesWeather;
  bool get isLoadingCitiesWeather => _cacheProvider.isLoadingCitiesWeather;
  // List<CommuteAdviceModel> get commuteAdvices =>
  //     _weatherDataProvider.commuteAdvices;
  String? get weatherSummary => _weatherDataProvider.weatherSummary;
  String? get forecast15dSummary => _weatherDataProvider.forecast15dSummary;
  bool get isGeneratingSummary => _weatherDataProvider.isGeneratingSummary;
  bool get isGenerating15dSummary =>
      _weatherDataProvider.isGenerating15dSummary;
  bool get isGeneratingCommuteAdvice =>
      _weatherDataProvider.isGeneratingCommuteAdvice;

  /// 初始化WeatherProvider
  void initialize() {
    // 初始化各个专门的Provider
    _weatherDataProvider = WeatherDataProvider();
    _locationProvider = LocationProvider();
    _cacheProvider = CacheProvider();
    _uiStateProvider = UIStateProvider();

    // 初始化定位Provider
    _locationProvider.initState();

    // 初始化缓存Provider
    _cacheProvider.initialize();

    // 添加监听器
    _weatherDataProvider.addListener(_onWeatherDataChanged);
    _locationProvider.addListener(_onLocationChanged);
    _cacheProvider.addListener(_onCacheChanged);
    _uiStateProvider.addListener(_onUIStateChanged);

    // 启动定时刷新
    _startPeriodicRefresh();

    Logger.s(
      'WeatherProviderRefactored 初始化完成',
      tag: 'WeatherProviderRefactored',
    );
  }

  /// 天气数据变化回调
  void _onWeatherDataChanged() {
    notifyListeners();
  }

  /// 定位变化回调
  void _onLocationChanged() {
    notifyListeners();
  }

  /// 缓存变化回调
  void _onCacheChanged() {
    notifyListeners();
  }

  /// UI状态变化回调
  void _onUIStateChanged() {
    notifyListeners();
  }

  /// 获取天气数据
  Future<void> getWeatherData(LocationModel location) async {
    try {
      _uiStateProvider.setLoadingWeather(true);
      _uiStateProvider.clearWeatherError();

      // 先尝试从缓存获取
      final cachedWeather = await _cacheProvider.getWeatherData(location);
      if (cachedWeather != null) {
        _weatherDataProvider.updateWeatherData(cachedWeather);
      }

      // 获取最新数据
      await _weatherDataProvider.getWeatherData(location);

      // 缓存数据
      if (_weatherDataProvider.currentWeather != null) {
        await _cacheProvider.cacheWeatherData(
          location,
          _weatherDataProvider.currentWeather!,
        );
      }

      // 更新小组件
      await _updateWidget();
    } catch (e) {
      _uiStateProvider.setWeatherError(e.toString());
      Logger.e('获取天气数据失败', tag: 'WeatherProviderRefactored', error: e);
      rethrow;
    } finally {
      _uiStateProvider.setLoadingWeather(false);
    }
  }

  /// 执行定位
  Future<LocationModel?> performLocation() async {
    try {
      _uiStateProvider.setLoadingLocation(true);
      _uiStateProvider.clearLocationError();

      final location = await _locationProvider.performLocation();

      if (location != null) {
        await getWeatherData(location);
      }

      return location;
    } catch (e) {
      _uiStateProvider.setLocationError(e.toString());
      Logger.e('执行定位失败', tag: 'WeatherProviderRefactored', error: e);
      rethrow;
    } finally {
      _uiStateProvider.setLoadingLocation(false);
    }
  }

  /// 刷新天气数据
  Future<void> refreshWeatherData() async {
    if (_locationProvider.currentLocation == null) return;

    try {
      _uiStateProvider.setRefreshing(true);
      await getWeatherData(_locationProvider.currentLocation!);
    } catch (e) {
      Logger.e('刷新天气数据失败', tag: 'WeatherProviderRefactored', error: e);
    } finally {
      _uiStateProvider.setRefreshing(false);
    }
  }

  /// 获取主要城市列表
  Future<void> loadMainCities() async {
    if (_isLoadingCities) return;

    try {
      _isLoadingCities = true;
      _uiStateProvider.setLoadingCities(true);
      _uiStateProvider.clearCitiesError();

      _mainCities = await _cityService.getMainCities();
      Logger.s(
        '主要城市列表加载完成，共 ${_mainCities.length} 个城市',
        tag: 'WeatherProviderRefactored',
      );
    } catch (e) {
      _uiStateProvider.setCitiesError(e.toString());
      Logger.e('加载主要城市列表失败', tag: 'WeatherProviderRefactored', error: e);
    } finally {
      _isLoadingCities = false;
      _uiStateProvider.setLoadingCities(false);
      notifyListeners();
    }
  }

  /// 刷新主要城市天气
  Future<void> refreshMainCitiesWeather() async {
    if (_mainCities.isEmpty) {
      await loadMainCities();
    }

    try {
      await _cacheProvider.refreshMainCitiesWeather(_mainCities);
    } catch (e) {
      Logger.e('刷新主要城市天气失败', tag: 'WeatherProviderRefactored', error: e);
    }
  }

  /// 获取特定城市的天气
  Future<void> getWeatherForCity(String cityName) async {
    try {
      _uiStateProvider.setLoadingWeather(true);
      _uiStateProvider.clearWeatherError();

      // 从主要城市天气中查找
      final weather = await _cacheProvider.getCityWeather(cityName);
      if (weather != null) {
        _weatherDataProvider.updateWeatherData(weather);
        _uiStateProvider.setShowingCityWeather(true);
        return;
      }

      // 实现城市天气获取
      try {
        // 模拟城市天气获取
        final location = LocationModel(
          district: cityName,
          city: cityName,
          province: cityName,
          lat: 39.9042, // 默认坐标（北京）
          lng: 116.4074,
          address: cityName,
          country: '中国',
          street: '',
          adcode: '',
          town: '',
        );

        await getWeatherData(location);
        _uiStateProvider.setShowingCityWeather(true);
        Logger.s('城市天气获取成功: $cityName', tag: 'WeatherProviderRefactored');
      } catch (e) {
        Logger.e(
          '获取城市天气失败: $cityName',
          tag: 'WeatherProviderRefactored',
          error: e,
        );
        _uiStateProvider.setWeatherError('获取城市天气失败: ${e.toString()}');
      }
    } catch (e) {
      _uiStateProvider.setWeatherError(e.toString());
      Logger.e('获取城市天气失败', tag: 'WeatherProviderRefactored', error: e);
    } finally {
      _uiStateProvider.setLoadingWeather(false);
    }
  }

  /// 恢复当前定位天气
  void restoreCurrentLocationWeather() {
    if (_locationProvider.originalLocation != null) {
      _locationProvider.restoreOriginalLocation();
      _uiStateProvider.setShowingCityWeather(false);
      Logger.d('恢复当前定位天气', tag: 'WeatherProviderRefactored');
    }
  }

  /// 设置当前标签页
  void setCurrentTabIndex(int index) {
    _uiStateProvider.setCurrentTabIndex(index);
  }

  /// 生成AI天气摘要
  Future<void> generateWeatherSummary() async {
    if (_locationProvider.currentLocation != null) {
      await _weatherDataProvider.generateWeatherSummary(
        _locationProvider.currentLocation!,
      );
    }
  }

  /// 生成15日预报AI总结
  Future<void> generateForecast15dSummary() async {
    if (_locationProvider.currentLocation != null) {
      await _weatherDataProvider.generateForecast15dSummary(
        _locationProvider.currentLocation!,
      );
    }
  }

  /// 检查并生成通勤建议
  Future<void> checkAndGenerateCommuteAdvices() async {
    if (_locationProvider.currentLocation != null) {
      await _weatherDataProvider.checkAndGenerateCommuteAdvices(
        _locationProvider.currentLocation!,
      );
    }
  }

  /// 更新小组件
  Future<void> _updateWidget() async {
    try {
      if (_weatherDataProvider.currentWeather != null &&
          _locationProvider.currentLocation != null) {
        await _widgetService.updateWidget(
          weatherData: _weatherDataProvider.currentWeather!,
          location: _locationProvider.currentLocation!,
        );
      }
    } catch (e) {
      Logger.e('更新小组件失败', tag: 'WeatherProviderRefactored', error: e);
    }
  }

  /// 启动定时刷新
  void _startPeriodicRefresh() {
    _stopPeriodicRefresh();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      _performPeriodicRefresh();
    });
    Logger.d('定时刷新已启动', tag: 'WeatherProviderRefactored');
  }

  /// 停止定时刷新
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 执行定时刷新
  void _performPeriodicRefresh() {
    if (_locationProvider.currentLocation != null) {
      refreshWeatherData();
    }
  }

  /// 清除所有数据
  void clearAllData() {
    _weatherDataProvider.clearAllData();
    _locationProvider.clearLocationData();
    _cacheProvider.clearAllCache();
    _uiStateProvider.resetAllStates();
    _mainCities.clear();
    Logger.d('所有数据已清除', tag: 'WeatherProviderRefactored');
  }

  @override
  void dispose() {
    _stopPeriodicRefresh();

    // 移除监听器
    _weatherDataProvider.removeListener(_onWeatherDataChanged);
    _locationProvider.removeListener(_onLocationChanged);
    _cacheProvider.removeListener(_onCacheChanged);
    _uiStateProvider.removeListener(_onUIStateChanged);

    // 销毁各个Provider
    _weatherDataProvider.dispose();
    _locationProvider.dispose();
    _cacheProvider.dispose();
    _uiStateProvider.dispose();

    super.dispose();
  }
}
