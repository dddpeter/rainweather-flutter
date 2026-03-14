/// 城市天气数据模型
/// 用于存储单个城市的完整天气数据状态
class CityWeatherData {
  /// 城市名称
  final String cityName;
  
  /// 城市ID
  final String? cityId;
  
  /// 天气数据
  final Map<String, dynamic>? weatherData;
  
  /// 缓存时间戳
  final DateTime cacheTime;
  
  /// 是否正在加载
  final bool isLoading;
  
  /// 错误信息
  final String? error;
  
  /// 是否有有效的缓存数据
  final bool hasCachedData;
  
  /// 缓存有效期（分钟）
  static const int cacheValidityMinutes = 30;

  const CityWeatherData({
    required this.cityName,
    this.cityId,
    this.weatherData,
    required this.cacheTime,
    this.isLoading = false,
    this.error,
    this.hasCachedData = false,
  });

  /// 检查缓存是否过期
  bool get isCacheExpired {
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    return difference.inMinutes > cacheValidityMinutes;
  }

  /// 检查缓存是否仍然有效
  bool get isCacheValid => !isCacheExpired && hasCachedData && weatherData != null;

  /// 复制并更新状态
  CityWeatherData copyWith({
    String? cityName,
    String? cityId,
    Map<String, dynamic>? weatherData,
    DateTime? cacheTime,
    bool? isLoading,
    String? error,
    bool? hasCachedData,
  }) {
    return CityWeatherData(
      cityName: cityName ?? this.cityName,
      cityId: cityId ?? this.cityId,
      weatherData: weatherData ?? this.weatherData,
      cacheTime: cacheTime ?? this.cacheTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasCachedData: hasCachedData ?? this.hasCachedData,
    );
  }

  /// 创建加载状态
  factory CityWeatherData.loading(String cityName, {String? cityId}) {
    return CityWeatherData(
      cityName: cityName,
      cityId: cityId,
      cacheTime: DateTime.now(),
      isLoading: true,
    );
  }

  /// 创建错误状态
  factory CityWeatherData.error(
    String cityName, {
    String? cityId,
    required String error,
  }) {
    return CityWeatherData(
      cityName: cityName,
      cityId: cityId,
      cacheTime: DateTime.now(),
      error: error,
    );
  }

  @override
  String toString() {
    return 'CityWeatherData(cityName: $cityName, cityId: $cityId, isLoading: $isLoading, error: $error, hasCachedData: $hasCachedData, cacheTime: $cacheTime)';
  }
}
