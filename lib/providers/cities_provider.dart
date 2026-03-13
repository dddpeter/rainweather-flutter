import 'package:flutter/foundation.dart';
import '../models/city_model.dart';
import '../models/weather_model.dart';
import '../services/city_service.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
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
      // 从数据库加载已保存的城市列表
      final savedCities = await _databaseService.getMainCities();

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

  /// 添加城市
  Future<bool> addCity(CityModel city) async {
    try {
      // 检查是否已存在
      if (_mainCities.any((c) => c.id == city.id)) {
        Logger.d('城市已存在: ${city.name}', tag: 'CitiesProvider');
        return false;
      }

      _mainCities.add(city);
      await _saveCitiesToDatabase();
      notifyListeners();

      // 刷新该城市的天气数据
      await refreshCityWeather(city);

      Logger.d('添加城市成功: ${city.name}', tag: 'CitiesProvider');
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
      _mainCities.removeWhere((c) => c.id == cityId);
      _mainCitiesWeather.remove(cityId);

      await _saveCitiesToDatabase();
      notifyListeners();

      Logger.d('移除城市成功: ${city.name}', tag: 'CitiesProvider');
      return true;
    } catch (e) {
      Logger.e('移除城市失败: $cityId', tag: 'CitiesProvider', error: e);
      return false;
    }
  }

  /// 更新城市排序
  Future<bool> updateCitiesSortOrder(List<CityModel> newOrder) async {
    try {
      _mainCities = List.from(newOrder);
      await _saveCitiesToDatabase();
      notifyListeners();
      Logger.d('更新城市排序成功', tag: 'CitiesProvider');
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
      final weatherData = await _weatherService.getWeatherData(city.name);

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
      // 逐个保存城市
      for (final city in _mainCities) {
        await _databaseService.saveCity(city);
      }
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
    ];

    final allDefaultCities = <CityModel>[];
    for (final cityName in defaultCityNames) {
      final results = await _cityService.searchCities(cityName);
      if (results.isNotEmpty) {
        final exactMatch = results.firstWhere(
          (city) => city.name == cityName,
          orElse: () => results.first,
        );
        allDefaultCities.add(exactMatch);
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
