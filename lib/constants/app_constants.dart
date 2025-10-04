class AppConstants {
  // API Endpoints
  static const String weatherApiBaseUrl =
      'https://www.weatherol.cn/api/home/getCurrAnd15dAnd24h?cityid=';
  static const String historyApiUrl =
      'https://www.ipip5.com/today/api.php?type=json';

  // Cache Keys
  static const String currentLocationKey = 'CURRENT_LOCATION';
  static const String weatherAllKey = 'WEATHER_ALL';
  static const String weather7dKey = 'WEATHER_7D';
  static const String weather15dKey = 'WEATHER_15D';
  static const String hourlyForecastKey = 'HOURLY_FORECAST';
  static const String dailyForecastKey = 'DAILY_FORECAST';
  static const String sunMoonIndexKey = 'SUN_MOON_INDEX';
  static const String historyKey = 'HISTORY';

  // Broadcast Actions
  static const String refreshAction = 'refresh_data';
  static const String refresh7dAction = 'refresh_7d_data';
  static const String refreshCityAction = 'refresh_city';

  // Main Cities
  static const List<String> mainCities = ['北京', '上海'];

  // Default Location
  static const String defaultCity = '北京';
  static const String defaultCityId = '101010100';

  // UI Constants - Section Title Styles
  static const double sectionTitleFontSize = 16.0;
  static const double sectionTitleIconSize = 20.0;

  // UI Constants - Spacing (Material Design 3)
  /// 大卡片之间的标准间距（20px符合M3规范，视觉舒适）
  static const double cardSpacing = 20.0;

  /// 卡片内部元素之间的间距
  static const double cardInnerSpacing = 16.0;

  /// 小元素之间的间距
  static const double smallSpacing = 8.0;

  // Weather Icons Mapping
  static const Map<String, String> weatherIcons = {
    '大雨': '🌧️',
    '暴雨': '⛈️',
    '冻雨': '🌨️',
    '大雪': '❄️',
    '暴雪': '🌨️',
    '多云': '⛅',
    '雷阵雨': '⛈️',
    '沙尘暴': '🌪️',
    '多云转晴': '⛅',
    '晴转多云': '⛅',
    '雾': '🌫️',
    '小雪': '🌨️',
    '小雨': '🌦️',
    '阴': '☁️',
    '晴': '☀️',
    '雨夹雪': '🌨️',
    '中雨': '🌧️',
    '中雪': '❄️',
    '阵雨': '🌦️',
    '霾': '🌫️',
    '扬沙': '🌪️',
    '浮尘': '🌫️',
  };

  // Weather Images Mapping (Day)
  static const Map<String, String> dayWeatherImages = {
    '大雨': 'dby.png',
    '暴雨': 'dby.png',
    '冻雨': 'dy.png',
    '大雪': 'dx.png',
    '暴雪': 'bx.png',
    '多云': 'dy.png',
    '多云转晴': 'dyq.png',
    '晴转多云': 'dyq.png',
    '雷阵雨': 'lzy.png',
    '沙尘暴': 'scb.png',
    '雾': 'w.png',
    '小雪': 'xx.png',
    '小雨': 'xy.png',
    '阴': 'y.png',
    '晴': 'q.png',
    '雨夹雪': 'yjx.png',
    '中雨': 'zhy.png',
    '中雪': 'zx.png',
    '阵雨': 'zy.png',
    '霾': 'scb.png',
    '扬沙': 'scb.png',
    '浮尘': 'scb.png',
  };

  // Weather Images Mapping (Night)
  static const Map<String, String> nightWeatherImages = {
    '大雨': 'dby.png',
    '暴雨': 'dby.png',
    '冻雨': 'dy0.png',
    '大雪': 'dx0.png',
    '暴雪': 'bx.png',
    '多云': 'dy0.png',
    '雷阵雨': 'lzy0.png',
    '沙尘暴': 'scb.png',
    '多云转晴': 'dyq0.png',
    '晴转多云': 'dyq0.png',
    '雾': 'w.png',
    '小雪': 'xx.png',
    '小雨': 'xy.png',
    '阴': 'y.png',
    '晴': 'q0.png',
    '雨夹雪': 'yjx.png',
    '中雨': 'zhy.png',
    '中雪': 'zx.png',
    '阵雨': 'zy0.png',
    '霾': 'scb.png',
    '扬沙': 'scb.png',
    '浮尘': 'scb.png',
  };

  // Air Quality Levels
  static const Map<int, String> airQualityLevels = {
    50: '优',
    100: '良',
    150: '轻度污染',
    200: '中度污染',
    300: '重度污染',
    500: '严重污染',
  };

  // Background Update Interval (5 minutes)
  static const Duration backgroundUpdateInterval = Duration(minutes: 5);

  // Cache Expiration (15 minutes)
  static const Duration cacheExpiration = Duration(minutes: 15);

  // Sun/Moon Index Cache Expiration (6 hours)
  static const Duration sunMoonIndexCacheExpiration = Duration(hours: 6);
}
