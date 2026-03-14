import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/weather_model.dart';
import '../../utils/weather_icon_helper.dart';
import '../../utils/date_utils.dart' as app_utils;
import '../../utils/formatters.dart';

/// 预报卡片组件
/// 
/// 用于显示每日天气预报信息
class ForecastCardWidget extends StatelessWidget {
  final DailyWeather day;
  final int index;
  final bool showSunriseSunset;

  const ForecastCardWidget({
    super.key,
    required this.day,
    required this.index,
    this.showSunriseSunset = false,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = app_utils.DateUtils.isToday(day.forecasttime ?? '');
    final isTomorrow = app_utils.DateUtils.isTomorrow(day.forecasttime ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildDateSection(isToday, isTomorrow),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeatherPeriods(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建日期部分
  Widget _buildDateSection(bool isToday, bool isTomorrow) {
    return SizedBox(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.accentBlue.withOpacity(0.2)
                  : AppColors.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(1),
              border: Border.all(
                color: isToday
                    ? AppColors.accentBlue.withOpacity(0.5)
                    : AppColors.accentGreen.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              isToday
                  ? '今天'
                  : isTomorrow
                      ? '明天'
                      : day.week ?? '',
              style: TextStyle(
                color: isToday
                    ? AppColors.textPrimary
                    : AppColors.accentGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.forecasttime ?? '',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showSunriseSunset && day.sunrise_sunset != null) ...[
            const SizedBox(height: 2),
            Text(
              day.sunrise_sunset!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 解析温度字符串为数值
  double _parseTemperature(String tempStr) {
    try {
      String cleanStr = tempStr
          .replaceAll('高温', '')
          .replaceAll('低温', '')
          .replaceAll('℃', '')
          .replaceAll('°', '')
          .replaceAll(' ', '')
          .trim();
      if (cleanStr.isEmpty) return 0;
      return double.parse(cleanStr);
    } catch (e) {
      return 0;
    }
  }

  /// 构建天气时段
  Widget _buildWeatherPeriods() {
    final tempAm = _parseTemperature(day.temperature_am ?? '');
    final tempPm = _parseTemperature(day.temperature_pm ?? '');
    // 判断哪个是低温数据
    final amIsLower = tempAm <= tempPm;

    return Row(
      children: [
        // 上午（显示低温）
        Expanded(
          child: _WeatherPeriodWidget(
            period: '上午',
            weather: amIsLower ? (day.weather_am ?? '晴') : (day.weather_pm ?? '晴'),
            temperature: amIsLower ? (day.temperature_am ?? '--') : (day.temperature_pm ?? '--'),
            weatherPic: amIsLower ? (day.weather_am_pic ?? 'd00') : (day.weather_pm_pic ?? 'n00'),
            windDir: amIsLower ? (day.winddir_am ?? '') : (day.winddir_pm ?? ''),
            windPower: amIsLower ? (day.windpower_am ?? '') : (day.windpower_pm ?? ''),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 40,
          color: AppColors.dividerColor,
        ),
        const SizedBox(width: 8),
        // 下午（显示高温）
        Expanded(
          child: _WeatherPeriodWidget(
            period: '下午',
            weather: amIsLower ? (day.weather_pm ?? '晴') : (day.weather_am ?? '晴'),
            temperature: amIsLower ? (day.temperature_pm ?? '--') : (day.temperature_am ?? '--'),
            weatherPic: amIsLower ? (day.weather_pm_pic ?? 'n00') : (day.weather_am_pic ?? 'd00'),
            windDir: amIsLower ? (day.winddir_pm ?? '') : (day.winddir_am ?? ''),
            windPower: amIsLower ? (day.windpower_pm ?? '') : (day.windpower_am ?? ''),
          ),
        ),
      ],
    );
  }
}

/// 天气时段组件
class _WeatherPeriodWidget extends StatelessWidget {
  final String period;
  final String weather;
  final String temperature;
  final String weatherPic;
  final String windDir;
  final String windPower;

  const _WeatherPeriodWidget({
    required this.period,
    required this.weather,
    required this.temperature,
    required this.weatherPic,
    required this.windDir,
    required this.windPower,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = WeatherIconHelper.isNightByPeriod(period);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: WeatherIconHelper.buildWeatherIcon(weather, isNight, 28),
            ),
            const SizedBox(width: 4),
            Text(
              '${Formatters.formatNumber(temperature)}℃',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          weather,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (windDir.isNotEmpty || windPower.isNotEmpty)
          Text(
            '$windDir$windPower',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}
