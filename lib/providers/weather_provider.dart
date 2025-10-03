import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../services/weather_service.dart';
import '../services/forecast15d_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/city_service.dart';
import '../constants/app_constants.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final Forecast15dService _forecast15dService = Forecast15dService.getInstance();
  final LocationService _locationService = LocationService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();
  final CityService _cityService = CityService.getInstance();
  
  WeatherModel? _currentWeather;
  LocationModel? _currentLocation;
  List<HourlyWeather>? _hourlyForecast;
  List<DailyWeather>? _dailyForecast;
  List<DailyWeather>? _forecast15d;
  bool _isLoading = false;
  String? _error;
  
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
        print('Got real location during initialization: ${realLocation.district}');
        _currentLocation = realLocation;
        
        // 清理默认位置的缓存数据
        await clearDefaultLocationCache();
        
        // 重新加载主要城市列表，确保当前定位城市被包含
        await loadMainCities();
        
        await refreshWeatherData();
        // 异步加载15日预报数据
        refresh15DayForecast();
      } else {
        // 如果没有获得真实位置，使用北京作为默认位置
        print('No real location available, using Beijing as default');
        _currentLocation = _getDefaultLocation();
        
        // 重新加载主要城市列表
        await loadMainCities();
        
        await refreshWeatherData();
        // 异步加载15日预报数据
        refresh15DayForecast();
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
      _currentLocation = await _databaseService.getLocationData(AppConstants.currentLocationKey);
      
      if (_currentLocation != null) {
        // Load cached weather data
        final weatherKey = '${_currentLocation!.district}:${AppConstants.weatherAllKey}';
        _currentWeather = await _databaseService.getWeatherData(weatherKey);
        
        if (_currentWeather != null) {
          _hourlyForecast = _currentWeather!.forecast24h;
          _dailyForecast = _currentWeather!.forecast15d?.take(7).toList();
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
      await _databaseService.putLocationData(AppConstants.currentLocationKey, location);
      
      // Update main cities list to include current location
      await loadMainCities();
      
      // Check if we have valid cached weather data
      final weatherKey = '${location.district}:${AppConstants.weatherAllKey}';
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(weatherKey);
      
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
        print('No valid cache found, fetching fresh weather data for ${location.district}');
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(location);
        
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
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(weatherKey);
      
      if (cachedWeather != null) {
        // Use cached data
        _currentWeather = cachedWeather;
        _hourlyForecast = cachedWeather.forecast24h;
        _dailyForecast = cachedWeather.forecast15d?.take(7).toList();
        print('Using cached weather data for $cityName');
      } else {
        // Fetch fresh data from API
        print('No valid cache found, fetching fresh weather data for $cityName');
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(cityLocation);
        
        if (weather != null) {
          _currentWeather = weather;
          _hourlyForecast = weather.forecast24h;
          _dailyForecast = weather.forecast15d?.take(7).toList();
          
          // Save to cache
          await _databaseService.putWeatherData(weatherKey, weather);
        } else {
          _error = 'Failed to fetch weather data for $cityName';
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
      WeatherModel? cachedWeather = await _databaseService.getWeatherData(weatherKey);
      
      if (cachedWeather != null) {
        // 使用缓存数据
        _mainCitiesWeather[cityName] = cachedWeather;
        print('Using cached weather data for $cityName in main cities');
        notifyListeners();
      } else {
        // 从API获取新数据
        print('No valid cache found, fetching fresh weather data for $cityName in main cities');
        
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
        WeatherModel? weather = await _weatherService.getWeatherDataForLocation(cityLocation);
        
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
      final currentLocationName = _currentLocation?.district ?? _originalLocation?.district;
      
      // Load main cities with current location first (this will handle adding current location if needed)
      _mainCities = await _cityService.getMainCitiesWithCurrentLocationFirst(currentLocationName);
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
        citySortOrders.add({
          'cityId': city.id,
          'sortOrder': sortOrder,
        });
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
      notifyListeners();
      print('All cache data cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear cached default location data when real location is available
  Future<void> clearDefaultLocationCache() async {
    try {
      // Get the default location
      final defaultLocation = _getDefaultLocation();
      
      // Clear cached weather data for default location
      final defaultWeatherKey = '${defaultLocation.district}:${AppConstants.weatherAllKey}';
      await _databaseService.deleteWeatherData(defaultWeatherKey);
      
      // Clear cached location if it's the default location
      final cachedLocation = await _databaseService.getLocationData(AppConstants.currentLocationKey);
      if (cachedLocation != null && cachedLocation.district == defaultLocation.district) {
        await _databaseService.deleteLocationData(AppConstants.currentLocationKey);
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
      print('Force refresh: clearing current location cache and getting fresh location');
      
      // Clear current location cache
      await _databaseService.deleteLocationData(AppConstants.currentLocationKey);
      
      // Clear current weather cache
      if (_currentLocation != null) {
        final currentWeatherKey = '${_currentLocation!.district}:${AppConstants.weatherAllKey}';
        await _databaseService.deleteWeatherData(currentWeatherKey);
        print('Cleared current location weather cache: ${_currentLocation!.district}');
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
      await _databaseService.putLocationData(AppConstants.currentLocationKey, location);
      
      // Update main cities list to include current location
      await loadMainCities();
      
      // Get fresh weather data (no cache)
      WeatherModel? weather = await _weatherService.getWeatherDataForLocation(location);
      
      if (weather != null) {
        _currentWeather = weather;
        _currentLocationWeather = weather;
        _originalLocation = location;
        _hourlyForecast = weather.forecast24h;
        _dailyForecast = weather.forecast15d?.take(7).toList();
        
        // Save fresh weather data to cache
        final weatherKey = '${location.district}:${AppConstants.weatherAllKey}';
        await _databaseService.putWeatherData(weatherKey, weather);
        
        // Cache location in service
        _locationService.setCachedLocation(location);
        
        print('Force refresh completed with fresh data for ${location.district}');
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
      print('Restored to current location weather: ${_originalLocation!.district}');
    }
  }

  /// 刷新15日预报数据
  Future<void> refresh15DayForecast() async {
    if (_currentLocation == null) return;
    
    _setLoading(true);
    _error = null;
    
    try {
      print('Refreshing 15-day forecast for: ${_currentLocation!.district}');
      
      // 检查缓存
      final forecastKey = '${_currentLocation!.district}:${AppConstants.weather15dKey}';
      WeatherModel? cachedForecast = await _databaseService.getWeatherData(forecastKey);
      
      if (cachedForecast != null) {
        // 使用缓存数据
        _forecast15d = cachedForecast.forecast15d;
        print('Using cached 15-day forecast data for ${_currentLocation!.district}');
      } else {
        // 从API获取新数据
        print('No valid cache found, fetching fresh 15-day forecast data for ${_currentLocation!.district}');
        WeatherModel? forecast = await _forecast15dService.get15DayForecastForLocation(_currentLocation!);
        
        if (forecast != null) {
          _forecast15d = forecast.forecast15d;
          
          // 保存到缓存
          await _databaseService.putWeatherData(forecastKey, forecast);
          print('15-day forecast data cached for ${_currentLocation!.district}');
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
}
