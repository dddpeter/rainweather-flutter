import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/forecast15d_chart.dart';

class Forecast15dScreen extends StatefulWidget {
  const Forecast15dScreen({super.key});

  @override
  State<Forecast15dScreen> createState() => _Forecast15dScreenState();
}

class _Forecast15dScreenState extends State<Forecast15dScreen> {
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
                  if (weatherProvider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textPrimary,
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
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '加载失败',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
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
                            onPressed: () =>
                                weatherProvider.refresh15DayForecast(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  }

                  final forecast15d = weatherProvider.forecast15d;

                  if (forecast15d == null || forecast15d.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '暂无15日预报数据',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      // 显示刷新提示
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('正在刷新15日预报数据...'),
                              ],
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }

                      await weatherProvider.refresh15DayForecast();

                      // 显示刷新完成提示
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('15日预报数据刷新完成'),
                            backgroundColor: AppColors.accentGreen,
                            duration: Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    color: AppColors.primaryBlue,
                    backgroundColor: AppColors.backgroundSecondary,
                    child: CustomScrollView(
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '15日预报',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: weatherProvider.isLoading
                                          ? null
                                          : () => weatherProvider
                                                .refresh15DayForecast(),
                                      icon: weatherProvider.isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.textPrimary),
                                              ),
                                            )
                                          : Icon(
                                              Icons.refresh,
                                              color:
                                                  AppColors.titleBarIconColor,
                                              size: AppColors.titleBarIconSize,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${weatherProvider.currentLocation?.district ?? '未知地区'} 未来15天天气预报',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.8,
                                    ),
                                    fontSize: AppConstants.sectionTitleFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Temperature Trend Chart
                        SliverToBoxAdapter(
                          child: Container(
                            margin: EdgeInsets.only(
                              left: AppConstants.screenHorizontalPadding,
                              right: AppConstants.screenHorizontalPadding,
                              top: 8, // 减少与副标题的间距
                            ),
                            child: Forecast15dChart(forecast15d: forecast15d),
                          ),
                        ),
                        // Forecast List
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final day = forecast15d[index];
                            return _buildForecastCard(
                              day,
                              weatherProvider,
                              index,
                            );
                          }, childCount: forecast15d.length),
                        ),
                      ],
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

  Widget _buildForecastCard(
    DailyWeather day,
    WeatherProvider weatherProvider,
    int index,
  ) {
    final isToday = index == 0;
    final isTomorrow = index == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
        vertical: 4,
      ),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date and week
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.accentBlue.withOpacity(0.2)
                            : AppColors.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(
                          color: isToday
                              ? AppColors.accentBlue.withOpacity(0.5)
                              : AppColors.accentGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isToday
                            ? '今天'
                            : isTomorrow
                            ? '明天'
                            : day.week ?? '',
                        style: TextStyle(
                          color: isToday
                              ? AppColors.textPrimary
                              : AppColors.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.forecasttime ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (day.sunrise_sunset != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        day.sunrise_sunset!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Weather info - compact horizontal layout
              Expanded(
                child: Row(
                  children: [
                    // Morning weather
                    Expanded(
                      child: _buildCompactWeatherPeriod(
                        '上午',
                        day.weather_am ?? '晴',
                        day.temperature_am ?? '--',
                        day.weather_am_pic ?? 'd00',
                        day.winddir_am ?? '',
                        day.windpower_am ?? '',
                        weatherProvider,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.dividerColor,
                    ),
                    const SizedBox(width: 8),
                    // Evening weather
                    Expanded(
                      child: _buildCompactWeatherPeriod(
                        '下午',
                        day.weather_pm ?? '晴',
                        day.temperature_pm ?? '--',
                        day.weather_pm_pic ?? 'n00',
                        day.winddir_pm ?? '',
                        day.windpower_pm ?? '',
                        weatherProvider,
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
  }

  Widget _buildCompactWeatherPeriod(
    String period,
    String weather,
    String temperature,
    String weatherPic,
    String windDir,
    String windPower,
    WeatherProvider weatherProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Weather icon
            Container(
              width: 24, // 增大宽度
              height: 24, // 增大高度
              alignment: Alignment.center, // 居中对齐
              child: Text(
                weatherProvider.getWeatherIcon(weather),
                style: TextStyle(fontSize: 20), // 增大图标大小
                textAlign: TextAlign.center, // 文字居中
                overflow: TextOverflow.visible, // 允许溢出但控制在容器内
              ),
            ),
            const SizedBox(width: 4),
            // Temperature
            Text(
              '$temperature℃',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Weather description
        Text(
          weather,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Wind info
        if (windDir.isNotEmpty || windPower.isNotEmpty)
          Text(
            '$windDir$windPower',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
      ],
    );
  }
}
