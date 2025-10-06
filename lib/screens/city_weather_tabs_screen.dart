import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
import '../models/weather_model.dart';

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

        return Scaffold(
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
                onTap: () => Navigator.pop(context),
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
                            onPressed: () => weatherProvider.getWeatherForCity(
                              widget.cityName,
                            ),
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
                            Tab(text: '预警信息'),
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
                    onTap: () => Navigator.of(context).pop(),
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
                          size: 120,
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
        await weatherProvider.getWeatherForCity(widget.cityName);
      },
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 详细信息卡片
            _buildWeatherDetails(weatherProvider),
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
        await weatherProvider.getWeatherForCity(widget.cityName);
      },
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
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
                child: Forecast15dChart(forecast15d: forecast15d),
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

                    // 15日预报列表
                    ...forecast15d.asMap().entries.map((entry) {
                      final index = entry.key;
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
    final weather = weatherProvider.currentWeather;
    final alerts = weather?.current?.alerts ?? [];

    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.accentGreen,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无预警信息',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前天气状况良好',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // 按发布时间排序，最新发布的往前放
    final sortedAlerts = List<WeatherAlert>.from(alerts);
    sortedAlerts.sort((a, b) {
      // 如果发布时间为空，放到最后
      if (a.publishTime == null && b.publishTime == null) return 0;
      if (a.publishTime == null) return 1;
      if (b.publishTime == null) return -1;

      try {
        // 尝试解析时间格式，支持多种格式
        DateTime timeA = _parseDateTime(a.publishTime!);
        DateTime timeB = _parseDateTime(b.publishTime!);
        return timeB.compareTo(timeA); // 降序：新的在前
      } catch (e) {
        // 如果解析失败，按字符串比较
        return b.publishTime!.compareTo(a.publishTime!);
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(widget.cityName);
      },
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenHorizontalPadding,
          vertical: 16,
        ),
        itemCount: sortedAlerts.length,
        itemBuilder: (context, index) {
          final alert = sortedAlerts[index];
          return _buildAlertCard(alert, index);
        },
      ),
    );
  }

  Widget _buildAlertCard(WeatherAlert alert, int index) {
    final levelColor = _getAlertLevelColor(alert.level);
    final levelBgColor = levelColor.withOpacity(0.15);

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: levelColor, width: 2),
      ),
      margin: EdgeInsets.only(bottom: AppColors.cardSpacing),
      child: InkWell(
        onTap: () => _showAlertDetailDialog(alert),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type and Level
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: levelBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAlertIcon(alert.type),
                      color: levelColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type ?? '未知类型',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: levelColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${alert.level ?? "未知"}预警',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              alert.city ?? '',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 点击提示图标
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Publish Time
              if (alert.publishTime != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '发布时间：${alert.publishTime}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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

  Widget _buildWeatherDetails(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final air = weather?.current?.air ?? weather?.air;

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
                    Icons.info_outline,
                    color: AppColors.moon,
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
                        '${_formatNumber(air.AQI)} (${air.levelIndex ?? '未知'})',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (weather?.current?.current != null)
                      Expanded(
                        child: _buildCompactDetailItem(
                          Icons.thermostat,
                          '体感温度',
                          '${_formatNumber(weather!.current!.current!.feelstemperature)}℃',
                          AppColors.cardThemeBlue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (weather?.current?.current != null) ...[
                // 第一行：湿度和气压
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.water_drop,
                        '湿度',
                        '${_formatNumber(weather!.current!.current!.humidity)}%',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.compress,
                        '气压',
                        '${_formatNumber(weather.current!.current!.airpressure)}hpa',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.visibility,
                        '能见度',
                        '${_formatNumber(weather.current!.current!.visibility)}km',
                        AppColors.cardThemeBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
    Color iconColor = _getDetailItemIconColor(icon);
    final themeProvider = context.read<ThemeProvider>();
    final backgroundOpacity = themeProvider.isLightTheme ? 0.08 : 0.25;
    final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.12 : 0.3;

    return Container(
      decoration: BoxDecoration(
        color: iconColor.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(4),
      ),
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
                    color: iconColor.withOpacity(iconBackgroundOpacity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
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
                  AppColors.primaryBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }

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

  Color _getDetailItemIconColor(IconData icon) {
    final themeProvider = context.read<ThemeProvider>();

    switch (icon) {
      case Icons.air:
        return themeProvider.isLightTheme
            ? const Color(0xFF1565C0)
            : const Color(0xFF42A5F5);
      case Icons.thermostat:
        return themeProvider.isLightTheme
            ? const Color(0xFFE53E3E)
            : const Color(0xFFFF6B6B);
      case Icons.water_drop:
        return themeProvider.isLightTheme
            ? const Color(0xFF0277BD)
            : const Color(0xFF29B6F6);
      case Icons.compress:
        return themeProvider.isLightTheme
            ? const Color(0xFF7B1FA2)
            : const Color(0xFFBA68C8);
      case Icons.visibility:
        return themeProvider.isLightTheme
            ? const Color(0xFF2E7D32)
            : const Color(0xFF4CAF50);
      default:
        return AppColors.cardThemeBlue;
    }
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

  Color _getAlertLevelColor(String? level) {
    if (level == null) return AppColors.textSecondary;

    switch (level) {
      case '红色':
        return const Color(0xFFD32F2F);
      case '橙色':
        return const Color(0xFFFF6F00);
      case '黄色':
        return const Color(0xFFF57C00);
      case '蓝色':
        return const Color(0xFF1976D2);
      default:
        return AppColors.warning;
    }
  }

  IconData _getAlertIcon(String? type) {
    if (type == null) return Icons.warning_rounded;

    if (type.contains('暴雨') || type.contains('雨')) {
      return Icons.water_drop_rounded;
    } else if (type.contains('地质') ||
        type.contains('滑坡') ||
        type.contains('泥石流')) {
      return Icons.landslide_rounded;
    } else if (type.contains('大雾') || type.contains('雾')) {
      return Icons.foggy;
    } else if (type.contains('雷') || type.contains('电')) {
      return Icons.thunderstorm_rounded;
    } else if (type.contains('台风') || type.contains('风')) {
      return Icons.air_rounded;
    } else if (type.contains('高温') || type.contains('温')) {
      return Icons.thermostat_rounded;
    } else if (type.contains('寒') || type.contains('冰') || type.contains('雪')) {
      return Icons.ac_unit_rounded;
    } else {
      return Icons.warning_rounded;
    }
  }

  void _showAlertDetailDialog(WeatherAlert alert) {
    final levelColor = _getAlertLevelColor(alert.level);
    final levelBgColor = levelColor.withOpacity(0.15);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: levelBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAlertIcon(alert.type),
                  color: levelColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.type ?? '未知类型',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: levelColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${alert.level ?? "未知"}预警',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          alert.city ?? '',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 发布时间
                if (alert.publishTime != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '发布时间：${alert.publishTime}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 详细内容
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.borderColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: levelColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    alert.content ?? '暂无详细内容',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '关闭',
                style: TextStyle(
                  color: levelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Text(
                weatherProvider.getWeatherIcon(weather),
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
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

  /// 解析时间字符串，支持多种格式
  DateTime _parseDateTime(String timeString) {
    // 尝试多种时间格式
    final formats = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy/MM/dd HH:mm',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'MM-dd HH:mm',
      'MM/dd HH:mm',
    ];

    for (String format in formats) {
      try {
        // 使用 intl 包的 DateFormat 来解析
        final dateFormat = DateFormat(format);
        return dateFormat.parse(timeString);
      } catch (e) {
        // 继续尝试下一个格式
        continue;
      }
    }

    // 如果所有格式都失败，尝试直接解析
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      // 如果还是失败，返回当前时间
      return DateTime.now();
    }
  }
}
