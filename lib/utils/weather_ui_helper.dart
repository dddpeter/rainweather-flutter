import '../constants/app_constants.dart';
import '../models/location_model.dart';
import '../services/weather_service.dart';

/// WeatherUIHelper - 天气相关 UI 工具类
///
/// 提供 UI 层需要的辅助方法：
/// - 天气图标/图片获取
/// - 空气质量等级
/// - 昼夜判断
/// - 默认位置
class WeatherUIHelper {
  final WeatherService weatherService;

  WeatherUIHelper({required this.weatherService});

  // 私有访问器
  WeatherService get _weatherService => weatherService;

  /// 获取默认位置（北京）
  LocationModel getDefaultLocation() {
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

  /// 获取天气图标
  String getWeatherIcon(String weatherType) {
    return _weatherService.getWeatherIcon(weatherType);
  }

  /// 获取天气图片
  String getWeatherImage(String weatherType) {
    bool isDay = _weatherService.isDayTime();
    return _weatherService.getWeatherImage(weatherType, isDay);
  }

  /// 获取空气质量等级
  String getAirQualityLevel(int aqi) {
    return _weatherService.getAirQualityLevel(aqi);
  }

  /// 判断是否是白天
  bool isDayTime() {
    return _weatherService.isDayTime();
  }
}
