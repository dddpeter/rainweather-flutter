import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/commute_advice_model.dart';
import '../models/city_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/database_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../utils/network_status_service.dart';
import 'location_provider.dart';
import 'cities_provider.dart';
import 'ai_insights_provider.dart';
import 'weather_data_provider.dart';
import 'refresh_coordinator.dart';

/// WeatherProvider - 天气数据状态管理 (Facade 模式)
///
/// 职责：
/// - 作为统一入口，协调各子 Provider
/// - 保持向后兼容的 API
/// - 提供快速启动协调方法
///
/// 架构：使用 Facade 模式，内部委托给专门的 Provider
/// - LocationProvider: 定位管理
/// - CitiesProvider: 城市管理
/// - AIInsightsProvider: AI 摘要和通勤建议
/// - WeatherDataProvider: 核心天气数据
/// - RefreshCoordinator: 定时刷新
class WeatherProvider extends ChangeNotifier {
  // ==================== 依赖服务 ====================
  final DatabaseService _databaseService = DatabaseService.getInstance();

  // ==================== 子Provider引用 ====================
  LocationProvider? _locationProvider;
  CitiesProvider? _citiesProvider;
  AIInsightsProvider? _aiInsightsProvider;
  WeatherDataProvider? _weatherDataProvider;
  RefreshCoordinator? _refreshCoordinator;

  // 网络状态服务
  final NetworkStatusService _networkStatus = NetworkStatusService();

  // ==================== 本地状态 ====================
  int _currentTabIndex = 0;

  /// 设置子Provider引用（在Provider注册后调用）
  void setChildProviders({
    required LocationProvider locationProvider,
    required CitiesProvider citiesProvider,
    required AIInsightsProvider aiInsightsProvider,
    required WeatherDataProvider weatherDataProvider,
    required RefreshCoordinator refreshCoordinator,
  }) {
    _locationProvider = locationProvider;
    _citiesProvider = citiesProvider;
    _aiInsightsProvider = aiInsightsProvider;
    _weatherDataProvider = weatherDataProvider;
    _refreshCoordinator = refreshCoordinator;

    // 监听所有子 Provider 的变化，转发到 UI
    if (_locationProvider != null) {
      _locationProvider!.addListener(() {
        notifyListeners();
      });
    }

    if (_citiesProvider != null) {
      _citiesProvider!.addListener(() {
        notifyListeners();
      });
    }

    if (_weatherDataProvider != null) {
      _weatherDataProvider!.addListener(() {
        notifyListeners();
      });
    }

    if (_aiInsightsProvider != null) {
      _aiInsightsProvider!.addListener(() {
        notifyListeners();
      });
    }

    // 同步天气数据到 AIInsightsProvider
    if (_weatherDataProvider != null && _aiInsightsProvider != null) {
      _weatherDataProvider!.addListener(() {
        _aiInsightsProvider!.setWeatherData(_weatherDataProvider!.currentWeather);
      });
    }

    Logger.d('WeatherProvider: 子Provider已设置', tag: 'WeatherProvider');
  }

  // ==================== 向后兼容的 Getters - 定位相关 ====================
  LocationModel? get currentLocation => _locationProvider?.currentLocation;
  LocationModel? get originalLocation => _locationProvider?.originalLocation;
  bool get isShowingCityWeather => _locationProvider?.isShowingCityWeather ?? false;
  bool get isLocationRefreshing => _locationProvider?.isLocationRefreshing ?? false;

  // ==================== 向后兼容的 Getters - 天气数据 ====================
  WeatherModel? get currentWeather => _weatherDataProvider?.currentWeather;
  WeatherModel? get currentLocationWeather => _weatherDataProvider?.currentWeather;
  List<HourlyWeather>? get hourlyForecast => _weatherDataProvider?.hourlyForecast;
  List<DailyWeather>? get dailyForecast => _weatherDataProvider?.dailyForecast;
  List<DailyWeather>? get forecast15d => _weatherDataProvider?.forecast15d;
  bool get isLoading => _weatherDataProvider?.isLoading ?? false;
  String? get error => _weatherDataProvider?.error;
  bool get isUsingCachedData => _weatherDataProvider?.isUsingCachedData ?? false;
  bool get isBackgroundRefreshing => false; // 不再使用
  SunMoonIndexData? get sunMoonIndexData => _weatherDataProvider?.sunMoonIndexData;
  bool get isLoadingSunMoonIndex => false; // 不再使用

  // ==================== 向后兼容的 Getters - 城市相关 ====================
  Map<String, WeatherModel> get mainCitiesWeather {
    if (_citiesProvider == null) return {};

    final result = <String, WeatherModel>{};
    for (final city in _citiesProvider!.mainCities) {
      final weather = _citiesProvider!.getWeatherForCity(city.id);
      if (weather != null) {
        result[city.id] = weather;
      }
    }
    return result;
  }
  List<CityModel> get mainCities => _citiesProvider?.mainCities ?? [];
  bool get isLoadingCitiesWeather => _citiesProvider?.isLoadingCitiesWeather ?? false;
  bool get isLoadingCities => _citiesProvider?.isLoadingCities ?? false;
  bool get hasPerformedInitialMainCitiesRefresh => _citiesProvider?.hasPerformedInitialMainCitiesRefresh ?? false;

  // ==================== 向后兼容的 Getters - AI 摘要相关 ====================
  String? get weatherSummary => _aiInsightsProvider?.dailySummary;
  String? get forecast15dSummary => _aiInsightsProvider?.forecast15dSummary;
  bool get isGeneratingSummary => _aiInsightsProvider?.isGeneratingSummary ?? false;
  bool get isGenerating15dSummary => _aiInsightsProvider?.isGenerating15dSummary ?? false;

  // ==================== 向后兼容的 Getters - 通勤建议相关 ====================
  List<CommuteAdviceModel> get commuteAdvices => _aiInsightsProvider?.commuteAdvices ?? [];
  bool get hasUnreadCommuteAdvices => _aiInsightsProvider?.hasUnreadCommuteAdvices ?? false;
  bool get hasShownCommuteAdviceToday => _aiInsightsProvider?.hasShownCommuteAdviceToday ?? false;
  bool get isGeneratingCommuteAdvice => _aiInsightsProvider?.isGeneratingCommuteAdvice ?? false;

  // ==================== 向后兼容的 Getters - 网络状态 ====================
  bool get isOffline => _networkStatus.isOffline;
  bool get isNetworkConnected => _networkStatus.isConnected;

  // ==================== 快速启动协调方法 ====================

  /// 快速启动：先加载缓存数据，后台刷新
  Future<void> quickStart() async {
    Logger.d('WeatherProvider: 快速启动开始', tag: 'WeatherProvider');

    try {
      // 初始化网络状态监听
      await _networkStatus.initialize();
      _networkStatus.addListener(_onNetworkStatusChanged);

      // 1. 从SQLite加载缓存的位置信息
      final cachedLocation = await _databaseService.getLocationData(
        AppConstants.currentLocationKey,
      );

      if (cachedLocation == null) {
        // 全新安装，无缓存数据
        Logger.d('检测到全新安装（无缓存位置）', tag: 'WeatherProvider');

        // 1. 委托给 LocationProvider 初始化
        await _locationProvider?.initializeLocation();

        // 2. 委托给 WeatherDataProvider 加载默认天气
        final defaultLocation = _locationProvider?.currentLocation;
        if (defaultLocation != null) {
          await _weatherDataProvider?.loadFromCache(defaultLocation);
        }

        // 3. 委托给 CitiesProvider 初始化城市
        await _citiesProvider?.initializeCities();

        // 4. 启动通勤建议定时器
        _aiInsightsProvider?.startCommuteCleanupTimer();
        await _aiInsightsProvider?.checkAndGenerateCommuteAdvices();

        // 5. 启动定时刷新
        _refreshCoordinator?.start();

        Logger.d('快速启动完成（全新安装）', tag: 'WeatherProvider');
        return;
      }

      // 2. 有缓存数据，先显示缓存
      Logger.d('显示缓存数据', tag: 'WeatherProvider');

      // 同步设置 LocationProvider 的缓存位置
      _locationProvider?.setCachedLocation(cachedLocation);

      // 委托给 WeatherDataProvider 加载缓存数据
      await _weatherDataProvider?.loadFromCache(cachedLocation);

      // 委托给 CitiesProvider 初始化
      await _citiesProvider?.initializeCities();

      // 同步天气数据到 AIInsightsProvider
      _aiInsightsProvider?.setWeatherData(_weatherDataProvider?.currentWeather);

      // 启动通勤建议定时器
      _aiInsightsProvider?.startCommuteCleanupTimer();
      await _aiInsightsProvider?.checkAndGenerateCommuteAdvices();

      // 启动定时刷新
      _refreshCoordinator?.start();

      // 后台异步刷新最新数据
      _backgroundRefresh();

      Logger.d('快速启动完成（有缓存）', tag: 'WeatherProvider');
    } catch (e, stackTrace) {
      Logger.e('快速启动失败', tag: 'WeatherProvider', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 后台刷新（不阻塞UI）
  Future<void> _backgroundRefresh() async {
    Logger.d('后台刷新开始', tag: 'WeatherProvider');

    try {
      // 刷新定位和天气
      await refreshLocation();

      // 刷新主要城市天气
      await _citiesProvider?.refreshAllCitiesWeather();

      Logger.d('后台刷新完成', tag: 'WeatherProvider');
    } catch (e) {
      Logger.e('后台刷新失败', tag: 'WeatherProvider', error: e);
    }
  }

  // ==================== 向后兼容的方法 - 定位相关 ====================

  /// 初始化定位
  Future<void> initializeWeather() async {
    await _locationProvider?.initializeLocation();
    final location = _locationProvider?.currentLocation;
    if (location != null) {
      await _weatherDataProvider?.loadFromCache(location);
    }
  }

  /// 刷新定位和天气
  Future<void> refreshLocation() async {
    await _locationProvider?.refreshLocation(forceRefresh: true);
    final location = _locationProvider?.currentLocation;
    if (location != null) {
      await _weatherDataProvider?.refreshWeatherData(location);
    }
  }

  /// 强制定位并刷新
  Future<void> forceRefreshWithLocation() async {
    await _locationProvider?.refreshLocation(forceRefresh: true);
    final location = _locationProvider?.currentLocation;
    if (location != null) {
      await _weatherDataProvider?.refreshWeatherData(location);
    }
  }

  /// 切换到城市天气
  void switchToCityWeather(LocationModel city) {
    _locationProvider?.switchToCityWeather(city);
    // 城市天气数据由 CitiesProvider 管理
  }

  /// 切换回定位天气
  void restoreCurrentLocationWeather() {
    _locationProvider?.restoreLocationWeather();
  }

  // ==================== 向后兼容的方法 - 天气数据相关 ====================

  /// 刷新天气数据
  Future<void> refreshWeatherData() async {
    final location = _locationProvider?.currentLocation;
    if (location != null) {
      await _weatherDataProvider?.refreshWeatherData(location);
    }
  }

  /// 获取城市天气数据
  Future<void> getWeatherForCity(
    LocationModel city, {
    bool forceRefresh = true,
  }) async {
    // 委托给 CitiesProvider (通过 CityModel)
    final cityModel = CityModel(
      id: city.adcode ?? city.city,
      name: city.district ?? city.city,
      isMainCity: true,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
    await _citiesProvider?.refreshCityWeather(cityModel);
  }

  /// 刷新15日预报
  Future<void> refresh15DayForecast() async {
    final location = _locationProvider?.currentLocation;
    if (location != null) {
      await _weatherDataProvider?.refresh15DayForecast(location);
    }
  }

  /// 刷新24小时预报（委托给刷新天气数据）
  Future<void> refresh24HourForecast() async {
    final location = _locationProvider?.currentLocation;
    if (location != null) {
      await _weatherDataProvider?.refreshHourlyForecast(location);
    }
  }

  /// 加载日出日落和生活指数数据（不再单独支持）
  Future<void> loadSunMoonIndexData() async {
    // 数据已在 refreshWeatherData 中加载
  }

  /// 清除天气缓存
  Future<void> clearWeatherCache() async {
    await _databaseService.clearWeatherData();
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    await _databaseService.clearAllCache();
  }

  // ==================== 向后兼容的方法 - 城市相关 ====================

  /// 初始化城市
  Future<void> initializeCities() async {
    await _citiesProvider?.initializeCities();
  }

  /// 加载主要城市
  Future<void> loadMainCities() async {
    await _citiesProvider?.initializeCities();
  }

  /// 刷新主要城市天气
  Future<void> refreshMainCitiesWeather({bool forceRefresh = true}) async {
    await _citiesProvider?.refreshAllCitiesWeather();
  }

  /// 智能刷新主要城市天气
  Future<void> smartRefreshMainCitiesWeather() async {
    await _citiesProvider?.refreshAllCitiesWeather();
  }

  /// 执行首次主要城市刷新
  Future<void> performInitialMainCitiesRefresh() async {
    await _citiesProvider?.performInitialMainCitiesRefresh();
  }

  /// 添加主要城市
  Future<bool> addMainCity(CityModel city) async {
    return await _citiesProvider?.addCity(city) ?? false;
  }

  /// 删除主要城市
  Future<bool> removeMainCity(String cityId) async {
    return await _citiesProvider?.removeCity(cityId) ?? false;
  }

  /// 更新城市排序
  Future<void> updateCitiesSortOrder(List<CityModel> reorderedCities) async {
    await _citiesProvider?.updateCitiesSortOrder(reorderedCities);
  }

  // ==================== 向后兼容的方法 - AI 摘要相关 ====================

  /// 生成每日天气摘要
  Future<void> generateWeatherSummary({
    bool forceRefresh = false,
    String? cityName,
  }) async {
    final weatherData = _weatherDataProvider?.currentWeather;
    if (weatherData != null) {
      await _aiInsightsProvider?.generateDailySummary(weatherData);
    }
  }

  /// 生成15日天气总结
  Future<void> generateForecast15dSummary() async {
    final forecast15d = _weatherDataProvider?.forecast15d;
    if (forecast15d != null && forecast15d.isNotEmpty) {
      await _aiInsightsProvider?.generate15dSummary(forecast15d);
    }
  }

  // ==================== 向后兼容的方法 - 通勤建议相关 ====================

  /// 检查并生成通勤建议
  Future<void> checkAndGenerateCommuteAdvices() async {
    await _aiInsightsProvider?.checkAndGenerateCommuteAdvices();
  }

  /// 加载通勤建议
  Future<void> loadCommuteAdvices({bool notifyUI = true}) async {
    await _aiInsightsProvider?.loadCommuteAdvices(notifyUI: notifyUI);
  }

  /// 标记通勤建议为已读
  Future<void> markCommuteAdviceAsRead(String adviceId) async {
    await _aiInsightsProvider?.markCommuteAdviceAsRead(adviceId);
  }

  /// 标记所有通勤建议为已读
  Future<void> markAllCommuteAdvicesAsRead() async {
    await _aiInsightsProvider?.markAllCommuteAdvicesAsRead();
  }

  // ==================== UI 辅助方法 ====================

  /// 设置当前标签页索引
  void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// 获取当前标签页索引
  int get currentTabIndex => _currentTabIndex;

  /// 判断是否白天
  bool isDayTime() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 6 && hour < 18;
  }

  // ==================== 页面生命周期 ====================

  /// 进入页面后执行定位
  Future<void> performLocationAfterEntering() async {
    await _locationProvider?.refreshLocation(forceRefresh: true);
  }

  // ==================== 城市相关方法 ====================

  /// 获取当前定位城市名称
  String? getCurrentLocationCityName() {
    // 优先使用区级名称，如果为空则使用城市名称
    String? currentName = _locationProvider?.currentLocation?.district
        ?? _locationProvider?.originalLocation?.district;

    // 如果区级名称为空，使用城市名称
    if (currentName == null || currentName.isEmpty) {
      currentName = _locationProvider?.currentLocation?.city
          ?? _locationProvider?.originalLocation?.city;
    }
    return currentName;
  }

  /// 获取城市天气数据
  WeatherModel? getCityWeather(String cityName) {
    // 获取当前定位城市名称
    final currentLocationName = getCurrentLocationCityName();

    // 如果请求的城市是当前定位城市，返回当前定位的天气数据
    if (currentLocationName != null &&
        (cityName.contains(currentLocationName) ||
        currentLocationName.contains(cityName))) {
      return _weatherDataProvider?.currentWeather;
    }

    // 从主要城市中找到匹配的城市（通过名称），然后用其ID获取天气数据
    if (_citiesProvider != null) {
      for (final city in _citiesProvider!.mainCities) {
        if (city.name == cityName || city.id == cityName) {
          return _citiesProvider!.getWeatherForCity(city.id);
        }
      }
    }

    return null;
  }

  /// 搜索城市
  Future<List<CityModel>> searchCities(String query) async {
    return await _citiesProvider?.searchCities(query) ?? [];
  }

  /// 刷新第一个城市定位和天气
  Future<bool> refreshFirstCityLocationAndWeather() async {
    if (_locationProvider?.isLocationRefreshing ?? false) {
      return false;
    }

    final success = await _locationProvider?.refreshLocation(forceRefresh: true) ?? false;
    if (success) {
      await refreshWeatherData();
    }
    return success;
  }

  // ==================== 网络状态处理 ====================

  void _onNetworkStatusChanged() {
    Logger.d('网络状态变化: ${_networkStatus.isConnected ? "已连接" : "已断开"}', tag: 'WeatherProvider');
    // 网络状态变化时，可以触发数据刷新
    if (_networkStatus.isConnected) {
      // 网络恢复，可以刷新数据
      refreshWeatherData();
    }
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    // 移除网络状态监听
    _networkStatus.removeListener(_onNetworkStatusChanged);

    // 停止定时刷新
    _refreshCoordinator?.stop();

    // 停止通勤建议定时器
    _aiInsightsProvider?.stopCommuteCleanupTimer();
    _aiInsightsProvider?.stopWeatherDataWatcher();

    super.dispose();
  }
}
