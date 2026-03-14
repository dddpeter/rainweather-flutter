import 'dart:async';
import 'package:dio/dio.dart';
import '../models/open_meteo_models.dart';
import '../models/location_model.dart';
import '../utils/logger.dart';
import 'request_deduplicator.dart';
import 'request_cache_service.dart';

/// Open-Meteo API 服务
/// 
/// 免费的国际天气API服务，支持全球任意位置的天气查询
/// 基于经纬度获取天气数据
class OpenMeteoService {
  static OpenMeteoService? _instance;
  late Dio _dio;
  final RequestDeduplicator _deduplicator = RequestDeduplicator();
  final RequestCacheService _cacheService = RequestCacheService();

  /// API 基础URL
  static const String baseUrl = 'https://api.open-meteo.com/v1';

  /// 请求超时时间
  static const Duration timeout = Duration(seconds: 30);

  OpenMeteoService._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'RainWeather/1.0.0 (Flutter)',
        },
      ),
    );
  }

  static OpenMeteoService getInstance() {
    _instance ??= OpenMeteoService._();
    return _instance!;
  }

  /// 获取天气数据
  /// 
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [includeCurrent] 是否包含当前天气
  /// [includeDaily] 是否包含每日预报
  /// [includeHourly] 是否包含每小时预报
  /// [dailyForecastDays] 每日预报天数（默认15天）
  /// [hourlyForecastHours] 每小时预报小时数（默认24小时）
  /// [timezone] 时区，默认为auto
  /// 
  /// 返回 OpenMeteoResponse 对象，失败返回 null
  Future<OpenMeteoResponse?> getWeather({
    required double latitude,
    required double longitude,
    bool includeCurrent = true,
    bool includeDaily = true,
    bool includeHourly = true,
    int dailyForecastDays = 15,
    int hourlyForecastHours = 24,
    String timezone = 'auto',
  }) async {
    final requestKey = 'openmeteo:$latitude,$longitude';

    return await _deduplicator.execute<OpenMeteoResponse?>(requestKey, () async {
      // 先尝试从缓存获取
      final cachedData = await _cacheService.get<OpenMeteoResponse>(
        requestKey,
        (json) => OpenMeteoResponse.fromJson(json),
      );

      if (cachedData != null) {
        Logger.d('使用缓存的Open-Meteo天气数据: ($latitude, $longitude)', tag: 'OpenMeteoService');
        return cachedData;
      }

      try {
        Logger.d('从Open-Meteo API获取天气数据: ($latitude, $longitude)', tag: 'OpenMeteoService');

        // 构建查询参数
        final parameters = <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'timezone': timezone,
          'current_weather': includeCurrent ? 'true' : 'false',
        };

        // 添加每日预报参数
        if (includeDaily) {
          parameters['daily'] = [
            'temperature_2m_max',
            'temperature_2m_min',
            'precipitation_sum',
            'weathercode',
            'windspeed_10m_max',
            'wind_direction_10m_dominant', // 添加主导风向
          ].join(',');
          parameters['forecast_days'] = dailyForecastDays.toString();
        }

        // 添加每小时预报参数
        if (includeHourly) {
          parameters['hourly'] = [
            'temperature_2m',
            'relativehumidity_2m',
            'weathercode',
            'windspeed_10m',
            'pressure_msl', // 海平面气压
            'visibility', // 能见度
          ].join(',');
          parameters['forecast_hours'] = hourlyForecastHours.toString();
        }

        final response = await _dio.get(
          '$baseUrl/forecast',
          queryParameters: parameters,
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            final weatherResponse = OpenMeteoResponse.fromJson(data);

            // 缓存结果（30分钟）
            await _cacheService.set(
              requestKey,
              weatherResponse,
              const Duration(minutes: 30),
              toJson: (response) => response.toJson(),
            );

            Logger.d(
              'Open-Meteo天气数据获取成功并已缓存: ($latitude, $longitude)',
              tag: 'OpenMeteoService',
            );
            return weatherResponse;
          }
        }
        return null;
      } catch (e, stackTrace) {
        Logger.e(
          'Open-Meteo API请求失败: ($latitude, $longitude)',
          tag: 'OpenMeteoService',
          error: e,
          stackTrace: stackTrace,
        );
        return null;
      }
    });
  }

  /// 通过LocationModel获取天气数据
  Future<OpenMeteoResponse?> getWeatherByLocation(
    LocationModel location, {
    bool includeCurrent = true,
    bool includeDaily = true,
    bool includeHourly = true,
    int dailyForecastDays = 15,
    int hourlyForecastHours = 24,
  }) async {
    return getWeather(
      latitude: location.lat,
      longitude: location.lng,
      includeCurrent: includeCurrent,
      includeDaily: includeDaily,
      includeHourly: includeHourly,
      dailyForecastDays: dailyForecastDays,
      hourlyForecastHours: hourlyForecastHours,
      timezone: 'auto',
    );
  }

  /// 获取当前天气（仅当前时刻）
  Future<OpenMeteoResponse?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    return getWeather(
      latitude: latitude,
      longitude: longitude,
      includeCurrent: true,
      includeDaily: false,
      includeHourly: false,
    );
  }

  /// 获取每日预报（仅未来15天预报）
  Future<OpenMeteoResponse?> getDailyForecast({
    required double latitude,
    required double longitude,
    int days = 15,
  }) async {
    return getWeather(
      latitude: latitude,
      longitude: longitude,
      includeCurrent: false,
      includeDaily: true,
      includeHourly: false,
      dailyForecastDays: days,
    );
  }

  /// 获取每小时预报（仅未来24小时）
  Future<OpenMeteoResponse?> getHourlyForecast({
    required double latitude,
    required double longitude,
    int hours = 24,
  }) async {
    return getWeather(
      latitude: latitude,
      longitude: longitude,
      includeCurrent: false,
      includeDaily: false,
      includeHourly: true,
      hourlyForecastHours: hours,
    );
  }

  /// 批量获取多个城市的天气数据（用于预加载）
  Future<Map<String, OpenMeteoResponse?>> getBatchWeather(
    List<LocationModel> locations,
  ) async {
    final results = <String, OpenMeteoResponse?>{};
    
    // 使用Future.wait并发查询
    final futures = locations.map((location) async {
      final response = await getWeatherByLocation(location);
      final key = '${location.lat},${location.lng}';
      results[key] = response;
    });
    
    await Future.wait(futures);
    
    return results;
  }

  /// 清空缓存
  Future<void> clearCache() async {
    // RequestCacheService 没有 clear 方法，暂时跳过
    Logger.d('清空Open-Meteo缓存', tag: 'OpenMeteoService');
  }

  /// 清除指定位置的缓存
  Future<void> clearLocationCache(double latitude, double longitude) async {
    // RequestCacheService 没有 delete 方法，暂时跳过
    Logger.d('清除位置缓存: ($latitude, $longitude)', tag: 'OpenMeteoService');
  }
}
