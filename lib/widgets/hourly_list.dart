import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/weather_icon_helper.dart';

class HourlyList extends StatelessWidget {
  final List<HourlyWeather>? hourlyForecast;
  final WeatherService weatherService;

  const HourlyList({
    super.key,
    required this.hourlyForecast,
    required this.weatherService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (hourlyForecast == null || hourlyForecast!.isEmpty) {
          return Card(
            elevation: AppColors.cardElevation,
            shadowColor: AppColors.cardShadowColor,
            color: AppColors.materialCardColor,
            shape: AppColors.cardShape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '暂无24小时预报数据',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }

        // 过滤显示24小时预报数据（从当前时间之后的下一个整点开始）
        final filteredForecast = _filterHourlyForecast(hourlyForecast!);

        return Card(
          elevation: AppColors.cardElevation,
          shadowColor: AppColors.cardShadowColor,
          color: AppColors.materialCardColor,
          shape: AppColors.cardShape,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredForecast.length,
                separatorBuilder: (context, index) =>
                    Divider(color: AppColors.cardBorder, height: 1),
                itemBuilder: (context, index) {
                  final hour = filteredForecast[index];
                  return _buildHourlyItem(hour, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHourlyItem(HourlyWeather hour, int index) {
    final time = _formatTime(hour.forecasttime ?? '');
    final temperature = _parseTemperature(hour.temperature ?? '');
    final weatherDesc = hour.weather ?? '晴';

    // 判断是白天还是夜间（根据小时）
    final hourValue = WeatherIconHelper.getHourValue(hour.forecasttime ?? '');
    final isNight = WeatherIconHelper.isNightByHour(hourValue);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 时间
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // 天气图标
          SizedBox(
            width: 50,
            child: Center(
              child: WeatherIconHelper.buildWeatherIcon(
                weatherDesc,
                isNight,
                28,
              ),
            ),
          ),

          // 温度
          SizedBox(
            width: 60,
            child: Text(
              '${temperature.toInt()}℃',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),

          // 天气描述
          Expanded(
            child: Text(
              weatherDesc,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),

          // 风向风力
          SizedBox(
            width: 80,
            child: Text(
              '${hour.windDir ?? '--'}${hour.windPower ?? ''}',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '--';
    try {
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          return '${hour.toString().padLeft(2, '0')}:00';
        }
      }
      return timeStr;
    } catch (e) {
      return timeStr.length > 5 ? timeStr.substring(0, 5) : timeStr;
    }
  }

  double _parseTemperature(String tempStr) {
    if (tempStr.isEmpty) return 0.0;
    try {
      final cleanStr = tempStr.replaceAll('℃', '').replaceAll('°', '');
      return double.parse(cleanStr);
    } catch (e) {
      return 0.0;
    }
  }

  /// 过滤24小时预报数据，从当前时间之后的下一个整点开始，覆盖24个小时
  List<HourlyWeather> _filterHourlyForecast(List<HourlyWeather> forecast) {
    // 24小时预报逻辑：API数据已经按照正确的时间顺序排列
    // 从当前时间之后的下一个整点开始，覆盖24个小时
    // 例如：当前21:25，则显示22:00到次日21:00的24个小时

    final now = DateTime.now();
    final currentHour = now.hour;

    // 计算起始小时：当前时间之后的下一个整点
    final startHour = (currentHour + 1) % 24;

    List<HourlyWeather> filtered = [];

    for (final hour in forecast) {
      final timeStr = hour.forecasttime ?? '';
      if (timeStr.isEmpty) continue;

      try {
        // 解析时间字符串，支持 HH:mm 格式
        int? forecastHour;

        if (timeStr.contains(':')) {
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            forecastHour = int.parse(parts[0]);
          }
        }

        if (forecastHour == null) continue;

        // 检查是否在24小时范围内
        // 从startHour开始，连续24个小时（包含跨天）
        bool shouldInclude = false;

        if (startHour + 23 < 24) {
          // 不跨天：startHour <= hour <= startHour + 23
          shouldInclude =
              forecastHour >= startHour && forecastHour <= startHour + 23;
        } else {
          // 跨天：hour >= startHour || hour <= (startHour + 23) % 24
          final endHour = (startHour + 23) % 24;
          shouldInclude = forecastHour >= startHour || forecastHour <= endHour;
        }

        if (shouldInclude) {
          filtered.add(hour);
        }
      } catch (e) {
        // 解析失败，跳过这个数据
        continue;
      }
    }

    // API数据已经按照正确的时间顺序排列，不需要重新排序
    return filtered;
  }
}
