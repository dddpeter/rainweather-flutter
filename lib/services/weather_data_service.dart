import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import 'weather_service.dart';
import '../utils/logger.dart';

/// WeatherDataService - 天气数据加载服务
///
/// 职责：
/// - 从 API 加载天气数据
/// - 处理数据刷新逻辑
/// - 单个/多个城市数据加载
class WeatherDataService {
  final WeatherService _weatherService = WeatherService.getInstance();

  /// 加载指定位置的天气数据
  Future<WeatherModel?> loadWeatherForLocation(LocationModel location) async {
    try {
      Logger.d('加载天气数据: ${location.district}', tag: 'WeatherDataService');
      return await _weatherService.getWeatherDataForLocation(location);
    } catch (e) {
      Logger.e('加载天气数据失败: ${location.district}', tag: 'WeatherDataService', error: e);
      return null;
    }
  }

  /// 加载单个城市的天气数据
  Future<WeatherModel?> loadCityWeather(CityModel city) async {
    try {
      Logger.d('加载城市天气: ${city.name}', tag: 'WeatherDataService');
      return await _weatherService.getWeatherData(city.name);
    } catch (e) {
      Logger.e('加载城市天气失败: ${city.name}', tag: 'WeatherDataService', error: e);
      return null;
    }
  }

  /// 刷新指定位置的天气数据
  Future<bool> refreshLocationWeather(LocationModel location) async {
    try {
      final weatherData = await loadWeatherForLocation(location);
      return weatherData != null;
    } catch (e) {
      Logger.e('刷新天气失败', tag: 'WeatherDataService', error: e);
      return false;
    }
  }

  /// 批量加载城市天气数据
  Future<Map<String, WeatherModel>> loadCitiesWeather(List<CityModel> cities) async {
    final results = <String, WeatherModel>{};

    for (final city in cities) {
      try {
        final weather = await loadCityWeather(city);
        if (weather != null) {
          results[city.name] = weather;
        }
      } catch (e) {
        Logger.e('加载城市天气失败: ${city.name}', tag: 'WeatherDataService', error: e);
      }
    }

    return results;
  }
}
