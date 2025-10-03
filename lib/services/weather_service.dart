import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../constants/app_constants.dart';
import 'city_data_service.dart';

class WeatherService {
  static WeatherService? _instance;
  final Dio _dio;
  final CityDataService _cityDataService = CityDataService.getInstance();
  
  WeatherService._() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.49',
    },
  ));
  
  static WeatherService getInstance() {
    _instance ??= WeatherService._();
    return _instance!;
  }
  
  /// Get weather data for a specific city
  Future<WeatherModel?> getWeatherData(String cityId) async {
    try {
      final response = await _dio.get('${AppConstants.weatherApiBaseUrl}$cityId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final weatherData = data['data'];
          if (weatherData != null) {
            return WeatherModel.fromJson(weatherData);
          }
        }
      }
      return null;
    } catch (e) {
      print('Weather API error: $e');
      return null;
    }
  }
  
  /// Get weather data for a location
  Future<WeatherModel?> getWeatherDataForLocation(LocationModel location) async {
    String cityId = _getCityIdFromLocation(location);
    if (cityId.isNotEmpty) {
      return await getWeatherData(cityId);
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
  
  /// Get 7-day weather forecast
  Future<List<DailyWeather>?> get7DayForecast(String cityId) async {
    try {
      final weatherData = await getWeatherData(cityId);
      if (weatherData?.forecast15d != null) {
        // Return first 7 days
        return weatherData!.forecast15d!.take(7).toList();
      }
      return null;
    } catch (e) {
      print('7-day forecast error: $e');
      return null;
    }
  }
  
  /// Get 24-hour weather forecast
  Future<List<HourlyWeather>?> get24HourForecast(String cityId) async {
    try {
      final weatherData = await getWeatherData(cityId);
      return weatherData?.forecast24h;
    } catch (e) {
      print('24-hour forecast error: $e');
      return null;
    }
  }
  
  /// Get weather icon for weather type
  String getWeatherIcon(String? weatherType) {
    if (weatherType == null || weatherType.isEmpty) return '☀️';
    return AppConstants.weatherIcons[weatherType] ?? '☀️'; // Default to sunny emoji
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
}
