import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/weather_service.dart';
import '../services/forecast15d_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/city_service.dart';
import '../services/city_data_service.dart';
import '../services/sun_moon_index_service.dart';
import '../constants/app_constants.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final Forecast15dService _forecast15dService =
      Forecast15dService.getInstance();
  final LocationService _locationService = LocationService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();
  final CityService _cityService = CityService.getInstance();

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

  // 主要城市天气数据
  Map<String, WeatherModel> _mainCitiesWeather = {};
  bool _isLoadingCitiesWeather = false;

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

  // 日出日落和生活指数数据getters
  SunMoonIndexData? get sunMoonIndexData => _sunMoonIndexData;
  bool get isLoadingSunMoonIndex => _isLoadingSunMoonIndex;

  // Dynamic cities getters
  List<CityModel> get mainCities => _mainCities;
  bool get isLoadingCities => _isLoadingCities;

  // 当前定位天气数据的getter
  WeatherModel? get currentLocationWeather => _currentLocationWeather;
  LocationModel? get originalLocation => _originalLocation;

  /// Initialize weather data
  Future<void> initializeWeather() async {
    try {
      await _databaseService.initDatabase();

      // 初始化城市数据（这里已经包含了loadMainCities的调用）
      await initializeCities();

      // 清理过期缓存数据
      await _cleanupExpiredCache();

      // 先尝试获取真实位置，如果失败再加载缓存数据
      LocationModel? realLocation = await _locationService.getCurrentLocation();

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
    } catch (e) {
      print('Database initialization failed: $e');
      // Continue without database for testing
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
        _currentLocationWeather = cachedWeather; // 保存当前定位天气数据
        _originalLocation = location; // 保存原始位置
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
          _currentLocationWeather = weather; // 保存当前定位天气数据
          _originalLocation = location; // 保存原始位置
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
        _currentWeather = cachedWeather;
        _hourlyForecast = cachedWeather.forecast24h;
        _dailyForecast = cachedWeather.forecast15d?.take(7).toList();
        _forecast15d = cachedWeather.forecast15d; // 保存15日预报数据
        print('Using cached weather data for $cityName');
      } else {
        // Fetch fresh data from API
        print(
          'No valid cache found, fetching fresh weather data for $cityName',
        );
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(
          cityLocation,
        );

        if (weather != null) {
          _currentWeather = weather;
          _hourlyForecast = weather.forecast24h;
          _dailyForecast = weather.forecast15d?.take(7).toList();
          _forecast15d = weather.forecast15d; // 保存15日预报数据

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

      // Load main cities with current location first (this will handle adding current location if needed)
      _mainCities = await _cityService.getMainCitiesWithCurrentLocationFirst(
        currentLocationName,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading main cities: $e');
    }
  }

  /// Get current location city name
  String? getCurrentLocationCityName() {
    return _currentLocation?.district ?? _originalLocation?.district;
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
        if (currentLocationName != null && city.name == currentLocationName) {
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
      print(
        'Force refresh: clearing current location cache and getting fresh location',
      );

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

      // Also refresh main cities weather
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

  /// 恢复到当前定位的天气数据（用于从城市天气页面返回到今日天气页面）
  void restoreCurrentLocationWeather() {
    if (_currentLocationWeather != null && _originalLocation != null) {
      _currentWeather = _currentLocationWeather;
      _currentLocation = _originalLocation;
      _hourlyForecast = _currentLocationWeather!.forecast24h;
      _dailyForecast = _currentLocationWeather!.forecast15d?.take(7).toList();
      _forecast15d = _currentLocationWeather!.forecast15d;
      notifyListeners();
      print(
        'Restored to current location weather: ${_originalLocation!.district}',
      );
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
