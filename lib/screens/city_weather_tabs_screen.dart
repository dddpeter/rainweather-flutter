import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/weather_chart.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/life_index_widget.dart';
import '../widgets/weather_animation_widget.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/hourly_list.dart';
import '../widgets/forecast15d_chart.dart';
import '../widgets/weather_details_widget.dart';
import '../widgets/ai_content_widget.dart';
import '../models/weather_model.dart';
import 'weather_alerts_screen.dart';

class CityWeatherTabsScreen extends StatefulWidget {
  final String cityName;

  const CityWeatherTabsScreen({super.key, required this.cityName});

  @override
  State<CityWeatherTabsScreen> createState() => _CityWeatherTabsScreenState();
}

class _CityWeatherTabsScreenState extends State<CityWeatherTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 获取指定城市的天气数据（包含日出日落和生活指数数据）
      await context.read<WeatherProvider>().getWeatherForCity(widget.cityName);
    });
  }

  @override
  void didUpdateWidget(CityWeatherTabsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果城市名称发生变化，重新获取天气数据
    if (oldWidget.cityName != widget.cityName) {
      print(
        '🏙️ CityWeatherTabsScreen: City changed from ${oldWidget.cityName} to ${widget.cityName}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<WeatherProvider>().getWeatherForCity(
          widget.cityName,
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                              onPressed: () => weatherProvider
                                  .getWeatherForCity(widget.cityName),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // 顶部天气信息区域
                        _buildTopWeatherSection(weatherProvider),

                        // 标签页
                        Container(
                          color: AppColors.backgroundPrimary,
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: AppColors.primaryBlue,
                            labelColor: AppColors.textPrimary,
                            unselectedLabelColor: AppColors.textSecondary,
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
                            controller: _tabController,
                            children: [
                              _buildCurrentWeatherTab(weatherProvider),
                              _buildForecastTab(weatherProvider),
                              _buildAlertsTab(weatherProvider),
                            ],
                          ),
                        ),
                      ],
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
                  // 预警图标
                  _buildAlertIcon(context, weatherProvider),
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
                          '${current?.temperature ?? '--'}℃',
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
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 农历日期
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

  // 第一个标签页：当前天气
  Widget _buildCurrentWeatherTab(WeatherProvider weatherProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(
          widget.cityName,
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
            _buildAirQualityCard(weatherProvider),
            AppColors.cardSpacingWidget,
            // 今日提醒卡片（在详细信息前面）
            _buildWeatherTipsCard(weatherProvider),
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
            _buildTemperatureChart(weatherProvider),
            const SizedBox(height: 80), // Space for bottom buttons
          ],
        ),
      ),
    );
  }

  // 第二个标签页：24小时和15日预报
  Widget _buildForecastTab(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final hourlyForecast = weather?.forecast24h ?? [];
    final forecast15d = weather?.forecast15d ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(
          widget.cityName,
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
                      return _buildForecastCard(day, weatherProvider, index);
                    }).toList(),
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

  // 第三个标签页：预警信息
  Widget _buildAlertsTab(WeatherProvider weatherProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(
          widget.cityName,
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
              fetchAIContent: () async {
                if (weatherProvider.weatherSummary != null) {
                  return weatherProvider.weatherSummary!;
                }
                await weatherProvider.generateWeatherSummary();
                return weatherProvider.weatherSummary ?? '';
              },
              defaultContent: '今日天气舒适，适合出行。注意温差变化，合理增减衣物。',
            ),
            AppColors.cardSpacingWidget,

            // 15日天气AI总结 - 使用渐进式展示
            AIContentWidget(
              title: '15日天气趋势',
              icon: Icons.trending_up,
              fetchAIContent: () async {
                if (weatherProvider.forecast15dSummary != null) {
                  return weatherProvider.forecast15dSummary!;
                }
                await weatherProvider.generateForecast15dSummary();
                return weatherProvider.forecast15dSummary ?? '';
              },
              defaultContent: '未来半月天气平稳，温度变化不大，适合安排户外活动。',
            ),
          ],
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

  /// 构建空气质量卡片
  Widget _buildAirQualityCard(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final air = weather?.current?.air ?? weather?.air;

    if (air == null) {
      return const SizedBox.shrink();
    }

    final aqi = int.tryParse(air.AQI ?? '');
    if (aqi == null) {
      return const SizedBox.shrink();
    }

    final level = air.levelIndex ?? _getAirQualityLevelText(aqi);
    final color = _getAirQualityColor(aqi);

    // 计算标尺位置（0-500范围）
    final progress = (aqi / 500).clamp(0.0, 1.0);

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Icon(
                    Icons.air,
                    color: color,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '空气质量',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // AQI数值
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$aqi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    level,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 空气质量标尺
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标尺背景和进度
                  Stack(
                    children: [
                      // 彩色渐变背景（6段）
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.airExcellent, // 优 0-50
                              AppColors.airGood, // 良 50-100
                              AppColors.airLight, // 轻度污染 100-150
                              AppColors.airModerate, // 中度污染 150-200
                              AppColors.airHeavy, // 重度污染 200-300
                              AppColors.airSevere, // 严重污染 300-500
                            ],
                            stops: [0.0, 0.1, 0.2, 0.4, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // 当前位置指示器
                      Positioned(
                        left:
                            progress * (MediaQuery.of(context).size.width - 64),
                        top: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 刻度标签
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScaleLabel('0'),
                      _buildScaleLabel('50'),
                      _buildScaleLabel('100'),
                      _buildScaleLabel('150'),
                      _buildScaleLabel('200'),
                      _buildScaleLabel('300+'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 等级说明 - 平均分布占满一行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildLevelTag('优', AppColors.airExcellent)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('良', AppColors.airGood)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('轻度', AppColors.airLight)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('中度', AppColors.airModerate)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('重度', AppColors.airHeavy)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildLevelTag('严重', AppColors.airSevere)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建刻度标签
  Widget _buildScaleLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 构建等级标签
  Widget _buildLevelTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 获取空气质量等级文本
  String _getAirQualityLevelText(int aqi) {
    if (aqi <= 50) return '优';
    if (aqi <= 100) return '良';
    if (aqi <= 150) return '轻度污染';
    if (aqi <= 200) return '中度污染';
    if (aqi <= 300) return '重度污染';
    return '严重污染';
  }

  /// 获取空气质量颜色
  Color _getAirQualityColor(int aqi) {
    if (aqi <= 50) return AppColors.airExcellent; // 优
    if (aqi <= 100) return AppColors.airGood; // 良
    if (aqi <= 150) return AppColors.airLight; // 轻度污染
    if (aqi <= 200) return AppColors.airModerate; // 中度污染
    if (aqi <= 300) return AppColors.airHeavy; // 重度污染
    return AppColors.airSevere; // 严重污染
  }

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

              if (tips != null) ...[
                _buildTipItem(Icons.wb_sunny_rounded, tips, AppColors.warning),
                const SizedBox(height: 12),
              ],

              if (current?.temperature != null)
                _buildTipItem(
                  Icons.checkroom_rounded,
                  _getClothingSuggestion(
                    current!.temperature!,
                    current.weather,
                  ),
                  const Color(0xFF64DD17), // 绿色（避免使用蓝色系）
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text, Color color) {
    final themeProvider = context.read<ThemeProvider>();
    // 根据传入的color判断是橙色还是绿色
    final isOrange = color == AppColors.warning || color.value == 0xFFFFB74D;

    // 根据颜色和主题决定样式
    Color backgroundColor;
    Color iconColor;
    Color textColor;
    double iconBackgroundOpacity;

    // 背景色的基础颜色（主题深蓝或橄榄绿）
    final baseColor = isOrange
        ? const Color(0xFF012d78) // 主题深蓝
        : const Color(0xFF6B8E23); // 橄榄绿

    if (themeProvider.isLightTheme) {
      // 亮色模式：图标主题深蓝色，背景保持深蓝/橄榄绿半透明，文字主题深蓝
      iconColor = const Color(0xFF012d78); // 图标主题深蓝色
      backgroundColor = baseColor.withOpacity(0.25); // 背景保持深蓝/橄榄绿半透明
      textColor = const Color(0xFF012d78); // 主题深蓝字
      iconBackgroundOpacity = 0.2;
    } else {
      // 暗色模式：图标白色，背景橙/绿半透明，文字白色
      iconColor = Colors.white; // 图标白色
      backgroundColor = color.withOpacity(0.25); // 背景橙/绿半透明
      textColor = AppColors.textPrimary; // 白字
      iconBackgroundOpacity = 0.3;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              themeProvider.isLightTheme ? 0.08 : 0.15,
            ),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(iconBackgroundOpacity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor, // 使用配对的文字颜色
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getClothingSuggestion(String temperature, String? weather) {
    try {
      final temp = int.parse(temperature);
      final hasRain = weather?.contains('雨') ?? false;
      final hasSnow = weather?.contains('雪') ?? false;

      String suggestion = '';

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

  Widget _buildForecastCard(
    DailyWeather day,
    WeatherProvider weatherProvider,
    int index,
  ) {
    // 根据实际日期判断今天和明天
    final isToday = _isToday(day.forecasttime ?? '');
    final isTomorrow = _isTomorrow(day.forecasttime ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
    // 判断是白天还是夜间（根据时段）
    // 注意：上午使用pm数据（夜间），下午使用am数据（白天）
    final isNight = period == '上午';

    // 获取中文天气图标路径
    String getChineseWeatherIcon(String weatherType, bool isNight) {
      final iconMap = isNight
          ? AppConstants.chineseNightWeatherImages
          : AppConstants.chineseWeatherImages;
      return iconMap[weatherType] ?? iconMap['晴'] ?? '晴.png';
    }

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
            // Weather icon - 使用中文PNG图标
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/${getChineseWeatherIcon(weather, isNight)}',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // 加载失败时显示默认图标
                  return Image.asset(
                    'assets/images/不清楚.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            // Temperature
            Text(
              '${_formatNumber(temperature)}℃',
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

  /// 格式化数值，去掉小数位
  String _formatNumber(dynamic value) {
    if (value == null) return '--';

    if (value is String) {
      // 如果是字符串，尝试转换为数字
      final numValue = double.tryParse(value);
      if (numValue != null) {
        return numValue.toInt().toString();
      }
      return value;
    }

    if (value is num) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  /// 构建气象预警图标按钮（仅显示原始预警，与主要城市列表卡片一致）
  Widget _buildAlertIcon(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    final weather = weatherProvider.currentWeather;

    // 获取气象预警（原始预警数据，来自天气API）
    final alerts = weather?.current?.alerts;

    // 过滤掉过期的预警
    final validAlerts = _filterExpiredAlerts(alerts);
    final hasValidAlerts = validAlerts.isNotEmpty;

    if (!hasValidAlerts) {
      return const SizedBox(width: 40); // 占位保持对称
    }

    // 气象预警数量
    final alertCount = validAlerts.length;

    // 显示气象预警图标
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherAlertsScreen(alerts: validAlerts),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: AppColors.titleBarIconSize,
            ),
            // 显示预警数量角标
            if (alertCount > 1)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$alertCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 过滤掉过期的气象预警
  List<WeatherAlert> _filterExpiredAlerts(List<WeatherAlert>? alerts) {
    if (alerts == null || alerts.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final validAlerts = <WeatherAlert>[];

    for (final alert in alerts) {
      // 检查预警是否有发布时间
      if (alert.publishTime == null || alert.publishTime!.isEmpty) {
        // 没有发布时间，保留
        validAlerts.add(alert);
        continue;
      }

      try {
        // 解析发布时间（格式如: "2025-10-10 08:00:00"）
        final publishTime = DateTime.parse(alert.publishTime!);

        // 预警有效期：发布后24小时内
        final expiryTime = publishTime.add(const Duration(hours: 24));

        if (now.isBefore(expiryTime)) {
          validAlerts.add(alert);
        } else {
          print('🗑️ 过滤过期预警: ${alert.type} (发布时间: ${alert.publishTime})');
        }
      } catch (e) {
        // 解析失败，保留该预警
        print('⚠️ 无法解析预警时间: ${alert.publishTime}，保留该预警');
        validAlerts.add(alert);
      }
    }

    return validAlerts;
  }
}
