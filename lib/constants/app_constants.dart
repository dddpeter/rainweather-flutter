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

  // Main Cities (国内城市 + 国际城市)
  static const List<String> mainCities = [
    '北京', 
    '上海',
    // 国际城市
    '东京',
    '首尔',
    '新加坡',
    '伦敦',
    '纽约',
  ];

  // Default Location
  static const String defaultCity = '北京';
  static const String defaultCityId = '101010100';

  // UI Constants - Section Title Styles
  static const double sectionTitleFontSize = 16.0;
  static const double sectionTitleIconSize = 20.0;

  // UI Constants - Spacing (Material Design 3)
  /// 屏幕边距 - 符合Material Design 3推荐标准（12dp更符合MD3紧凑布局）
  static const double screenHorizontalPadding = 12.0;

  /// 大卡片之间的最小间距（12dp符合M3最小推荐值）
  static const double cardSpacing = 12.0;

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
    '多云': '☁️',
    '多云转晴': '⛅',
    '晴转多云': '⛅',
    '少云': '🌤',

    // 阴天
    '阴': '☁️',
    '阴天': '☁️',

    // 雨系列
    '小雨': '🌧',
    '中雨': '🌧',
    '大雨': '🌧',
    '暴雨': '⛈️',
    '大暴雨': '⛈️',
    '特大暴雨': '⛈',
    '阵雨': '🌧',
    '强阵雨': '⛈️',
    '雷阵雨': '⚡️',
    '强雷阵雨': '⚡️',
    '雷雨': '⚡️',
    '雷阵雨伴有冰雹': '⚡️',
    '冻雨': '🌧',
    '毛毛雨': '🌧',

    // 雪系列
    '小雪': '❄️',
    '中雪': '❄️',
    '大雪': '❄️',
    '暴雪': '❄️',
    '阵雪': '❄️',
    '吹雪': '❄️',
    '雨夹雪': '🌨',
    '雨雪天气': '🌨',
    '晴转小雨夹雪': '🌨',
    '雪转晴': '❄️',
    '雪': '❄️',

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
    '平静': '😌',
    '高温': '🌡️',
    '低温': '🌡️',
    '不清楚': '❓',
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

  // Chinese Weather Images Mapping (Day) - 基于中文PNG图标
  static const Map<String, String> chineseWeatherImages = {
    // 晴天系列
    '晴': '晴.png',
    '晴间多云': '晴间多云.png',
    '少云': '晴间多云.png', // 使用晴间多云代替
    // 多云系列
    '多云': '多云.png',
    '多云转晴': '多云转晴.png',
    '晴转多云': '多云转晴.png', // 复用多云转晴
    // 阴天
    '阴': '阴天.png',
    '阴天': '阴天.png',

    // 雨系列
    '小雨': '小雨.png',
    '中雨': '中雨.png',
    '大雨': '大雨.png',
    '暴雨': '暴雨.png',
    '大暴雨': '大暴雨.png',
    '特大暴雨': '特大暴雨.png',
    '阵雨': '阵雨.png',
    '强阵雨': '强阵雨.png',
    '雷阵雨': '雷阵雨.png',
    '强雷阵雨': '强雷阵雨.png',
    '雷雨': '雷雨.png',
    '雷阵雨伴有冰雹': '雷阵雨.png', // 使用雷阵雨代替
    '冻雨': '冻雨.png',
    '毛毛雨': '毛毛雨.png',

    // 雪系列
    '小雪': '小雪.png',
    '中雪': '中雪.png',
    '大雪': '大雪.png',
    '暴雪': '暴雪.png',
    '大暴雪': '大暴雪.png',
    '阵雪': '小雪.png', // 使用小雪代替
    '吹雪': '吹雪.png',
    '雨夹雪': '雨夹雪.png',
    '雨雪天气': '雨夹雪.png', // 使用雨夹雪代替
    '晴转小雨夹雪': '晴转小雨夹雪.png',
    '雪转晴': '雪转晴.png',
    '雪': '雪.png',

    // 雾霾系列
    '雾': '雾.png',
    '浓雾': '浓雾.png',
    '强浓雾': '强浓雾.png',
    '轻雾': '轻雾.png',
    '霾': '霾.png',
    '中度霾': '中度霾.png',
    '重度霾': '重度霾.png',
    '严重霾': '严重霾.png',

    // 沙尘系列
    '浮尘': '浮尘.png',
    '扬沙': '浮尘.png', // 使用浮尘代替
    '沙尘暴': '沙尘暴.png',
    '强沙尘暴': '强沙尘暴.png',

    // 其他特殊天气
    '冰雹': '冰雹.png',
    '雨凇': '雨凇.png',
    '平静': '晴.png', // 使用晴天代替
    '高温': '高温.png',
    '低温': '低温.png',
    '不清楚': '不清楚.png',
  };

  // Chinese Weather Images Mapping (Night) - 基于中文PNG图标
  // 夜间图标较少，没有的使用日间图标
  static const Map<String, String> chineseNightWeatherImages = {
    // 晴天系列 (有夜间版本)
    '晴': 'night/晴.png',
    '晴间多云': 'night/晴间多云.png',
    '少云': 'night/少云.png',

    // 多云系列 (有夜间版本)
    '多云': 'night/多云.png',
    '多云转晴': 'night/多云转晴.png',
    '晴转多云': 'night/晴转多云.png',

    // 阴天 (有夜间版本)
    '阴': 'night/阴天.png',
    '阴天': 'night/阴天.png',

    // 雨系列 (使用日间图标)
    '小雨': '小雨.png',
    '中雨': '中雨.png',
    '大雨': '大雨.png',
    '暴雨': '暴雨.png',
    '大暴雨': '大暴雨.png',
    '特大暴雨': '特大暴雨.png',
    '阵雨': '阵雨.png',
    '强阵雨': '强阵雨.png',
    '雷阵雨': '雷阵雨.png',
    '强雷阵雨': '强雷阵雨.png',
    '雷雨': '雷雨.png',
    '雷阵雨伴有冰雹': '雷阵雨.png',
    '冻雨': '冻雨.png',
    '毛毛雨': '毛毛雨.png',

    // 雪系列 (部分有夜间版本)
    '小雪': '小雪.png',
    '中雪': '中雪.png',
    '大雪': '大雪.png',
    '暴雪': '暴雪.png',
    '大暴雪': '大暴雪.png',
    '阵雪': '小雪.png',
    '吹雪': '吹雪.png',
    '雨夹雪': 'night/雨夹雪.png',
    '雨雪天气': 'night/雨夹雪.png',
    '晴转小雨夹雪': '晴转小雨夹雪.png',
    '雪转晴': 'night/雪转晴.png',
    '雪': '雪.png',

    // 雾霾系列 (使用日间图标)
    '雾': '雾.png',
    '浓雾': '浓雾.png',
    '强浓雾': '强浓雾.png',
    '轻雾': '轻雾.png',
    '霾': '霾.png',
    '中度霾': '中度霾.png',
    '重度霾': '重度霾.png',
    '严重霾': '严重霾.png',

    // 沙尘系列 (使用日间图标)
    '浮尘': '浮尘.png',
    '扬沙': '浮尘.png',
    '沙尘暴': '沙尘暴.png',
    '强沙尘暴': '强沙尘暴.png',

    // 其他特殊天气 (使用日间图标)
    '冰雹': '冰雹.png',
    '雨凇': '雨凇.png',
    '平静': 'night/晴.png',
    '高温': '高温.png',
    '低温': '低温.png',
    '不清楚': '不清楚.png',
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

  // ==================== 时间常量 ====================

  /// 后台更新间隔 (5分钟)
  static const Duration backgroundUpdateInterval = Duration(minutes: 5);

  /// 缓存过期时间 (15分钟)
  static const Duration cacheExpiration = Duration(minutes: 15);

  /// 缓存过期阈值 (1小时) - 超过此时间显示加载动画
  static const Duration cacheStaleThreshold = Duration(hours: 1);

  /// 日出月相索引缓存过期时间 (6小时)
  static const Duration sunMoonIndexCacheExpiration = Duration(hours: 6);

  /// 天气数据刷新间隔 (30分钟)
  static const Duration refreshInterval = Duration(minutes: 30);

  /// 后台超时时间 (30分钟)
  static const Duration backgroundTimeout = Duration(minutes: 30);

  /// 定位超时时间 (45秒) - 首次定位需要更长时间
  static const Duration locationTimeout = Duration(seconds: 45);

  /// 快速定位超时时间 (15秒)
  static const Duration quickLocationTimeout = Duration(seconds: 15);

  /// 网络请求超时时间 (30秒)
  static const Duration networkTimeout = Duration(seconds: 30);

  /// AI 摘要缓存时间 (5分钟)
  static const Duration aiSummaryCacheExpiration = Duration(minutes: 5);

  /// 15日预报缓存时间 (5分钟)
  static const Duration forecast15dCacheExpiration = Duration(minutes: 5);

  /// 黄历缓存时间 (10天)
  static const Duration lunarCalendarCacheExpiration = Duration(days: 10);

  /// 动画持续时间 (300ms)
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// 主题切换动画时间 (300ms)
  static const Duration themeSwitchAnimationDuration = Duration(milliseconds: 300);

  /// 打字机效果每字符延迟 (30ms)
  static const Duration typewriterCharDelay = Duration(milliseconds: 30);

  /// 页面切换动画时间
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  // ==================== 数值常量 ====================

  /// 默认定位精度阈值 (米)
  static const double defaultLocationAccuracy = 100.0;

  /// 最佳定位精度阈值 (米)
  static const double bestLocationAccuracy = 5.0;

  /// 温度图表 Y 轴保留数据点数量
  static const int chartYAxisReservedSize = 40;

  /// 24小时预报显示数量
  static const int hourlyForecastDisplayCount = 24;

  /// 7日预报显示数量
  static const int daily7ForecastDisplayCount = 7;

  /// 15日预报显示数量
  static const int daily15ForecastDisplayCount = 15;

  /// 生活指数显示数量
  static const int lifeIndexDisplayCount = 8;
}
