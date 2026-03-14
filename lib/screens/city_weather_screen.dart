import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/weather_animation_widget.dart';
import '../widgets/weather_details_widget.dart';
import '../utils/formatters.dart';
import 'hourly_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 获取指定城市的天气数据（包含日出日落和生活指数数据）
      await context.read<WeatherProvider>().getWeatherForCity(widget.cityName);
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<WeatherProvider>().getWeatherForCity(
          widget.cityName,
        );
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

        return PopScope(
          onPopInvoked: (didPop) {
            if (didPop) {
              // 手势返回时重置到当前定位数据
              context.read<WeatherProvider>().restoreCurrentLocationWeather();
            }
          },
          child: Scaffold(
            // 右下角浮动返回按钮
            floatingActionButton: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    // 返回时重置到当前定位数据
                    context
                        .read<WeatherProvider>()
                        .restoreCurrentLocationWeather();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: AppColors.screenBackgroundGradient,
              ),
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
                              onPressed: () => weatherProvider
                                  .getWeatherForCity(widget.cityName),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        // iOS触觉反馈
                        if (Platform.isIOS) {
                          HapticFeedback.mediumImpact();
                        }
                        await weatherProvider.getWeatherForCity(
                          widget.cityName,
                        );
                        if (Platform.isIOS) {
                          HapticFeedback.lightImpact();
                        }
                      },
                      color: AppColors.primaryBlue,
                      backgroundColor: AppColors.backgroundSecondary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildTopWeatherSection(weatherProvider),
                            AppColors.cardSpacingWidget,
                            // 24小时天气
                            _buildHourlyWeather(weatherProvider),
                            AppColors.cardSpacingWidget,
                            // 详细信息卡片
                            WeatherDetailsWidget(
                              weather: weatherProvider.currentWeather,
                            ),
                            AppColors.cardSpacingWidget,
                            // 生活指数
                            LifeIndexWidget(weatherProvider: weatherProvider),
                            AppColors.cardSpacingWidget,
                            // 天气提示卡片
                            _buildWeatherTipsCard(weatherProvider),
                            AppColors.cardSpacingWidget,
                            const SunMoonWidget(),
                            AppColors.cardSpacingWidget,
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
      decoration: BoxDecoration(
        gradient: context.read<ThemeProvider>().headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
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
                    onTap: () {
                      // 返回时重置到当前定位数据
                      context
                          .read<WeatherProvider>()
                          .restoreCurrentLocationWeather();
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back,
                        color: context.read<ThemeProvider>().getColor(
                          'headerIconColor',
                        ),
                        size: AppColors.titleBarIconSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.cityName,
                        style: TextStyle(
                          color: context.read<ThemeProvider>().getColor(
                            'headerTextPrimary',
                          ),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 右侧占位
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),

              // Weather animation, weather text and temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左侧天气动画区域 - 45%宽度，右对齐
                  Flexible(
                    flex: 45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        WeatherAnimationWidget(
                          weatherType: current?.weather ?? '晴',
                          size: 100,
                          isPlaying: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // 右侧温度和天气汉字区域 - 55%宽度，左对齐
                  Flexible(
                    flex: 55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Formatters.formatNumber(current?.temperature)}℃',
                          style: TextStyle(
                            color: context.read<ThemeProvider>().getColor(
                              'headerTextPrimary',
                            ),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          current?.weather ?? '晴',
                          style: TextStyle(
                            color: context.read<ThemeProvider>().getColor(
                              'headerTextSecondary',
                            ),
                            fontSize: 24, // 从28减小到24
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
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
                    color: context.read<ThemeProvider>().getColor(
                      'headerTextSecondary',
                    ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
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
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
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

  /// 构建天气提示卡片（Material Design 3）
  Widget _buildWeatherTipsCard(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final tips = weather?.current?.tips;
    final current = weather?.current?.current;

    if (tips == null && current == null) {
      return const SizedBox.shrink();
    }

    return Padding(
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

  // /// 获取详细信息项图标颜色
  // Color _getDetailItemIconColor(IconData icon) {
  //   // 使用更明快、活泼的两种颜色：橙色和蓝色
  //   if (icon == Icons.water_drop ||
  //       icon == Icons.air ||
  //       icon == Icons.eco ||
  //       icon == Icons.checkroom ||
  //       icon == Icons.local_hospital) {
  //     // 橙色系 - 明快活泼
  //     return const Color(0xFFFFB74D); // 在亮色和暗色主题下都使用相同的橙色
  //   } else {
  //     // 蓝色系 - 明快清新
  //     return const Color(0xFF4FC3F7); // 在亮色和暗色主题下都使用相同的蓝色
  //   }
  // }

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
