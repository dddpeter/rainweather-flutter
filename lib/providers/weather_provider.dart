import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/weather_service.dart';
import '../services/forecast15d_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/weather_alert_service.dart';
import '../services/city_service.dart';
import '../services/city_data_service.dart';
import '../services/sun_moon_index_service.dart';
import '../constants/app_constants.dart';
import '../utils/app_state_manager.dart';
import '../utils/city_name_matcher.dart';
import '../services/location_change_notifier.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final Forecast15dService _forecast15dService =
      Forecast15dService.getInstance();
  final LocationService _locationService = LocationService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();
  final CityService _cityService = CityService.getInstance();
  final WeatherAlertService _alertService = WeatherAlertService.instance;

  // 获取CityDataService实例
  CityDataService get _cityDataService => CityDataService.getInstance();

  WeatherModel? _currentWeather;
  LocationModel? _currentLocation;
  List<HourlyWeather>? _hourlyForecast;
  List<DailyWeather>? _dailyForecast;
  List<DailyWeather>? _forecast15d;
  bool _isLoading = false;
  String? _error;

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

  // Dynamic cities list
  List<CityModel> _mainCities = [];
  bool _isLoadingCities = false;

  // Getters
  WeatherModel? get currentWeather => _currentWeather;
  LocationModel? get currentLocation => _currentLocation;
  List<HourlyWeather>? get hourlyForecast => _hourlyForecast;
  List<DailyWeather>? get dailyForecast => _dailyForecast;
  List<DailyWeather>? get forecast15d => _forecast15d;
  bool get isLoading => _isLoading;
  String? get error => _error;
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

  // 当前定位天气数据的getter
  WeatherModel? get currentLocationWeather => _currentLocationWeather;
  LocationModel? get originalLocation => _originalLocation;
  bool get isShowingCityWeather => _isShowingCityWeather;
  int get currentTabIndex => _currentTabIndex;

  /// Initialize weather data
  Future<void> initializeWeather() async {
    final appStateManager = AppStateManager();

    // 检查是否可以初始化
    if (!appStateManager.canFetchWeatherData()) {
      print('🚫 WeatherProvider: 应用状态不允许初始化，跳过');
      return;
    }

    // 标记开始初始化
    appStateManager.markInitializationStarted();

    try {
      await _databaseService.initDatabase();

      // 初始化城市数据（这里已经包含了loadMainCities的调用）
      await initializeCities();

      // 清理过期缓存数据
      await _cleanupExpiredCache();

      // 先使用缓存的位置，不进行实时定位
      LocationModel? realLocation;
      LocationModel? cachedLocation = _locationService.getCachedLocation();
      if (cachedLocation != null) {
        print('🔄 WeatherProvider: 使用缓存的位置 ${cachedLocation.district}');
        realLocation = cachedLocation;
      } else {
        print('🔄 WeatherProvider: 无缓存位置，使用默认位置');
        // 使用默认位置（北京）
        realLocation = LocationModel(
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

      if (realLocation != null) {
        // 如果获得了真实位置，直接使用它，不使用缓存
        print(
          'Got real location during initialization: ${realLocation.district}',
        );
        _currentLocation = realLocation;

        // 清理默认位置的缓存数据
        await clearDefaultLocationCache();

        // 重新加载主要城市列表，确保当前定位城市被包含
        await loadMainCities();

        await refreshWeatherData();
        // 异步加载15日预报数据
        refresh15DayForecast();
        // 异步加载日出日落和生活指数数据
        loadSunMoonIndexData();
      } else {
        // 如果没有获得真实位置，使用北京作为默认位置
        print('No real location available, using Beijing as default');
        _currentLocation = _getDefaultLocation();

        // 重新加载主要城市列表
        await loadMainCities();

        await refreshWeatherData();
        // 异步加载15日预报数据
        refresh15DayForecast();
        // 异步加载日出日落和生活指数数据
        loadSunMoonIndexData();
      }

      // 异步加载主要城市天气数据
      _loadMainCitiesWeather();

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
    final appStateManager = AppStateManager();

    // 检查是否可以刷新数据
    if (!appStateManager.canFetchWeatherData()) {
      print('🚫 WeatherProvider: 应用状态不允许刷新天气数据，跳过');
      return;
    }

    _setLoading(true);
    _error = null;

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
        print('Using cached weather data for ${location.district}');
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
        } else {
          _error = 'Failed to fetch weather data';
        }
      }
    } catch (e) {
      if (e is LocationException) {
        _error = e.message;
        print('Location error: ${e.message}');
      } else {
        _error = 'Error: $e';
        print('Weather refresh error: $e');
      }
    } finally {
      _setLoading(false);

      // 如果定位成功，通知所有监听器
      if (_currentLocation != null && _error == null) {
        print('📍 WeatherProvider: refreshWeatherData 准备发送定位成功通知');
        LocationChangeNotifier().notifyLocationSuccess(_currentLocation!);
      } else {
        print(
          '📍 WeatherProvider: refreshWeatherData 跳过通知 - 位置: ${_currentLocation?.district}, 错误: $_error',
        );
      }
    }
  }

  /// Get weather data for specific city
  Future<void> getWeatherForCity(String cityName) async {
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
  Future<void> _loadMainCitiesWeather() async {
    _isLoadingCitiesWeather = true;
    notifyListeners();

    try {
      // 并行获取所有主要城市的天气数据
      List<Future<void>> futures = [];

      // 获取主要城市列表（从数据库或常量）
      final cityNames = _mainCities.isNotEmpty
          ? _mainCities.map((city) => city.name).toList()
          : AppConstants.mainCities;

      for (String cityName in cityNames) {
        futures.add(_loadSingleCityWeather(cityName));
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

  /// 加载单个城市的天气数据
  Future<void> _loadSingleCityWeather(String cityName) async {
    try {
      // 检查是否有有效的缓存数据
      final weatherKey = '$cityName:${AppConstants.weatherAllKey}';
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(
        weatherKey,
      );

      if (cachedWeather != null) {
        // 使用缓存数据
        _mainCitiesWeather[cityName] = cachedWeather;
        print('Using cached weather data for $cityName in main cities');
        notifyListeners();
      } else {
        // 从API获取新数据
        print(
          'No valid cache found, fetching fresh weather data for $cityName in main cities',
        );

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

          // 分析天气提醒
          try {
            await _alertService.analyzeWeather(weather, cityLocation);
            print('🏙️ WeatherProvider: 已分析 $cityName 的天气提醒');
          } catch (e) {
            print('🏙️ WeatherProvider: 分析 $cityName 天气提醒失败 - $e');
          }

          // 通知UI更新
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading weather for $cityName: $e');
    }
  }

  /// 获取指定城市的天气数据
  WeatherModel? getCityWeather(String cityName) {
    return _mainCitiesWeather[cityName];
  }

  /// 刷新主要城市天气数据
  Future<void> refreshMainCitiesWeather() async {
    _mainCitiesWeather.clear();
    await _loadMainCitiesWeather();
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

    // 刷新主要城市天气数据
    await refreshMainCitiesWeather();
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

  /// 为指定位置加载天气数据
  Future<void> _loadWeatherDataForLocation(LocationModel location) async {
    try {
      print('🔄 WeatherProvider: 为位置 ${location.district} 加载天气数据');

      // 获取天气数据
      final weather = await _weatherService.getWeatherDataForLocation(location);

      if (weather != null) {
        // 更新当前天气数据
        _currentWeather = weather;
        _currentLocationWeather = weather;
        _originalLocation = location;
        _isShowingCityWeather = false;

        // 更新预报数据
        _hourlyForecast = weather.forecast24h;
        _dailyForecast = weather.forecast15d?.take(7).toList();
        _forecast15d = weather.forecast15d;

        print('✅ WeatherProvider: 位置 ${location.district} 天气数据加载成功');
      } else {
        print('❌ WeatherProvider: 位置 ${location.district} 天气数据加载失败');
      }
    } catch (e) {
      print('❌ WeatherProvider: 加载位置天气数据异常: $e');
    }
  }

  /// 在进入今日天气页面后进行定位
  Future<void> performLocationAfterEntering() async {
    // 如果已经进行过首次定位，则不再执行
    if (_hasPerformedInitialLocation) {
      print('🔄 WeatherProvider: 已经进行过首次定位，跳过');
      return;
    }

    print('🔄 WeatherProvider: 首次进入今日天气页面，开始定位...');

    try {
      // 显示定位状态
      _isLoading = true;
      _error = null;
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

        // 更新位置
        _currentLocation = newLocation;
        _locationService.setCachedLocation(newLocation);

        // 清理默认位置的缓存数据
        await clearDefaultLocationCache();

        // 重新加载主要城市列表
        await loadMainCities();

        // 获取新位置的天气数据
        await _loadWeatherDataForLocation(newLocation);

        // 标记已经进行过首次定位
        _hasPerformedInitialLocation = true;

        _error = null;

        // 通知所有监听器定位成功
        print('📍 WeatherProvider: 准备发送定位成功通知');
        LocationChangeNotifier().notifyLocationSuccess(newLocation);
      } else {
        print('❌ WeatherProvider: 定位失败');
        _error = '定位失败，请检查网络连接和位置权限';

        // 通知所有监听器定位失败
        print('📍 WeatherProvider: 准备发送定位失败通知');
        LocationChangeNotifier().notifyLocationFailed(_error!);
      }
    } catch (e) {
      print('❌ WeatherProvider: 定位异常: $e');
      _error = '定位失败: $e';
    } finally {
      _isLoading = false;
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
}
