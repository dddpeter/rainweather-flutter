import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/weather_alert_service.dart';
import '../services/city_service.dart';
import '../services/city_data_service.dart';
import '../services/sun_moon_index_service.dart';
import '../services/weather_widget_service.dart';
import '../services/commute_advice_service.dart';
import '../services/ai_service.dart';
import '../models/commute_advice_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_state_manager.dart';
import '../utils/city_name_matcher.dart';
import '../services/location_change_notifier.dart';
import 'dart:async';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final LocationService _locationService = LocationService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();
  final CityService _cityService = CityService.getInstance();
  final WeatherAlertService _alertService = WeatherAlertService.instance;
  final WeatherWidgetService _widgetService =
      WeatherWidgetService.getInstance();

  // 获取CityDataService实例
  CityDataService get _cityDataService => CityDataService.getInstance();

  WeatherModel? _currentWeather;
  LocationModel? _currentLocation;
  List<HourlyWeather>? _hourlyForecast;
  List<DailyWeather>? _dailyForecast;
  List<DailyWeather>? _forecast15d;
  bool _isLoading = false;
  String? _error;
  bool _isUsingCachedData = false; // 标记当前是否使用缓存数据
  bool _isBackgroundRefreshing = false; // 标记后台是否正在刷新
  bool _isLocationRefreshing = false; // 全局定位刷新锁，防止多页面同时刷新

  // 日出日落和生活指数数据
  SunMoonIndexData? _sunMoonIndexData;
  bool _isLoadingSunMoonIndex = false;

  // 当前定位的天气数据（用于今日天气页面）
  WeatherModel? _currentLocationWeather;
  LocationModel? _originalLocation;
  bool _isShowingCityWeather = false; // 标记当前是否显示城市天气数据
  int _currentTabIndex = 0; // 当前标签页索引
  bool _hasPerformedInitialLocation = false; // 是否已经进行过首次定位

  // 主要城市天气数据
  Map<String, WeatherModel> _mainCitiesWeather = {};
  bool _isLoadingCitiesWeather = false;
  bool _hasPerformedInitialMainCitiesRefresh = false; // 是否已经进行过首次主要城市刷新
  DateTime? _lastMainCitiesRefreshTime; // 上次刷新主要城市的时间

  // 定时刷新
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(hours: 1); // 1小时刷新一次，避免过于频繁

  // 定位防抖
  DateTime? _lastLocationTime; // 最后一次成功定位的时间
  static const Duration _locationDebounceInterval = Duration(
    minutes: 5,
  ); // 5分钟内不重复定位

  // Dynamic cities list
  List<CityModel> _mainCities = [];
  bool _isLoadingCities = false;

  // 通勤建议相关
  List<CommuteAdviceModel> _commuteAdvices = [];
  bool _hasShownCommuteAdviceToday = false; // 今日是否已显示过通勤建议
  Timer? _commuteCleanupTimer; // 通勤建议清理定时器

  // AI智能摘要
  String? _weatherSummary; // AI生成的天气摘要
  bool _isGeneratingSummary = false;
  String? _forecast15dSummary; // AI生成的15日天气总结
  bool _isGenerating15dSummary = false;
  final AIService _aiService = AIService();

  // Getters
  WeatherModel? get currentWeather => _currentWeather;
  LocationModel? get currentLocation => _currentLocation;
  List<HourlyWeather>? get hourlyForecast => _hourlyForecast;
  List<DailyWeather>? get dailyForecast => _dailyForecast;
  List<DailyWeather>? get forecast15d => _forecast15d;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingCachedData => _isUsingCachedData; // 是否使用缓存数据
  bool get isBackgroundRefreshing => _isBackgroundRefreshing; // 后台是否刷新中
  bool get isLocationRefreshing => _isLocationRefreshing; // 全局定位刷新锁状态
  Map<String, WeatherModel> get mainCitiesWeather => _mainCitiesWeather;
  bool get isLoadingCitiesWeather => _isLoadingCitiesWeather;
  bool get hasPerformedInitialMainCitiesRefresh =>
      _hasPerformedInitialMainCitiesRefresh;

  // 日出日落和生活指数数据getters
  SunMoonIndexData? get sunMoonIndexData => _sunMoonIndexData;
  bool get isLoadingSunMoonIndex => _isLoadingSunMoonIndex;

  // Dynamic cities getters
  List<CityModel> get mainCities => _mainCities;
  bool get isLoadingCities => _isLoadingCities;

  // 通勤建议getters
  List<CommuteAdviceModel> get commuteAdvices => _commuteAdvices;
  bool get hasUnreadCommuteAdvices => _commuteAdvices.any((a) => !a.isRead);
  bool get hasShownCommuteAdviceToday => _hasShownCommuteAdviceToday;

  // AI摘要相关
  String? get weatherSummary => _weatherSummary;
  bool get isGeneratingSummary => _isGeneratingSummary;
  String? get forecast15dSummary => _forecast15dSummary;
  bool get isGenerating15dSummary => _isGenerating15dSummary;

  // 当前定位天气数据的getter
  WeatherModel? get currentLocationWeather => _currentLocationWeather;
  LocationModel? get originalLocation => _originalLocation;
  bool get isShowingCityWeather => _isShowingCityWeather;
  int get currentTabIndex => _currentTabIndex;

  /// 快速启动：先加载缓存数据，后台刷新
  Future<void> quickStart() async {
    print('\n🚀 ========== WeatherProvider: 快速启动模式 ==========');

    try {
      // 1. 从SQLite加载缓存的位置信息
      final cachedLocation = await _databaseService.getLocationData(
        AppConstants.currentLocationKey,
      );

      if (cachedLocation == null) {
        // 全新安装，无缓存数据，使用正常初始化流程
        print('📦 检测到全新安装（无缓存位置）');
        print('📋 策略: 使用正常初始化流程，同步加载数据');
        print('⏱️ 预计时间: 5-10秒（需定位和获取数据）');

        // 显示加载状态
        _isLoading = true;
        notifyListeners();

        await initializeWeather();

        _isLoading = false;
        notifyListeners();

        print('✅ 全新安装初始化完成\n');
        return;
      }

      // 2. 从SQLite加载缓存的天气数据（立即显示）
      final weatherKey =
          '${cachedLocation.district}:${AppConstants.weatherAllKey}';
      final cachedWeather = await _databaseService.getWeatherData(weatherKey);

      if (cachedWeather == null) {
        print('📦 有位置缓存但无天气数据缓存，执行完整初始化');
        _isLoading = true;
        notifyListeners();
        await initializeWeather();
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('📦 使用SQLite缓存数据快速显示');
      print('   位置: ${cachedLocation.district}');
      print('   温度: ${cachedWeather.current?.current?.temperature ?? '--'}℃');

      // 立即设置缓存数据并通知UI
      _currentWeather = cachedWeather;
      _currentLocation = cachedLocation;
      _currentLocationWeather = cachedWeather;
      _originalLocation = cachedLocation;
      _isUsingCachedData = true; // 标记为使用缓存数据
      _isShowingCityWeather = false; // 显示当前定位的天气

      // 如果有缓存的预报数据
      _hourlyForecast = cachedWeather.forecast24h;
      _dailyForecast = cachedWeather.forecast15d?.take(7).toList();
      _forecast15d = cachedWeather.forecast15d;

      // 确保LocationService也有缓存的位置
      _locationService.setCachedLocation(cachedLocation);

      // 将当前定位天气数据同步到主要城市列表中
      _mainCitiesWeather[cachedLocation.district] = cachedWeather;
      print('✅ 当前定位城市数据已同步到主要城市列表: ${cachedLocation.district}');

      // 重置加载状态（避免显示"正在更新"）
      _isLoading = false;
      _error = null;

      notifyListeners();
      print('✅ SQLite缓存数据已显示，用户可立即查看');
      print('   - 24小时预报: ${_hourlyForecast?.length ?? 0}条');
      print('   - 15日预报: ${_forecast15d?.length ?? 0}天');
      print('🔄 后台开始刷新最新数据...\n');

      // 启动通勤建议清理定时器
      _startCommuteCleanupTimer();

      // App重启：清理当前时段的旧建议，重新生成
      await _cleanAndRegenerateCommuteAdvices();

      // 使用缓存数据先生成一次AI智能摘要（快速显示）
      // 后台刷新成功后会用最新数据重新生成
      generateWeatherSummary();

      // 3. 后台异步刷新（不阻塞UI）
      _backgroundRefresh();
    } catch (e) {
      print('❌ WeatherProvider: 快速启动失败: $e');
      // 降级到正常初始化
      _isLoading = true;
      notifyListeners();

      await initializeWeather();

      _isLoading = false;
      notifyListeners();
    }
  }

  /// 后台刷新最新数据
  Future<void> _backgroundRefresh() async {
    // 检查全局定位刷新锁
    if (_isLocationRefreshing) {
      print('🔒 后台刷新: 定位刷新正在进行中，跳过后台刷新');
      return;
    }

    try {
      _isBackgroundRefreshing = true;
      _isLocationRefreshing = true; // 设置全局锁
      notifyListeners(); // 立即通知UI，显示刷新状态

      // 异步执行，不阻塞UI
      Future.delayed(const Duration(milliseconds: 100), () async {
        // 先保存当前数据快照（在try外层，确保catch也能访问）
        final snapshotWeather = _currentWeather;
        final snapshotLocation = _currentLocation;
        final snapshotLocationWeather = _currentLocationWeather;
        final snapshotOriginalLocation = _originalLocation;
        final snapshotForecast15d = _forecast15d;
        final snapshotHourlyForecast = _hourlyForecast;
        final snapshotDailyForecast = _dailyForecast;
        final snapshotIsShowingCityWeather = _isShowingCityWeather;

        try {
          print('🔄 开始后台数据刷新');

          // 初始化数据库
          await _databaseService.initDatabase();

          // 初始化城市数据
          await initializeCities();

          // 获取最新定位和天气（带超时保护，最长20秒）
          final success = await _refreshLocationAndWeather(notifyUI: false)
              .timeout(
                const Duration(seconds: 20),
                onTimeout: () {
                  print('⏰ 后台刷新超时');
                  return false;
                },
              );

          _isBackgroundRefreshing = false;
          _isLocationRefreshing = false; // 释放全局锁

          if (success) {
            // 成功获取到新数据，标记缓存数据已更新
            _isUsingCachedData = false;

            // 同步当前定位天气数据到主要城市列表
            if (_currentLocation != null && _currentLocationWeather != null) {
              _mainCitiesWeather[_currentLocation!.district] =
                  _currentLocationWeather!;
              print('✅ 后台刷新：当前定位城市数据已同步到主要城市列表');
            }

            print('✅ 后台数据刷新完成，已替换为最新数据');
            notifyListeners(); // 一次性通知UI

            // 后台刷新成功后，重新生成AI智能摘要（使用最新数据）
            generateWeatherSummary();

            // 后台刷新成功后，检查并生成通勤提醒
            await checkAndGenerateCommuteAdvices();
          } else {
            // 刷新失败，完整恢复所有快照数据
            print('⚠️ 后台刷新失败，恢复缓存数据');
            print('   恢复位置: ${snapshotLocation?.district ?? '未知'}');
            print(
              '   恢复温度: ${snapshotWeather?.current?.current?.temperature ?? '--'}℃',
            );
            print('   恢复24小时: ${snapshotHourlyForecast?.length ?? 0}条');
            print('   恢复15日: ${snapshotForecast15d?.length ?? 0}天');

            _currentWeather = snapshotWeather;
            _currentLocation = snapshotLocation;
            _currentLocationWeather = snapshotLocationWeather;
            _originalLocation = snapshotOriginalLocation;
            _forecast15d = snapshotForecast15d;
            _hourlyForecast = snapshotHourlyForecast;
            _dailyForecast = snapshotDailyForecast;
            _isShowingCityWeather = snapshotIsShowingCityWeather;

            // 确保LocationService也有正确的缓存位置
            if (snapshotLocation != null) {
              _locationService.setCachedLocation(snapshotLocation);
            }

            notifyListeners(); // 一次性通知UI
          }
        } catch (e) {
          print('❌ 后台刷新异常: $e');
          _isBackgroundRefreshing = false;
          _isLocationRefreshing = false; // 释放全局锁

          // 异常时完整恢复快照数据
          print('⚠️ 异常恢复，恢复缓存数据');
          _currentWeather = snapshotWeather;
          _currentLocation = snapshotLocation;
          _currentLocationWeather = snapshotLocationWeather;
          _originalLocation = snapshotOriginalLocation;
          _forecast15d = snapshotForecast15d;
          _hourlyForecast = snapshotHourlyForecast;
          _dailyForecast = snapshotDailyForecast;
          _isShowingCityWeather = snapshotIsShowingCityWeather;

          // 确保LocationService也有正确的缓存位置
          if (snapshotLocation != null) {
            _locationService.setCachedLocation(snapshotLocation);
          }

          notifyListeners();
        }
      });
    } catch (e) {
      print('❌ 后台刷新外层失败: $e');
      _isBackgroundRefreshing = false;
      _isLocationRefreshing = false; // 释放全局锁
      notifyListeners();
    }
  }

  /// 检查是否需要重新定位（防抖）
  bool _shouldRefreshLocation() {
    if (_lastLocationTime == null) {
      // 从未定位过，需要定位
      return true;
    }

    final timeSinceLastLocation = DateTime.now().difference(_lastLocationTime!);
    if (timeSinceLastLocation < _locationDebounceInterval) {
      // 距离上次定位时间太短，不需要重新定位
      print('⏱️ 距离上次定位仅${timeSinceLastLocation.inMinutes}分钟，使用缓存位置');
      return false;
    }

    // 超过防抖间隔，可以重新定位
    print('✅ 距离上次定位已${timeSinceLastLocation.inMinutes}分钟，允许重新定位');
    return true;
  }

  /// 刷新定位和天气数据（返回是否成功）
  Future<bool> _refreshLocationAndWeather({
    bool notifyUI = true,
    bool forceLocation = false, // 是否强制定位（忽略防抖）
  }) async {
    try {
      LocationModel? location;

      // 检查是否需要重新定位
      if (forceLocation || _shouldRefreshLocation()) {
        // 获取最新定位（添加超时保护）
        location = await _locationService.getCurrentLocation().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⏰ 获取定位超时');
            return null;
          },
        );

        // 定位成功，更新最后定位时间
        if (location != null) {
          _lastLocationTime = DateTime.now();
          print('✅ 定位成功，更新最后定位时间');
        }
      } else {
        // 使用缓存的位置
        location = _currentLocation;
        print('📍 使用缓存位置: ${location?.district}');
      }

      if (location != null) {
        // 先尝试加载天气数据（不修改当前位置）
        final success = await _loadWeatherDataForLocation(location);

        if (success) {
          // 只有成功获取天气数据后，才更新当前位置
          // (_loadWeatherDataForLocation 内部已经更新了 _currentLocation)

          // 通知UI更新（平滑显示新数据）
          if (notifyUI) {
            notifyListeners();
          }

          // 更新小组件
          if (_currentWeather != null && _currentLocation != null) {
            _widgetService.updateWidget(
              weatherData: _currentWeather!,
              location: _currentLocation!,
            );
          }

          return true;
        } else {
          print('⚠️ 获取天气数据失败，不更新位置信息');
          return false;
        }
      }

      print('⚠️ 未获取到定位信息');
      return false;
    } catch (e) {
      print('❌ 刷新定位和天气失败: $e');
      return false;
    }
  }

  /// Initialize weather data
  Future<void> initializeWeather() async {
    final appStateManager = AppStateManager();

    // 检查是否可以初始化
    if (!appStateManager.canFetchWeatherData()) {
      print('🚫 WeatherProvider: 应用状态不允许初始化，跳过');
      return;
    }

    // 标记开始初始化
    await appStateManager.markInitializationStarted();

    try {
      await _databaseService.initDatabase();

      // 初始化城市数据（这里已经包含了loadMainCities的调用）
      await initializeCities();

      // 清理过期缓存数据
      await _cleanupExpiredCache();

      // 先使用缓存的位置，不进行实时定位
      LocationModel? cachedLocation = _locationService.getCachedLocation();
      if (cachedLocation != null) {
        print('🔄 WeatherProvider: 使用缓存的位置 ${cachedLocation.district}');
        _currentLocation = cachedLocation;
      } else {
        print('🔄 WeatherProvider: 无缓存位置，使用默认位置');
        // 使用默认位置（北京）
        _currentLocation = LocationModel(
          lat: 39.9042,
          lng: 116.4074,
          address: '北京市东城区',
          country: '中国',
          province: '北京市',
          city: '北京市',
          district: '东城区',
          street: '天安门广场',
          adcode: '110101',
          town: '',
          isProxyDetected: false,
        );
      }

      // 清理默认位置的缓存数据
      await clearDefaultLocationCache();

      // 重新加载主要城市列表，确保当前定位城市被包含
      await loadMainCities();

      await refreshWeatherData();

      // 异步加载15日预报数据
      refresh15DayForecast();
      // 异步加载日出日落和生活指数数据
      loadSunMoonIndexData();

      // 异步加载主要城市天气数据
      _loadMainCitiesWeather();

      // 启动通勤建议清理定时器
      _startCommuteCleanupTimer();

      // App重启：清理当前时段的旧建议，重新生成
      _cleanAndRegenerateCommuteAdvices();

      // 生成AI智能天气摘要
      generateWeatherSummary();

      // 标记初始化完成
      appStateManager.markInitializationCompleted();
    } catch (e) {
      print('Database initialization failed: $e');
      // Continue without database for testing

      // 即使出错也要标记初始化完成
      appStateManager.markInitializationCompleted();
    }
  }

  /// Load cached data
  Future<void> loadCachedData() async {
    try {
      // Load cached location
      _currentLocation = await _databaseService.getLocationData(
        AppConstants.currentLocationKey,
      );

      if (_currentLocation != null) {
        // Load cached weather data
        final weatherKey =
            '${_currentLocation!.district}:${AppConstants.weatherAllKey}';
        _currentWeather = await _databaseService.getWeatherData(weatherKey);

        if (_currentWeather != null) {
          _hourlyForecast = _currentWeather!.forecast24h;
          _dailyForecast = _currentWeather!.forecast15d?.take(7).toList();
          _forecast15d = _currentWeather!.forecast15d; // 保存15日预报数据
        }
      } else {
        // If no cached location, use Beijing as default
        _currentLocation = _getDefaultLocation();
        print('No cached location found, using Beijing as default');
      }

      notifyListeners();
    } catch (e) {
      print('Error loading cached data: $e');
      // If error loading cached data, use Beijing as default
      _currentLocation = _getDefaultLocation();
      notifyListeners();
    }
  }

  /// Refresh weather data (without re-requesting permission)
  Future<void> refreshWeatherData() async {
    // 检查全局定位刷新锁
    if (_isLocationRefreshing) {
      print('🔒 refreshWeatherData: 定位刷新正在进行中，跳过');
      return;
    }

    final appStateManager = AppStateManager();

    // 检查是否可以刷新数据
    if (!appStateManager.canFetchWeatherData()) {
      print('🚫 WeatherProvider: 应用状态不允许刷新天气数据，跳过');
      return;
    }

    // 检查是否已有缓存数据
    final hasCachedData =
        _currentWeather != null &&
        _currentLocation != null &&
        _hourlyForecast != null &&
        _forecast15d != null;

    // 设置全局锁
    _isLocationRefreshing = true;

    _setLoading(true);
    if (!hasCachedData) {
      _error = null; // 只在没有缓存时清空错误
    }

    try {
      // Use current location without re-requesting permission
      LocationModel? location = _currentLocation ?? _getDefaultLocation();
      print('Refreshing weather for: ${location.district}');

      _currentLocation = location;

      // Save location to cache
      await _databaseService.putLocationData(
        AppConstants.currentLocationKey,
        location,
      );

      // Update main cities list to include current location
      await loadMainCities();

      // Check if we have valid cached weather data
      final weatherKey = '${location.district}:${AppConstants.weatherAllKey}';
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(
        weatherKey,
      );

      if (cachedWeather != null) {
        // Use cached data
        _currentWeather = cachedWeather;

        // 保存当前定位天气数据（保持原始状态）
        _currentLocationWeather = cachedWeather;
        _originalLocation = location; // 保存原始位置
        _isShowingCityWeather = false; // 重置标记，表示现在显示原始定位数据
        _hourlyForecast = cachedWeather.forecast24h;
        _dailyForecast = cachedWeather.forecast15d?.take(7).toList();
        _forecast15d = cachedWeather.forecast15d; // 保存15日预报数据
        _locationService.setCachedLocation(location);

        // 同步当前定位天气数据到主要城市列表
        _mainCitiesWeather[location.district] = cachedWeather;
        print('Using cached weather data for ${location.district}');
        print('✅ 当前定位城市数据已同步到主要城市列表');

        // 清空错误（有缓存数据就不应该显示错误）
        _error = null;
      } else {
        // Fetch fresh data from API
        print(
          'No valid cache found, fetching fresh weather data for ${location.district}',
        );
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(
          location,
        );

        if (weather != null) {
          _currentWeather = weather;

          // 保存当前定位天气数据（保持原始状态）
          _currentLocationWeather = weather;
          _originalLocation = location; // 保存原始位置
          _isShowingCityWeather = false; // 重置标记，表示现在显示原始定位数据
          _hourlyForecast = weather.forecast24h;
          _dailyForecast = weather.forecast15d?.take(7).toList();
          _forecast15d = weather.forecast15d; // 保存15日预报数据

          // Save weather data to cache
          await _databaseService.putWeatherData(weatherKey, weather);

          // Cache location in service
          _locationService.setCachedLocation(location);

          // 同步当前定位天气数据到主要城市列表
          _mainCitiesWeather[location.district] = weather;
          print('✅ 当前定位城市数据已同步到主要城市列表');

          // 分析天气提醒（智能提醒，仅当前定位城市）
          try {
            print('🏙️ WeatherProvider: 分析当前定位城市的天气提醒');
            await _alertService.analyzeWeather(weather, location);
            print('🏙️ WeatherProvider: 已生成当前定位城市的天气提醒');
          } catch (e) {
            print('🏙️ WeatherProvider: 分析天气提醒失败 - $e');
          }

          // 清空错误
          _error = null;
        } else {
          // 获取失败
          if (hasCachedData) {
            // 有缓存数据，不显示错误，保持显示
            print('⚠️ 刷新失败，但有缓存数据，保持显示');
            _error = null;
          } else {
            // 无缓存数据，显示错误
            _error = 'Failed to fetch weather data';
          }
        }
      }
    } catch (e) {
      if (e is LocationException) {
        if (hasCachedData) {
          print('⚠️ 定位异常，但有缓存数据，不显示错误');
          _error = null;
        } else {
          _error = e.message;
          print('Location error: ${e.message}');
        }
      } else {
        if (hasCachedData) {
          print('⚠️ 刷新异常，但有缓存数据，不显示错误');
          _error = null;
        } else {
          _error = 'Error: $e';
          print('Weather refresh error: $e');
        }
      }
    } finally {
      _setLoading(false);
      _isLocationRefreshing = false; // 释放全局锁

      // 如果定位成功且无错误，通知所有监听器
      if (_currentLocation != null && _error == null) {
        print('📍 WeatherProvider: refreshWeatherData 准备发送定位成功通知');
        LocationChangeNotifier().notifyLocationSuccess(_currentLocation!);

        // 更新小组件
        if (_currentWeather != null) {
          _widgetService.updateWidget(
            weatherData: _currentWeather!,
            location: _currentLocation!,
          );
        }

        // 刷新成功后，重新生成AI智能摘要
        generateWeatherSummary();

        // 刷新成功后，检查并生成通勤提醒
        await checkAndGenerateCommuteAdvices();
      } else if (_error != null) {
        print(
          '📍 WeatherProvider: refreshWeatherData 跳过通知 - 位置: ${_currentLocation?.district}, 错误: $_error',
        );
      }
    }
  }

  /// Get weather data for specific city
  /// 获取指定城市的天气
  /// [cityName] 城市名称
  /// [forceRefreshAI] 是否强制刷新AI总结，忽略缓存（默认false）
  Future<void> getWeatherForCity(
    String cityName, {
    bool forceRefreshAI = false,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Create location for the city
      LocationModel cityLocation = LocationModel(
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

      // 不要覆盖当前定位的位置信息，只更新当前显示的天气数据
      // _currentLocation 保持为原始定位
      // _originalLocation 保持不变

      // Check if we have valid cached weather data for this city
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(
        weatherKey,
      );

      if (cachedWeather != null) {
        // Use cached data
        print(
          '🏙️ BEFORE SETTING CACHED WEATHER FOR $cityName: ${_currentWeather?.current?.current?.temperature}',
        );
        _currentWeather = cachedWeather;
        _hourlyForecast = cachedWeather.forecast24h;
        _dailyForecast = cachedWeather.forecast15d?.take(7).toList();
        _forecast15d = cachedWeather.forecast15d; // 保存15日预报数据
        _isShowingCityWeather = true; // 标记当前显示城市天气数据
        print(
          '🏙️ AFTER SETTING CACHED WEATHER FOR $cityName: ${_currentWeather?.current?.current?.temperature}',
        );
        print('✅ Using cached weather data for $cityName');
        print('🏙️ _isShowingCityWeather set to: $_isShowingCityWeather');
      } else {
        // Fetch fresh data from API
        print(
          'No valid cache found, fetching fresh weather data for $cityName',
        );
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(
          cityLocation,
        );

        if (weather != null) {
          print(
            'Before setting fresh weather for $cityName: ${_currentWeather?.current?.current?.temperature}',
          );
          _currentWeather = weather;
          _hourlyForecast = weather.forecast24h;
          _dailyForecast = weather.forecast15d?.take(7).toList();
          _forecast15d = weather.forecast15d; // 保存15日预报数据
          _isShowingCityWeather = true; // 标记当前显示城市天气数据
          print(
            'After setting fresh weather for $cityName: ${_currentWeather?.current?.current?.temperature}',
          );
          print('🏙️ _isShowingCityWeather set to: $_isShowingCityWeather');

          // Save to cache
          await _databaseService.putWeatherData(weatherKey, weather);
        } else {
          _error = 'Failed to fetch weather data for $cityName';
        }
      }

      // 为特定城市加载日出日落和生活指数数据
      await _loadSunMoonIndexDataForCity(cityName);

      // 切换城市后，重新生成AI智能摘要（基于当前城市天气）
      if (_currentWeather != null) {
        generateWeatherSummary(forceRefresh: forceRefreshAI);

        // 生成15日天气总结
        if (_forecast15d != null && _forecast15d!.isNotEmpty) {
          generateForecast15dSummary(forceRefresh: forceRefreshAI);
        }
      }
    } catch (e) {
      _error = 'Error: $e';
      print('City weather error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get default location
  LocationModel _getDefaultLocation() {
    return LocationModel(
      address: AppConstants.defaultCity,
      country: '中国',
      province: '北京市',
      city: '北京市',
      district: AppConstants.defaultCity,
      street: '未知',
      adcode: '110101',
      town: '未知',
      lat: 39.9042,
      lng: 116.4074,
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    print(
      '_setLoading($loading) called, current weather temp: ${_currentWeather?.current?.current?.temperature}',
    );
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get weather icon
  String getWeatherIcon(String weatherType) {
    return _weatherService.getWeatherIcon(weatherType);
  }

  /// Get weather image
  String getWeatherImage(String weatherType) {
    bool isDay = _weatherService.isDayTime();
    return _weatherService.getWeatherImage(weatherType, isDay);
  }

  /// Get air quality level
  String getAirQualityLevel(int aqi) {
    return _weatherService.getAirQualityLevel(aqi);
  }

  /// Check if it's day time
  bool isDayTime() {
    return _weatherService.isDayTime();
  }

  /// 异步加载主要城市天气数据
  /// [forceRefresh] - 是否强制刷新（忽略缓存）
  /// [skipCurrentLocation] - 是否跳过当前位置城市
  Future<void> _loadMainCitiesWeather({
    bool forceRefresh = false,
    bool skipCurrentLocation = false,
  }) async {
    _isLoadingCitiesWeather = true;
    notifyListeners();

    try {
      // 并行获取所有主要城市的天气数据
      List<Future<void>> futures = [];

      // 获取主要城市列表（从数据库或常量）
      final cityNames = _mainCities.isNotEmpty
          ? _mainCities.map((city) => city.name).toList()
          : AppConstants.mainCities;

      // 获取当前位置名称
      final currentLocationName = _currentLocation?.district;

      for (String cityName in cityNames) {
        // 如果设置了跳过当前位置，且当前城市是当前位置，则跳过
        if (skipCurrentLocation &&
            currentLocationName != null &&
            cityName == currentLocationName) {
          print('🏙️ WeatherProvider: 跳过当前位置城市 $cityName 的刷新');
          continue;
        }

        futures.add(
          _loadSingleCityWeather(cityName, forceRefresh: forceRefresh),
        );
      }

      // 等待所有请求完成
      await Future.wait(futures);
    } catch (e) {
      print('Error loading main cities weather: $e');
    } finally {
      _isLoadingCitiesWeather = false;
      _hasPerformedInitialMainCitiesRefresh = true; // 标记首次刷新已完成
      notifyListeners();
    }
  }

  /// 检查缓存是否过期
  /// 返回 true 表示缓存已过期或不存在，需要刷新
  Future<bool> _isCacheExpired(String cacheKey) async {
    try {
      final cachedWeather = await _databaseService.getWeatherData(cacheKey);
      if (cachedWeather == null) {
        return true; // 无缓存，需要刷新
      }

      // 检查缓存时间（通过数据库的 timestamp 字段）
      // 注意：这需要 DatabaseService 支持获取缓存时间
      // 这里先简化处理，假设15分钟后过期
      // TODO: 后续可以优化为从数据库读取缓存时间戳
      return false; // 暂时假设有缓存就不过期
    } catch (e) {
      print('Error checking cache expiration: $e');
      return true; // 出错时强制刷新
    }
  }

  /// 加载单个城市的天气数据
  /// [forceRefresh] - 是否强制刷新（忽略缓存）
  /// [checkExpiration] - 是否检查缓存有效期（默认true）
  Future<void> _loadSingleCityWeather(
    String cityName, {
    bool forceRefresh = false,
    bool checkExpiration = true,
  }) async {
    try {
      // 检查是否有有效的缓存数据
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';
      WeatherModel? cachedWeather;

      // 如果不强制刷新，尝试使用缓存
      if (!forceRefresh) {
        cachedWeather = await _databaseService.getWeatherData(weatherKey);

        // 如果启用过期检查，且缓存过期，则需要刷新
        if (cachedWeather != null && checkExpiration) {
          final isExpired = await _isCacheExpired(weatherKey);
          if (isExpired) {
            print('🕒 $cityName 缓存已过期，需要刷新');
            cachedWeather = null; // 清空缓存，强制刷新
          }
        }
      }

      if (cachedWeather != null && !forceRefresh) {
        // 使用缓存数据
        _mainCitiesWeather[cityName] = cachedWeather;
        print('✅ Using cached weather data for $cityName in main cities');
        notifyListeners();
      } else {
        // 从API获取新数据
        print('🌐 Fetching fresh weather data for $cityName in main cities');

        // 创建城市位置
        LocationModel cityLocation = LocationModel(
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

        // 获取天气数据
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(
          cityLocation,
        );

        if (weather != null) {
          _mainCitiesWeather[cityName] = weather;

          // 保存到缓存
          await _databaseService.putWeatherData(weatherKey, weather);

          // 只为当前定位城市分析天气提醒（智能提醒）
          // 其他城市只使用气象预警（原始预警数据）
          final currentLocationName = getCurrentLocationCityName();
          final isCurrentLocation = cityName == currentLocationName;

          if (isCurrentLocation) {
            try {
              print('🏙️ WeatherProvider: 分析当前定位城市 $cityName 的天气提醒');
              await _alertService.analyzeWeather(weather, cityLocation);
              print('🏙️ WeatherProvider: 已分析 $cityName 的天气提醒');
            } catch (e) {
              print('🏙️ WeatherProvider: 分析 $cityName 天气提醒失败 - $e');
            }
          } else {
            print('🏙️ WeatherProvider: $cityName 是自定义城市，跳过天气提醒分析（只使用气象预警）');
          }

          // 通知UI更新
          notifyListeners();
        } else {
          print('❌ Failed to fetch weather data for $cityName');
        }
      }
    } catch (e) {
      print('❌ Error loading weather for $cityName: $e');
    }
  }

  /// 获取指定城市的天气数据
  WeatherModel? getCityWeather(String cityName) {
    // 获取当前定位城市名称
    final currentLocationName = getCurrentLocationCityName();

    // 如果请求的城市是当前定位城市，返回当前定位的天气数据
    if (currentLocationName != null &&
        CityNameMatcher.isCityNameMatch(cityName, currentLocationName)) {
      // 优先返回 _currentLocationWeather（保存了原始定位天气数据）
      // 如果不存在，则返回 _currentWeather（可能被城市天气覆盖）
      return _currentLocationWeather ?? _currentWeather;
    }

    // 否则从主要城市天气数据map中获取
    return _mainCitiesWeather[cityName];
  }

  /// 刷新主要城市天气数据（不进行定位，只更新列表数据）
  /// [forceRefresh] - 是否强制刷新（默认true，用于下拉刷新）
  Future<void> refreshMainCitiesWeather({bool forceRefresh = true}) async {
    print('🔄 refreshMainCitiesWeather: 只刷新列表数据，不进行定位');

    // 如果是强制刷新，清空缓存
    if (forceRefresh) {
      _mainCitiesWeather.clear();
    }

    // 更新刷新时间
    _lastMainCitiesRefreshTime = DateTime.now();

    await _loadMainCitiesWeather(forceRefresh: forceRefresh);
  }

  /// 智能刷新主要城市天气数据（根据上次刷新时间判断是否需要刷新）
  /// 这个方法适用于后台定时刷新场景
  Future<void> smartRefreshMainCitiesWeather() async {
    // 检查是否需要刷新（距离上次刷新超过30分钟）
    if (_lastMainCitiesRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(
        _lastMainCitiesRefreshTime!,
      );
      if (timeSinceLastRefresh < const Duration(minutes: 30)) {
        print('⏭️ 距离上次刷新仅${timeSinceLastRefresh.inMinutes}分钟，跳过智能刷新');
        return;
      }
    }

    print('🔄 智能刷新主要城市数据（距上次刷新超过30分钟）');
    await refreshMainCitiesWeather(forceRefresh: false);
  }

  /// 定位并更新主要城市列表的第一个卡片（当前定位城市）
  /// 失败时保持显示原有数据，不移除卡片
  /// 用户主动点击，强制定位（忽略防抖）
  Future<bool> refreshFirstCityLocationAndWeather() async {
    // 检查全局定位刷新锁
    if (_isLocationRefreshing) {
      print('🔒 refreshFirstCityLocationAndWeather: 定位刷新正在进行中，跳过');
      return false;
    }

    try {
      _isLocationRefreshing = true;
      _isLoading = true;
      notifyListeners();

      print('📍 开始定位并更新第一个卡片（用户主动点击，强制定位）');

      // 尝试获取当前位置（带超时，用户主动点击不使用防抖）
      LocationModel? newLocation = await _locationService
          .getCurrentLocation()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ 定位超时');
              return null;
            },
          );

      if (newLocation == null) {
        print('❌ 定位失败，保持显示原有数据');
        _isLoading = false;
        _isLocationRefreshing = false;
        notifyListeners();
        return false;
      }

      print('✅ 定位成功: ${newLocation.district}');

      // 更新最后定位时间
      _lastLocationTime = DateTime.now();

      // 更新当前位置
      _currentLocation = newLocation;
      _locationService.setCachedLocation(newLocation);

      // 保存位置到数据库
      await _databaseService.putLocationData(
        AppConstants.currentLocationKey,
        newLocation,
      );

      // 重新加载主要城市列表（会自动添加当前位置到第一个）
      await loadMainCities();

      // 只获取第一个城市（当前定位城市）的天气数据
      final firstCity = _mainCities.isNotEmpty ? _mainCities.first.name : null;
      if (firstCity != null) {
        print('🔄 刷新第一个卡片: $firstCity');
        await _loadSingleCityWeather(firstCity, forceRefresh: true);

        // 如果这是当前定位城市，也更新主天气数据
        if (firstCity == newLocation.district) {
          final weatherKey =
              '${newLocation.district}:${AppConstants.weatherAllKey}';
          final weather = await _databaseService.getWeatherData(weatherKey);
          if (weather != null) {
            _currentWeather = weather;
            _currentLocationWeather = weather;
            _originalLocation = newLocation;
            _hourlyForecast = weather.forecast24h;
            _dailyForecast = weather.forecast15d?.take(7).toList();
            _forecast15d = weather.forecast15d;
          }
        }
      }

      _isLoading = false;
      _isLocationRefreshing = false;
      notifyListeners();

      print('✅ 第一个卡片更新完成');
      return true;
    } catch (e) {
      print('❌ 定位并更新第一个卡片失败: $e');
      print('❌ 保持显示原有数据');

      _isLoading = false;
      _isLocationRefreshing = false;
      notifyListeners();
      return false;
    }
  }

  /// 首次进入主要城市列表时主动刷新天气数据
  Future<void> performInitialMainCitiesRefresh() async {
    // 如果已经进行过首次刷新，则跳过
    if (_hasPerformedInitialMainCitiesRefresh) {
      print('🏙️ WeatherProvider: 主要城市天气数据已经刷新过，跳过');
      return;
    }

    print('🏙️ WeatherProvider: 首次进入主要城市列表，开始刷新天气数据...');

    // 确保主要城市列表已加载
    if (_mainCities.isEmpty) {
      await loadMainCities();
    }

    // 当前定位城市的天气数据已经在 quickStart 或 initializeWeather 时加载
    // 这里只需要确保 _mainCitiesWeather 也包含当前定位城市的数据
    final currentLocationName = getCurrentLocationCityName();
    if (currentLocationName != null && _currentLocationWeather != null) {
      // 将当前定位的天气数据同步到 _mainCitiesWeather 中
      _mainCitiesWeather[currentLocationName] = _currentLocationWeather!;
      print('✅ 当前定位城市 $currentLocationName 的数据已同步到主要城市列表');
    }

    // 刷新其他城市天气数据（跳过当前位置城市，只刷新其他城市）
    print('🏙️ WeatherProvider: 刷新非当前位置的城市天气数据');
    await _loadMainCitiesWeather(
      forceRefresh: false, // 不强制刷新，使用缓存优先
      skipCurrentLocation: true, // 跳过当前位置城市（已经有数据了）
    );

    // 更新刷新时间
    _lastMainCitiesRefreshTime = DateTime.now();
  }

  /// 清理过期缓存数据
  Future<void> _cleanupExpiredCache() async {
    try {
      final deletedCount = await _databaseService.cleanExpiredData();
      if (deletedCount > 0) {
        print('Cleaned up $deletedCount expired cache entries');
      }
    } catch (e) {
      print('Error cleaning up expired cache: $e');
    }
  }

  /// 启动定时刷新
  void _startPeriodicRefresh() {
    _stopPeriodicRefresh(); // 先停止现有的定时器

    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      print('⏰ WeatherProvider: 定时刷新触发');
      _performPeriodicRefresh();
    });

    print('⏰ WeatherProvider: 定时刷新已启动，间隔 ${_refreshInterval.inMinutes} 分钟');
  }

  /// 停止定时刷新
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('⏰ WeatherProvider: 定时刷新已停止');
  }

  /// 执行定时刷新
  Future<void> _performPeriodicRefresh() async {
    try {
      print('⏰ WeatherProvider: 开始执行定时刷新');

      // 刷新当前定位天气数据
      await refreshWeatherData();

      // 智能刷新主要城市天气数据（根据上次刷新时间判断）
      await smartRefreshMainCitiesWeather();

      print('⏰ WeatherProvider: 定时刷新完成');
    } catch (e) {
      print('❌ WeatherProvider: 定时刷新失败: $e');
    }
  }

  /// Initialize cities from JSON and load main cities
  Future<void> initializeCities() async {
    _isLoadingCities = true;
    notifyListeners();

    try {
      // Initialize cities from JSON if not already done
      await _cityService.initializeCitiesFromJson();

      // Remove any duplicate cities
      await _databaseService.removeDuplicateCities();

      // Load main cities from database
      await loadMainCities();

      print('Cities initialized successfully');
    } catch (e) {
      _error = 'Failed to initialize cities: $e';
      print('Error initializing cities: $e');
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  /// Load main cities from database
  Future<void> loadMainCities() async {
    try {
      // Get current location name for prioritizing in the list
      final currentLocationName =
          _currentLocation?.district ?? _originalLocation?.district;

      print('🔍 loadMainCities - currentLocationName: $currentLocationName');
      print(
        '🔍 loadMainCities - _currentLocation: ${_currentLocation?.district}',
      );
      print(
        '🔍 loadMainCities - _originalLocation: ${_originalLocation?.district}',
      );

      // Load main cities with current location first (this will handle adding current location if needed)
      _mainCities = await _cityService.getMainCitiesWithCurrentLocationFirst(
        currentLocationName,
      );

      print('🔍 loadMainCities - loaded ${_mainCities.length} cities');
      for (int i = 0; i < _mainCities.length; i++) {
        print('🔍 loadMainCities - city[$i]: ${_mainCities[i].name}');
      }
      notifyListeners();
    } catch (e) {
      print('Error loading main cities: $e');
    }
  }

  /// Get current location city name
  String? getCurrentLocationCityName() {
    // 优先使用区级名称，如果为空则使用城市名称
    String? currentName =
        _currentLocation?.district ?? _originalLocation?.district;

    // 如果区级名称为空，使用城市名称
    if (currentName == null || currentName.isEmpty) {
      currentName = _currentLocation?.city ?? _originalLocation?.city;
    }

    print('🔍 getCurrentLocationCityName: $currentName');
    print('🔍 _currentLocation?.district: ${_currentLocation?.district}');
    print('🔍 _originalLocation?.district: ${_originalLocation?.district}');
    print('🔍 _currentLocation?.city: ${_currentLocation?.city}');
    print('🔍 _originalLocation?.city: ${_originalLocation?.city}');
    return currentName;
  }

  /// Add a city to main cities
  Future<bool> addMainCity(CityModel city) async {
    try {
      final success = await _cityService.addMainCity(city);
      if (success) {
        await loadMainCities();
        // Refresh weather data for the new city
        await refreshMainCitiesWeather();
      }
      return success;
    } catch (e) {
      print('Error adding main city: $e');
      return false;
    }
  }

  /// Remove a city from main cities
  Future<bool> removeMainCity(String cityId) async {
    try {
      final success = await _cityService.removeMainCity(cityId);
      if (success) {
        await loadMainCities();
        // Remove from weather cache
        final city = await _cityService.getCityById(cityId);
        if (city != null) {
          _mainCitiesWeather.remove(city.name);
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error removing main city: $e');
      return false;
    }
  }

  /// Update cities sort order
  Future<void> updateCitiesSortOrder(List<CityModel> reorderedCities) async {
    try {
      // Update sort order for each city (excluding current location which should stay at 0)
      final currentLocationName = getCurrentLocationCityName();
      final citySortOrders = <Map<String, dynamic>>[];

      for (int i = 0; i < reorderedCities.length; i++) {
        final city = reorderedCities[i];
        // Skip current location city as it should always have sortOrder = 0
        if (currentLocationName != null &&
            CityNameMatcher.isCityNameMatch(city.name, currentLocationName)) {
          continue;
        }

        // Set sort order starting from 1 (current location is 0)
        final sortOrder = i + 1;
        citySortOrders.add({'cityId': city.id, 'sortOrder': sortOrder});
      }

      // Update database
      await _databaseService.updateCitiesSortOrder(citySortOrders);

      // Reload cities to reflect new order
      await loadMainCities();
    } catch (e) {
      print('Error updating cities sort order: $e');
    }
  }

  /// Search cities by name
  Future<List<CityModel>> searchCities(String query) async {
    try {
      return await _cityService.searchCities(query);
    } catch (e) {
      print('Error searching cities: $e');
      return [];
    }
  }

  /// Get main city names (for compatibility)
  Future<List<String>> getMainCityNames() async {
    try {
      return await _cityService.getMainCityNames();
    } catch (e) {
      print('Error getting main city names: $e');
      return AppConstants.mainCities; // Fallback
    }
  }

  /// 手动清理所有缓存数据
  Future<void> clearAllCache() async {
    try {
      await _databaseService.clearAllData();
      _mainCitiesWeather.clear();
      _currentWeather = null;
      _currentLocation = null;
      _currentLocationWeather = null;
      _originalLocation = null;
      _hourlyForecast = null;
      _dailyForecast = null;
      _sunMoonIndexData = null; // 清除日出日落和生活指数数据
      notifyListeners();
      print('All cache data cleared including sun/moon index data');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// 只清理天气数据，保留城市列表
  Future<void> clearWeatherCache() async {
    try {
      // 只清理天气相关的缓存数据
      await _databaseService.clearWeatherData();

      // 清空内存中的天气数据
      _mainCitiesWeather.clear();
      _currentWeather = null;
      _currentLocationWeather = null;
      _hourlyForecast = null;
      _dailyForecast = null;
      _sunMoonIndexData = null;

      // 保留城市列表和位置信息
      // _mainCities 和 _currentLocation 保持不变

      notifyListeners();
      print('Weather cache cleared, cities preserved');

      // 清理后自动刷新数据
      await refreshWeatherData();
    } catch (e) {
      print('Error clearing weather cache: $e');
    }
  }

  /// Clear cached default location data when real location is available
  Future<void> clearDefaultLocationCache() async {
    try {
      // Get the default location
      final defaultLocation = _getDefaultLocation();

      // Clear cached weather data for default location
      final defaultWeatherKey =
          '${defaultLocation.district}:${AppConstants.weatherAllKey}';
      await _databaseService.deleteWeatherData(defaultWeatherKey);

      // Clear cached location if it's the default location
      final cachedLocation = await _databaseService.getLocationData(
        AppConstants.currentLocationKey,
      );
      if (cachedLocation != null &&
          cachedLocation.district == defaultLocation.district) {
        await _databaseService.deleteLocationData(
          AppConstants.currentLocationKey,
        );
        print('Cleared default location cache');
      }
    } catch (e) {
      print('Error clearing default location cache: $e');
    }
  }

  /// Force refresh with location and clear current location cache
  Future<void> forceRefreshWithLocation() async {
    // 检查全局定位刷新锁
    if (_isLocationRefreshing) {
      print('🔒 forceRefreshWithLocation: 定位刷新正在进行中，跳过');
      return;
    }

    // 设置全局锁
    _isLocationRefreshing = true;

    _setLoading(true);
    _error = null;

    try {
      print('Force refresh: clearing ALL cache and getting fresh data');

      // Clear current location cache
      await _databaseService.deleteLocationData(
        AppConstants.currentLocationKey,
      );

      // Clear current weather cache
      if (_currentLocation != null) {
        final currentWeatherKey =
            '${_currentLocation!.district}:${AppConstants.weatherAllKey}';
        await _databaseService.deleteWeatherData(currentWeatherKey);
        print(
          'Cleared current location weather cache: ${_currentLocation!.district}',
        );
      }

      // 清空所有主要城市的天气缓存
      for (var city in _mainCities) {
        final weatherKey = '${city.name}:${AppConstants.weatherAllKey}';
        await _databaseService.deleteWeatherData(weatherKey);
        print('Cleared weather cache for main city: ${city.name}');
      }

      // 清空内存中的主要城市天气数据
      _mainCitiesWeather.clear();
      print('Cleared all main cities weather cache');

      // Force get fresh location
      LocationModel? location = await _locationService.getCurrentLocation();

      if (location == null) {
        // If still no location, use default
        location = _getDefaultLocation();
        print('No location available, using default: ${location.district}');
      } else {
        print('Got fresh location: ${location.district}');
      }

      _currentLocation = location;

      // Save fresh location to cache
      await _databaseService.putLocationData(
        AppConstants.currentLocationKey,
        location,
      );

      // Update main cities list to include current location
      await loadMainCities();

      // Get fresh weather data (no cache)
      WeatherModel? weather = await _weatherService.getWeatherDataForLocation(
        location,
      );

      if (weather != null) {
        _currentWeather = weather;
        _currentLocationWeather = weather;
        _originalLocation = location;
        _hourlyForecast = weather.forecast24h;
        _dailyForecast = weather.forecast15d?.take(7).toList();
        _forecast15d = weather.forecast15d; // 保存15日预报数据

        // Save fresh weather data to cache
        final weatherKey = '${location.district}:${AppConstants.weatherAllKey}';
        await _databaseService.putWeatherData(weatherKey, weather);

        // Cache location in service
        _locationService.setCachedLocation(location);

        print(
          'Force refresh completed with fresh data for ${location.district}',
        );
      } else {
        _error = 'Failed to fetch fresh weather data';
        print('Force refresh failed: $_error');
      }

      // 强制刷新所有主要城市天气（从API重新获取）
      await refreshMainCitiesWeather();
    } catch (e) {
      if (e is LocationException) {
        _error = e.message;
        print('Location error during force refresh: ${e.message}');
      } else {
        _error = 'Force refresh failed: $e';
        print('Force refresh error: $e');
      }
    } finally {
      _setLoading(false);
      _isLocationRefreshing = false; // 释放全局锁

      // 更新小组件（确保数据及时同步）
      if (_currentWeather != null &&
          _currentLocation != null &&
          _error == null) {
        _widgetService.updateWidget(
          weatherData: _currentWeather!,
          location: _currentLocation!,
        );

        // 强制刷新成功后，重新生成AI智能摘要
        generateWeatherSummary();

        // 强制刷新成功后，检查并生成通勤提醒
        await checkAndGenerateCommuteAdvices();
      }

      notifyListeners();
    }
  }

  /// 创建一个清除预警信息的天气数据副本
  WeatherModel _createWeatherWithoutAlerts(WeatherModel weather) {
    return WeatherModel(
      current: weather.current != null
          ? CurrentWeatherData(
              alerts: null, // 清除预警信息
              current: weather.current!.current,
              nongLi: weather.current!.nongLi,
              air: weather.current!.air,
              tips: weather.current!.tips,
            )
          : null,
      forecast24h: weather.forecast24h,
      forecast15d: weather.forecast15d,
      air: weather.air,
      tips: weather.tips,
    );
  }

  /// 恢复到当前定位的天气数据（用于从城市天气页面返回到今日天气页面）
  void restoreCurrentLocationWeather() {
    print('🔄 RESTORE CURRENT LOCATION WEATHER CALLED 🔄');
    print(
      '💾 _currentLocationWeather != null: ${_currentLocationWeather != null}',
    );
    print('🏠 _originalLocation != null: ${_originalLocation != null}');
    print('🔍 _isShowingCityWeather: $_isShowingCityWeather');

    if (_currentLocationWeather != null) {
      print(
        '💾 _currentLocationWeather temp: ${_currentLocationWeather!.current?.current?.temperature}',
      );
    }

    if (_originalLocation != null) {
      print('🏠 _originalLocation district: ${_originalLocation!.district}');
    }

    // 只有在真正需要恢复时才执行恢复逻辑
    if (_currentLocationWeather != null &&
        _originalLocation != null &&
        _isShowingCityWeather) {
      print(
        'Before restore - _currentWeather temp: ${_currentWeather?.current?.current?.temperature}',
      );
      print(
        'Before restore - _currentLocationWeather temp: ${_currentLocationWeather!.current?.current?.temperature}',
      );
      print(
        'Before restore - _currentLocation district: ${_currentLocation?.district}',
      );
      print(
        'Before restore - _originalLocation district: ${_originalLocation!.district}',
      );

      // 恢复当前定位天气数据，但清除预警信息
      _currentWeather = _createWeatherWithoutAlerts(_currentLocationWeather!);
      _currentLocation = _originalLocation;
      _hourlyForecast = _currentLocationWeather!.forecast24h;
      _dailyForecast = _currentLocationWeather!.forecast15d?.take(7).toList();
      _forecast15d = _currentLocationWeather!.forecast15d;
      _isShowingCityWeather = false; // 重置标记，表示现在显示原始定位数据

      print(
        '🚨 After restore - alerts cleared: ${_currentWeather?.current?.alerts}',
      );

      print(
        'After restore - _currentWeather temp: ${_currentWeather?.current?.current?.temperature}',
      );
      print(
        'After restore - _currentLocation district: ${_currentLocation?.district}',
      );

      notifyListeners();
      print(
        'Restored to current location weather (alerts already cleared): ${_originalLocation!.district}',
      );
    } else {
      print(
        'No restore needed: _currentLocationWeather=${_currentLocationWeather != null}, _originalLocation=${_originalLocation != null}, _isShowingCityWeather=$_isShowingCityWeather',
      );
    }
    print('=== restoreCurrentLocationWeather finished ===');
  }

  /// 设置当前标签页索引
  void setCurrentTabIndex(int index) {
    print('📱 Tab index changed to: $index');
    _currentTabIndex = index;

    // 如果切换到今日页面（索引0），且当前显示城市数据，则恢复
    if (index == 0 && _isShowingCityWeather) {
      print('📱 Switched to today tab, checking if restore needed');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        restoreCurrentLocationWeather();
      });
    }
  }

  /// 为指定位置加载天气数据（返回是否成功）
  Future<bool> _loadWeatherDataForLocation(LocationModel location) async {
    try {
      print('🔄 WeatherProvider: 为位置 ${location.district} 加载天气数据');

      // 获取天气数据
      final weather = await _weatherService.getWeatherDataForLocation(location);

      if (weather != null) {
        // 更新当前天气数据和位置信息
        _currentWeather = weather;
        _currentLocation = location; // 同步更新当前位置
        _currentLocationWeather = weather;
        _originalLocation = location;
        _isShowingCityWeather = false;

        // 更新预报数据
        _hourlyForecast = weather.forecast24h;
        _dailyForecast = weather.forecast15d?.take(7).toList();
        _forecast15d = weather.forecast15d;

        print('✅ WeatherProvider: 位置 ${location.district} 天气数据加载成功');
        return true;
      } else {
        print('❌ WeatherProvider: 位置 ${location.district} 天气数据加载失败');
        return false;
      }
    } catch (e) {
      print('❌ WeatherProvider: 加载位置天气数据异常: $e');
      return false;
    }
  }

  /// 在进入今日天气页面后进行定位
  Future<void> performLocationAfterEntering() async {
    // 检查全局定位刷新锁
    if (_isLocationRefreshing) {
      print('🔒 WeatherProvider: 定位刷新正在进行中，跳过');
      return;
    }

    // 如果已经进行过首次定位，则不再执行
    if (_hasPerformedInitialLocation) {
      print('🔄 WeatherProvider: 已经进行过首次定位，跳过');
      return;
    }

    print('🔄 WeatherProvider: 首次进入今日天气页面，开始定位...');

    // 设置全局锁
    _isLocationRefreshing = true;

    // 检查是否已有缓存数据
    final hasCachedData = _currentWeather != null && _currentLocation != null;
    if (hasCachedData) {
      print('📦 已有缓存数据，定位失败时将保持缓存显示');
    }

    try {
      // 显示定位状态（但不清空错误信息，避免影响UI）
      _isLoading = true;
      if (!hasCachedData) {
        _error = null; // 只在没有缓存时清空错误
      }
      notifyListeners();

      // 尝试获取当前位置
      LocationModel? newLocation = await _locationService
          .getCurrentLocation()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ WeatherProvider: 定位超时');
              return null;
            },
          );

      if (newLocation != null) {
        print('✅ WeatherProvider: 定位成功 ${newLocation.district}');

        // 更新最后定位时间
        _lastLocationTime = DateTime.now();

        // 更新位置
        _currentLocation = newLocation;
        _locationService.setCachedLocation(newLocation);

        // 清理默认位置的缓存数据
        await clearDefaultLocationCache();

        // 重新加载主要城市列表
        await loadMainCities();

        // 获取新位置的天气数据（检查是否成功）
        final success = await _loadWeatherDataForLocation(newLocation);

        if (success) {
          // 天气数据加载成功
          _hasPerformedInitialLocation = true;
          _error = null;

          // 启动定时刷新
          _startPeriodicRefresh();

          // 通知所有监听器定位成功
          print('📍 WeatherProvider: 准备发送定位成功通知');
          LocationChangeNotifier().notifyLocationSuccess(newLocation);
        } else {
          // 天气数据加载失败
          print('❌ 天气数据加载失败');
          if (hasCachedData) {
            // 有缓存数据，保持显示缓存，不显示错误
            print('📦 保持缓存数据显示');
            _error = null;
          } else {
            // 无缓存数据，显示错误
            _error = '无法获取天气数据，请检查网络连接';
          }
        }
      } else {
        print('❌ WeatherProvider: 定位失败');

        if (hasCachedData) {
          // 有缓存数据，保持显示缓存，不显示错误
          print('📦 定位失败，但有缓存数据，保持显示');
          _error = null;
        } else {
          // 无缓存数据，显示错误
          _error = '定位失败，请检查网络连接和位置权限';

          // 通知所有监听器定位失败
          print('📍 WeatherProvider: 准备发送定位失败通知');
          LocationChangeNotifier().notifyLocationFailed(_error!);
        }
      }
    } catch (e) {
      print('❌ WeatherProvider: 定位异常: $e');

      if (hasCachedData) {
        // 有缓存数据，不显示错误
        print('📦 定位异常，但有缓存数据，保持显示');
        _error = null;
      } else {
        // 无缓存数据，显示错误
        _error = '定位失败: $e';
      }
    } finally {
      _isLoading = false;
      _isLocationRefreshing = false; // 释放全局锁
      notifyListeners();
    }
  }

  /// 刷新15日预报数据
  Future<void> refresh15DayForecast() async {
    if (_currentLocation == null) return;

    _setLoading(true);
    _error = null;

    try {
      print('Refreshing 15-day forecast for: ${_currentLocation!.district}');

      // 优先使用主天气数据的缓存（包含24小时和15日数据）
      final weatherKey =
          '${_currentLocation!.district}:${AppConstants.weatherAllKey}';
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(
        weatherKey,
      );

      if (cachedWeather != null && cachedWeather.forecast15d != null) {
        // 从主天气数据中获取15日预报
        _forecast15d = cachedWeather.forecast15d;
        // 同时更新24小时数据，保持一致性
        _hourlyForecast = cachedWeather.forecast24h;
        print(
          'Using cached weather data (with 15d+24h) for ${_currentLocation!.district}',
        );
      } else {
        // 如果主缓存不存在，从API获取新数据
        print(
          'No valid cache found, fetching fresh weather data for ${_currentLocation!.district}',
        );
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(
          _currentLocation!,
        );

        if (weather != null) {
          _forecast15d = weather.forecast15d;
          _hourlyForecast = weather.forecast24h;

          // 保存到主缓存
          await _databaseService.putWeatherData(weatherKey, weather);

          print(
            'Weather data (with 15d+24h) cached for ${_currentLocation!.district}',
          );
        } else {
          _error = 'Failed to fetch 15-day forecast data';
        }
      }
    } catch (e) {
      _error = 'Error refreshing 15-day forecast: $e';
      print('15-day forecast refresh error: $e');
    } finally {
      _setLoading(false);
    }

    // 生成AI 15日天气总结
    if (_forecast15d != null && _forecast15d!.isNotEmpty) {
      generateForecast15dSummary();
    }
  }

  /// 刷新24小时预报数据
  Future<void> refresh24HourForecast() async {
    if (_currentLocation == null) return;

    _setLoading(true);
    _error = null;

    try {
      print('Refreshing 24-hour forecast for: ${_currentLocation!.district}');

      // 优先使用主天气数据的缓存（包含24小时和15日数据）
      final weatherKey =
          '${_currentLocation!.district}:${AppConstants.weatherAllKey}';
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(
        weatherKey,
      );

      if (cachedWeather != null && cachedWeather.forecast24h != null) {
        // 从主天气数据中获取24小时预报
        _hourlyForecast = cachedWeather.forecast24h;
        // 同时更新15日数据，保持一致性
        _forecast15d = cachedWeather.forecast15d;
        print(
          'Using cached weather data (with 24h+15d) for ${_currentLocation!.district}',
        );
      } else {
        // 如果主缓存不存在，从API获取新数据
        print(
          'No valid cache found, fetching fresh weather data for ${_currentLocation!.district}',
        );
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(
          _currentLocation!,
        );

        if (weather != null) {
          _hourlyForecast = weather.forecast24h;
          _forecast15d = weather.forecast15d;

          // 保存到主缓存
          await _databaseService.putWeatherData(weatherKey, weather);
          print(
            'Fresh weather data saved to cache for ${_currentLocation!.district}',
          );
        }
      }
    } catch (e) {
      _error = 'Error refreshing 24-hour forecast: $e';
      print('24-hour forecast refresh error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 获取日出日落和生活指数数据
  Future<void> loadSunMoonIndexData() async {
    if (_currentLocation == null) return;

    _isLoadingSunMoonIndex = true;
    notifyListeners();

    try {
      // 获取城市ID
      String cityId = _getCityIdFromLocation(_currentLocation!);
      if (cityId.isEmpty) {
        cityId = AppConstants.defaultCityId;
      }

      print('Loading sun/moon index data for city ID: $cityId');

      // 检查缓存
      final cacheKey = '${_currentLocation!.district}:sun_moon_index';
      final cachedData = await _databaseService.getSunMoonIndexData(cacheKey);

      if (cachedData != null) {
        // 使用缓存数据
        _sunMoonIndexData = cachedData;
        print(
          'Using cached sun/moon index data for ${_currentLocation!.district}',
        );
        notifyListeners(); // 通知UI更新
      } else {
        // 从API获取新数据
        print(
          'No valid cache found, fetching fresh sun/moon index data for ${_currentLocation!.district}',
        );
        final response = await SunMoonIndexService.getSunMoonAndIndex(cityId);

        if (response != null && response.code == 200 && response.data != null) {
          _sunMoonIndexData = response.data;

          // 调试信息
          print('Sun/moon index data loaded successfully:');
          print('  - sunAndMoon: ${response.data!.sunAndMoon}');
          print('  - index count: ${response.data!.index?.length ?? 0}');
          if (response.data!.index != null) {
            for (var item in response.data!.index!) {
              print('  - ${item.indexTypeCh}: ${item.indexLevel}');
            }
          }

          // 保存到缓存
          await _databaseService.putSunMoonIndexData(cacheKey, response.data!);
          print('Sun/moon index data cached for ${_currentLocation!.district}');
          notifyListeners(); // 通知UI更新
        } else {
          print('Failed to fetch sun/moon index data - response: $response');
          notifyListeners(); // 通知UI更新，即使失败也要更新状态
        }
      }
    } catch (e) {
      print('Error loading sun/moon index data: $e');
      notifyListeners(); // 通知UI更新，即使出错也要更新状态
    } finally {
      _isLoadingSunMoonIndex = false;
      notifyListeners();
    }
  }

  /// 为特定城市获取日出日落和生活指数数据
  Future<void> _loadSunMoonIndexDataForCity(String cityName) async {
    _isLoadingSunMoonIndex = true;
    notifyListeners();

    try {
      // 获取城市ID
      String cityId =
          _cityDataService.findCityIdByName(cityName) ??
          AppConstants.defaultCityId;

      print(
        'Loading sun/moon index data for city: $cityName, city ID: $cityId',
      );

      // 检查缓存
      final cacheKey = '$cityName:sun_moon_index';
      final cachedData = await _databaseService.getSunMoonIndexData(cacheKey);

      if (cachedData != null) {
        // 使用缓存数据
        _sunMoonIndexData = cachedData;
        print('Using cached sun/moon index data for $cityName');
        notifyListeners(); // 通知UI更新
      } else {
        // 从API获取新数据
        print(
          'No valid cache found, fetching fresh sun/moon index data for $cityName',
        );
        final response = await SunMoonIndexService.getSunMoonAndIndex(cityId);

        if (response != null && response.code == 200 && response.data != null) {
          _sunMoonIndexData = response.data;

          // 调试信息
          print('Sun/moon index data loaded successfully for $cityName:');
          print('  - sunAndMoon: ${response.data!.sunAndMoon}');
          print('  - index count: ${response.data!.index?.length ?? 0}');
          if (response.data!.index != null) {
            for (var item in response.data!.index!) {
              print('  - ${item.indexTypeCh}: ${item.indexLevel}');
            }
          }

          // 保存到缓存
          await _databaseService.putSunMoonIndexData(cacheKey, response.data!);
          print('Sun/moon index data cached for $cityName');
          notifyListeners(); // 通知UI更新
        } else {
          print(
            'Failed to fetch sun/moon index data for $cityName - response: $response',
          );
          notifyListeners(); // 通知UI更新，即使失败也要更新状态
        }
      }
    } catch (e) {
      print('Error loading sun/moon index data for $cityName: $e');
      notifyListeners(); // 通知UI更新，即使出错也要更新状态
    } finally {
      _isLoadingSunMoonIndex = false;
      notifyListeners();
    }
  }

  /// 获取城市ID（从LocationModel）
  String _getCityIdFromLocation(LocationModel location) {
    // 使用CityDataService来获取城市ID
    final cityDataService = _cityDataService;

    // Try to find city ID by district first
    String? cityId = cityDataService.findCityIdByName(location.district);

    // If not found, try by city
    if (cityId == null && location.city.isNotEmpty) {
      cityId = cityDataService.findCityIdByName(location.city);
    }

    // If still not found, try by province
    if (cityId == null && location.province.isNotEmpty) {
      cityId = cityDataService.findCityIdByName(location.province);
    }

    // Return found city ID or default
    return cityId ?? AppConstants.defaultCityId;
  }

  // ==================== 通勤建议相关方法 ====================

  /// App重启时清理并重新生成通勤建议
  Future<void> _cleanAndRegenerateCommuteAdvices() async {
    print('\n╔════════════════════════════════════════╗');
    print('║  🔄 App重启：清理并重新生成建议  ║');
    print('╚════════════════════════════════════════╝');

    try {
      // 检查是否在通勤时段
      if (!CommuteAdviceService.isInCommuteTime()) {
        print('⏰ 不在通勤时段，只加载历史建议');
        await loadCommuteAdvices();
        return;
      }

      final currentTimeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();
      if (currentTimeSlot == null) {
        print('⏰ 无法获取当前时段');
        await loadCommuteAdvices();
        return;
      }

      print(
        '⏰ 当前时段: ${currentTimeSlot == CommuteTimeSlot.morning ? '早高峰' : '晚高峰'}',
      );

      // 清理当前时段的所有建议
      print('🗑️ 清理当前时段的旧建议...');
      final deletedCount = await _databaseService.cleanEndedTimeSlotAdvices(
        currentTimeSlot.toString().split('.').last,
      );
      print('✅ 已清理 $deletedCount 条旧建议');

      // 重置标记，允许重新生成
      _hasShownCommuteAdviceToday = false;

      // 重新生成通勤建议
      print('🚀 重新生成通勤建议...\n');
      await checkAndGenerateCommuteAdvices();
    } catch (e) {
      print('❌ 清理并重新生成建议失败: $e');
      // 失败时至少加载现有建议
      await loadCommuteAdvices();
    }
  }

  /// 生成智能天气摘要
  /// [forceRefresh] 是否强制刷新，忽略缓存（默认false）
  Future<void> generateWeatherSummary({bool forceRefresh = false}) async {
    if (_currentWeather == null) {
      print('⚠️ 无天气数据，无法生成智能摘要');
      return;
    }

    if (_isGeneratingSummary) {
      print('⏳ 智能摘要生成中，跳过重复请求');
      return;
    }

    _isGeneratingSummary = true;
    notifyListeners();

    // 先准备数据（在try外层，确保catch也能访问）
    final current = _currentWeather!.current?.current;
    final air = _currentWeather!.current?.air ?? _currentWeather!.air;
    final hourly = _currentWeather!.forecast24h;

    if (current == null) {
      print('❌ 无当前天气数据');
      _isGeneratingSummary = false;
      notifyListeners();
      return;
    }

    // 构建未来天气趋势
    final upcomingWeather = <String>[];
    if (hourly != null && hourly.isNotEmpty) {
      final next3Hours = hourly.take(3);
      for (var hour in next3Hours) {
        if (hour.weather != null && hour.weather!.isNotEmpty) {
          upcomingWeather.add(hour.weather!);
        }
      }
    }

    try {
      // 构建缓存key（包含城市名、天气、温度等关键信息）
      final cityName =
          _currentLocation?.district ?? _currentLocation?.city ?? '未知';
      final cacheKey =
          'ai_summary:$cityName:${current.weather}:${current.temperature}';

      // 如果不是强制刷新，先尝试从缓存获取
      if (!forceRefresh) {
        final cachedSummary = await _databaseService.getAISummary(cacheKey);
        if (cachedSummary != null && cachedSummary.isNotEmpty) {
          _weatherSummary = cachedSummary;
          print('✅ 使用缓存的AI摘要: $_weatherSummary');
          _isGeneratingSummary = false;
          notifyListeners();
          return;
        }
      } else {
        print('🔄 强制刷新模式，忽略缓存');
      }

      print('\n🎨 开始生成AI智能天气摘要...');

      // 构建prompt
      final prompt = _aiService.buildWeatherSummaryPrompt(
        currentWeather: current.weather ?? '晴',
        temperature: current.temperature ?? '--',
        airQuality: air?.levelIndex ?? '未知',
        upcomingWeather: upcomingWeather,
        humidity: current.humidity,
        windPower: current.windpower,
      );

      // 调用AI
      final aiResponse = await _aiService.generateSmartAdvice(prompt);

      if (aiResponse != null && aiResponse.isNotEmpty) {
        _weatherSummary = _aiService.parseAlertText(aiResponse);
        print('✅ AI摘要生成成功: $_weatherSummary');

        // 保存到缓存（6小时有效期）
        await _databaseService.putAISummary(cacheKey, _weatherSummary!);
        print('💾 AI摘要已缓存');
      } else {
        print('❌ AI摘要生成失败，使用默认文案');
        _weatherSummary = _generateDefaultWeatherSummary(
          current,
          upcomingWeather,
        );
      }
    } catch (e) {
      print('❌ 生成智能摘要异常: $e');
      // 失败时使用默认文案
      _weatherSummary = _generateDefaultWeatherSummary(
        current,
        upcomingWeather,
      );
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  /// 生成默认天气摘要（包含带伞、穿衣建议）
  String _generateDefaultWeatherSummary(
    CurrentWeather current,
    List<String> upcomingWeather,
  ) {
    final weather = current.weather ?? '晴';
    final temp = int.tryParse(current.temperature ?? '20') ?? 20;

    // 基础天气描述
    String summary = '$weather，温度${current.temperature}℃。';

    // 带伞建议
    final needUmbrella =
        weather.contains('雨') || upcomingWeather.any((w) => w.contains('雨'));
    if (needUmbrella) {
      summary += '建议携带雨具。';
    }

    // 穿衣建议
    if (temp <= 10) {
      summary += '天气较冷，注意保暖，建议穿厚外套。';
    } else if (temp <= 18) {
      summary += '温度适中，建议穿长袖衬衫或薄外套。';
    } else if (temp <= 25) {
      summary += '天气舒适，适合短袖或薄长袖。';
    } else {
      summary += '天气炎热，建议穿轻薄透气衣物，注意防晒。';
    }

    return summary;
  }

  /// 生成15日天气总结
  /// [forceRefresh] 是否强制刷新，忽略缓存（默认false）
  Future<void> generateForecast15dSummary({bool forceRefresh = false}) async {
    if (_forecast15d == null || _forecast15d!.isEmpty) {
      print('⚠️ 无15日预报数据，无法生成总结');
      return;
    }

    if (_isGenerating15dSummary) {
      print('⏳ 15日天气总结生成中，跳过重复请求');
      return;
    }

    _isGenerating15dSummary = true;
    notifyListeners();

    try {
      // 构建天气数据
      final dailyForecasts = <Map<String, dynamic>>[];
      for (var day in _forecast15d!) {
        // 优先使用白天天气，如果没有则使用下午天气
        final weather = day.weather_am ?? day.weather_pm ?? '未知';
        dailyForecasts.add({
          'weather': weather,
          'tempMax': day.temperature_am,
          'tempMin': day.temperature_pm,
        });
      }

      // 构建缓存key（包含城市名和主要天气类型）
      final cityName =
          _currentLocation?.district ?? _currentLocation?.city ?? '未知';
      final mainWeathers = dailyForecasts
          .take(5)
          .map((d) => d['weather'])
          .join(',');
      final cacheKey = 'ai_15d_summary:$cityName:$mainWeathers';

      // 如果不是强制刷新，先尝试从缓存获取
      if (!forceRefresh) {
        final cachedSummary = await _databaseService.getAI15dSummary(cacheKey);
        if (cachedSummary != null && cachedSummary.isNotEmpty) {
          _forecast15dSummary = cachedSummary;
          print('✅ 使用缓存的15日天气总结: $_forecast15dSummary');
          _isGenerating15dSummary = false;
          notifyListeners();
          return;
        }
      } else {
        print('🔄 强制刷新模式，忽略15日天气缓存');
      }

      print('\n🎨 开始生成AI 15日天气总结...');

      // 构建prompt
      final prompt = _aiService.buildForecast15dSummaryPrompt(
        dailyForecasts: dailyForecasts,
        cityName: _currentLocation?.district ?? '当前位置',
      );

      // 调用AI
      final aiResponse = await _aiService.generateSmartAdvice(prompt);

      if (aiResponse != null && aiResponse.isNotEmpty) {
        _forecast15dSummary = _aiService.parseAlertText(aiResponse);
        print('✅ 15日天气总结生成成功: $_forecast15dSummary');

        // 保存到缓存（6小时有效期）
        await _databaseService.putAI15dSummary(cacheKey, _forecast15dSummary!);
        print('💾 15日天气总结已缓存');
      } else {
        print('❌ 15日天气总结生成失败，使用默认文案');
        _forecast15dSummary = _getDefault15dSummary();
      }
    } catch (e) {
      print('❌ 生成15日天气总结异常: $e');
      // 失败时使用简单的默认文案
      _forecast15dSummary = _getDefault15dSummary();
    } finally {
      _isGenerating15dSummary = false;
      notifyListeners();
    }
  }

  /// 获取默认15日天气总结
  String _getDefault15dSummary() {
    if (_forecast15d == null || _forecast15d!.isEmpty) {
      return '暂无15日天气预报数据';
    }

    // 统计主要天气类型
    final weatherTypes = <String>{};
    for (var day in _forecast15d!) {
      // 优先使用白天天气，如果没有则使用下午天气
      final weather = day.weather_am ?? day.weather_pm;
      if (weather != null && weather.isNotEmpty) {
        weatherTypes.add(weather);
      }
    }

    return '未来15天主要天气：${weatherTypes.take(3).join('、')}等，请关注天气变化，合理安排出行。';
  }

  /// 检查并生成通勤建议
  Future<void> checkAndGenerateCommuteAdvices() async {
    // 检查是否在通勤时段
    if (!CommuteAdviceService.isInCommuteTime()) {
      print('⏰ 不在通勤时段，加载历史通勤建议');
      // 不在通勤时段时，加载历史建议以便显示
      await loadCommuteAdvices();
      return;
    }

    // 检查今日当前时段是否已生成过建议
    final currentTimeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();
    if (currentTimeSlot == null) {
      print('⏰ 无法获取当前时段，加载历史建议');
      // 无法获取时段时，至少加载历史建议
      await loadCommuteAdvices();
      return;
    }

    // 检查数据库中是否已有当前时段的建议
    final existingAdvices = await _databaseService.getTodayCommuteAdvices();
    final hasCurrentSlotAdvices = existingAdvices.any(
      (a) => a.timeSlot == currentTimeSlot,
    );

    if (hasCurrentSlotAdvices) {
      print('✅ 当前时段已有通勤建议，加载到界面');
      _hasShownCommuteAdviceToday = true;

      // 加载已有的建议到内存并通知UI
      await loadCommuteAdvices();
      return;
    }

    // 检查是否有天气数据
    if (_currentWeather == null) {
      print('❌ 无天气数据，无法生成通勤建议，加载历史建议');
      // 无天气数据时，至少加载历史建议
      await loadCommuteAdvices();
      return;
    }

    try {
      print('\n╔════════════════════════════════════════╗');
      print('║  🚀 WeatherProvider: 通勤建议生成 ║');
      print('╚════════════════════════════════════════╝');
      print('📍 当前位置: ${_currentLocation?.district}');
      print('⏰ 当前时间: ${DateTime.now()}');
      print('🌡️ 天气数据: ${_currentWeather != null ? '已加载' : '未加载'}');

      if (_currentWeather != null) {
        print('   - 温度: ${_currentWeather!.current?.current?.temperature}℃');
        print('   - 天气: ${_currentWeather!.current?.current?.weather}');
        print('   - 风力: ${_currentWeather!.current?.current?.windpower}');
        print('   - 24h预报: ${_currentWeather!.forecast24h?.length ?? 0}条');
      }
      print('');

      // 生成通勤建议（使用AI或规则引擎）
      final commuteService = CommuteAdviceService();
      final advices = await commuteService.generateAdvices(_currentWeather!);

      if (advices.isEmpty) {
        print('ℹ️ 当前天气条件无需特别提醒');
        _hasShownCommuteAdviceToday = true;
        print('');
        return;
      }

      print('╔════════════════════════════════════════╗');
      print('║  📝 生成结果                        ║');
      print('╚════════════════════════════════════════╝');
      print('生成建议数: ${advices.length}');
      for (int i = 0; i < advices.length; i++) {
        final advice = advices[i];
        print('');
        print('建议 ${i + 1}:');
        print('   标题: ${advice.title}');
        print('   类型: ${advice.adviceType}');
        print(
          '   级别: ${advice.getLevelName()} (${advice.level.toString().split('.').last})',
        );
        print('   图标: ${advice.icon}');
        print(
          '   内容: ${advice.content.substring(0, advice.content.length > 50 ? 50 : advice.content.length)}...',
        );
      }

      // 保存到数据库
      print('\n💾 保存到数据库...');
      await _databaseService.saveCommuteAdvices(advices);
      print('✅ 数据库保存成功');

      // 加载通勤建议
      print('📂 加载通勤建议...');
      await loadCommuteAdvices();
      print('✅ 加载完成，当前建议数: ${_commuteAdvices.length}');

      // 标记今日已显示
      _hasShownCommuteAdviceToday = true;

      print('\n╔════════════════════════════════════════╗');
      print('║  ✅ 通勤建议生成完成              ║');
      print('╚════════════════════════════════════════╝\n');

      notifyListeners();
    } catch (e, stackTrace) {
      print('\n╔════════════════════════════════════════╗');
      print('║  ❌ 通勤建议生成失败              ║');
      print('╚════════════════════════════════════════╝');
      print('错误: $e');
      print('堆栈: $stackTrace\n');

      // 生成失败时，至少加载历史建议
      await loadCommuteAdvices();
    }
  }

  /// 加载通勤建议
  Future<void> loadCommuteAdvices() async {
    try {
      print('\n📚 开始加载通勤建议...');

      // 先清理数据库中的重复数据
      await _databaseService.cleanDuplicateCommuteAdvices();

      final advices = await _databaseService.getTodayCommuteAdvices();
      print('   数据库中今日建议: ${advices.length}条');

      if (advices.isEmpty) {
        print('   ℹ️ 数据库中没有今日通勤建议');
        _commuteAdvices = [];
        notifyListeners();
        return;
      }

      // 获取当前通勤时段
      final currentTimeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();
      final now = DateTime.now();

      // 过滤逻辑：
      // 1. 如果当前在通勤时段，只显示当前时段的建议
      // 2. 如果不在通勤时段，不显示任何建议（已过期）
      final filteredAdvices = advices.where((advice) {
        if (currentTimeSlot != null) {
          // 在通勤时段内，只显示当前时段的建议
          return advice.timeSlot == currentTimeSlot;
        } else {
          // 不在通勤时段，检查时段是否已结束
          final settings = WeatherAlertService.instance.settings;
          final currentMinutes = now.hour * 60 + now.minute;

          if (advice.timeSlot == CommuteTimeSlot.morning) {
            final morningEndMinutes =
                settings.commuteTime.morningEnd.hour * 60 +
                settings.commuteTime.morningEnd.minute;
            // 早高峰已结束，不显示
            return currentMinutes < morningEndMinutes;
          } else {
            final eveningEndMinutes =
                settings.commuteTime.eveningEnd.hour * 60 +
                settings.commuteTime.eveningEnd.minute;
            // 晚高峰已结束，不显示
            return currentMinutes < eveningEndMinutes;
          }
        }
      }).toList();

      print('   过滤后剩余: ${filteredAdvices.length}条');

      // 二次去重：按 adviceType + timeSlot 去重（防止并发导致的重复）
      final uniqueAdvices = <String, CommuteAdviceModel>{};
      for (var advice in filteredAdvices) {
        final key = '${advice.adviceType}_${advice.timeSlot}';
        // 如果已存在相同类型和时段的建议，保留时间最新的
        if (!uniqueAdvices.containsKey(key) ||
            advice.timestamp.isAfter(uniqueAdvices[key]!.timestamp)) {
          uniqueAdvices[key] = advice;
        }
      }

      _commuteAdvices = uniqueAdvices.values.toList();
      _commuteAdvices.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('✅ 加载通勤建议: ${_commuteAdvices.length}条（去重后）');
      if (_commuteAdvices.isNotEmpty) {
        print('   建议详情:');
        for (var advice in _commuteAdvices) {
          print(
            '   - ${advice.timeSlot == CommuteTimeSlot.morning ? "早高峰" : "晚高峰"}: ${advice.title}',
          );
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ 加载通勤建议失败: $e');
    }
  }

  /// 标记通勤建议为已读
  Future<void> markCommuteAdviceAsRead(String adviceId) async {
    try {
      await _databaseService.markCommuteAdviceAsRead(adviceId);
      // 更新本地状态
      final index = _commuteAdvices.indexWhere((a) => a.id == adviceId);
      if (index != -1) {
        _commuteAdvices[index] = _commuteAdvices[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print('❌ 标记通勤建议失败: $e');
    }
  }

  /// 标记所有通勤建议为已读
  Future<void> markAllCommuteAdvicesAsRead() async {
    try {
      await _databaseService.markAllCommuteAdvicesAsRead();
      // 更新本地状态
      _commuteAdvices = _commuteAdvices
          .map((a) => a.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      print('❌ 批量标记通勤建议失败: $e');
    }
  }

  /// 启动通勤建议清理定时器
  void _startCommuteCleanupTimer() {
    _stopCommuteCleanupTimer();

    // 每5分钟检查一次是否需要清理
    _commuteCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndCleanupCommuteAdvices();
    });

    print('⏰ 通勤建议清理定时器已启动');
  }

  /// 停止通勤建议清理定时器
  void _stopCommuteCleanupTimer() {
    _commuteCleanupTimer?.cancel();
    _commuteCleanupTimer = null;
  }

  /// 检查并清理通勤建议
  Future<void> _checkAndCleanupCommuteAdvices() async {
    try {
      // 1. 清理15天前的旧记录
      await _databaseService.cleanExpiredCommuteAdvices();

      // 2. 检查当前时段是否结束，清理当前时段的建议
      final timeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();
      if (timeSlot != null) {
        // 还在通勤时段，不清理
        return;
      }

      // 不在通勤时段，检查是否需要清理
      if (_commuteAdvices.isNotEmpty) {
        final firstAdvice = _commuteAdvices.first;
        if (CommuteAdviceService.isTimeSlotEnded(firstAdvice.timeSlot)) {
          // 时段已结束，清理当天该时段的建议
          await _databaseService.cleanEndedTimeSlotAdvices(
            firstAdvice.timeSlot.toString().split('.').last,
          );

          // 重新加载建议
          await loadCommuteAdvices();

          // 重置今日显示标记
          _hasShownCommuteAdviceToday = false;

          print('✅ 通勤时段结束，已清理建议');
        }
      }
    } catch (e) {
      print('❌ 清理通勤建议失败: $e');
    }
  }

  @override
  void dispose() {
    // 停止定时刷新
    _stopPeriodicRefresh();
    // 停止通勤建议清理定时器
    _stopCommuteCleanupTimer();
    super.dispose();
  }
}
