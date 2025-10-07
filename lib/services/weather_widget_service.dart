import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../widgets/weather_widget_config.dart';
import '../utils/lunar_calendar.dart';

/// 天气小组件服务
class WeatherWidgetService {
  static WeatherWidgetService? _instance;

  WeatherWidgetService._();

  static WeatherWidgetService getInstance() {
    _instance ??= WeatherWidgetService._();
    return _instance!;
  }

  /// 更新小组件数据
  Future<void> updateWidget({
    required WeatherModel weatherData,
    required LocationModel location,
  }) async {
    try {
      final now = DateTime.now();

      // 准备小组件数据
      final widgetData = _prepareWidgetData(
        weatherData: weatherData,
        location: location,
        now: now,
      );

      // 使用 SharedPreferences 和 home_widget 插件更新小组件
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('date', widgetData['date'] as String);
      await prefs.setString('weekday', widgetData['weekday'] as String);
      await prefs.setString('lunar_date', widgetData['lunar_date'] as String);
      await prefs.setString('time', widgetData['time'] as String);
      await prefs.setString(
        'weather_text',
        widgetData['weather_text'] as String,
      );
      await prefs.setString('temperature', widgetData['temperature'] as String);
      await prefs.setString('location', widgetData['location'] as String);
      await prefs.setString('aqi', widgetData['aqi'] as String);
      await prefs.setString('wind', widgetData['wind'] as String);
      await prefs.setString('rain_alert', widgetData['rain_alert'] as String);
      await prefs.setString(
        'forecast_5d',
        jsonEncode(widgetData['forecast_5d']),
      );

      // 通知Widget更新
      await HomeWidget.updateWidget(
        androidName: 'WeatherWidgetProvider',
        iOSName: WeatherWidgetConfig.widgetName,
      );

      print('📱 WeatherWidgetService: 小组件数据已更新');
      print('📱 数据: ${jsonEncode(widgetData)}');
    } catch (e) {
      print('❌ WeatherWidgetService: 更新小组件失败 - $e');
    }
  }

  /// 准备小组件数据
  Map<String, dynamic> _prepareWidgetData({
    required WeatherModel weatherData,
    required LocationModel location,
    required DateTime now,
  }) {
    // 第一行：日期、星期、农历
    final dateStr = DateFormat('MM月dd日').format(now);
    final weekday = _getWeekday(now.weekday);
    final lunarDate = LunarCalendar.format(now);

    // 第二行：时间、天气
    final timeStr = DateFormat('HH:mm').format(now);
    final weatherIcon = weatherData.current?.current?.weatherPic ?? '';
    final weatherText = weatherData.current?.current?.weather ?? '未知';
    final temperature = '${weatherData.current?.current?.temperature ?? '--'}℃';

    // 第三行：位置、空气、风力、降雨
    final locationStr = location.district;
    final aqi = weatherData.current?.air?.AQI?.toString() ?? '--';
    final aqiLevel = _getAqiLevel(
      int.tryParse(weatherData.current?.air?.AQI ?? '0') ?? 0,
    );
    final wind =
        '${weatherData.current?.current?.winddir ?? ''}'
        '${weatherData.current?.current?.windpower ?? ''}';
    final rainAlert = _getRainAlert(weatherData);

    // 第四行：5日天气预报
    final forecast5d = _getForecast5Days(weatherData);

    return {
      WeatherWidgetConfig.keyDate: dateStr,
      WeatherWidgetConfig.keyWeekday: weekday,
      WeatherWidgetConfig.keyLunarDate: lunarDate,
      WeatherWidgetConfig.keyTime: timeStr,
      WeatherWidgetConfig.keyWeatherIcon: weatherIcon,
      WeatherWidgetConfig.keyWeatherText: weatherText,
      WeatherWidgetConfig.keyTemperature: temperature,
      WeatherWidgetConfig.keyLocation: locationStr,
      WeatherWidgetConfig.keyAqi: '$aqi $aqiLevel',
      WeatherWidgetConfig.keyWind: wind,
      WeatherWidgetConfig.keyRainAlert: rainAlert,
      WeatherWidgetConfig.keyForecast5d: forecast5d
          .map((f) => f.toMap())
          .toList(),
    };
  }

  /// 获取星期几
  String _getWeekday(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }

  /// 获取空气质量等级
  String _getAqiLevel(int aqi) {
    if (aqi <= 50) return '优';
    if (aqi <= 100) return '良';
    if (aqi <= 150) return '轻度';
    if (aqi <= 200) return '中度';
    if (aqi <= 300) return '重度';
    return '严重';
  }

  /// 获取降雨提醒
  String _getRainAlert(WeatherModel weatherData) {
    // 检查今日是否有雨
    final todayForecast = weatherData.forecast15d?.isNotEmpty == true
        ? weatherData.forecast15d!.first
        : null;

    if (todayForecast == null) return '暂无降雨';

    final textDay = todayForecast.weather_am?.toLowerCase() ?? '';
    final textNight = todayForecast.weather_pm?.toLowerCase() ?? '';

    if (textDay.contains('雨') || textNight.contains('雨')) {
      // 简化提醒（因为当前模型没有降雨概率字段）
      return '今日有雨 带伞';
    }

    return '今日无雨';
  }

  /// 获取5日天气预报
  List<ForecastDay> _getForecast5Days(WeatherModel weatherData) {
    final List<ForecastDay> result = [];

    if (weatherData.forecast15d == null || weatherData.forecast15d!.isEmpty) {
      return result;
    }

    // 跳过今天，取接下来的5天（明天到第6天）
    final forecasts = weatherData.forecast15d!.skip(1).take(5).toList();

    for (int i = 0; i < forecasts.length; i++) {
      final forecast = forecasts[i];

      // 解析日期
      DateTime? date;
      try {
        date = DateTime.parse(forecast.forecasttime ?? '');
      } catch (e) {
        // 如果解析失败，使用当前日期加上索引+1（因为跳过了今天）
        date = DateTime.now().add(Duration(days: i + 1));
      }

      // 格式化日期
      String dateStr;
      String weekdayStr = _getWeekday(date.weekday);

      if (i == 0) {
        dateStr = '明天';
      } else {
        dateStr = DateFormat('MM/dd').format(date);
      }

      result.add(
        ForecastDay(
          date: dateStr,
          weekday: weekdayStr,
          weatherIcon: forecast.weather_am ?? forecast.weather_pm ?? '',
          tempHigh: '${forecast.temperature_pm ?? '--'}℃',
          tempLow: '${forecast.temperature_am ?? '--'}℃',
        ),
      );
    }

    return result;
  }

  /// 清除小组件数据
  Future<void> clearWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('date');
      await prefs.remove('weekday');
      await prefs.remove('lunar_date');
      await prefs.remove('time');
      await prefs.remove('weather_text');
      await prefs.remove('temperature');
      await prefs.remove('location');
      await prefs.remove('aqi');
      await prefs.remove('wind');
      await prefs.remove('rain_alert');
      await prefs.remove('forecast_5d');

      print('📱 WeatherWidgetService: 小组件数据已清除');
    } catch (e) {
      print('❌ WeatherWidgetService: 清除小组件失败 - $e');
    }
  }
}
