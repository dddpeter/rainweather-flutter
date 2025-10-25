import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import 'city_data_service.dart';
import 'request_deduplicator.dart';
import 'request_cache_service.dart';
import 'network_config_service.dart';

class WeatherService {
  static WeatherService? _instance;
  final CityDataService _cityDataService = CityDataService.getInstance();
  final RequestDeduplicator _deduplicator = RequestDeduplicator();
  final RequestCacheService _cacheService = RequestCacheService();
  final NetworkConfigService _networkConfig = NetworkConfigService();

  WeatherService._();

  static WeatherService getInstance() {
    _instance ??= WeatherService._();
    return _instance!;
  }

  /// Get weather data for a specific city with deduplication and caching
  Future<WeatherModel?> getWeatherData(String cityId) async {
    final requestKey = RequestKeyGenerator.weatherRequest(cityId);

    return await _deduplicator.execute<WeatherModel?>(requestKey, () async {
      // 先尝试从缓存获取
      final cachedData = await _cacheService.get<WeatherModel>(
        requestKey,
        (json) => WeatherModel.fromJson(json),
      );

      if (cachedData != null) {
        Logger.d('使用缓存数据 - $cityId', tag: 'WeatherService');
        return cachedData;
      }

      // 缓存未命中，发起网络请求
      Logger.d('发起网络请求 - $cityId', tag: 'WeatherService');

      try {
        // 根据网络质量调整配置
        final networkQuality = await _networkConfig.getNetworkQuality();
        final baseConfig = _networkConfig.getConfig(RequestType.weather);
        final adjustedConfig = _networkConfig.adjustConfigForNetworkQuality(
          baseConfig,
          networkQuality,
        );

        // 创建带超时配置的 Dio 实例
        final dio = Dio(
          BaseOptions(
            connectTimeout: adjustedConfig.connectTimeout,
            receiveTimeout: adjustedConfig.receiveTimeout,
            sendTimeout: adjustedConfig.sendTimeout,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'RainWeather/1.0.0 (Flutter)',
            },
          ),
        );

        final response = await dio.get(
          '${AppConstants.weatherApiBaseUrl}$cityId',
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            final weatherData = data['data'];
            if (weatherData != null) {
              final weatherModel = WeatherModel.fromJson(weatherData);

              // 缓存结果
              await _cacheService.set(
                requestKey,
                weatherModel,
                CacheConfig.weatherData,
                toJson: (model) => model.toJson(),
              );

              Logger.d('天气数据获取成功并已缓存 - $cityId', tag: 'WeatherService');
              return weatherModel;
            }
          }
        }
        return null;
      } catch (e, stackTrace) {
        Logger.e(
          'Weather API error',
          tag: 'WeatherService',
          error: e,
          stackTrace: stackTrace,
        );
        ErrorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'WeatherService.GetWeatherData',
          type: AppErrorType.network,
        );
        return null;
      }
    });
  }

  /// Get weather data for a location
  Future<WeatherModel?> getWeatherDataForLocation(
    LocationModel location,
  ) async {
    String cityId = _getCityIdFromLocation(location);
    Logger.d(
      '获取天气数据 - 位置: ${location.district}, 城市ID: $cityId',
      tag: 'WeatherService',
    );

    if (cityId.isNotEmpty) {
      final result = await getWeatherData(cityId);
      if (result == null) {
        Logger.e('获取城市ID的天气数据失败: $cityId', tag: 'WeatherService');
      }
      return result;
    } else {
      Logger.w('无法找到位置对应的城市ID: ${location.district}', tag: 'WeatherService');
    }
    return null;
  }

  /// Get city ID from location
  String _getCityIdFromLocation(LocationModel location) {
    // Ensure city data is loaded
    _cityDataService.loadCityData();

    // Try to find city ID by district first
    String? cityId = _cityDataService.findCityIdByName(location.district);

    // If not found, try by city
    if (cityId == null && location.city.isNotEmpty) {
      cityId = _cityDataService.findCityIdByName(location.city);
    }

    // If still not found, try by province
    if (cityId == null && location.province.isNotEmpty) {
      cityId = _cityDataService.findCityIdByName(location.province);
    }

    // Return found city ID or default
    return cityId ?? AppConstants.defaultCityId;
  }

  /// Get 7-day weather forecast with caching
  Future<List<DailyWeather>?> get7DayForecast(String cityId) async {
    final requestKey = RequestKeyGenerator.weatherRequest(cityId, type: '7day');

    return await _deduplicator.execute<List<DailyWeather>?>(
      requestKey,
      () async {
        // 先尝试从缓存获取
        final cachedData = await _cacheService.get<List<DailyWeather>>(
          requestKey,
          (json) => (json['forecast'] as List)
              .map((item) => DailyWeather.fromJson(item))
              .toList(),
        );

        if (cachedData != null) {
          Logger.d('使用7日预报缓存数据 - $cityId', tag: 'WeatherService');
          return cachedData;
        }

        try {
          final weatherData = await getWeatherData(cityId);
          if (weatherData?.forecast15d != null) {
            // Return first 7 days
            final forecast7d = weatherData!.forecast15d!.take(7).toList();

            // 缓存7日预报数据
            await _cacheService.set(
              requestKey,
              forecast7d,
              CacheConfig.weatherData,
              toJson: (forecast) => {
                'forecast': forecast.map((item) => item.toJson()).toList(),
              },
            );

            Logger.d('7日预报数据获取成功并已缓存 - $cityId', tag: 'WeatherService');
            return forecast7d;
          }
          return null;
        } catch (e, stackTrace) {
          Logger.e(
            '7日天气预报错误',
            tag: 'WeatherService',
            error: e,
            stackTrace: stackTrace,
          );
          ErrorHandler.handleError(
            e,
            stackTrace: stackTrace,
            context: 'WeatherService.Get7DayForecast',
            type: AppErrorType.network,
          );
          return null;
        }
      },
    );
  }

  /// Get 24-hour weather forecast with caching
  Future<List<HourlyWeather>?> get24HourForecast(String cityId) async {
    final requestKey = RequestKeyGenerator.weatherRequest(
      cityId,
      type: '24hour',
    );

    return await _deduplicator.execute<List<HourlyWeather>?>(
      requestKey,
      () async {
        // 先尝试从缓存获取
        final cachedData = await _cacheService.get<List<HourlyWeather>>(
          requestKey,
          (json) => (json['forecast'] as List)
              .map((item) => HourlyWeather.fromJson(item))
              .toList(),
        );

        if (cachedData != null) {
          Logger.d('使用24小时预报缓存数据 - $cityId', tag: 'WeatherService');
          return cachedData;
        }

        try {
          final weatherData = await getWeatherData(cityId);
          final forecast24h = weatherData?.forecast24h;

          if (forecast24h != null) {
            // 缓存24小时预报数据
            await _cacheService.set(
              requestKey,
              forecast24h,
              CacheConfig.weatherData,
              toJson: (forecast) => {
                'forecast': forecast.map((item) => item.toJson()).toList(),
              },
            );

            Logger.d('24小时预报数据获取成功并已缓存 - $cityId', tag: 'WeatherService');
          }

          return forecast24h;
        } catch (e, stackTrace) {
          Logger.e(
            '24小时天气预报错误',
            tag: 'WeatherService',
            error: e,
            stackTrace: stackTrace,
          );
          ErrorHandler.handleError(
            e,
            stackTrace: stackTrace,
            context: 'WeatherService.Get24HourForecast',
            type: AppErrorType.network,
          );
          return null;
        }
      },
    );
  }

  /// Get weather icon for weather type
  String getWeatherIcon(String? weatherType) {
    if (weatherType == null || weatherType.isEmpty) return '☀️';
    return AppConstants.weatherIcons[weatherType] ??
        '☀️'; // Default to sunny emoji
  }

  /// Get weather image for weather type (day/night)
  String getWeatherImage(String? weatherType, bool isDay) {
    if (weatherType == null || weatherType.isEmpty) {
      return isDay ? 'q.png' : 'q0.png';
    }
    if (isDay) {
      return AppConstants.dayWeatherImages[weatherType] ?? 'q.png';
    } else {
      return AppConstants.nightWeatherImages[weatherType] ?? 'q0.png';
    }
  }

  /// Get air quality level
  String getAirQualityLevel(int? aqi) {
    if (aqi == null) return '未知';
    if (aqi <= 50) return '优';
    if (aqi <= 100) return '良';
    if (aqi <= 150) return '轻度污染';
    if (aqi <= 200) return '中度污染';
    if (aqi <= 300) return '重度污染';
    return '严重污染';
  }

  /// Check if it's day time
  bool isDayTime() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 6 && hour <= 18;
  }

  /// 清理天气数据缓存
  Future<void> clearWeatherCache() async {
    await _cacheService.clearAll();
    Logger.d('天气数据缓存已清理', tag: 'WeatherService');
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  /// 取消所有正在进行的请求
  void cancelAllRequests() {
    _deduplicator.cancelAll();
    Logger.d('所有天气请求已取消', tag: 'WeatherService');
  }

  /// 获取正在进行的请求数量
  int get pendingRequestCount => _deduplicator.pendingRequestCount;
}
