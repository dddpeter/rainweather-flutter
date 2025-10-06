import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/weather_chart.dart';
import '../widgets/hourly_weather_widget.dart';
import '../services/weather_service.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../models/location_model.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/life_index_widget.dart';
import '../widgets/weather_animation_widget.dart';
import '../widgets/app_menu.dart';
import '../widgets/weather_alert_widget.dart';
import '../services/weather_alert_service.dart';
import '../services/location_change_notifier.dart';
import 'hourly_screen.dart';
import 'weather_alerts_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with WidgetsBindingObserver, LocationChangeListener {
  bool _isVisible = false;
  final WeatherAlertService _alertService = WeatherAlertService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化天气提醒服务
    _alertService.initialize();

    // 添加定位变化监听器
    print('📍 TodayScreen: 开始注册定位变化监听器');
    LocationChangeNotifier().addListener(this);
    print('📍 TodayScreen: 定位变化监听器注册完成');
    // 调试：打印当前监听器状态
    LocationChangeNotifier().debugPrintStatus();

    // 首次进入今日天气页面时，自动刷新当前定位和数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentLocationAndWeather();
    });
  }

  /// 刷新当前定位和天气数据
  Future<void> _refreshCurrentLocationAndWeather() async {
    try {
      print('🔄 TodayScreen: 首次进入，开始定位和刷新天气数据');

      final weatherProvider = context.read<WeatherProvider>();

      // 调用新的定位方法（内部会检查是否首次定位）
      await weatherProvider.performLocationAfterEntering();

      print('✅ TodayScreen: 当前定位和天气数据刷新完成');
    } catch (e) {
      print('❌ TodayScreen: 刷新当前定位和天气数据失败: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 移除定位变化监听器
    print('📍 TodayScreen: 开始移除定位变化监听器');
    LocationChangeNotifier().removeListener(this);
    print('📍 TodayScreen: 定位变化监听器移除完成');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 这个回调在应用生命周期变化时被调用，但不适合我们的场景
  }

  /// 定位成功回调
  @override
  void onLocationSuccess(LocationModel newLocation) {
    print('📍 TodayScreen: 收到定位成功通知 ${newLocation.district}');
    print(
      '📍 TodayScreen: 定位详情 - 城市: ${newLocation.city}, 区县: ${newLocation.district}, 省份: ${newLocation.province}',
    );
    print('📍 TodayScreen: 页面可见状态: $_isVisible');

    // 如果页面可见，刷新天气数据
    if (_isVisible) {
      print('📍 TodayScreen: 页面可见，准备刷新天气数据');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshWeatherData();
      });
    } else {
      print('📍 TodayScreen: 页面不可见，跳过刷新');
    }
  }

  /// 定位失败回调
  @override
  void onLocationFailed(String error) {
    print('❌ TodayScreen: 收到定位失败通知 $error');
    print('❌ TodayScreen: 页面可见状态: $_isVisible');

    // 如果页面可见，可以显示错误信息
    if (_isVisible) {
      print('❌ TodayScreen: 页面可见，显示错误信息');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('定位失败: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      });
    } else {
      print('❌ TodayScreen: 页面不可见，跳过显示错误信息');
    }
  }

  /// 刷新天气数据
  Future<void> _refreshWeatherData() async {
    try {
      print('🔄 TodayScreen: 开始刷新天气数据');
      final weatherProvider = context.read<WeatherProvider>();
      print('🔄 TodayScreen: 调用 WeatherProvider.refreshWeatherData()');
      await weatherProvider.refreshWeatherData();
      print('✅ TodayScreen: 天气数据刷新完成');
    } catch (e) {
      print('❌ TodayScreen: 刷新天气数据失败: $e');
      print('❌ TodayScreen: 错误堆栈: ${StackTrace.current}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 检查当前页面是否可见
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = Navigator.of(context);
      final canPop = navigator.canPop();
      _isVisible = !canPop; // 如果无法弹出，说明是主页面
      print(
        '📱 TodayScreen didChangeDependencies - _isVisible: $_isVisible, canPop: $canPop',
      );
    });
  }

  @override
  void didUpdateWidget(TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('=== TodayScreen didUpdateWidget called ===');
    // 简化逻辑：直接尝试恢复，由WeatherProvider内部判断是否需要恢复
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
        'TodayScreen didUpdateWidget - calling restoreCurrentLocationWeather',
      );
      context.read<WeatherProvider>().restoreCurrentLocationWeather();
    });
  }

  String _getDisplayCity(LocationModel? location) {
    if (location == null) {
      return AppConstants.defaultCity;
    }

    // 调试信息
    print(
      'Location debug: district=${location.district}, city=${location.city}, province=${location.province}',
    );

    // 优先显示district，如果为空则显示city，最后显示province
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
            child: Consumer<WeatherProvider>(
              builder: (context, weatherProvider, child) {
                print('🔥 TodayScreen build called 🔥');
                print(
                  '🌡️ Current weather temp: ${weatherProvider.currentWeather?.current?.current?.temperature}',
                );
                print(
                  '📍 Current location: ${weatherProvider.currentLocation?.district}',
                );
                print(
                  '🏠 Original location: ${weatherProvider.originalLocation?.district}',
                );
                print(
                  '💾 Current location weather: ${weatherProvider.currentLocationWeather != null}',
                );

                // 检查是否需要恢复当前定位数据
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // 使用标签页索引来判断当前是否在今日页面
                  final isTodayTab = weatherProvider.currentTabIndex == 0;
                  final navigator = Navigator.of(context);
                  final canPop = navigator.canPop();

                  // 更新可见性状态
                  _isVisible = !canPop;

                  print(
                    '📱 TodayScreen build - tabIndex: ${weatherProvider.currentTabIndex}, isTodayTab: $isTodayTab',
                  );

                  // 如果当前在今日页面且显示的是城市数据，则恢复
                  if (isTodayTab &&
                      weatherProvider.currentLocationWeather != null &&
                      weatherProvider.originalLocation != null &&
                      weatherProvider.isShowingCityWeather) {
                    print(
                      '=== TodayScreen build - checking if restore needed ===',
                    );
                    print(
                      '🔍 isShowingCityWeather: ${weatherProvider.isShowingCityWeather}',
                    );
                    print(
                      '📱 _isVisible: $_isVisible, canPop: $canPop, isTodayTab: $isTodayTab',
                    );
                    print(
                      'Current location: ${weatherProvider.currentLocation?.district}',
                    );
                    print(
                      'Original location: ${weatherProvider.originalLocation?.district}',
                    );
                    print(
                      '=== TodayScreen build - calling restoreCurrentLocationWeather ===',
                    );
                    weatherProvider.restoreCurrentLocationWeather();
                  } else {
                    print(
                      '🚫 TodayScreen build - no restore needed: isTodayTab=$isTodayTab, _isVisible=$_isVisible, canPop=$canPop, isShowingCityWeather=${weatherProvider.isShowingCityWeather}',
                    );
                  }
                });

                if (weatherProvider.isLoading &&
                    weatherProvider.currentWeather == null) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentBlue,
                    ),
                  );
                }

                if (weatherProvider.error != null &&
                    weatherProvider.currentWeather == null) {
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
                          weatherProvider.error!,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _handleRefreshWithFeedback(
                            context,
                            weatherProvider,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: AppColors.textPrimary,
                          ),
                          child: Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await weatherProvider.refreshWeatherData();
                    // 刷新天气数据后分析提醒
                    if (weatherProvider.currentWeather != null &&
                        weatherProvider.currentLocation != null) {
                      await _alertService.analyzeWeather(
                        weatherProvider.currentWeather!,
                        weatherProvider.currentLocation!,
                      );
                      setState(() {}); // 刷新UI显示提醒
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
                        // 天气提醒卡片 - 放在详细信息卡片之前
                        _buildWeatherAlertCard(weatherProvider),
                        // 只有在有提醒时才显示间距
                        if (_alertService
                            .getAlertsForCity(
                              _getDisplayCity(weatherProvider.currentLocation),
                            )
                            .isNotEmpty)
                          AppColors.cardSpacingWidget,
                        // 24小时天气
                        _buildHourlyWeather(weatherProvider),
                        AppColors.cardSpacingWidget,
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
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopWeatherSection(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final location = weatherProvider.currentLocation;
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
              // City name and menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppMenu(), // 菜单按钮
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _getDisplayCity(location),
                            style: TextStyle(
                              color: context.read<ThemeProvider>().getColor(
                                'headerTextPrimary',
                              ),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (location?.isProxyDetected == true) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '可能使用代理',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // 告警图标或右侧占位
                  _buildAlertButton(weatherProvider),
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
                          size: 120, // 从100增大到120
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
            MaterialPageRoute(builder: (context) => const HourlyScreen()),
          );
        },
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
    // 根据图标类型获取对应的颜色
    Color iconColor = _getDetailItemIconColor(icon);
    final themeProvider = context.read<ThemeProvider>();
    final backgroundOpacity = themeProvider.isLightTheme ? 0.08 : 0.25;
    final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.12 : 0.3;

    return Container(
      decoration: BoxDecoration(
        color: iconColor.withOpacity(backgroundOpacity), // 根据主题调整透明度
        borderRadius: BorderRadius.circular(4), // 与今日提醒保持一致
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
                    color: iconColor.withOpacity(
                      iconBackgroundOpacity,
                    ), // 根据主题调整透明度
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor, // 使用图标颜色
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
    // 获取当前城市的提醒
    final currentCity = _getDisplayCity(weatherProvider.currentLocation);
    final smartAlerts = _alertService.getAlertsForCity(currentCity);
    final originalAlerts = weatherProvider.currentWeather?.current?.alerts;

    // 合并智能提醒和原始预警
    final allAlerts = <dynamic>[];
    if (smartAlerts.isNotEmpty) {
      allAlerts.addAll(smartAlerts);
    }
    if (originalAlerts != null && originalAlerts.isNotEmpty) {
      allAlerts.addAll(originalAlerts);
    }

    // 调试信息
    print(
      'TodayScreen _buildAlertButton: smartAlerts=${smartAlerts.length}, originalAlerts=${originalAlerts?.length ?? 0}',
    );

    if (allAlerts.isNotEmpty) {
      return CompactWeatherAlertWidget(
        alerts: smartAlerts,
        onTap: () {
          if (smartAlerts.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WeatherAlertDetailScreen(alerts: smartAlerts),
              ),
            );
          } else if (originalAlerts != null && originalAlerts.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WeatherAlertsScreen(alerts: originalAlerts),
              ),
            );
          }
        },
      );
    }

    return const SizedBox(width: 40); // 占位保持对称
  }

  /// 构建天气提醒卡片
  Widget _buildWeatherAlertCard(WeatherProvider weatherProvider) {
    // 获取当前城市的提醒
    final currentCity = _getDisplayCity(weatherProvider.currentLocation);
    final alerts = _alertService.getAlertsForCity(currentCity);

    // 如果没有提醒，返回空组件
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return WeatherAlertWidget(
      alerts: alerts,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherAlertDetailScreen(alerts: alerts),
          ),
        );
      },
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
    final themeProvider = context.read<ThemeProvider>();
    final backgroundOpacity = themeProvider.isLightTheme ? 0.08 : 0.25;
    final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.12 : 0.3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(iconBackgroundOpacity),
              borderRadius: BorderRadius.circular(4),
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

  /// 根据图标类型获取对应的颜色
  Color _getDetailItemIconColor(IconData icon) {
    final themeProvider = context.read<ThemeProvider>();

    switch (icon) {
      case Icons.air:
        return themeProvider.isLightTheme
            ? const Color(0xFF1565C0) // 亮色模式：深蓝色
            : const Color(0xFF42A5F5); // 暗色模式：亮蓝色
      case Icons.thermostat:
        return themeProvider.isLightTheme
            ? const Color(0xFFE53E3E) // 亮色模式：深红色
            : const Color(0xFFFF6B6B); // 暗色模式：亮红色
      case Icons.water_drop:
        return themeProvider.isLightTheme
            ? const Color(0xFF0277BD) // 亮色模式：深青色
            : const Color(0xFF29B6F6); // 暗色模式：亮青色
      case Icons.compress:
        return themeProvider.isLightTheme
            ? const Color(0xFF7B1FA2) // 亮色模式：深紫色
            : const Color(0xFFBA68C8); // 暗色模式：亮紫色
      case Icons.visibility:
        return themeProvider.isLightTheme
            ? const Color(0xFF2E7D32) // 亮色模式：深绿色
            : const Color(0xFF4CAF50); // 暗色模式：亮绿色
      default:
        return AppColors.cardThemeBlue; // 默认使用主题蓝色
    }
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

  /// 处理刷新按钮点击，显示反馈信息
  Future<void> _handleRefreshWithFeedback(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) async {
    try {
      // 执行强制刷新
      await weatherProvider.forceRefreshWithLocation();
    } catch (e) {
      // 静默处理错误，不显示Toast
      print('刷新失败: ${e.toString()}');
    }
  }
}
