import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../constants/app_constants.dart';
import 'city_data_service.dart';

class Forecast15dService {
  static Forecast15dService? _instance;
  final Dio _dio;
  final CityDataService _cityDataService = CityDataService.getInstance();
  
  Forecast15dService._() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.49',
    },
  ));
  
  static Forecast15dService getInstance() {
    _instance ??= Forecast15dService._();
    return _instance!;
  }
  
  /// Get 15-day weather forecast data
  Future<WeatherModel?> get15DayForecast(String cityId) async {
    try {
      final response = await _dio.get('https://www.weatherol.cn/api/home/getCurrAnd15dAnd24h?cityid=$cityId');
      
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
      print('15-day forecast API error: $e');
      return null;
    }
  }
  
  /// Get 15-day weather forecast for a location
  Future<WeatherModel?> get15DayForecastForLocation(LocationModel location) async {
    String cityId = _getCityIdFromLocation(location);
    if (cityId.isNotEmpty) {
      return await get15DayForecast(cityId);
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
}
