import 'package:sqflite/sqflite.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../models/sun_moon_index_model.dart';
import '../models/commute_advice_model.dart';
import 'database/database_core.dart';
import 'database/cache_service.dart';
import 'database/weather_cache_service.dart';
import 'database/location_cache_service.dart';
import 'database/city_service.dart';
import 'database/commute_advice_service.dart';

/// DatabaseService - 数据库服务门面类
///
/// 采用 Facade 模式，将原有的 DatabaseService 拆分为多个专门的服务：
/// - DatabaseCore: 核心数据库管理
/// - CacheService: 通用缓存操作
/// - WeatherCacheService: 天气数据缓存
/// - LocationCacheService: 位置数据缓存
/// - CityService: 城市管理
/// - CommuteAdviceService: 通勤建议管理
///
/// 此类保持向后兼容，所有方法调用委托给对应的子服务
class DatabaseService {
  static DatabaseService? _instance;

  // 子服务实例
  late final DatabaseCore _core;
  late final CacheService _cacheService;
  late final WeatherCacheService _weatherCacheService;
  late final LocationCacheService _locationCacheService;
  late final CityService _cityService;
  late final CommuteAdviceService _commuteAdviceService;

  DatabaseService._() {
    _core = DatabaseCore();
    _cacheService = CacheService(_core);
    _weatherCacheService = WeatherCacheService(_core);
    _locationCacheService = LocationCacheService(_core);
    _cityService = CityService(_core);
    _commuteAdviceService = CommuteAdviceService(_core);
  }

  static DatabaseService getInstance() {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  // ==================== DatabaseCore 委托方法 ====================

  /// Initialize database
  Future<void> initDatabase() => _core.initDatabase();

  /// Get database instance
  Future<Database> get database => _core.database;

  /// Close database
  Future<void> close() => _core.close();

  // ==================== CacheService 委托方法 ====================

  /// Store string data
  Future<void> putString(String key, String value) =>
      _cacheService.putString(key, value);

  /// Get string data
  Future<String?> getString(String key) => _cacheService.getString(key);

  /// Store boolean data
  Future<void> putBoolean(String key, bool value) =>
      _cacheService.putBoolean(key, value);

  /// Get boolean data
  Future<bool> getBoolean(String key, bool defaultValue) =>
      _cacheService.getBoolean(key, defaultValue);

  /// Store integer data
  Future<void> putInt(String key, int value) =>
      _cacheService.putInt(key, value);

  /// Get integer data
  Future<int> getInt(String key, int defaultValue) =>
      _cacheService.getInt(key, defaultValue);

  /// Delete expired data
  Future<int> cleanExpiredData() => _cacheService.cleanExpiredData();

  /// Clear all cached data
  Future<void> clearAllCache() => _cacheService.clearAllCache();

  /// Clear only weather data, preserve cities and location
  Future<void> clearWeatherData() => _cacheService.clearWeatherData();

  // ==================== WeatherCacheService 委托方法 ====================

  /// Store weather data
  Future<void> putWeatherData(String key, WeatherModel weatherData) =>
      _weatherCacheService.putWeatherData(key, weatherData);

  /// Get weather data
  Future<WeatherModel?> getWeatherData(String key) =>
      _weatherCacheService.getWeatherData(key);

  /// Store sun/moon index data
  Future<void> putSunMoonIndexData(
    String key,
    SunMoonIndexData sunMoonIndexData,
  ) => _weatherCacheService.putSunMoonIndexData(key, sunMoonIndexData);

  /// Get sun/moon index data
  Future<SunMoonIndexData?> getSunMoonIndexData(String key) =>
      _weatherCacheService.getSunMoonIndexData(key);

  /// Store AI summary
  Future<void> putAISummary(String key, String summary) =>
      _weatherCacheService.putAISummary(key, summary);

  /// Get AI summary
  Future<String?> getAISummary(String key) =>
      _weatherCacheService.getAISummary(key);

  /// Store AI 15-day forecast summary
  Future<void> putAI15dSummary(String key, String summary) =>
      _weatherCacheService.putAI15dSummary(key, summary);

  /// Get AI 15-day forecast summary
  Future<String?> getAI15dSummary(String key) =>
      _weatherCacheService.getAI15dSummary(key);

  /// Delete weather data by key
  Future<void> deleteWeatherData(String key) =>
      _weatherCacheService.deleteWeatherData(key);

  // ==================== LocationCacheService 委托方法 ====================

  /// Store location data
  Future<void> putLocationData(String key, LocationModel locationData) =>
      _locationCacheService.putLocationData(key, locationData);

  /// Get location data
  Future<LocationModel?> getLocationData(String key) =>
      _locationCacheService.getLocationData(key);

  /// Delete location data by key
  Future<void> deleteLocationData(String key) =>
      _locationCacheService.deleteLocationData(key);

  // ==================== CityService 委托方法 ====================

  /// Save a city to database
  Future<void> saveCity(CityModel city) => _cityService.saveCity(city);

  /// Get all cities from database
  Future<List<CityModel>> getAllCities() => _cityService.getAllCities();

  /// Get main cities from database
  Future<List<CityModel>> getMainCities() => _cityService.getMainCities();

  /// Get main cities with current location first
  Future<List<CityModel>> getMainCitiesWithCurrentLocationFirst(
    String? currentLocationName,
  ) => _cityService.getMainCitiesWithCurrentLocationFirst(
        currentLocationName);

  /// Check if current location city is already in main cities list
  Future<bool> isCurrentLocationInMainCities(
    String? currentLocationName,
  ) => _cityService.isCurrentLocationInMainCities(currentLocationName);

  /// Get city by name
  Future<CityModel?> getCityByName(String name) =>
      _cityService.getCityByName(name);

  /// Get city by ID
  Future<CityModel?> getCityById(String id) => _cityService.getCityById(id);

  /// Delete a city from database
  Future<void> deleteCity(String cityId) => _cityService.deleteCity(cityId);

  /// Delete city by name
  Future<void> deleteCityByName(String name) =>
      _cityService.deleteCityByName(name);

  /// Update city main status
  Future<void> updateCityMainStatus(String cityId, bool isMainCity) =>
      _cityService.updateCityMainStatus(cityId, isMainCity);

  /// Update city sort order
  Future<void> updateCitySortOrder(String cityId, int sortOrder) =>
      _cityService.updateCitySortOrder(cityId, sortOrder);

  /// Update multiple cities sort order
  Future<void> updateCitiesSortOrder(
    List<Map<String, dynamic>> citySortOrders,
  ) => _cityService.updateCitiesSortOrder(citySortOrders);

  /// Check if cities table is initialized
  Future<bool> isCitiesTableInitialized() =>
      _cityService.isCitiesTableInitialized();

  /// Save city to search table
  Future<void> saveCityToSearch(String id, String name) =>
      _cityService.saveCityToSearch(id, name);

  /// Search cities by name from search table
  Future<List<Map<String, dynamic>>> searchCitiesFromDatabase(
    String query,
  ) => _cityService.searchCitiesFromDatabase(query);

  /// Initialize city search data from JSON
  Future<void> initializeCitySearchData() =>
      _cityService.initializeCitySearchData();

  /// Clear city search data
  Future<void> clearCitySearchData() => _cityService.clearCitySearchData();

  /// Remove duplicate cities with the same name
  Future<void> removeDuplicateCities() =>
      _cityService.removeDuplicateCities();

  /// Clear all cities from database
  Future<void> clearAllCities() => _cityService.clearAllCities();

  // ==================== CommuteAdviceService 委托方法 ====================

  /// 保存通勤建议
  Future<void> saveCommuteAdvice(CommuteAdviceModel advice) =>
      _commuteAdviceService.saveCommuteAdvice(advice);

  /// 批量保存通勤建议
  Future<void> saveCommuteAdvices(List<CommuteAdviceModel> advices) =>
      _commuteAdviceService.saveCommuteAdvices(advices);

  /// 获取所有通勤建议
  Future<List<CommuteAdviceModel>> getAllCommuteAdvices() =>
      _commuteAdviceService.getAllCommuteAdvices();

  /// 获取未读的通勤建议
  Future<List<CommuteAdviceModel>> getUnreadCommuteAdvices() =>
      _commuteAdviceService.getUnreadCommuteAdvices();

  /// 获取今日的通勤建议
  Future<List<CommuteAdviceModel>> getTodayCommuteAdvices() =>
      _commuteAdviceService.getTodayCommuteAdvices();

  /// 标记建议为已读
  Future<void> markCommuteAdviceAsRead(String adviceId) =>
      _commuteAdviceService.markCommuteAdviceAsRead(adviceId);

  /// 批量标记建议为已读
  Future<void> markAllCommuteAdvicesAsRead() =>
      _commuteAdviceService.markAllCommuteAdvicesAsRead();

  /// 删除指定的通勤建议
  Future<void> deleteCommuteAdvice(String adviceId) =>
      _commuteAdviceService.deleteCommuteAdvice(adviceId);

  /// 清理过期的通勤建议（保留15天内的）
  Future<int> cleanExpiredCommuteAdvices() =>
      _commuteAdviceService.cleanExpiredCommuteAdvices();

  /// 清理当前时段结束的通勤建议
  Future<int> cleanEndedTimeSlotAdvices(String timeSlot) =>
      _commuteAdviceService.cleanEndedTimeSlotAdvices(timeSlot);

  /// 清理重复的通勤建议
  Future<int> cleanDuplicateCommuteAdvices() =>
      _commuteAdviceService.cleanDuplicateCommuteAdvices();

  // ==================== 其他工具方法 ====================

  /// Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('weather_cache');
    await db.delete('location_cache');
    await db.delete('cities');
  }
}
