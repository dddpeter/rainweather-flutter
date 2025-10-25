import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lunar/lunar.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../widgets/weather_widget_config.dart';
import '../utils/logger.dart';

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

      // 顶部区域数据
      await prefs.setString(
        'location',
        widgetData[WeatherWidgetConfig.keyLocation] as String? ?? '未知位置',
      );
      await prefs.setString(
        'gregorian_date',
        widgetData[WeatherWidgetConfig.keyGregorianDate] as String? ??
            '--月--日 星期--',
      );
      await prefs.setString(
        'current_temp',
        widgetData[WeatherWidgetConfig.keyCurrentTemp] as String? ?? '--°',
      );
      await prefs.setString(
        'current_weather',
        widgetData[WeatherWidgetConfig.keyCurrentWeather] as String? ?? '未知',
      );
      await prefs.setString(
        'current_weather_icon',
        widgetData[WeatherWidgetConfig.keyCurrentWeatherIcon] as String? ?? '',
      );
      await prefs.setString(
        'today_high',
        widgetData[WeatherWidgetConfig.keyTodayHigh] as String? ?? '最高 --°',
      );
      await prefs.setString(
        'today_low',
        widgetData[WeatherWidgetConfig.keyTodayLow] as String? ?? '最低 --°',
      );

      // 24小时预报数据
      await prefs.setString(
        'hourly_forecast',
        jsonEncode(widgetData[WeatherWidgetConfig.keyHourlyForecast] ?? []),
      );

      // 5日预报数据
      await prefs.setString(
        'forecast_5d',
        jsonEncode(widgetData[WeatherWidgetConfig.keyForecast5d] ?? []),
      );

      // 农历和空气质量数据
      await prefs.setString(
        'lunar_date',
        widgetData[WeatherWidgetConfig.keyLunarDate] as String? ?? '农历 --',
      );
      await prefs.setString(
        'air_quality',
        widgetData[WeatherWidgetConfig.keyAirQuality] as String? ?? '空气质量 --',
      );

      // 生活提示数据
      await prefs.setString(
        'life_tips',
        widgetData[WeatherWidgetConfig.keyLifeTips] as String? ??
            '生活提示：建议穿薄外套，无需带伞',
      );

      // 通知Widget更新
      await HomeWidget.updateWidget(
        androidName: 'WeatherWidgetProvider',
        iOSName: WeatherWidgetConfig.widgetName,
      );

      Logger.s('小组件数据已更新', tag: 'WeatherWidgetService');
      Logger.d('数据: ${jsonEncode(widgetData)}', tag: 'WeatherWidgetService');
    } catch (e) {
      Logger.e('更新小组件失败', tag: 'WeatherWidgetService', error: e);
    }
  }

  /// 准备小组件数据
  Map<String, dynamic> _prepareWidgetData({
    required WeatherModel weatherData,
    required LocationModel location,
    required DateTime now,
  }) {
    // 顶部区域：位置、当前温度、今日高低温度
    final locationStr = location.district;
    final currentTemp = '${weatherData.current?.current?.temperature ?? '--'}°';
    final currentWeather = weatherData.current?.current?.weather ?? '未知';
    final currentWeatherIcon = weatherData.current?.current?.weatherPic ?? '';

    // 今日高低温度
    final todayForecast = weatherData.forecast15d?.isNotEmpty == true
        ? weatherData.forecast15d!.first
        : null;
    final todayHigh = '最高 ${todayForecast?.temperature_pm ?? '--'}°';
    final todayLow = '最低 ${todayForecast?.temperature_am ?? '--'}°';

    // 24小时天气预报
    final hourlyForecast = _getHourlyForecast(weatherData);

    // 5日天气预报
    final forecast5d = _getForecast5Days(weatherData);

    // 公历日期和星期
    final gregorianDate = _getGregorianDate(now);

    // 农历信息
    final lunarDate = _getLunarDate(now);

    // 空气质量
    final airQuality = _getAirQuality(weatherData);

    // 生活提示（穿衣+带伞）
    final lifeTips = _getLifeTips(weatherData);

    return {
      WeatherWidgetConfig.keyLocation: locationStr,
      WeatherWidgetConfig.keyGregorianDate: gregorianDate,
      WeatherWidgetConfig.keyCurrentTemp: currentTemp,
      WeatherWidgetConfig.keyCurrentWeather: currentWeather,
      WeatherWidgetConfig.keyCurrentWeatherIcon: currentWeatherIcon,
      WeatherWidgetConfig.keyTodayHigh: todayHigh,
      WeatherWidgetConfig.keyTodayLow: todayLow,
      WeatherWidgetConfig.keyLunarDate: lunarDate,
      WeatherWidgetConfig.keyAirQuality: airQuality,
      WeatherWidgetConfig.keyLifeTips: lifeTips,
      WeatherWidgetConfig.keyHourlyForecast: hourlyForecast
          .map((h) => h.toMap())
          .toList(),
      WeatherWidgetConfig.keyForecast5d: forecast5d
          .map((f) => f.toMap())
          .toList(),
    };
  }

  /// 获取24小时天气预报
  List<HourlyForecast> _getHourlyForecast(WeatherModel weatherData) {
    final List<HourlyForecast> result = [];

    if (weatherData.forecast24h == null || weatherData.forecast24h!.isEmpty) {
      return result;
    }

    // 取前8个小时的预报
    final hourlyData = weatherData.forecast24h!.take(8).toList();

    for (int i = 0; i < hourlyData.length; i++) {
      final hour = hourlyData[i];

      // 格式化时间，如 "21时"
      final timeStr = _formatHourlyTime(hour.forecasttime ?? '');

      result.add(
        HourlyForecast(
          time: timeStr,
          temperature: '${hour.temperature?.replaceAll('℃', '°') ?? '--°'}',
          weatherIcon: hour.weatherPic ?? '',
          weatherText: hour.weather ?? '',
        ),
      );
    }

    return result;
  }

  /// 格式化小时时间
  String _formatHourlyTime(String timeStr) {
    try {
      // 解析时间字符串，如 "21:00"
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 1) {
        final hour = int.parse(timeParts[0]);
        return '${hour}时';
      }
    } catch (e) {
      // 解析失败，返回原字符串
    }
    return timeStr;
  }

  /// 获取星期几
  String _getWeekday(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }

  /// 获取5日天气预报
  List<ForecastDay> _getForecast5Days(WeatherModel weatherData) {
    final List<ForecastDay> result = [];

    if (weatherData.forecast15d == null || weatherData.forecast15d!.isEmpty) {
      return result;
    }

    // 跳过今天，取接下来的5天（明天到第6天）
    final forecasts = weatherData.forecast15d!.skip(1).take(5).toList();

    // 收集所有温度数据，用于计算全局范围
    final List<int> allTemps = [];
    final List<Map<String, int>> tempRanges = [];

    for (int i = 0; i < forecasts.length; i++) {
      final forecast = forecasts[i];
      final tempAm = int.tryParse(forecast.temperature_am ?? '') ?? 0;
      final tempPm = int.tryParse(forecast.temperature_pm ?? '') ?? 0;

      // 计算最高温度和最低温度
      final tempHigh = math.max(tempAm, tempPm);
      final tempLow = math.min(tempAm, tempPm);

      allTemps.addAll([tempHigh, tempLow]);
      tempRanges.add({'high': tempHigh, 'low': tempLow});
    }

    if (allTemps.isEmpty) return result;

    // 找到全局最低温度和最高温度
    final globalMinTemp = allTemps.reduce(math.min);
    final globalMaxTemp = allTemps.reduce(math.max);

    // 计算五天内的最大温差
    final maxTempDiff = globalMaxTemp - globalMinTemp;
    int offset = 3;
    // 映射到大于等于3的范围：让最小温度变成3
    if (globalMinTemp < 0) {
      offset = 0 - globalMinTemp;
    } else {
      offset = globalMinTemp;
    }

    // 标尺最大值：五天最高温度 + offset（最大温差）
    final scaleMax = globalMaxTemp + offset + 3;

    // 调试输出全局范围
    Logger.d(
      '全局温度范围: ${globalMinTemp}° 到 ${globalMaxTemp}°',
      tag: 'WeatherWidgetService',
    );
    Logger.d('五天最大温差: ${maxTempDiff}°', tag: 'WeatherWidgetService');
    Logger.d('映射偏移: $offset, 标尺最大值: $scaleMax', tag: 'WeatherWidgetService');

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

      // 格式化星期
      String weekdayStr = _getWeekday(date.weekday);

      final tempRange = tempRanges[i];
      final tempHigh = tempRange['high']!;
      final tempLow = tempRange['low']!;

      // 映射温度到0+范围
      final mappedHigh = tempHigh + offset;
      final mappedLow = tempLow + offset;

      // 计算进度百分比
      final highProgress = ((mappedHigh / scaleMax) * 100).round();
      final lowProgress = ((mappedLow / scaleMax) * 100).round();

      // 确保低温进度至少为1%（如果温度范围不为0）
      final finalLowProgress = tempHigh > tempLow
          ? math.max(1, lowProgress)
          : lowProgress;

      // 调试输出
      Logger.d(
        '第${i + 1}天温度: ${tempLow}°-${tempHigh}°, 映射: ${mappedLow}-${mappedHigh}, 进度: ${finalLowProgress}%-${highProgress}%',
        tag: 'WeatherWidgetService',
      );
      Logger.d(
        '第${i + 1}天详细计算: mappedLow=$mappedLow, scaleMax=$scaleMax, 低温比例=${mappedLow / scaleMax}',
        tag: 'WeatherWidgetService',
      );

      // 计算温差（用于显示）
      final tempDiff = tempHigh - tempLow;

      result.add(
        ForecastDay(
          weekday: weekdayStr,
          weatherIcon: forecast.weather_am ?? forecast.weather_pm ?? '',
          tempHigh: '${tempHigh}°',
          tempLow: '${tempLow}°',
          tempDiff: tempDiff,
          progressPercent: highProgress, // 存储高温进度
          lowProgressPercent: finalLowProgress, // 新增：低温进度（修正后）
        ),
      );
    }

    return result;
  }

  /// 清除小组件数据
  Future<void> clearWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 清除顶部区域数据
      await prefs.remove('location');
      await prefs.remove('current_temp');
      await prefs.remove('current_weather');
      await prefs.remove('current_weather_icon');
      await prefs.remove('today_high');
      await prefs.remove('today_low');

      // 清除24小时预报数据
      await prefs.remove('hourly_forecast');

      // 清除5日预报数据
      await prefs.remove('forecast_5d');

      Logger.s('小组件数据已清除', tag: 'WeatherWidgetService');
    } catch (e) {
      Logger.e('清除小组件失败', tag: 'WeatherWidgetService', error: e);
    }
  }

  /// 获取公历日期和星期
  String _getGregorianDate(DateTime now) {
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.month}月${now.day}日 $weekday';
  }

  /// 获取农历信息
  String _getLunarDate(DateTime now) {
    try {
      // 使用农历库获取农历信息
      final lunar = Lunar.fromDate(now);

      // 获取农历信息（lunar.toString()返回如"二〇二五年九月初四"）
      final lunarStr = lunar.toString();
      // 移除年份，只保留月日
      final lunarWithoutYear = lunarStr.replaceFirst(RegExp(r'二〇二五年'), '');

      return lunarWithoutYear;
    } catch (e) {
      // 如果农历转换失败，返回简化版本
      return '农历${now.day}日';
    }
  }

  /// 获取空气质量信息
  String _getAirQuality(WeatherModel weatherData) {
    final aqi = weatherData.current?.air?.AQI;
    final level = weatherData.current?.air?.levelIndex;

    if (aqi != null && level != null) {
      return '空气质量 $level';
    }
    return '空气质量 --';
  }

  /// 获取生活提示（穿衣+带伞）
  String _getLifeTips(WeatherModel weatherData) {
    final currentWeather = weatherData.current?.current?.weather ?? '';
    final currentTemp =
        int.tryParse(weatherData.current?.current?.temperature ?? '') ?? 0;

    // 穿衣建议
    String dressAdvice = '';
    if (currentTemp <= 0) {
      dressAdvice = '建议穿厚羽绒服';
    } else if (currentTemp <= 5) {
      dressAdvice = '建议穿厚外套';
    } else if (currentTemp <= 10) {
      dressAdvice = '建议穿薄外套';
    } else if (currentTemp <= 15) {
      dressAdvice = '建议穿长袖';
    } else if (currentTemp <= 20) {
      dressAdvice = '建议穿薄长袖';
    } else {
      dressAdvice = '建议穿短袖';
    }

    // 带伞建议
    String umbrellaAdvice = '';
    if (currentWeather.contains('雨') ||
        currentWeather.contains('雪') ||
        currentWeather.contains('雷') ||
        currentWeather.contains('阵雨') ||
        currentWeather.contains('暴雨') ||
        currentWeather.contains('中雨') ||
        currentWeather.contains('小雨')) {
      umbrellaAdvice = '建议带伞';
    } else {
      umbrellaAdvice = '无需带伞';
    }

    return '生活提示：$dressAdvice，$umbrellaAdvice';
  }
}
