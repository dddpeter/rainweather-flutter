import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sun_moon_index_model.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class SunMoonWidget extends StatelessWidget {
  const SunMoonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final sunMoonData = weatherProvider.sunMoonIndexData;
        final forecast15d = weatherProvider.currentWeather?.forecast15d ?? [];

        // 优先使用API数据，如果没有则使用15天预报数据
        if (sunMoonData?.sunAndMoon != null) {
          return _SunMoonCard(sunAndMoon: sunMoonData!.sunAndMoon!);
        } else if (forecast15d.isNotEmpty) {
          return _SunriseSunsetCard(forecast15d: forecast15d);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class _SunMoonCard extends StatelessWidget {
  final SunAndMoon sunAndMoon;

  const _SunMoonCard({required this.sunAndMoon});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        final sun = sunAndMoon.sun;
        final moon = sunAndMoon.moon;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.screenHorizontalPadding,
          ),
          child: Card(
            elevation: AppColors.cardElevation,
            shadowColor: AppColors.cardShadowColor,
            color: AppColors.materialCardColor,
            surfaceTintColor: Colors.transparent,
            shape: AppColors.cardShape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  _buildSectionTitle(
                    icon: Icons.wb_sunny_outlined,
                    title: '日出日落',
                    color: AppColors.sunrise,
                  ),
                  const SizedBox(height: 16),

                  // 田字型布局（带中心月相emoji和月龄）
                  SizedBox(
                    height: 156,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _SunMoonGrid(
                          sunrise: sun?.sunrise ?? '--',
                          sunset: sun?.sunset ?? '--',
                          moonrise: moon?.moonrise ?? '--',
                          moonset: moon?.moonset ?? '--',
                          moonAge: moon?.moonage,
                        ),
                        // 中心的月相emoji和月龄信息
                        if (moon?.moonage != null)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 月相emoji
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.moon,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getMoonPhaseEmoji(moon?.moonage),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 月相名称
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.moon.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.moon.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  moon?.moonage ?? '月相',
                                  style: TextStyle(
                                    color: AppColors.moon,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getMoonPhaseEmoji(String? moonPhaseName) {
    if (moonPhaseName == null) return '🌙';

    // 根据月相名称返回对应的emoji
    switch (moonPhaseName) {
      case '新月':
        return '🌑';
      case '峨眉月':
        return '🌒';
      case '上弦月':
        return '🌓';
      case '盈凸月':
        return '🌔';
      case '满月':
        return '🌕';
      case '亏凸月':
        return '🌖';
      case '下弦月':
        return '🌗';
      case '残月':
        return '🌘';
      default:
        return '🌙'; // 默认月亮
    }
  }
}

class _SunMoonGrid extends StatelessWidget {
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String? moonAge;

  const _SunMoonGrid({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    this.moonAge,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 根据主题模式选择月落颜色
        final moonsetColor = themeProvider.isLightTheme
            ? AppColors
                  .primaryBlue // 浅色模式使用主题蓝色
            : AppColors.accentBlue; // 深色模式使用亮蓝色

        return Column(
          children: [
            // 第一行
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    // 日出
                    Expanded(
                      child: Center(
                        child: _GridItem(
                          label: '日出',
                          time: sunrise,
                          color: AppColors.sunrise,
                          icon: Icons.wb_sunny_outlined,
                        ),
                      ),
                    ),
                    // 月出
                    Expanded(
                      child: Center(
                        child: _GridItem(
                          label: '月出',
                          time: moonrise,
                          color: AppColors.moon, // 月出 - 使用主题化颜色
                          icon: Icons.bedtime,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 第二行
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // 日落
                    Expanded(
                      child: Center(
                        child: _GridItem(
                          label: '日落',
                          time: sunset,
                          color: AppColors.sunset,
                          icon: Icons.wb_twilight_outlined,
                        ),
                      ),
                    ),
                    // 月落
                    Expanded(
                      child: Center(
                        child: _GridItem(
                          label: '月落',
                          time: moonset,
                          color: moonsetColor, // 月落 - 根据主题模式动态选择颜色
                          icon: Icons.bedtime_off,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridItem extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final IconData icon;

  const _GridItem({
    required this.label,
    required this.time,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SunriseSunsetCard extends StatelessWidget {
  final List<dynamic> forecast15d;

  const _SunriseSunsetCard({required this.forecast15d});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

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

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.screenHorizontalPadding,
          ),
          child: Card(
            elevation: AppColors.cardElevation,
            shadowColor: AppColors.cardShadowColor,
            color: AppColors.materialCardColor,
            surfaceTintColor: Colors.transparent,
            shape: AppColors.cardShape,
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
                        child: _SunriseSunsetItem(
                          label: '日出',
                          time: sunrise,
                          color: AppColors.sunrise,
                          icon: Icons.wb_sunny_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SunriseSunsetItem(
                          label: '日落',
                          time: sunset,
                          color: AppColors.sunset,
                          icon: Icons.wb_twilight_outlined,
                        ),
                      ),
                    ],
                  ),

                  // 白昼时长
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
          ),
        );
      },
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

class _SunriseSunsetItem extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final IconData icon;

  const _SunriseSunsetItem({
    required this.label,
    required this.time,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
