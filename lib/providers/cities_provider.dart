import 'package:flutter/foundation.dart';
import '../models/city_model.dart';
import '../models/weather_model.dart';
import '../services/city_service.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../services/geocoding_service.dart';
import '../utils/logger.dart';

/// CitiesProvider - 城市管理 Provider
///
/// 职责：
/// - 管理主要城市列表（增删改查、排序）
/// - 管理城市天气数据
/// - 城市搜索功能
/// - 城市天气刷新状态管理
class CitiesProvider extends ChangeNotifier {
  final CityService _cityService = CityService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();
  final WeatherService _weatherService = WeatherService.getInstance();
  final GeocodingService _geocodingService = GeocodingService.getInstance();

  // ===== 城市列表 =====
  List<CityModel> _mainCities = [];
  bool _isLoadingCities = false;
  String? _citiesError;

  // ===== 城市天气数据 =====
  final Map<String, WeatherModel> _mainCitiesWeather = {};
  bool _isLoadingCitiesWeather = false;
  bool _hasPerformedInitialMainCitiesRefresh = false;

  // ===== Getters =====
  List<CityModel> get mainCities => List.unmodifiable(_mainCities);
  bool get isLoadingCities => _isLoadingCities;
  bool get isLoadingCitiesWeather => _isLoadingCitiesWeather;
  bool get hasPerformedInitialMainCitiesRefresh =>
      _hasPerformedInitialMainCitiesRefresh;
  String? get citiesError => _citiesError;

  /// 获取指定城市的天气数据
  WeatherModel? getWeatherForCity(String cityId) {
    return _mainCitiesWeather[cityId];
  }

  /// 初始化城市列表
  Future<bool> initializeCities() async {
    setLoadingCities(true);

    try {
      // 从数据库加载已保存的城市列表（国内城市在前，国际城市在后）
      final savedCities = await _databaseService.getMainCitiesWithCurrentLocationFirst(null);

      if (savedCities.isNotEmpty) {
        _mainCities = savedCities;
        Logger.d('加载了 ${savedCities.length} 个城市', tag: 'CitiesProvider');
        notifyListeners();
        return true;
      } else {
        // 如果没有保存的城市，加载默认城市
        await _loadDefaultCities();
        return true;
      }
    } catch (e) {
      _citiesError = e.toString();
      Logger.e('加载城市列表失败', tag: 'CitiesProvider', error: e);
      return false;
    } finally {
      setLoadingCities(false);
    }
  }

  /// 搜索城市
  Future<List<CityModel>> searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final results = await _cityService.searchCities(query);
      Logger.d('搜索 "$query" 找到 ${results.length} 个结果', tag: 'CitiesProvider');
      return results;
    } catch (e) {
      Logger.e('搜索城市失败: $query', tag: 'CitiesProvider', error: e);
      return [];
    }
  }

  /// 获取主要城市名称列表
  Future<List<String>> getMainCityNames() async {
    try {
      return await _cityService.getMainCityNames();
    } catch (e) {
      Logger.e('获取主要城市名称失败', tag: 'CitiesProvider', error: e);
      return [];
    }
  }

  /// 添加城市
  Future<bool> addCity(CityModel city) async {
    try {
      // 检查是否已存在
      if (_mainCities.any((c) => c.id == city.id)) {
        Logger.d('城市已存在: ${city.name}', tag: 'CitiesProvider');
        return false;
      }

      // 确保城市被标记为主要城市，并设置排序order
      final maxOrder = _mainCities.isNotEmpty 
          ? _mainCities.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b)
          : 0;
      final mainCity = city.copyWith(
        isMainCity: true,
        sortOrder: maxOrder + 1,
      );
      
      _mainCities.add(mainCity);
      await _saveCitiesToDatabase();
      notifyListeners();

      // 刷新该城市的天气数据
      await refreshCityWeather(mainCity);

      Logger.d('添加城市成功: ${mainCity.name} (isMainCity: ${mainCity.isMainCity}, sortOrder: ${mainCity.sortOrder})', tag: 'CitiesProvider');
      return true;
    } catch (e) {
      Logger.e('添加城市失败: ${city.name}', tag: 'CitiesProvider', error: e);
      return false;
    }
  }

  /// 移除城市
  Future<bool> removeCity(String cityId) async {
    try {
      final city = _mainCities.firstWhere((c) => c.id == cityId);
      
      // 从数据库中删除该城市
      await _databaseService.deleteCity(cityId);
      Logger.d('从数据库删除城市: ${city.name} ($cityId)', tag: 'CitiesProvider');
      
      _mainCities.removeWhere((c) => c.id == cityId);
      _mainCitiesWeather.remove(cityId);

      // 重新计算剩余城市的sortOrder
      final updatedCities = <CityModel>[];
      for (int i = 0; i < _mainCities.length; i++) {
        final updatedCity = _mainCities[i].copyWith(sortOrder: i);
        updatedCities.add(updatedCity);
      }
      _mainCities = updatedCities;

      await _saveCitiesToDatabase();
      notifyListeners();

      Logger.d('移除城市成功: ${city.name}，重新排序 ${updatedCities.length} 个城市', tag: 'CitiesProvider');
      return true;
    } catch (e) {
      Logger.e('移除城市失败: $cityId', tag: 'CitiesProvider', error: e);
      return false;
    }
  }

  /// 更新城市排序
  Future<bool> updateCitiesSortOrder(List<CityModel> newOrder) async {
    try {
      // 根据新顺序更新sortOrder
      final updatedCities = <CityModel>[];
      for (int i = 0; i < newOrder.length; i++) {
        final city = newOrder[i];
        // 更新sortOrder为当前索引
        final updatedCity = city.copyWith(sortOrder: i);
        updatedCities.add(updatedCity);
      }
      
      _mainCities = updatedCities;
      await _saveCitiesToDatabase();
      notifyListeners();
      Logger.d('更新城市排序成功，新顺序: ${updatedCities.map((c) => "${c.name}(order:${c.sortOrder})").join(", ")}', tag: 'CitiesProvider');
      return true;
    } catch (e) {
      Logger.e('更新城市排序失败', tag: 'CitiesProvider', error: e);
      return false;
    }
  }

  /// 刷新所有城市天气数据
  Future<bool> refreshAllCitiesWeather() async {
    if (_mainCities.isEmpty) {
      Logger.d('没有需要刷新天气的城市', tag: 'CitiesProvider');
      return true;
    }

    setLoadingCitiesWeather(true);

    try {
      for (final city in _mainCities) {
        await refreshCityWeather(city);
      }

      _hasPerformedInitialMainCitiesRefresh = true;
      Logger.d('刷新所有城市天气完成', tag: 'CitiesProvider');
      return true;
    } catch (e) {
      Logger.e('刷新城市天气失败', tag: 'CitiesProvider', error: e);
      return false;
    } finally {
      setLoadingCitiesWeather(false);
    }
  }

  /// 刷新单个城市天气
  Future<bool> refreshCityWeather(CityModel city) async {
    try {
      // 判断是否为国际城市（ID 以 INT_ 开头）
      final isInternational = city.id.startsWith('INT_');
      
      WeatherModel? weatherData;
      if (isInternational) {
        // 国际城市：使用地理编码服务获取坐标，然后通过坐标获取天气
        Logger.d('国际城市，使用GeocodingService获取坐标: ${city.name}', tag: 'CitiesProvider');
        
        final location = await _geocodingService.geocode(city.name);
        if (location != null) {
          Logger.d('获取到国际城市坐标: ${city.name} (${location.lat}, ${location.lng})', tag: 'CitiesProvider');
          weatherData = await _weatherService.getWeatherDataForLocation(location);
        } else {
          Logger.e('无法获取国际城市坐标: ${city.name}', tag: 'CitiesProvider');
          return false;
        }
      } else if (city.id.isEmpty) {
        // 无有效ID的城市：尝试通过城市名称获取天气
        Logger.d('无有效ID，尝试通过城市名称获取天气: ${city.name}', tag: 'CitiesProvider');
        weatherData = await _weatherService.getWeatherData(city.name);
      } else {
        // 国内城市：使用城市ID查询
        Logger.d('国内城市，使用城市ID查询: ${city.name} (${city.id})', tag: 'CitiesProvider');
        weatherData = await _weatherService.getWeatherData(city.id);
      }

      if (weatherData != null) {
        _mainCitiesWeather[city.id] = weatherData;
        notifyListeners();
        Logger.d('刷新城市天气成功: ${city.name}', tag: 'CitiesProvider');
        return true;
      }
      return false;
    } catch (e) {
      Logger.e('刷新城市天气失败: ${city.name}', tag: 'CitiesProvider', error: e);
      return false;
    }
  }

  /// 执行首次主要城市刷新
  Future<void> performInitialMainCitiesRefresh() async {
    if (!_hasPerformedInitialMainCitiesRefresh) {
      await refreshAllCitiesWeather();
    }
  }

  /// 设置加载状态
  void setLoadingCities(bool loading) {
    if (_isLoadingCities != loading) {
      _isLoadingCities = loading;
      notifyListeners();
    }
  }

  void setLoadingCitiesWeather(bool loading) {
    if (_isLoadingCitiesWeather != loading) {
      _isLoadingCitiesWeather = loading;
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    if (_citiesError != null) {
      _citiesError = null;
      notifyListeners();
    }
  }

  /// 保存城市列表到数据库
  Future<void> _saveCitiesToDatabase() async {
    try {
      // 逐个保存城市，确保所有城市都被标记为主要城市
      for (final city in _mainCities) {
        final mainCity = city.isMainCity ? city : city.copyWith(isMainCity: true);
        await _databaseService.saveCity(mainCity);
      }
      Logger.d('保存 ${_mainCities.length} 个主要城市到数据库', tag: 'CitiesProvider');
    } catch (e) {
      Logger.e('保存城市列表失败', tag: 'CitiesProvider', error: e);
    }
  }

  /// 加载默认城市
  Future<void> _loadDefaultCities() async {
    const defaultCityNames = [
      '上海',
      '广州',
      '深圳',
      '成都',
      '杭州',
      '武汉',
      '西安',
      '南京',
      // 国际城市
      '东京',
      '首尔',
      '新加坡',
      '伦敦',
      '纽约',
    ];

    final allDefaultCities = <CityModel>[];
    for (int i = 0; i < defaultCityNames.length; i++) {
      final cityName = defaultCityNames[i];
      final results = await _cityService.searchCities(cityName);
      if (results.isNotEmpty) {
        final exactMatch = results.firstWhere(
          (city) => city.name == cityName,
          orElse: () => results.first,
        );
        // 设置sortOrder为当前索引
        final cityWithOrder = exactMatch.copyWith(
          isMainCity: true,
          sortOrder: i,
        );
        allDefaultCities.add(cityWithOrder);
      } else {
        // 对于国际城市，如果数据库中没有，创建一个虚拟城市条目
        // ID 使用 INT_ 前缀标识，CityWeatherProvider 会识别并使用 Open-Meteo API
        if (['东京', '首尔', '新加坡', '伦敦', '纽约'].contains(cityName)) {
          final virtualCity = CityModel(
            id: 'INT_${cityName.toUpperCase()}',
            name: cityName,
            isMainCity: true,
            createdAt: DateTime.now(),
            sortOrder: i, // 设置sortOrder
          );
          allDefaultCities.add(virtualCity);
          Logger.d('为国际城市创建虚拟条目: $cityName (order: $i)', tag: 'CitiesProvider');
        }
      }
    }

    if (allDefaultCities.isNotEmpty) {
      _mainCities = allDefaultCities;
      await _saveCitiesToDatabase();
      notifyListeners();
      Logger.d('加载了 ${allDefaultCities.length} 个默认城市', tag: 'CitiesProvider');
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _mainCities.clear();
    _mainCitiesWeather.clear();
    super.dispose();
  }
}
