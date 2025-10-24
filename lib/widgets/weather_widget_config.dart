import 'package:flutter/material.dart';

/// 天气小组件配置
class WeatherWidgetConfig {
  // 小组件ID
  static const String widgetName = 'WeatherWidget';

  // 数据键 - 顶部区域
  static const String keyLocation = 'location';
  static const String keyGregorianDate = 'gregorian_date';
  static const String keyCurrentTemp = 'current_temp';
  static const String keyCurrentWeather = 'current_weather';
  static const String keyCurrentWeatherIcon = 'current_weather_icon';
  static const String keyTodayHigh = 'today_high';
  static const String keyTodayLow = 'today_low';

  // 数据键 - 24小时预报
  static const String keyHourlyForecast = 'hourly_forecast';

  // 数据键 - 5日预报
  static const String keyForecast5d = 'forecast_5d';

  // 数据键 - 农历和空气质量
  static const String keyLunarDate = 'lunar_date';
  static const String keyAirQuality = 'air_quality';
  static const String keyLifeTips = 'life_tips';

  // 小组件尺寸 (dp) - 4x4 小组件
  static const double widgetHeight = 400.0; // 4x4 小组件高度
  static const double widgetWidth = 400.0; // 4x4 小组件宽度

  // 颜色配置 - 多彩毛玻璃风格
  static const Color backgroundColor = Color(0x80012d78); // 深蓝色半透明背景
  static const Color textPrimaryColor = Color(0xFFFFFFFF); // 白色主文字
  static const Color textSecondaryColor = Color(0xFFE8F4FD); // 浅蓝色次文字
  static const Color textTertiaryColor = Color(0xFFB8D9F5); // 更浅的蓝色

  // 主题色彩
  static const Color accentColor = Color(0xFF4A90E2); // 主题蓝色
  static const Color dividerColor = Color(0xFF3A3A3C); // 分隔线颜色

  // 功能色彩
  static const Color temperatureColor = Color(0xFFFF6B35); // 温度橙色
  static const Color weatherColor = Color(0xFF4ECDC4); // 天气青色
  static const Color lunarColor = Color(0xFFFFD93D); // 农历金色
  static const Color airQualityColor = Color(0xFF6BCF7F); // 空气质量绿色
  static const Color adviceColor = Color(0xFFFF8A80); // 建议粉色
  static const Color forecastColor = Color(0xFF9C88FF); // 预报紫色

  // 字体大小
  static const double fontSizeLocation = 16.0; // 位置文字
  static const double fontSizeCurrentTemp = 48.0; // 当前温度
  static const double fontSizeCurrentWeather = 18.0; // 当前天气
  static const double fontSizeTodayTemp = 16.0; // 今日高低温度
  static const double fontSizeHourlyTime = 12.0; // 小时时间
  static const double fontSizeHourlyTemp = 14.0; // 小时温度
  static const double fontSizeDailyWeekday = 14.0; // 日期星期
  static const double fontSizeDailyTemp = 12.0; // 日期温度
}

/// 24小时天气预报数据模型
class HourlyForecast {
  final String time; // 时间，如 "21时"
  final String temperature; // 温度
  final String weatherIcon; // 天气图标名称
  final String weatherText; // 天气文字

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherIcon,
    required this.weatherText,
  });

  Map<String, String> toMap() {
    return {
      'time': time,
      'temperature': temperature,
      'weatherIcon': weatherIcon,
      'weatherText': weatherText,
    };
  }

  factory HourlyForecast.fromMap(Map<String, dynamic> map) {
    return HourlyForecast(
      time: map['time'] ?? '',
      temperature: map['temperature'] ?? '',
      weatherIcon: map['weatherIcon'] ?? '',
      weatherText: map['weatherText'] ?? '',
    );
  }
}

/// 5日天气预报数据模型
class ForecastDay {
  final String weekday; // 周一、周二等
  final String weatherIcon; // 天气图标名称
  final String tempHigh; // 最高温度
  final String tempLow; // 最低温度
  final int tempDiff; // 温差
  final int progressPercent; // 高温进度百分比（0-100）
  final int lowProgressPercent; // 低温进度百分比（0-100）

  ForecastDay({
    required this.weekday,
    required this.weatherIcon,
    required this.tempHigh,
    required this.tempLow,
    required this.tempDiff,
    required this.progressPercent,
    required this.lowProgressPercent,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekday': weekday,
      'weatherIcon': weatherIcon,
      'tempHigh': tempHigh,
      'tempLow': tempLow,
      'tempDiff': tempDiff,
      'progressPercent': progressPercent,
      'lowProgressPercent': lowProgressPercent,
    };
  }

  factory ForecastDay.fromMap(Map<String, dynamic> map) {
    return ForecastDay(
      weekday: map['weekday'] ?? '',
      weatherIcon: map['weatherIcon'] ?? '',
      tempHigh: map['tempHigh'] ?? '',
      tempLow: map['tempLow'] ?? '',
      tempDiff: map['tempDiff'] ?? 0,
      progressPercent: map['progressPercent'] ?? 0,
      lowProgressPercent: map['lowProgressPercent'] ?? 0,
    );
  }
}
