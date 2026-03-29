import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/city_weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/city_weather_data.dart';
import '../models/weather_model.dart';
import '../models/sun_moon_index_model.dart';
import '../widgets/weather_chart.dart';
import '../services/weather_share_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/life_index_widget.dart';
import '../widgets/weather_animation_widget.dart';
import '../widgets/forecast15d_chart.dart';
import '../widgets/weather_details_widget.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/hourly_list.dart';
import '../widgets/common/state_widgets.dart';
import '../widgets/common/info_chip_widget.dart';
import '../widgets/weather/forecast_card_widget.dart';
import '../models/location_model.dart';
import '../utils/formatters.dart';
import '../utils/clothing_advisor.dart';
import '../services/weather_service.dart';

/// 城市天气页面 - 全新实现
/// 
/// 使用独立的 CityWeatherProvider 管理数据，不干扰当前定位城市的天气数据
class CityWeatherPage extends StatefulWidget {
  final String cityName;
  final String? cityId;

  const CityWeatherPage({
    super.key,
    required this.cityName,
    this.cityId,
  });

  @override
  State<CityWeatherPage> createState() => _CityWeatherPageState();
}

class _CityWeatherPageState extends State<CityWeatherPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WeatherService _weatherService = WeatherService.getInstance();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 加载城市天气数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCityWeather();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载城市天气数据
  Future<void> _loadCityWeather({bool forceRefresh = false}) async {
    final provider = context.read<CityWeatherProvider>();
    await provider.loadCityWeather(
      widget.cityName,
      cityId: widget.cityId,
      forceRefresh: forceRefresh,
    );

    // 预取AI摘要
    if (provider.getCityWeatherSummary(widget.cityName) == null ||
        provider.getCityWeatherSummary(widget.cityName)!.isEmpty) {
      provider.generateWeatherSummary(widget.cityName);
    }
    if (provider.getCityForecast15dSummary(widget.cityName) == null ||
        provider.getCityForecast15dSummary(widget.cityName)!.isEmpty) {
      provider.generateForecast15dSummary(widget.cityName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, CityWeatherProvider>(
      builder: (context, themeProvider, cityWeatherProvider, _) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        final cityWeatherData = cityWeatherProvider.getCityWeatherData(widget.cityName);
        final weather = cityWeatherProvider.getCityWeather(widget.cityName);
        final sunMoonIndexData = cityWeatherProvider.getCitySunMoonIndexData(widget.cityName);

        return Scaffold(
          appBar: _buildAppBar(themeProvider, cityWeatherProvider, weather),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.screenBackgroundGradient,
            ),
            child: SafeArea(
              child: _buildBody(cityWeatherProvider, cityWeatherData, weather, sunMoonIndexData),
            ),
          ),
        );
      },
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar(
    ThemeProvider themeProvider,
    CityWeatherProvider cityWeatherProvider,
    WeatherModel? weather,
  ) {
    return AppBar(
      elevation: 4,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: AppColors.appBarBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: themeProvider.getColor('border').withOpacity(0.2),
        ),
      ),
      toolbarHeight: 56,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: themeProvider.isLightTheme
              ? AppColors.primaryBlue
              : AppColors.accentBlue,
          size: 24,
        ),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: '返回',
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: themeProvider.isLightTheme
                ? AppColors.primaryBlue
                : AppColors.accentBlue,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            widget.cityName,
            style: TextStyle(
              color: themeProvider.isLightTheme
                  ? AppColors.primaryBlue
                  : AppColors.accentBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showAISummaryDialog(context, cityWeatherProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (themeProvider.isLightTheme ? AppColors.primaryBlue : AppColors.accentBlue).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (themeProvider.isLightTheme ? AppColors.primaryBlue : AppColors.accentBlue).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: themeProvider.isLightTheme ? AppColors.primaryBlue : AppColors.accentBlue, size: 11),
                  const SizedBox(width: 3),
                  Text(
                    'AI解读',
                    style: TextStyle(
                      color: themeProvider.isLightTheme ? AppColors.primaryBlue : AppColors.accentBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_rounded,
            color: themeProvider.isLightTheme
                ? AppColors.primaryBlue
                : AppColors.accentBlue,
            size: 24,
          ),
          onPressed: () => _shareWeather(cityWeatherProvider, weather),
          tooltip: '分享天气',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 构建主体内容
  Widget _buildBody(
    CityWeatherProvider cityWeatherProvider,
    CityWeatherData? cityWeatherData,
    WeatherModel? weather,
    SunMoonIndexData? sunMoonIndexData,
  ) {
    // 1. 加载中状态
    if (cityWeatherData?.isLoading == true && weather == null) {
      return const LoadingWidget();
    }

    // 2. 错误状态（且没有缓存数据）
    if (cityWeatherData?.error != null && weather == null) {
      return ErrorStateWidget(
        error: cityWeatherData!.error,
        onRetry: () => _loadCityWeather(forceRefresh: true),
      );
    }

    // 3. 空数据状态
    if (weather == null) {
      return EmptyStateWidget(
        icon: Icons.cloud_off_rounded,
        message: '暂无天气数据',
        subMessage: '无法获取 "${widget.cityName}" 的天气信息',
        onAction: () => _loadCityWeather(forceRefresh: true),
        actionText: '重试',
      );
    }

    // 4. 正常显示
    return Column(
      children: [
        // Tab栏
        _buildTabBar(),
        // Tab内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentWeatherPage(cityWeatherProvider, weather, sunMoonIndexData),
              _buildHourlyForecastPage(cityWeatherProvider, weather),
              _build15DayForecastPage(cityWeatherProvider, weather),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建 Tab 栏
  Widget _buildTabBar() {
    final themeProvider = context.read<ThemeProvider>();
    final activeColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;

    // 深色模式下使用更深的背景，让浅色文字更清晰
    final indicatorColor = themeProvider.isLightTheme
        ? activeColor.withOpacity(0.95)
        : const Color(0xFF1E3A5F).withOpacity(0.95);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      height: 40,
      decoration: BoxDecoration(
        color: themeProvider.isLightTheme
            ? Colors.grey.withOpacity(0.25)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: indicatorColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        dividerColor: Colors.transparent,
        // 深色模式：白色文字；浅色模式：白色文字
        labelColor: Colors.white,
        unselectedLabelColor: themeProvider.isLightTheme
            ? AppColors.textSecondary
            : Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: '当前天气'),
          Tab(text: '24小时'),
          Tab(text: '15日预报'),
        ],
      ),
    );
  }

  /// 构建当前天气页面
  Widget _buildCurrentWeatherPage(
    CityWeatherProvider cityWeatherProvider,
    WeatherModel weather,
    SunMoonIndexData? sunMoonIndexData,
  ) {
    return RefreshIndicator(
      onRefresh: () => _loadCityWeather(forceRefresh: true),
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 头部天气信息
            _buildTopWeatherSection(weather),
            const SizedBox(height: 16),
            // 空气质量
            AirQualityCard(weather: weather),
            AppColors.cardSpacingWidget,
            // 今日提醒
            _buildWeatherTipsCard(weather),
            AppColors.cardSpacingWidget,
            // 详细信息
            WeatherDetailsWidget(
              weather: weather,
              showAirQuality: false,
            ),
            AppColors.cardSpacingWidget,
            // 生活指数（使用新的widget，传入sunMoonIndexData）
            if (sunMoonIndexData != null)
              _buildLifeIndexWidget(sunMoonIndexData),
            AppColors.cardSpacingWidget,
            // 日出日落（使用新的widget，传入sunMoonIndexData）
            if (sunMoonIndexData != null)
              _buildSunMoonWidget(sunMoonIndexData),
            AppColors.cardSpacingWidget,
            // 温度趋势图
            _buildTemperatureChart(weather),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// 构建头部天气信息区域
  Widget _buildTopWeatherSection(WeatherModel weather) {
    final current = weather.current?.current;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.weatherHeaderCardBackground,
        image: const DecorationImage(
          image: AssetImage('assets/images/backgroud.png'),
          fit: BoxFit.cover,
          opacity: 0.25,
        ),
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
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
          child: Column(
            children: [
              // 天气动画和温度 - 与今日天气页面布局一致
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧天气动画 - 居中
                  Flexible(
                    flex: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        WeatherAnimationWidget(
                          weatherType: current?.weather ?? '晴',
                          size: 80,
                          isPlaying: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 右侧温度和天气信息 - 左对齐
                  Flexible(
                    flex: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 温度行
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Formatters.formatNumber(current?.temperature),
                              style: TextStyle(
                                color: context.read<ThemeProvider>().getColor('headerTextPrimary'),
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '℃',
                              style: TextStyle(
                                color: context.read<ThemeProvider>().getColor('headerTextPrimary'),
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // 体感温度
                        if (current?.feelstemperature != null &&
                            current?.feelstemperature != current?.temperature)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.thermostat_rounded,
                                  color: context.read<ThemeProvider>().getColor('headerTextSecondary'),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '体感 ${Formatters.formatNumber(current?.feelstemperature)}℃',
                                  style: TextStyle(
                                    color: context.read<ThemeProvider>().getColor('headerTextSecondary'),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 2),
                        // 天气文字
                        Text(
                          current?.weather ?? '晴',
                          style: TextStyle(
                            color: context.read<ThemeProvider>().getColor('headerTextSecondary'),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSimplifiedDetails(current),
              // 农历日期和节气 - 与今日天气页面一致
              if (weather.current?.nongLi != null) ...[
                const SizedBox(height: 16),
                _buildLunarAndSolarTerm(weather),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建简化的详细信息
  Widget _buildSimplifiedDetails(CurrentWeather? current) {
    if (current == null) return const SizedBox.shrink();

    return WeatherInfoRow(
      items: [
        InfoChipData(icon: Icons.water_drop, label: '湿度', value: Formatters.formatHumidity(current.humidity)),
        InfoChipData(icon: Icons.air, label: '风力', value: '${current.winddir ?? '--'} ${current.windpower ?? ''}'),
        InfoChipData(icon: Icons.compress, label: '气压', value: Formatters.formatPressure(current.airpressure)),
        InfoChipData(icon: Icons.visibility, label: '能见度', value: Formatters.formatVisibility(current.visibility)),
      ],
    );
  }

  Future<void> _showAISummaryDialog(BuildContext context, CityWeatherProvider provider) async {
    final content = provider.getCityWeatherSummary(widget.cityName);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: BoxDecoration(
              gradient: AppColors.screenBackgroundGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('AI智能助手', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      (content != null && content.isNotEmpty) ? content : '今日天气舒适，适合出行。注意温差变化，合理增减衣物。',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建天气提醒卡片
  Widget _buildWeatherTipsCard(WeatherModel weather) {
    final tips = weather.current?.tips;
    final current = weather.current?.current;

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
                  ClothingAdvisor.getSuggestion(
                    current!.temperature!,
                    current.weather,
                  ),
                  const Color(0xFF64DD17),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建提醒项
  Widget _buildTipItem(IconData icon, String text, Color color) {
    final themeProvider = context.read<ThemeProvider>();
    final isOrange = color == AppColors.warning || color.value == 0xFFFFB74D;
    final baseColor = isOrange
        ? const Color(0xFF012d78)
        : const Color(0xFF6B8E23);

    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (themeProvider.isLightTheme) {
      iconColor = const Color(0xFF012d78);
      backgroundColor = baseColor.withOpacity(0.25);
      textColor = const Color(0xFF012d78);
    } else {
      iconColor = Colors.white;
      backgroundColor = color.withOpacity(0.25);
      textColor = AppColors.textPrimary;
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
              color: iconColor.withOpacity(themeProvider.isLightTheme ? 0.2 : 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建生活指数Widget
  Widget _buildLifeIndexWidget(SunMoonIndexData sunMoonIndexData) {
    return LifeIndexWidget.custom(sunMoonIndexData: sunMoonIndexData);
  }

  /// 构建日出日落Widget
  Widget _buildSunMoonWidget(SunMoonIndexData sunMoonIndexData) {
    return SunMoonWidget.custom(sunMoonIndexData: sunMoonIndexData);
  }

  /// 构建温度趋势图表
  Widget _buildTemperatureChart(WeatherModel weather) {
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
                  dailyForecast: weather.forecast15d?.take(7).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建24小时预报页面
  Widget _buildHourlyForecastPage(
    CityWeatherProvider cityWeatherProvider,
    WeatherModel weather,
  ) {
    final hourlyForecast = weather.forecast24h ?? [];

    return RefreshIndicator(
      onRefresh: () => _loadCityWeather(forceRefresh: true),
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
                weatherService: _weatherService,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// 构建15日预报页面
  Widget _build15DayForecastPage(
    CityWeatherProvider cityWeatherProvider,
    WeatherModel weather,
  ) {
    final forecast15d = weather.forecast15d ?? [];

    return RefreshIndicator(
      onRefresh: () => _loadCityWeather(forceRefresh: true),
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 15日天气AI解读tag
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenHorizontalPadding),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.accentBlue, size: AppConstants.sectionTitleIconSize),
                  const SizedBox(width: 8),
                  Text(
                    '15日详细预报',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAI15dSummaryDialog(context, cityWeatherProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentBlue.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.accentBlue, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            'AI解读',
                            style: TextStyle(
                              color: AppColors.accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    ...forecast15d.skip(1).toList().asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final day = entry.value;
                      return ForecastCardWidget(day: day, index: index);
                    }),
                  ],
                ),
              ),
              AppColors.cardSpacingWidget,
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _showAI15dSummaryDialog(BuildContext context, CityWeatherProvider provider) async {
    final content = provider.getCityForecast15dSummary(widget.cityName);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: BoxDecoration(
              gradient: AppColors.screenBackgroundGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('15日天气趋势', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      (content != null && content.isNotEmpty) ? content : '未来半月天气平稳，温度变化不大，适合安排户外活动。',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 分享天气信息
  Future<void> _shareWeather(
    CityWeatherProvider provider,
    WeatherModel? weather,
  ) async {
    if (weather == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('天气数据加载中，请稍后再试'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final location = LocationModel(
      address: widget.cityName,
      city: widget.cityName,
      district: widget.cityName,
      province: '',
      country: '中国',
      street: '',
      adcode: '',
      town: '',
      lat: 0.0,
      lng: 0.0,
    );

    final sunMoonIndexData = provider.getCitySunMoonIndexData(widget.cityName);

    try {
      final success = await WeatherShareService.instance.generateAndSavePoster(
        context: context,
        weather: weather,
        location: location,
        themeProvider: context.read<ThemeProvider>(),
        sunMoonIndexData: sunMoonIndexData,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('生成海报失败，请稍后再试'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败：${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 构建农历和节气节日信息（头部区域）- Tag样式，与今日天气页面一致
  Widget _buildLunarAndSolarTerm(WeatherModel weather) {
    final nongLi = weather.current?.nongLi;
    if (nongLi == null) return const SizedBox.shrink();

    // 收集所有要显示的标签
    final tags = <Widget>[];

    // 农历日期
    String formattedNongLi = nongLi;
    final match = RegExp(r'^(正|二|三|四|五|六|七|八|九|十|冬|腊)(初|十|廿|卅)').hasMatch(nongLi);
    if (match && !nongLi.contains('月')) {
      if (nongLi.length >= 2) {
        final firstChar = nongLi[0];
        final rest = nongLi.substring(1);
        formattedNongLi = '$firstChar月$rest';
      }
    }

    tags.add(_buildTag(formattedNongLi, Icons.calendar_today));

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: tags,
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.read<ThemeProvider>().isLightTheme
            ? Colors.black.withOpacity(0.05)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.read<ThemeProvider>().isLightTheme
              ? Colors.black.withOpacity(0.08)
              : Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: context.read<ThemeProvider>().getColor('headerTextSecondary'),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: context.read<ThemeProvider>().getColor('headerTextSecondary'),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
