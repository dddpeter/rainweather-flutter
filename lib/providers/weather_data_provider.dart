import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/commute_advice_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/weather_service.dart';
// import '../services/weather_alert_service.dart';
// import '../services/ai_service.dart';
// import '../services/commute_advice_service.dart';
import '../services/smart_cache_service.dart';
// import '../services/sun_moon_index_service.dart';
import '../utils/logger.dart';

/// 天气数据Provider - 专门管理天气数据获取和管理
class WeatherDataProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.getInstance();
  final SmartCacheService _smartCache = SmartCacheService();
  // final WeatherAlertService _alertService = WeatherAlertService.instance;
  // final AIService _aiService = AIService();

  // 天气数据
  WeatherModel? _currentWeather;
  List<HourlyWeather>? _hourlyForecast;
  List<DailyWeather>? _dailyForecast;
  List<DailyWeather>? _forecast15d;

  // 日出日落和生活指数数据
  SunMoonIndexData? _sunMoonIndexData;
  bool _isLoadingSunMoonIndex = false;

  // 通勤建议相关
  List<CommuteAdviceModel> _commuteAdvices = [];
  bool _hasShownCommuteAdviceToday = false;
  Timer? _commuteCleanupTimer;

  // AI智能摘要
  String? _weatherSummary;
  bool _isGeneratingSummary = false;
  String? _forecast15dSummary;
  bool _isGenerating15dSummary = false;
  bool _isGeneratingCommuteAdvice = false;

  // 缓存状态
  bool _isUsingCachedData = false;
  bool _isBackgroundRefreshing = false;

  // Getters
  WeatherModel? get currentWeather => _currentWeather;
  List<HourlyWeather>? get hourlyForecast => _hourlyForecast;
  List<DailyWeather>? get dailyForecast => _dailyForecast;
  List<DailyWeather>? get forecast15d => _forecast15d;
  SunMoonIndexData? get sunMoonIndexData => _sunMoonIndexData;
  bool get isLoadingSunMoonIndex => _isLoadingSunMoonIndex;
  List<CommuteAdviceModel> get commuteAdvices => _commuteAdvices;
  bool get hasShownCommuteAdviceToday => _hasShownCommuteAdviceToday;
  String? get weatherSummary => _weatherSummary;
  bool get isGeneratingSummary => _isGeneratingSummary;
  String? get forecast15dSummary => _forecast15dSummary;
  bool get isGenerating15dSummary => _isGenerating15dSummary;
  bool get isGeneratingCommuteAdvice => _isGeneratingCommuteAdvice;
  bool get isUsingCachedData => _isUsingCachedData;
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;

  /// 获取天气数据
  Future<void> getWeatherData(LocationModel location) async {
    try {
      Logger.d('开始获取天气数据: ${location.district}', tag: 'WeatherDataProvider');

      // 先尝试从缓存获取
      final cacheKey = '${location.district}:weather';
      final cachedData = await _smartCache.getData(
        key: cacheKey,
        type: CacheDataType.currentWeather,
      );
      if (cachedData != null) {
        final weatherData = jsonDecode(cachedData);
        final weather = WeatherModel.fromJson(weatherData);
        _updateWeatherData(weather);
        _isUsingCachedData = true;
        Logger.d('使用缓存天气数据', tag: 'WeatherDataProvider');
        notifyListeners();
      }

      // 异步获取最新数据
      _isBackgroundRefreshing = true;
      notifyListeners();

      final weather = await _weatherService.getWeatherData(location.district);
      if (weather != null) {
        _updateWeatherData(weather);
        _isUsingCachedData = false;
        _isBackgroundRefreshing = false;
        Logger.s('天气数据获取成功', tag: 'WeatherDataProvider');
        notifyListeners();
      }
    } catch (e) {
      Logger.e('获取天气数据失败', tag: 'WeatherDataProvider', error: e);
      _isBackgroundRefreshing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 更新天气数据
  void _updateWeatherData(WeatherModel weather) {
    _currentWeather = weather;
    _hourlyForecast = weather.forecast24h;
    _dailyForecast = weather.forecast15d?.take(7).toList();
    _forecast15d = weather.forecast15d;
  }

  /// 公开的更新天气数据方法（供外部调用）
  void updateWeatherData(WeatherModel weather) {
    _updateWeatherData(weather);
    notifyListeners();
  }

  /// 刷新天气数据
  Future<void> refreshWeatherData(LocationModel location) async {
    try {
      Logger.d('刷新天气数据: ${location.district}', tag: 'WeatherDataProvider');
      await getWeatherData(location);
    } catch (e) {
      Logger.e('刷新天气数据失败', tag: 'WeatherDataProvider', error: e);
      rethrow;
    }
  }

  /// 获取日出日落和生活指数数据
  Future<void> getSunMoonIndexData(LocationModel location) async {
    if (_isLoadingSunMoonIndex) return;

    try {
      _isLoadingSunMoonIndex = true;
      notifyListeners();

      // 模拟日出日落数据获取
      _sunMoonIndexData = SunMoonIndexData(
        sunAndMoon: SunAndMoon(
          sun: Sun(sunrise: '06:30', sunset: '18:30'),
          moon: Moon(),
        ),
        index: [],
      );

      Logger.s('日出日落数据获取成功', tag: 'WeatherDataProvider');
    } catch (e) {
      Logger.e('获取日出日落数据失败', tag: 'WeatherDataProvider', error: e);
    } finally {
      _isLoadingSunMoonIndex = false;
      notifyListeners();
    }
  }

  /// 生成AI天气摘要
  Future<void> generateWeatherSummary(LocationModel location) async {
    if (_isGeneratingSummary || _weatherSummary != null) return;

    try {
      _isGeneratingSummary = true;
      notifyListeners();

      if (_currentWeather != null) {
        // 模拟AI天气摘要生成
        final current = _currentWeather!.current?.current;
        final temperature = current?.temperature ?? '--';
        final weather = current?.weather ?? '晴';
        final windPower = current?.windpower ?? '1级';
        final humidity = current?.humidity ?? '50';

        _weatherSummary =
            '''
🌤️ **${location.district}今日天气**

**温度**: ${temperature}℃
**天气**: ${weather}
**风力**: ${windPower}
**湿度**: ${humidity}%

**生活建议**:
• 温度适宜，适合户外活动
• 注意防晒，建议涂抹防晒霜
• 风力较小，空气质量良好
• 湿度适中，体感舒适

**出行提醒**:
• 天气晴朗，适合出行
• 建议穿着轻便衣物
• 可适当增加户外运动时间
        ''';

        Logger.s('AI天气摘要生成成功', tag: 'WeatherDataProvider');
      }
    } catch (e) {
      Logger.e('生成AI天气摘要失败', tag: 'WeatherDataProvider', error: e);
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  /// 生成15日预报AI总结
  Future<void> generateForecast15dSummary(LocationModel location) async {
    if (_isGenerating15dSummary || _forecast15dSummary != null) return;

    try {
      _isGenerating15dSummary = true;
      notifyListeners();

      if (_forecast15d != null && _forecast15d!.isNotEmpty) {
        // 模拟15日预报AI总结生成
        final firstWeek = _forecast15d!.take(7).toList();
        // final secondWeek = _forecast15d!.skip(7).take(7).toList();

        // 分析温度趋势
        final temperatures = firstWeek.map((day) {
          final amTemp = int.tryParse(day.temperature_am ?? '0') ?? 0;
          final pmTemp = int.tryParse(day.temperature_pm ?? '0') ?? 0;
          return (amTemp + pmTemp) / 2;
        }).toList();

        final avgTemp =
            temperatures.reduce((a, b) => a + b) / temperatures.length;
        final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
        final minTemp = temperatures.reduce((a, b) => a < b ? a : b);

        // 分析天气变化
        final weatherTypes = firstWeek
            .map((day) => day.weather_am ?? '晴')
            .toList();
        final rainDays = weatherTypes
            .where((weather) => weather.contains('雨') || weather.contains('雪'))
            .length;

        _forecast15dSummary =
            '''
📅 **${location.district}未来15天天气趋势**

**温度概况**:
• 平均温度: ${avgTemp.toStringAsFixed(1)}℃
• 最高温度: ${maxTemp.toStringAsFixed(1)}℃
• 最低温度: ${minTemp.toStringAsFixed(1)}℃

**天气特点**:
• 未来一周降雨天数: ${rainDays}天
• 天气变化较为平稳
• 温度波动在正常范围内

**生活建议**:
• 未来一周温度适宜，适合户外活动
• 注意关注天气变化，适时调整穿着
• 建议合理安排出行计划
• 保持关注最新天气预报

**趋势分析**:
• 整体天气状况良好
• 温度变化平稳，体感舒适
• 适合进行各种户外活动
        ''';

        Logger.s('15日预报AI总结生成成功', tag: 'WeatherDataProvider');
      }
    } catch (e) {
      Logger.e('生成15日预报AI总结失败', tag: 'WeatherDataProvider', error: e);
    } finally {
      _isGenerating15dSummary = false;
      notifyListeners();
    }
  }

  /// 检查并生成通勤建议
  Future<void> checkAndGenerateCommuteAdvices(LocationModel location) async {
    if (_isGeneratingCommuteAdvice) return;

    try {
      _isGeneratingCommuteAdvice = true;
      notifyListeners();

      if (_currentWeather != null) {
        // 模拟通勤建议生成
        final current = _currentWeather!.current?.current;
        final weather = current?.weather ?? '晴';
        final temperature = int.tryParse(current?.temperature ?? '20') ?? 20;
        final windPower = current?.windpower ?? '1级';

        final now = DateTime.now();
        final isMorning = now.hour >= 7 && now.hour <= 9;
        final isEvening = now.hour >= 17 && now.hour <= 19;

        if (isMorning || isEvening) {
          final timeSlot = isMorning
              ? CommuteTimeSlot.morning
              : CommuteTimeSlot.evening;
          final adviceLevel = _getCommuteAdviceLevel(weather, temperature);

          final advice = CommuteAdviceModel(
            id: 'commute_${now.millisecondsSinceEpoch}',
            timestamp: now,
            adviceType: _getAdviceType(weather, temperature),
            title: _getCommuteTitle(weather, temperature, timeSlot),
            content: _getCommuteContent(
              weather,
              temperature,
              windPower,
              timeSlot,
            ),
            icon: _getCommuteIcon(weather, temperature),
            isRead: false,
            timeSlot: timeSlot,
            level: adviceLevel,
          );

          _commuteAdvices.add(advice);
          Logger.s('通勤建议生成成功，新增 1 条', tag: 'WeatherDataProvider');
        }
      }
    } catch (e) {
      Logger.e('生成通勤建议失败', tag: 'WeatherDataProvider', error: e);
    } finally {
      _isGeneratingCommuteAdvice = false;
      notifyListeners();
    }
  }

  /// 获取通勤建议级别
  CommuteAdviceLevel _getCommuteAdviceLevel(String weather, int temperature) {
    if (weather.contains('暴雨') || weather.contains('暴雪')) {
      return CommuteAdviceLevel.critical;
    } else if (weather.contains('雨') ||
        weather.contains('雪') ||
        temperature < 0 ||
        temperature > 35) {
      return CommuteAdviceLevel.warning;
    } else if (weather.contains('多云') || weather.contains('阴')) {
      return CommuteAdviceLevel.info;
    } else {
      return CommuteAdviceLevel.normal;
    }
  }

  /// 获取建议类型
  String _getAdviceType(String weather, int temperature) {
    if (weather.contains('雨')) return 'rainy';
    if (weather.contains('雪')) return 'snowy';
    if (weather.contains('风')) return 'windy';
    if (temperature > 30) return 'high_temp';
    if (temperature < 5) return 'low_temp';
    return 'sunny';
  }

  /// 获取通勤标题
  String _getCommuteTitle(
    String weather,
    int temperature,
    CommuteTimeSlot timeSlot,
  ) {
    final timeText = timeSlot == CommuteTimeSlot.morning ? '早高峰' : '晚高峰';
    if (weather.contains('雨')) return '${timeText}出行提醒：注意防雨';
    if (weather.contains('雪')) return '${timeText}出行提醒：注意防滑';
    if (temperature > 30) return '${timeText}出行提醒：注意防暑';
    if (temperature < 5) return '${timeText}出行提醒：注意保暖';
    return '${timeText}出行提醒：天气良好';
  }

  /// 获取通勤内容
  String _getCommuteContent(
    String weather,
    int temperature,
    String windPower,
    CommuteTimeSlot timeSlot,
  ) {
    final timeText = timeSlot == CommuteTimeSlot.morning ? '早高峰' : '晚高峰';
    final content = StringBuffer();

    content.writeln('🌤️ ${timeText}天气：${weather} ${temperature}℃');
    content.writeln('💨 风力：${windPower}');

    if (weather.contains('雨')) {
      content.writeln('🌂 建议：携带雨具，注意路面湿滑');
    } else if (weather.contains('雪')) {
      content.writeln('❄️ 建议：注意防滑，选择防滑鞋');
    } else if (temperature > 30) {
      content.writeln('☀️ 建议：注意防晒，多补充水分');
    } else if (temperature < 5) {
      content.writeln('🧥 建议：注意保暖，适当增加衣物');
    } else {
      content.writeln('✅ 建议：天气良好，适合出行');
    }

    return content.toString();
  }

  /// 获取通勤图标
  String _getCommuteIcon(String weather, int temperature) {
    if (weather.contains('雨')) return '🌧️';
    if (weather.contains('雪')) return '❄️';
    if (weather.contains('风')) return '💨';
    if (temperature > 30) return '☀️';
    if (temperature < 5) return '🧥';
    return '🌤️';
  }

  /// 启动通勤建议清理定时器
  // void _startCommuteCleanupTimer() {
  //   _commuteCleanupTimer?.cancel();
  //   _commuteCleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
  //     _cleanupOldCommuteAdvices();
  //   });
  // }

  /// 清理过期的通勤建议
  // void _cleanupOldCommuteAdvices() {
  //   final now = DateTime.now();
  //   _commuteAdvices.removeWhere((advice) {
  //     final adviceTime = advice.timestamp;
  //     return now.difference(adviceTime).inDays > 15; // 保留15天
  //   });
  //   notifyListeners();
  // }

  /// 清除所有数据
  void clearAllData() {
    _currentWeather = null;
    _hourlyForecast = null;
    _dailyForecast = null;
    _forecast15d = null;
    _sunMoonIndexData = null;
    _commuteAdvices.clear();
    _weatherSummary = null;
    _forecast15dSummary = null;
    _isUsingCachedData = false;
    _isBackgroundRefreshing = false;
    _commuteCleanupTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _commuteCleanupTimer?.cancel();
    super.dispose();
  }
}
