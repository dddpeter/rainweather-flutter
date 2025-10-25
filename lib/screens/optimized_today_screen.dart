import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider_simplified.dart';
import '../providers/theme_provider.dart';
import '../widgets/weather_chart.dart';
import '../widgets/hourly_weather_widget.dart';
import '../services/weather_service.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../widgets/sun_moon_widget.dart';
// import '../widgets/life_index_widget.dart';
import '../widgets/weather_animation_widget.dart';
// import '../widgets/weather_alert_widget.dart';
import '../widgets/ai_smart_assistant_widget.dart';
import '../services/weather_alert_service.dart';
// import '../services/database_service.dart';
import '../services/location_change_notifier.dart';
import '../services/page_activation_observer.dart';
import '../services/lunar_service.dart';
import '../widgets/lunar_info_widget.dart';
import '../widgets/weather_details_widget.dart';
import '../widgets/air_quality_card.dart';
// import '../utils/weather_icon_helper.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';
import '../widgets/error_dialog.dart';
import 'hourly_screen.dart';

/// 优化后的今日天气页面 - 使用Selector精确监听状态变化
class OptimizedTodayScreen extends StatefulWidget {
  const OptimizedTodayScreen({super.key});

  @override
  State<OptimizedTodayScreen> createState() => _OptimizedTodayScreenState();
}

class _OptimizedTodayScreenState extends State<OptimizedTodayScreen>
    with
        WidgetsBindingObserver,
        LocationChangeListener,
        PageActivationMixin,
        AutomaticKeepAliveClientMixin {
  // bool _isVisible = false;
  final WeatherAlertService _alertService = WeatherAlertService.instance;
  // bool _isRefreshing = false;

  // 定时刷新相关
  // Timer? _refreshTimer;
  // static const Duration _refreshInterval = Duration(minutes: 30);
  // bool _isAppInBackground = false;

  @override
  bool get wantKeepAlive => true; // 保持页面状态

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _alertService.initialize();

    // 添加定位变化监听器
    Logger.d('开始注册定位变化监听器', tag: 'OptimizedTodayScreen');
    LocationChangeNotifier().addListener(this);
    Logger.d('定位变化监听器注册完成', tag: 'OptimizedTodayScreen');

    // 注册页面激活监听器
    PageActivationObserver().addListener(this);

    // 首次进入今日天气页面时，自动刷新当前定位和数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentLocationAndWeather();
    });

    // 启动定时刷新
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _stopPeriodicRefresh();
    WidgetsBinding.instance.removeObserver(this);
    LocationChangeNotifier().removeListener(this);
    PageActivationObserver().removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持AutomaticKeepAlive

    return Selector<ThemeProvider, ThemeProvider>(
      selector: (context, themeProvider) => themeProvider,
      builder: (context, themeProvider, child) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Selector<
          WeatherProviderSimplified,
          ({
            WeatherModel? currentWeather,
            LocationModel? currentLocation,
            bool isLoading,
            String? error,
            bool isUsingCachedData,
            bool isBackgroundRefreshing,
          })
        >(
          selector: (context, weatherProvider) => (
            currentWeather: weatherProvider.currentWeather,
            currentLocation: weatherProvider.currentLocation,
            isLoading: weatherProvider.isLoading,
            error: weatherProvider.error,
            isUsingCachedData: weatherProvider.isUsingCachedData,
            isBackgroundRefreshing: weatherProvider.isBackgroundRefreshing,
          ),
          builder: (context, data, child) {
            return Container(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Builder(
                builder: (context) {
                  if (data.currentWeather == null && data.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentBlue,
                      ),
                    );
                  }

                  if (data.error != null && data.currentWeather == null) {
                    return _buildErrorWidget(data.error!);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      if (Platform.isIOS) {
                        HapticFeedback.mediumImpact();
                      }
                      await context
                          .read<WeatherProviderSimplified>()
                          .refreshWeatherData();
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
                          _buildTopWeatherSection(
                            data.currentWeather,
                            data.currentLocation,
                          ),
                          AppColors.cardSpacingWidget,
                          // AI智能助手卡片
                          AISmartAssistantWidget(
                            key: const ValueKey(
                              'optimized_today_ai_smart_assistant',
                            ),
                          ),
                          AppColors.cardSpacingWidget,
                          // 空气质量卡片
                          AirQualityCard(weather: data.currentWeather),
                          AppColors.cardSpacingWidget,
                          // 24小时天气
                          _buildHourlyWeather(data.currentWeather),
                          AppColors.cardSpacingWidget,
                          // 详细信息卡片
                          WeatherDetailsWidget(weather: data.currentWeather),
                          AppColors.cardSpacingWidget,
                          // 生活指数
                          // LifeIndexWidget(
                          //   weatherProvider: context
                          //       .read<WeatherProviderSimplified>(),
                          // ),
                          AppColors.cardSpacingWidget,
                          const SunMoonWidget(),
                          AppColors.cardSpacingWidget,
                          _buildTemperatureChart(data.currentWeather),
                          AppColors.cardSpacingWidget,
                          // 农历信息
                          _buildLunarInfo(),
                          AppColors.cardSpacingWidget,
                          // 宜忌信息
                          _buildYiJiInfo(),
                          AppColors.cardSpacingWidget,
                          // 即将到来的节气
                          _buildUpcomingSolarTerms(),
                          const SizedBox(
                            height: 80,
                          ), // Space for bottom buttons
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// 构建错误Widget
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _handleRefreshWithFeedback(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('重试'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showErrorDialog(context, error),
            child: Text(
              '查看详细错误信息',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部天气区域
  Widget _buildTopWeatherSection(
    WeatherModel? weather,
    LocationModel? location,
  ) {
    final current = weather?.current?.current;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.weatherHeaderCardBackground,
        image: const DecorationImage(
          image: AssetImage('assets/images/backgroud.png'),
          fit: BoxFit.cover,
          opacity: 0.4,
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
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              // 城市名称和菜单
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 主题切换按钮
                  _buildThemeToggleButton(context),
                  Expanded(
                    child: Center(
                      child: Text(
                        _getDisplayCity(location),
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
                  // 告警图标或右侧占位
                  _buildAlertButton(),
                ],
              ),
              const SizedBox(height: 40),

              // 天气动画和温度
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左侧天气动画区域
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
                  // 右侧温度和天气汉字区域
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
            ],
          ),
        ),
      ),
    );
  }

  /// 构建主题切换按钮
  Widget _buildThemeToggleButton(BuildContext context) {
    return Selector<ThemeProvider, bool>(
      selector: (context, themeProvider) => themeProvider.isLightTheme,
      builder: (context, isLightTheme, child) {
        return SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: Icon(
              isLightTheme ? Icons.dark_mode : Icons.light_mode,
              color: context.read<ThemeProvider>().getColor(
                'headerTextPrimary',
              ),
              size: 24,
            ),
            onPressed: () {
              if (Platform.isIOS) {
                HapticFeedback.mediumImpact();
              }
              context.read<ThemeProvider>().setThemeMode(
                isLightTheme ? AppThemeMode.dark : AppThemeMode.light,
              );
            },
            padding: EdgeInsets.zero,
            tooltip: isLightTheme ? '切换到暗色模式' : '切换到亮色模式',
          ),
        );
      },
    );
  }

  /// 构建告警按钮
  Widget _buildAlertButton() {
    return const SizedBox(width: 40); // 占位保持对称
  }

  /// 构建24小时天气
  Widget _buildHourlyWeather(WeatherModel? weather) {
    final weatherService = WeatherService.getInstance();
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: HourlyWeatherWidget(
        hourlyForecast: weather?.forecast24h,
        weatherService: weatherService,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HourlyScreen()),
          );
        },
      ),
    );
  }

  /// 构建温度趋势图
  Widget _buildTemperatureChart(WeatherModel? weather) {
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
                  dailyForecast: weather?.forecast15d?.take(7).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建农历信息
  Widget _buildLunarInfo() {
    try {
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(DateTime.now());
      return LunarInfoWidget(lunarInfo: lunarInfo);
    } catch (e) {
      Logger.e('获取农历信息失败: $e', tag: 'OptimizedTodayScreen');
      return const SizedBox.shrink();
    }
  }

  /// 构建宜忌信息
  Widget _buildYiJiInfo() {
    try {
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(DateTime.now());
      return YiJiWidget(lunarInfo: lunarInfo);
    } catch (e) {
      Logger.e('获取宜忌信息失败: $e', tag: 'OptimizedTodayScreen');
      return const SizedBox.shrink();
    }
  }

  /// 构建即将到来的节气
  Widget _buildUpcomingSolarTerms() {
    try {
      final lunarService = LunarService.getInstance();
      final upcomingTerms = lunarService.getUpcomingSolarTerms(days: 60);

      if (upcomingTerms.isEmpty) {
        return const SizedBox.shrink();
      }

      return SolarTermListWidget(solarTerms: upcomingTerms, title: '即将到来的节气');
    } catch (e) {
      Logger.e('获取节气信息失败: $e', tag: 'OptimizedTodayScreen');
      return const SizedBox.shrink();
    }
  }

  /// 获取显示城市名称
  String _getDisplayCity(LocationModel? location) {
    if (location == null) {
      return AppConstants.defaultCity;
    }

    if (location.district.isNotEmpty && location.district != '未知') {
      return location.district;
    } else if (location.city.isNotEmpty && location.city != '未知') {
      return location.city;
    } else if (location.province.isNotEmpty && location.province != '未知') {
      return location.province;
    } else {
      return AppConstants.defaultCity;
    }
  }

  /// 处理刷新按钮点击
  Future<void> _handleRefreshWithFeedback(BuildContext context) async {
    try {
      await context.read<WeatherProviderSimplified>().refreshWeatherData();
    } catch (e) {
      Logger.e('刷新失败: ${e.toString()}', tag: 'OptimizedTodayScreen');
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(BuildContext context, String error) {
    AppErrorType errorType = AppErrorType.unknown;
    if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('timeout')) {
      errorType = AppErrorType.network;
    } else if (error.toLowerCase().contains('location') ||
        error.toLowerCase().contains('gps')) {
      errorType = AppErrorType.location;
    } else if (error.toLowerCase().contains('permission')) {
      errorType = AppErrorType.permission;
    }

    ErrorDialog.show(
      context: context,
      title: '加载失败',
      message: error,
      errorType: errorType,
      onRetry: () {
        Navigator.of(context).pop();
        _handleRefreshWithFeedback(context);
      },
      retryText: '重试',
    );
  }

  // 其他必要的方法实现...
  void _refreshCurrentLocationAndWeather() {
    // 实现刷新逻辑
  }

  void _startPeriodicRefresh() {
    // 实现定时刷新逻辑
  }

  void _stopPeriodicRefresh() {
    // 实现停止定时刷新逻辑
  }

  @override
  void onPageActivated() {
    // 实现页面激活逻辑
  }

  @override
  void onPageDeactivated() {
    // 实现页面停用逻辑
  }

  @override
  void onLocationSuccess(LocationModel newLocation) {
    // 实现定位成功逻辑
  }

  @override
  void onLocationFailed(String error) {
    // 实现定位失败逻辑
  }
}
