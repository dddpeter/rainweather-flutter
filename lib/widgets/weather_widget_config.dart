import 'package:flutter/material.dart';

/// 天气小组件配置
class WeatherWidgetConfig {
  // 小组件ID
  static const String widgetName = 'WeatherWidget';

  // 数据键
  static const String keyDate = 'date';
  static const String keyWeekday = 'weekday';
  static const String keyLunarDate = 'lunar_date';
  static const String keyTime = 'time';
  static const String keyWeatherIcon = 'weather_icon';
  static const String keyWeatherText = 'weather_text';
  static const String keyTemperature = 'temperature';
  static const String keyLocation = 'location';
  static const String keyAqi = 'aqi';
  static const String keyWind = 'wind';
  static const String keyRainAlert = 'rain_alert';
  static const String keyForecast5d = 'forecast_5d';

  // 小组件尺寸 (dp)
  static const double widgetHeight = 220.0;
  static const double widgetWidth = 380.0;

  // 颜色配置
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textTertiaryColor = Color(0xFF999999);
  static const Color accentColor = Color(0xFF4A90E2);

  // 字体大小
  static const double fontSizeDate = 14.0;
  static const double fontSizeTime = 18.0;
  static const double fontSizeTemperature = 36.0;
  static const double fontSizeWeather = 16.0;
  static const double fontSizeLocation = 13.0;
  static const double fontSizeInfo = 12.0;
  static const double fontSizeForecast = 11.0;
}

/// 5日天气预报数据模型
class ForecastDay {
  final String date; // MM/DD
  final String weekday; // 周一、周二等
  final String weatherIcon; // 天气图标名称
  final String tempHigh; // 最高温度
  final String tempLow; // 最低温度

  ForecastDay({
    required this.date,
    required this.weekday,
    required this.weatherIcon,
    required this.tempHigh,
    required this.tempLow,
  });

  Map<String, String> toMap() {
    return {
      'date': date,
      'weekday': weekday,
      'weatherIcon': weatherIcon,
      'tempHigh': tempHigh,
      'tempLow': tempLow,
    };
  }

  factory ForecastDay.fromMap(Map<String, dynamic> map) {
    return ForecastDay(
      date: map['date'] ?? '',
      weekday: map['weekday'] ?? '',
      weatherIcon: map['weatherIcon'] ?? '',
      tempHigh: map['tempHigh'] ?? '',
      tempLow: map['tempLow'] ?? '',
    );
  }
}
