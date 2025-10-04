import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';

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

        // 过滤显示当前时间前2小时、当前时间和当前时间后21小时的数据
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
    final weatherIcon = weatherService.getWeatherIcon(hour.weather ?? '晴');
    final isCurrentHour = _isCurrentHour(time);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                if (isCurrentHour)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.currentTagBackground,
                      border: Border.all(
                        color: AppColors.currentTagBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '现在',
                      style: TextStyle(
                        color: AppColors.currentTag,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 天气图标
          SizedBox(
            width: 50,
            child: Center(
              child: Text(weatherIcon, style: const TextStyle(fontSize: 24)),
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
              hour.weather ?? '晴',
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

  bool _isCurrentHour(String timeStr) {
    try {
      final now = DateTime.now();
      final currentHour = now.hour;

      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          return hour == currentHour;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 过滤逐小时预报数据，显示当前时间前2小时、当前时间和当前时间后21小时
  List<HourlyWeather> _filterHourlyForecast(List<HourlyWeather> forecast) {
    final now = DateTime.now();
    final currentHour = now.hour;

    // 计算时间范围：当前时间前2小时到当前时间后21小时
    final startHour = (currentHour - 2 + 24) % 24; // 前2小时
    final endHour = (currentHour + 21) % 24; // 后21小时

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

        // 检查是否在时间范围内（考虑跨天情况）
        bool shouldInclude = false;

        if (startHour <= endHour) {
          // 不跨天：startHour <= hour <= endHour
          shouldInclude = forecastHour >= startHour && forecastHour <= endHour;
        } else {
          // 跨天：hour >= startHour || hour <= endHour
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

    // 按时间排序
    filtered.sort((a, b) {
      final hourA = _parseHour(a.forecasttime ?? '');
      final hourB = _parseHour(b.forecasttime ?? '');
      return hourA.compareTo(hourB);
    });

    return filtered;
  }

  /// 解析时间字符串为小时数
  int _parseHour(String timeStr) {
    try {
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return int.parse(parts[0]);
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
