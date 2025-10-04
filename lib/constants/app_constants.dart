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

  // UI Constants - Border Radius (Material Design 3 标准)
  /// 标准圆角 - 用于卡片和容器 (8px)
  static const double borderRadius = 8.0;

  /// 小圆角 - 用于按钮和小元素 (4px)
  static const double smallBorderRadius = 4.0;

  /// 大圆角 - 用于对话框和特殊元素 (12px)
  static const double largeBorderRadius = 12.0;

  /// 超大圆角 - 用于底部表单等 (16px)
  static const double extraLargeBorderRadius = 16.0;

  // Weather Icons Mapping
  // 使用兼容性更好的 emoji 图标
  static const Map<String, String> weatherIcons = {
    // 晴天系列
    '晴': '☀️',
    '晴间多云': '🌤',

    // 多云系列
    '多云': '⛅',
    '多云转晴': '⛅',
    '晴转多云': '⛅',
    '少云': '🌤',

    // 阴天
    '阴': '☁️',

    // 雨系列
    '小雨': '🌧',
    '中雨': '🌧',
    '大雨': '🌧',
    '暴雨': '⛈',
    '大暴雨': '⛈',
    '特大暴雨': '⛈',
    '阵雨': '🌧',
    '雷阵雨': '⛈',
    '雷阵雨伴有冰雹': '⛈',
    '冻雨': '🌧',
    '毛毛雨': '🌧',

    // 雪系列
    '小雪': '❄️',
    '中雪': '❄️',
    '大雪': '❄️',
    '暴雪': '❄️',
    '阵雪': '❄️',
    '雨夹雪': '🌨',
    '雨雪天气': '🌨',

    // 雾霾系列
    '雾': '🌁',
    '浓雾': '🌁',
    '强浓雾': '🌁',
    '轻雾': '🌁',
    '霾': '🌁',
    '中度霾': '🌁',
    '重度霾': '🌁',
    '严重霾': '🌁',

    // 沙尘系列
    '浮尘': '💨',
    '扬沙': '💨',
    '沙尘暴': '💨',
    '强沙尘暴': '💨',

    // 其他特殊天气
    '冰雹': '🧊',
    '雨凇': '🧊',
    '雪': '❄️',
    '平静': '😌',
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
