import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_chart.dart';
import '../widgets/hourly_weather_widget.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/life_index_widget.dart';
import '../widgets/app_menu.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/weather_icon_helper.dart';
import '../screens/hourly_screen.dart';

class WeatherPageCommon {
  /// 构建顶部天气信息区域
  static Widget buildTopWeatherSection({
    required WeatherProvider weatherProvider,
    required WeatherService weatherService,
    required String cityName,
    required VoidCallback? onRefresh,
    bool showMenu = true,
  }) {
    return Container(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.screenHorizontalPadding,
            8.0,
            AppConstants.screenHorizontalPadding,
            16.0,
          ),
          child: Column(
            children: [
              // 城市名称和菜单
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cityName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      if (showMenu) const AppMenu(),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onRefresh,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.titleBarDecorIconColor,
                            size: AppColors.titleBarDecorIconSize,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 刷新按钮
                      GestureDetector(
                        onTap: onRefresh,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: weatherProvider.isLoading
                                    ? AppColors.glassBackground.withOpacity(0.8)
                                    : AppColors.glassBackground,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppColors.borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: weatherProvider.isLoading
                                      ? null
                                      : onRefresh,
                                  child: Center(
                                    child: weatherProvider.isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.textPrimary,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.refresh,
                                            color: AppColors.titleBarIconColor,
                                            size: AppColors.titleBarIconSize,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 主要天气信息
              _buildMainWeatherInfo(weatherProvider, weatherService),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建主要天气信息
  static Widget _buildMainWeatherInfo(
    WeatherProvider weatherProvider,
    WeatherService weatherService,
  ) {
    final weather = weatherProvider.currentWeather?.current?.current;
    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
      );
    }

    final temperature = weather.temperature ?? '--';
    final weatherDesc = weather.weather ?? '晴';

    // 判断是白天还是夜间
    final isDay = weatherService.isDayTime();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColors.standardCardDecoration,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WeatherIconHelper.buildWeatherIcon(weatherDesc, !isDay, 56),
                    const SizedBox(height: 8),
                    Text(
                      weatherDesc,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    temperature,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    '℃',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 日出日落信息
          const SunMoonWidget(),
        ],
      ),
    );
  }

  /// 构建24小时预报
  static Widget buildHourlyForecast({
    required BuildContext context,
    required WeatherProvider weatherProvider,
    required WeatherService weatherService,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HourlyScreen()),
        );
      },
      child: HourlyWeatherWidget(
        hourlyForecast: weatherProvider.currentWeather?.forecast24h,
        weatherService: weatherService,
      ),
    );
  }

  /// 构建天气详情
  static Widget buildWeatherDetails(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    final weather = weatherProvider.currentWeather;

    return Column(
      children: [
        // 温度图表
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColors.standardCardDecoration,
          child: SizedBox(
            height: 220,
            child: WeatherChart(dailyForecast: weather?.forecast15d),
          ),
        ),
        const SizedBox(height: 16),
        // 生活指数
        LifeIndexWidget(weatherProvider: weatherProvider),
        const SizedBox(height: 16),
        // 天气详情
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenHorizontalPadding,
          ),
          child: Card(
            elevation: AppColors.cardElevation,
            shadowColor: AppColors.cardShadowColor,
            color: AppColors.materialCardColor,
            surfaceTintColor: Colors.transparent,
            shape: AppColors.cardShape,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildCompactWeatherDetail(context, weatherProvider),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建紧凑的天气详情
  static Widget _buildCompactWeatherDetail(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    final weather = weatherProvider.currentWeather?.current?.current;
    if (weather == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thermostat,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '天气详情',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showLifeAdviceDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.titleBarDecorIconColor,
                  size: AppColors.titleBarDecorIconSize,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactDetailItem(
                '体感温度',
                '${weather.feelstemperature ?? '--'}°',
                Icons.thermostat,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactDetailItem(
                '湿度',
                '${weather.humidity ?? '--'}%',
                Icons.water_drop,
                AppColors.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactDetailItem(
                '风速',
                '${weather.windpower ?? '--'}',
                Icons.air,
                AppColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactDetailItem(
                '气压',
                '${weather.airpressure ?? '--'}hPa',
                Icons.speed,
                AppColors.moon,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建紧凑的详情项
  static Widget _buildCompactDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.25), // 内层小卡片: 0.4 × 0.618 ≈ 0.25
      surfaceTintColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.40), // 图标容器: 0.25 / 0.618 ≈ 0.40
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示生活建议对话框
  static void _showLifeAdviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Material Design 3: 弹窗样式
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 3,
          icon: Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.warning,
            size: 32,
          ),
          title: Text(
            '生活建议',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          content: Text(
            '今日天气适宜外出，建议穿着舒适，注意防晒。',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
