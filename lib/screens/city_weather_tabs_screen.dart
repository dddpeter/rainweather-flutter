import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/hourly_list.dart';
import '../widgets/forecast15d_chart.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/weather_details_widget.dart';
import '../widgets/life_index_widget.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/ai_content_widget.dart';
import '../widgets/city_weather_screen_base.dart';

/// 城市天气标签屏幕 - 使用TabBar实现页面切换
/// 继承自CityWeatherScreenBase基类，复用公共逻辑
class CityWeatherTabsScreen extends StatefulWidget {
  final String cityName;
  final String? cityId;

  const CityWeatherTabsScreen({
    super.key,
    required this.cityName,
    this.cityId,
  });

  @override
  State<CityWeatherTabsScreen> createState() => _CityWeatherTabsScreenState();
}

class _CityWeatherTabsScreenState extends CityWeatherScreenBase<CityWeatherTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initControllers() {
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void disposeControllers() {
    _tabController.dispose();
  }

  @override
  String getOldCityName(CityWeatherTabsScreen oldWidget) {
    return oldWidget.cityName;
  }

  @override
  String get cityName => widget.cityName;

  @override
  String? get cityId => widget.cityId;

  @override
  Widget buildNavigationController(WeatherProvider weatherProvider) {
    // 检查状态
    if (weatherProvider.isLoading && weatherProvider.currentWeather == null) {
      return Column(
        children: [
          // 简化的顶部（不显示天气信息）
          _buildSimpleHeader(),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (weatherProvider.error != null && weatherProvider.currentWeather == null) {
      return Column(
        children: [
          _buildSimpleHeader(),
          Expanded(
            child: Center(
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
                      cityName,
                      cityId: cityId,
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (weatherProvider.currentWeather == null) {
      return Column(
        children: [
          _buildSimpleHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.textPrimary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无天气数据',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '无法获取 "$cityName" 的天气信息',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => weatherProvider.getWeatherForCity(
                      cityName,
                      cityId: cityId,
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // 顶部天气信息区域
        buildTopWeatherSection(weatherProvider),

        // 标签页
        Container(
          color: AppColors.appBarBackground, // 使用与 AppBar 一致的背景色
          child: TabBar(
            controller: _tabController,
            indicatorColor: context.read<ThemeProvider>().isLightTheme
                ? AppColors.primaryBlue
                : AppColors.accentBlue, // 使用与 AppBar 一致的颜色
            labelColor: context.read<ThemeProvider>().isLightTheme
                ? AppColors.primaryBlue
                : AppColors.accentBlue, // 使用与 AppBar 一致的颜色
            unselectedLabelColor: context.read<ThemeProvider>().isLightTheme
                ? AppColors.textSecondary // 亮色模式：使用次要文字色，提高对比度
                : AppColors.accentBlue.withOpacity(0.6), // 暗色模式：使用半透明主题色
            dividerColor: Colors.transparent, // 移除下边框
            dividerHeight: 0, // 移除下边框高度
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: '当前天气'),
              Tab(text: '24小时&15日'),
              Tab(text: 'AI总结'),
            ],
          ),
        ),

        // 标签页内容
        Expanded(
          child: TabBarView(
            key: const PageStorageKey('city_weather_tab_view'),
            controller: _tabController,
            physics: const AlwaysScrollableScrollPhysics(), // 允许滚动切换
            children: [
              Container(
                key: const PageStorageKey('current_weather_tab'),
                child: _buildCurrentWeatherTab(weatherProvider),
              ),
              Container(
                key: const PageStorageKey('forecast_tab'),
                child: _buildForecastTab(weatherProvider),
              ),
              Container(
                key: const PageStorageKey('alerts_tab'),
                child: _buildAlertsTab(weatherProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建简化的头部（用于加载/错误状态）
  Widget _buildSimpleHeader() {
    return Container(
      color: AppColors.appBarBackground,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          cityName,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 第一个标签页：当前天气
  Widget _buildCurrentWeatherTab(WeatherProvider weatherProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(
          cityName,
          forceRefreshAI: true,
        );
      },
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 空气质量卡片
            AirQualityCard(weather: weatherProvider.currentWeather),
            AppColors.cardSpacingWidget,
            // 今日提醒卡片（在详细信息前面）
            buildWeatherTipsCard(weatherProvider),
            AppColors.cardSpacingWidget,
            // 详细信息卡片
            WeatherDetailsWidget(
              weather: weatherProvider.currentWeather,
              showAirQuality: false,
            ),
            AppColors.cardSpacingWidget,
            // 生活指数
            LifeIndexWidget(weatherProvider: weatherProvider),
            AppColors.cardSpacingWidget,
            const SunMoonWidget(),
            AppColors.cardSpacingWidget,
            buildTemperatureChart(weatherProvider),
            const SizedBox(height: 80), // Space for bottom buttons
          ],
        ),
      ),
    );
  }

  /// 第二个标签页：24小时和15日预报
  Widget _buildForecastTab(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final hourlyForecast = weather?.forecast24h ?? [];
    final forecast15d = weather?.forecast15d ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(
          cityName,
          forceRefreshAI: true,
        );
      },
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 24小时温度趋势图
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenHorizontalPadding,
              ),
              child: HourlyChart(hourlyForecast: hourlyForecast),
            ),
            AppColors.cardSpacingWidget,

            // 24小时天气列表
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenHorizontalPadding,
              ),
              child: HourlyList(
                hourlyForecast: hourlyForecast,
                weatherService: WeatherService.getInstance(),
              ),
            ),
            AppColors.cardSpacingWidget,

            // 15日预报图表
            if (forecast15d.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenHorizontalPadding,
                ),
                child: Forecast15dChart(
                  forecast15d: forecast15d.skip(1).toList(),
                ),
              ),
              AppColors.cardSpacingWidget,

              // 15日预报列表
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.accentBlue,
                          size: AppConstants.sectionTitleIconSize,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '15日详细预报',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppConstants.sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 15日预报列表（跳过第一个对象，即昨天）
                    ...forecast15d.skip(1).toList().asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key + 1; // 保持原始索引
                      final day = entry.value;
                      return buildForecastCard(day, weatherProvider, index);
                    }),
                  ],
                ),
              ),
              AppColors.cardSpacingWidget,
            ],

            const SizedBox(height: 80), // Space for bottom buttons
          ],
        ),
      ),
    );
  }

  /// 第三个标签页：预警信息（AI总结）
  Widget _buildAlertsTab(WeatherProvider weatherProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(
          cityName,
          forceRefreshAI: true,
        );
      },
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenHorizontalPadding,
          vertical: 16,
        ),
        child: Column(
          children: [
            // AI智能助手（24小时天气总结） - 使用渐进式展示
            AIContentWidget(
              title: 'AI智能助手',
              icon: Icons.auto_awesome,
              cityName: cityName, // 传入城市名称
              refreshKey: weatherProvider
                  .currentWeather
                  ?.current
                  ?.current
                  ?.reporttime, // 使用报告时间作为刷新键
              fetchAIContent: () async {
                try {
                  // 如果已有内容，直接返回
                  if (weatherProvider.weatherSummary != null &&
                      weatherProvider.weatherSummary!.isNotEmpty) {
                    return weatherProvider.weatherSummary!;
                  }

                  // 如果正在生成中，等待一下再检查
                  if (weatherProvider.isGeneratingSummary) {
                    print('⏳ AI摘要正在生成中，等待完成...');
                    // 等待最多5秒
                    for (int i = 0; i < 50; i++) {
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (weatherProvider.weatherSummary != null &&
                          weatherProvider.weatherSummary!.isNotEmpty) {
                        return weatherProvider.weatherSummary!;
                      }
                      if (!weatherProvider.isGeneratingSummary) {
                        break; // 生成完成，跳出循环
                      }
                    }
                  }

                  // 如果仍然没有内容且不在生成中，尝试生成一次
                  if ((weatherProvider.weatherSummary == null ||
                          weatherProvider.weatherSummary!.isEmpty) &&
                      !weatherProvider.isGeneratingSummary) {
                    print('🔄 开始生成城市天气AI摘要: $cityName');
                    await weatherProvider.generateWeatherSummary(
                      cityName: cityName, // 传入城市名称
                    );
                  }

                  // 最终检查
                  if (weatherProvider.weatherSummary != null &&
                      weatherProvider.weatherSummary!.isNotEmpty) {
                    return weatherProvider.weatherSummary!;
                  }

                  // 如果仍然没有内容，返回默认内容而不是抛出异常
                  print('⚠️ 无法获取AI摘要，使用默认内容');
                  return '今日天气舒适，适合出行。注意温差变化，合理增减衣物。';
                } catch (e) {
                  print('❌ 加载AI智能助手失败: $e');
                  // 返回默认内容而不是抛出异常，避免无限重试
                  return '今日天气舒适，适合出行。注意温差变化，合理增减衣物。';
                }
              },
              defaultContent: '今日天气舒适，适合出行。注意温差变化，合理增减衣物。',
            ),
            AppColors.cardSpacingWidget,

            // 15日天气AI总结 - 使用渐进式展示
            AIContentWidget(
              title: '15日天气趋势',
              icon: Icons.trending_up,
              cityName: cityName, // 传入城市名称
              refreshKey: weatherProvider
                  .currentWeather
                  ?.current
                  ?.current
                  ?.reporttime, // 使用报告时间作为刷新键
              fetchAIContent: () async {
                try {
                  // 如果已有内容，直接返回
                  if (weatherProvider.forecast15dSummary != null &&
                      weatherProvider.forecast15dSummary!.isNotEmpty) {
                    return weatherProvider.forecast15dSummary!;
                  }

                  // 如果正在生成中，等待一下再检查
                  if (weatherProvider.isGenerating15dSummary) {
                    print('⏳ 15日AI总结正在生成中，等待完成...');
                    // 等待最多5秒
                    for (int i = 0; i < 50; i++) {
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (weatherProvider.forecast15dSummary != null &&
                          weatherProvider.forecast15dSummary!.isNotEmpty) {
                        return weatherProvider.forecast15dSummary!;
                      }
                      if (!weatherProvider.isGenerating15dSummary) {
                        break; // 生成完成，跳出循环
                      }
                    }
                  }

                  // 如果仍然没有内容且不在生成中，尝试生成一次
                  if ((weatherProvider.forecast15dSummary == null ||
                          weatherProvider.forecast15dSummary!.isEmpty) &&
                      !weatherProvider.isGenerating15dSummary) {
                    print('🔄 开始生成城市15日天气AI总结: $cityName');
                    await weatherProvider.generateForecast15dSummary(
                      cityName: cityName, // 传入城市名称
                    );
                  }

                  // 最终检查
                  if (weatherProvider.forecast15dSummary != null &&
                      weatherProvider.forecast15dSummary!.isNotEmpty) {
                    return weatherProvider.forecast15dSummary!;
                  }

                  // 如果仍然没有内容，返回默认内容而不是抛出异常
                  print('⚠️ 无法获取15日AI总结，使用默认内容');
                  return '未来半月天气平稳，温度变化不大，适合安排户外活动。';
                } catch (e) {
                  print('❌ 加载15日天气趋势失败: $e');
                  // 返回默认内容而不是抛出异常，避免无限重试
                  return '未来半月天气平稳，温度变化不大，适合安排户外活动。';
                }
              },
              defaultContent: '未来半月天气平稳，温度变化不大，适合安排户外活动。',
            ),
          ],
        ),
      ),
    );
  }
}
