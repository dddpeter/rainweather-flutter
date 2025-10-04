import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/weather_chart.dart';
import '../widgets/hourly_weather_widget.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/life_index_widget.dart';
import 'hourly_screen.dart';
import 'weather_alerts_screen.dart';

class CityWeatherScreen extends StatefulWidget {
  final String cityName;

  const CityWeatherScreen({super.key, required this.cityName});

  @override
  State<CityWeatherScreen> createState() => _CityWeatherScreenState();
}

class _CityWeatherScreenState extends State<CityWeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 获取指定城市的天气数据（包含日出日落和生活指数数据）
      context.read<WeatherProvider>().getWeatherForCity(widget.cityName);
    });
  }

  @override
  void didUpdateWidget(CityWeatherScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果城市名称发生变化，重新获取天气数据
    if (oldWidget.cityName != widget.cityName) {
      print(
        '🏙️ CityWeatherScreen: City changed from ${oldWidget.cityName} to ${widget.cityName}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<WeatherProvider>().getWeatherForCity(widget.cityName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听主题变化，确保整个页面在主题切换时重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Consumer<WeatherProvider>(
                builder: (context, weatherProvider, child) {
                  if (weatherProvider.isLoading &&
                      weatherProvider.currentWeather == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    );
                  }

                  if (weatherProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.textPrimary,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '加载失败',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            weatherProvider.error!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => weatherProvider.getWeatherForCity(
                              widget.cityName,
                            ),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        weatherProvider.getWeatherForCity(widget.cityName),
                    color: AppColors.primaryBlue,
                    backgroundColor: AppColors.backgroundSecondary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildTopWeatherSection(weatherProvider),
                          const SizedBox(height: AppConstants.cardSpacing),
                          // 详细信息卡片 - 移到头部之下
                          _buildWeatherDetails(weatherProvider),
                          const SizedBox(height: AppConstants.cardSpacing),
                          // 天气提示卡片
                          _buildWeatherTipsCard(weatherProvider),
                          const SizedBox(height: AppConstants.cardSpacing),
                          const SunMoonWidget(),
                          const SizedBox(height: AppConstants.cardSpacing),
                          LifeIndexWidget(weatherProvider: weatherProvider),
                          const SizedBox(height: AppConstants.cardSpacing),
                          _buildHourlyWeather(weatherProvider),
                          const SizedBox(height: AppConstants.cardSpacing),
                          _buildTemperatureChart(weatherProvider),
                          const SizedBox(
                            height: 80,
                          ), // Space for bottom buttons
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopWeatherSection(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final current = weather?.current?.current;

    return Container(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              // City name and navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.titleBarIconColor,
                        size: AppColors.titleBarIconSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.cityName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 告警图标或右侧占位
                  _buildAlertButton(weatherProvider),
                ],
              ),
              const SizedBox(height: 16),

              // Weather icon, weather text and temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weatherProvider.getWeatherIcon(current?.weather ?? '晴'),
                    style: TextStyle(
                      fontSize: 72,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    current?.weather ?? '晴',
                    style: TextStyle(
                      color: AppColors.textSecondary, // 修复：使用深色以确保亮色模式下可见
                      fontSize: 30, // 48 * 0.618 ≈ 30
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '${current?.temperature ?? '--'}℃',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // 农历日期 - Material Design 3
              if (weather?.current?.nongLi != null) ...[
                const SizedBox(height: 8),
                Text(
                  weather!.current!.nongLi!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureChart(WeatherProvider weatherProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '7日温度趋势',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: WeatherChart(
                  dailyForecast: weatherProvider.dailyForecast,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyWeather(WeatherProvider weatherProvider) {
    final weatherService = WeatherService.getInstance();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: HourlyWeatherWidget(
        hourlyForecast: weatherProvider.currentWeather?.forecast24h,
        weatherService: weatherService,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HourlyScreen()),
          );
        },
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final air = weather?.current?.air ?? weather?.air;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.moon, // 使用紫色图标
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '详细信息',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (air != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.air,
                        '空气质量',
                        '${air.AQI ?? '--'} (${air.levelIndex ?? '未知'})',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                    const SizedBox(width: 4), // 减小间隙
                    if (weather?.current?.current != null)
                      Expanded(
                        child: _buildCompactDetailItem(
                          Icons.thermostat,
                          '体感温度',
                          '${weather!.current!.current!.feelstemperature ?? '--'}℃',
                          AppColors.cardThemeBlue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4), // 减小间隙
              ],
              if (weather?.current?.current != null) ...[
                // 第一行：湿度和气压
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.water_drop,
                        '湿度',
                        '${weather!.current!.current!.humidity ?? '--'}%',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                    const SizedBox(width: 4), // 减小间隙
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.compress,
                        '气压',
                        '${weather.current!.current!.airpressure ?? '--'}hpa',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // 减小间隙
                // 第二行：风力和能见度
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.air,
                        '风力',
                        '${weather.current!.current!.winddir ?? '--'} ${weather.current!.current!.windpower ?? ''}',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                    const SizedBox(width: 4), // 减小间隙
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.visibility,
                        '能见度',
                        '${weather.current!.current!.visibility ?? '--'}km',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // 减小间隙
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.25), // 内层小卡片: 0.4 × 0.618 ≈ 0.25
      surfaceTintColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors
                        .cardThemeBlueIconBackgroundColor, // 使用主题蓝色图标背景
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.cardThemeBlueIconColor, // 使用主题蓝色图标颜色
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13, // 从11增大到13
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertButton(WeatherProvider weatherProvider) {
    final alerts = weatherProvider.currentWeather?.current?.alerts;
    final hasAlerts = alerts != null && alerts.isNotEmpty;

    // 调试信息
    print(
      'CityWeatherScreen _buildAlertButton: hasAlerts=$hasAlerts, alerts=$alerts',
    );

    if (hasAlerts) {
      return Stack(
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeatherAlertsScreen(alerts: alerts),
                ),
              );
            },
            icon: Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: AppColors.titleBarIconSize,
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundPrimary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox(width: 40, height: 40); // 占位保持对称
  }

  /// 构建天气提示卡片（Material Design 3）
  Widget _buildWeatherTipsCard(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final tips = weather?.current?.tips;
    final current = weather?.current?.current;

    if (tips == null && current == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    Icons.lightbulb_rounded,
                    color: AppColors.warning,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '今日提醒',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 天气提示
              if (tips != null) ...[
                _buildTipItem(Icons.wb_sunny_rounded, tips, AppColors.warning),
                const SizedBox(height: 12),
              ],

              // 穿衣建议
              if (current?.temperature != null)
                _buildTipItem(
                  Icons.checkroom_rounded,
                  _getClothingSuggestion(
                    current!.temperature!,
                    current.weather,
                  ),
                  AppColors.primaryBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建提示项
  Widget _buildTipItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据温度和天气生成穿衣建议
  String _getClothingSuggestion(String temperature, String? weather) {
    try {
      final temp = int.parse(temperature);
      final hasRain = weather?.contains('雨') ?? false;
      final hasSnow = weather?.contains('雪') ?? false;

      String suggestion = '';

      // 温度建议
      if (temp >= 30) {
        suggestion = '天气炎热，建议穿短袖、短裤等清凉透气的衣服';
      } else if (temp >= 25) {
        suggestion = '天气温暖，适合穿短袖、薄长裤等夏季服装';
      } else if (temp >= 20) {
        suggestion = '天气舒适，建议穿长袖衬衫、薄外套等';
      } else if (temp >= 15) {
        suggestion = '天气微凉，建议穿夹克、薄毛衣等';
      } else if (temp >= 10) {
        suggestion = '天气较冷，建议穿厚外套、毛衣等保暖衣物';
      } else if (temp >= 0) {
        suggestion = '天气寒冷，建议穿棉衣、羽绒服等厚实保暖的衣服';
      } else {
        suggestion = '天气严寒，建议穿加厚羽绒服、保暖内衣等防寒衣物';
      }

      // 天气补充建议
      if (hasRain) {
        suggestion += '，记得带伞☂️';
      } else if (hasSnow) {
        suggestion += '，注意防滑保暖❄️';
      }

      return suggestion;
    } catch (e) {
      return '根据天气情况适当增减衣物';
    }
  }
}
