import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sun_moon_index_model.dart';
import '../providers/weather_provider.dart';
import '../constants/app_colors.dart';

class SunMoonWidget extends StatelessWidget {
  final WeatherProvider weatherProvider;

  const SunMoonWidget({super.key, required this.weatherProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final sunMoonData = weatherProvider.sunMoonIndexData;
        final forecast15d = weatherProvider.currentWeather?.forecast15d ?? [];

        // 优先使用API数据，如果没有则使用15天预报数据
        if (sunMoonData?.sunAndMoon != null) {
          return _buildSunMoonFromAPI(sunMoonData!.sunAndMoon!);
        } else if (forecast15d.isNotEmpty) {
          return _buildSunMoonFromForecast(forecast15d);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildSunMoonFromAPI(SunAndMoon sunAndMoon) {
    final sun = sunAndMoon.sun;
    final moon = sunAndMoon.moon;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  '日出日落',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.nightlight_round_outlined,
                  size: 20,
                  color: AppColors.moon,
                ),
                const SizedBox(width: 8),
                Text(
                  '月相',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 日出日落和月相信息
            Row(
              children: [
                // 日出日落
                Expanded(
                  child: Column(
                    children: [
                      _buildTimeItem(
                        '日出',
                        sun?.sunrise ?? '--',
                        AppColors.sunrise,
                        Icons.wb_sunny_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeItem(
                        '日落',
                        sun?.sunset ?? '--',
                        AppColors.sunset,
                        Icons.wb_twilight_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 月相信息
                Expanded(
                  child: Column(
                    children: [
                      _buildTimeItem(
                        '月出',
                        moon?.moonrise ?? '--',
                        AppColors.moon,
                        Icons.nightlight_round_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeItem(
                        '月落',
                        moon?.moonset ?? '--',
                        AppColors.moon,
                        Icons.nightlight_round_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 月龄信息
            if (moon?.moonage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.moon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.moon.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle_outlined,
                      size: 16,
                      color: AppColors.moon,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '月龄 ${moon!.moonage}天',
                      style: TextStyle(
                        color: AppColors.moon,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSunMoonFromForecast(List<dynamic> forecast15d) {
    final today = forecast15d.first;
    final sunriseSunset = today.sunrise_sunset;

    if (sunriseSunset == null || !sunriseSunset.contains('|')) {
      return const SizedBox.shrink();
    }

    // 解析日出日落时间 "06:48|18:34"
    final times = sunriseSunset.split('|');
    if (times.length != 2) return const SizedBox.shrink();

    final sunrise = times[0]; // "06:48"
    final sunset = times[1]; // "18:34"

    // 计算白昼时长
    final sunriseMinutes = _parseTime(sunrise);
    final sunsetMinutes = _parseTime(sunset);
    final dayDuration = sunsetMinutes - sunriseMinutes;
    final hours = dayDuration ~/ 60;
    final minutes = dayDuration % 60;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  '日出日落',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 日出日落信息
            Row(
              children: [
                Expanded(
                  child: _buildTimeItem(
                    '日出',
                    sunrise,
                    AppColors.sunrise,
                    Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeItem(
                    '日落',
                    sunset,
                    AppColors.sunset,
                    Icons.wb_twilight_outlined,
                  ),
                ),
              ],
            ),

            // 白昼时长
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '白昼时长 ${hours}小时${minutes}分钟',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem(String label, String time, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }
}
