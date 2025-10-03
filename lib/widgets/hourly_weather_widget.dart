import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class HourlyWeatherWidget extends StatelessWidget {
  final List<HourlyWeather>? hourlyForecast;
  final WeatherService weatherService;

  const HourlyWeatherWidget({
    super.key,
    required this.hourlyForecast,
    required this.weatherService,
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
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: AppColors.standardCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '24小时预报',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '更多',
                      style: TextStyle(
                        color: themeProvider.isLightTheme 
                            ? AppColors.primaryBlue  // 亮色主题使用深蓝色
                            : AppColors.accentBlue,   // 暗色主题使用亮蓝色
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: hourlyForecast!.length,
                  itemBuilder: (context, index) {
                    final hour = hourlyForecast![index];
                    return _buildHourlyItem(hour, index);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHourlyItem(HourlyWeather hour, int index) {
    final time = _formatHourTime(hour.forecasttime ?? '');
    final temperature = _parseTemperature(hour.temperature ?? '');
    final weatherIcon = weatherService.getWeatherIcon(hour.weather ?? '晴');

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 4),
      child: Column(
        children: [
          Text(
            time,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weatherIcon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            '${temperature.toInt()}°',
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