import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/forecast15d_chart.dart';
import '../widgets/ai_content_widget.dart';
import '../widgets/floating_action_island.dart';
import '../widgets/app_drawer.dart';
import 'daily_weather_detail_screen.dart';

class Forecast15dScreen extends StatefulWidget {
  const Forecast15dScreen({super.key});

  @override
  State<Forecast15dScreen> createState() => _Forecast15dScreenState();
}

class _Forecast15dScreenState extends State<Forecast15dScreen>
    with WidgetsBindingObserver {
  Key _chartKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // 应用恢复时刷新数据
      context.read<WeatherProvider>().refresh15DayForecast();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面显示时刷新15日预报数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 更新key强制重建子组件
        setState(() {
          _chartKey = UniqueKey();
        });

        // 刷新15日预报数据
        context.read<WeatherProvider>().refresh15DayForecast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听主题变化，确保整个页面在主题切换时重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Consumer<WeatherProvider>(
          builder: (context, weatherProvider, child) {
            return Scaffold(
              drawer: const AppDrawer(),
              floatingActionButton: _buildFloatingActionIsland(weatherProvider),
              body: Container(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Builder(
                    builder: (context) {
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
                          // iOS触觉反馈
                          if (Platform.isIOS) {
                            HapticFeedback.mediumImpact();
                          }
                          await weatherProvider.refresh15DayForecast();
                          if (Platform.isIOS) {
                            HapticFeedback.lightImpact();
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
                                                        >(
                                                          AppColors.textPrimary,
                                                        ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.refresh,
                                                  color: AppColors
                                                      .titleBarIconColor,
                                                  size: AppColors
                                                      .titleBarIconSize,
                                                ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${weatherProvider.currentLocation?.district ?? '未知地区'} 未来15天天气预报',
                                      style: TextStyle(
                                        color: AppColors.textSecondary
                                            .withOpacity(0.8),
                                        fontSize:
                                            AppConstants.sectionTitleFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // AI Weather Summary - 使用渐进式展示
                            SliverToBoxAdapter(
                              child: AIContentWidget(
                                title: '15日天气趋势',
                                icon: Icons.trending_up,
                                fetchAIContent: () async {
                                  if (weatherProvider.forecast15dSummary !=
                                      null) {
                                    return weatherProvider.forecast15dSummary!;
                                  }
                                  await weatherProvider
                                      .generateForecast15dSummary();
                                  return weatherProvider.forecast15dSummary ??
                                      '';
                                },
                                defaultContent: '未来半月天气平稳，温度变化不大，适合安排户外活动。',
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
                                child: Forecast15dChart(
                                  key: _chartKey,
                                  forecast15d: forecast15d.skip(1).toList(),
                                ),
                              ),
                            ),
                            // Forecast List
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  // 跳过第一个对象（昨天），从索引1开始
                                  final actualIndex = index + 1;
                                  if (actualIndex >= forecast15d.length)
                                    return null;

                                  final day = forecast15d[actualIndex];
                                  return _buildForecastCard(
                                    day,
                                    weatherProvider,
                                    actualIndex,
                                  );
                                },
                                childCount: forecast15d.length > 1
                                    ? forecast15d.length - 1
                                    : 0,
                              ),
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
      },
    );
  }

  Widget _buildForecastCard(
    DailyWeather day,
    WeatherProvider weatherProvider,
    int index,
  ) {
    // 根据实际日期判断今天和明天
    final isToday = _isToday(day.forecasttime ?? '');
    final isTomorrow = _isTomorrow(day.forecasttime ?? '');

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
        child: InkWell(
          onTap: () {
            // 跳转到单日详情页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyWeatherDetailScreen(
                  dailyWeather: day,
                  dayIndex: index,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
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
                      // Morning weather (使用pm数据)
                      Expanded(
                        child: _buildCompactWeatherPeriod(
                          '上午',
                          day.weather_pm ?? '晴',
                          day.temperature_pm ?? '--',
                          day.weather_pm_pic ?? 'n00',
                          day.winddir_pm ?? '',
                          day.windpower_pm ?? '',
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
                      // Evening weather (使用am数据)
                      Expanded(
                        child: _buildCompactWeatherPeriod(
                          '下午',
                          day.weather_am ?? '晴',
                          day.temperature_am ?? '--',
                          day.weather_am_pic ?? 'd00',
                          day.winddir_am ?? '',
                          day.windpower_am ?? '',
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

  /// 判断是否为今天
  bool _isToday(String forecastTime) {
    if (forecastTime.isEmpty) return false;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 尝试解析预报时间
      DateTime forecastDate;
      if (forecastTime.contains('-')) {
        // 格式：2024-10-06 或 10-06
        final parts = forecastTime.split(' ')[0].split('-');
        if (parts.length == 3) {
          // 完整日期格式
          forecastDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else if (parts.length == 2) {
          // 月-日格式
          forecastDate = DateTime(
            now.year,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else {
          return false;
        }
      } else if (forecastTime.contains('/')) {
        // 格式：2024/10/06 或 10/06
        final parts = forecastTime.split(' ')[0].split('/');
        if (parts.length == 3) {
          // 完整日期格式
          forecastDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else if (parts.length == 2) {
          // 月/日格式
          forecastDate = DateTime(
            now.year,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else {
          return false;
        }
      } else {
        return false;
      }

      return forecastDate.year == today.year &&
          forecastDate.month == today.month &&
          forecastDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  /// 判断是否为明天
  bool _isTomorrow(String forecastTime) {
    if (forecastTime.isEmpty) return false;

    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      // 尝试解析预报时间
      DateTime forecastDate;
      if (forecastTime.contains('-')) {
        // 格式：2024-10-06 或 10-06
        final parts = forecastTime.split(' ')[0].split('-');
        if (parts.length == 3) {
          // 完整日期格式
          forecastDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else if (parts.length == 2) {
          // 月-日格式
          forecastDate = DateTime(
            now.year,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else {
          return false;
        }
      } else if (forecastTime.contains('/')) {
        // 格式：2024/10/06 或 10/06
        final parts = forecastTime.split(' ')[0].split('/');
        if (parts.length == 3) {
          // 完整日期格式
          forecastDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else if (parts.length == 2) {
          // 月/日格式
          forecastDate = DateTime(
            now.year,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else {
          return false;
        }
      } else {
        return false;
      }

      return forecastDate.year == tomorrow.year &&
          forecastDate.month == tomorrow.month &&
          forecastDate.day == tomorrow.day;
    } catch (e) {
      return false;
    }
  }

  /// 构建浮动操作岛
  Widget _buildFloatingActionIsland(WeatherProvider weatherProvider) {
    final themeProvider = context.read<ThemeProvider>();

    return FloatingActionIsland(
      mainIcon: Icons.menu_rounded,
      mainTooltip: '快捷操作',
      actions: [
        // 刷新
        IslandAction(
          icon: Icons.refresh_rounded,
          label: '刷新',
          onTap: () async {
            // iOS触觉反馈
            if (Platform.isIOS) {
              HapticFeedback.mediumImpact();
            }

            await weatherProvider.refresh15DayForecast();

            // iOS触觉反馈 - 刷新完成
            if (Platform.isIOS) {
              HapticFeedback.lightImpact();
            }
          },
          backgroundColor: AppColors.primaryBlue,
        ),
        // 设置
        IslandAction(
          icon: Icons.settings_rounded,
          label: '设置',
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          backgroundColor: AppColors.primaryBlue,
        ),
        // 主题切换
        IslandAction(
          icon: themeProvider.isLightTheme
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          label: themeProvider.isLightTheme ? '暗色' : '亮色',
          onTap: () {
            // 切换主题：亮色→暗色，暗色→亮色
            themeProvider.setThemeMode(
              themeProvider.isLightTheme
                  ? AppThemeMode.dark
                  : AppThemeMode.light,
            );
          },
          backgroundColor: AppColors.primaryBlue,
        ),
      ],
    );
  }
}
