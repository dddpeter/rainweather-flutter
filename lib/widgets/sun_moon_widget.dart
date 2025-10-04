import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sun_moon_index_model.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';

class SunMoonWidget extends StatelessWidget {
  final WeatherProvider weatherProvider;

  const SunMoonWidget({Key? key, required this.weatherProvider})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final sunMoonData = weatherProvider.sunMoonIndexData;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: AppColors.cardElevation,
            shadowColor: AppColors.cardShadowColor,
            color: AppColors.materialCardColor,
            shape: AppColors.cardShape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '日出日落',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 日出日落信息
                  if (sunMoonData?.sunAndMoon != null) ...[
                    _buildSunMoonInfo(sunMoonData!.sunAndMoon!),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '暂无日出日落数据',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSunMoonInfo(SunAndMoon sunAndMoon) {
    return Row(
      children: [
        Expanded(
          child: _buildSunMoonItem(
            Icons.wb_sunny,
            '日出',
            sunAndMoon.sun?.sunrise ?? '--',
            AppColors.sunrise,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSunMoonItem(
            Icons.nightlight_round,
            '日落',
            sunAndMoon.sun?.sunset ?? '--',
            AppColors.sunset,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSunMoonItem(
            Icons.brightness_2,
            '月龄',
            sunAndMoon.moon?.moonage ?? '--',
            AppColors.moon,
          ),
        ),
      ],
    );
  }

  Widget _buildSunMoonItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
