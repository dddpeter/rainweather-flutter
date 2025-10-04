import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/theme_provider.dart';

class HourlyWeatherWidget extends StatelessWidget {
  final List<HourlyWeather>? hourlyForecast;
  final WeatherService weatherService;
  final VoidCallback? onTap;

  const HourlyWeatherWidget({
    super.key,
    required this.hourlyForecast,
    required this.weatherService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (hourlyForecast == null || hourlyForecast!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AppColors.standardCardDecoration,
            child: Center(
              child: Text(
                '暂无24小时预报数据',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ),
          );
        }

        return Card(
          elevation: AppColors.cardElevation,
          shadowColor: AppColors.cardShadowColor,
          color: AppColors.materialCardColor,
          shape: AppColors.cardShape,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.accentBlue,
                            size: AppConstants.sectionTitleIconSize,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '24小时预报',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: AppConstants.sectionTitleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '更多',
                        style: TextStyle(
                          color: themeProvider.isLightTheme
                              ? AppColors.primaryBlue
                              : AppColors.accentBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: hourlyForecast!.length,
                    itemBuilder: (context, index) {
                      final hour = hourlyForecast![index];
                      return _buildHourlyItem(hour, index);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHourlyItem(HourlyWeather hour, int index) {
    final time = _formatHourTime(hour.forecasttime ?? '');
    final temperature = _parseTemperature(hour.temperature ?? '');
    final weatherIcon = weatherService.getWeatherIcon(hour.weather ?? '晴');
    final weatherDesc = hour.weather ?? '晴'; // 天气描述

    return Container(
      width: 70, // 80 -> 70 (减少宽度)
      margin: const EdgeInsets.only(right: 2), // 4 -> 2 (1/2)
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
        children: [
          Text(
            time,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3), // 8 -> 3 (约1/3)
          Text(
            weatherIcon,
            style: const TextStyle(fontSize: 22), // 24 -> 22 (稍微缩小)
          ),
          const SizedBox(height: 2), // 图标和描述间距
          Text(
            weatherDesc,
            style: TextStyle(
              color: AppColors.textSecondary, // 使用主题色
              fontSize: 10, // 小字体
              fontWeight: FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // 防止文字过长
          ),
          const SizedBox(height: 2), // 描述和温度间距
          Text(
            '${temperature.toInt()}℃',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHourTime(String timeStr) {
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
      // 处理 "21℃" 格式
      final cleanStr = tempStr.replaceAll('℃', '').replaceAll('°', '');
      return double.parse(cleanStr);
    } catch (e) {
      return 0.0;
    }
  }
}
