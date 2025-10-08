import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/page_activation_observer.dart';
import '../services/lunar_service.dart';
import '../widgets/lunar_info_widget.dart';
import 'hourly_screen.dart';
import 'weather_alerts_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with WidgetsBindingObserver, LocationChangeListener, PageActivationMixin {
  bool _isVisible = false;
  final WeatherAlertService _alertService = WeatherAlertService.instance;
  bool _isRefreshing = false; // 防止重复刷新

  // 定时刷新相关
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 30); // 30分钟刷新一次
  bool _isAppInBackground = false; // 应用是否在后台

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

    // 注册页面激活监听器
    PageActivationObserver().addListener(this);

    // 首次进入今日天气页面时，自动刷新当前定位和数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentLocationAndWeather();
    });

    // 启动定时刷新
    _startPeriodicRefresh();
  }

  /// 页面被激活时调用（类似Vue的activated）
  @override
  void onPageActivated() {
    print('📱 TodayScreen: 页面被激活，开始刷新天气提醒');
    _isVisible = true;

    // 延迟执行，确保页面完全激活
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshWeatherAlertsOnActivation();
    });
  }

  /// 页面被停用时调用（类似Vue的deactivated）
  @override
  void onPageDeactivated() {
    print('📱 TodayScreen: 页面被停用');
    _isVisible = false;
  }

  /// 页面激活时刷新天气提醒
  /// 注意：页面激活时不分析新提醒，只刷新UI显示已有提醒
  Future<void> _refreshWeatherAlertsOnActivation() async {
    try {
      print('📱 TodayScreen: 页面激活，刷新UI显示提醒');

      // 只刷新UI，不重新分析提醒（避免重复通知）
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('📱 TodayScreen: 页面激活刷新失败: $e');
    }
  }

  /// 刷新当前定位和天气数据
  Future<void> _refreshCurrentLocationAndWeather({
    bool skipAlertAnalysis = false,
  }) async {
    // 防止重复刷新
    if (_isRefreshing) {
      print('🔄 TodayScreen: 正在刷新中，跳过重复请求');
      return;
    }

    try {
      _isRefreshing = true;
      print('🔄 TodayScreen: 开始定位和刷新天气数据');

      final weatherProvider = context.read<WeatherProvider>();

      // 调用新的定位方法（内部会检查是否首次定位）
      await weatherProvider.performLocationAfterEntering();

      // 刷新天气提醒（只在不跳过的情况下）
      if (!skipAlertAnalysis &&
          weatherProvider.currentWeather != null &&
          weatherProvider.currentLocation != null) {
        print('🔄 TodayScreen: 开始刷新天气提醒');
        final newAlerts = await _alertService.analyzeWeather(
          weatherProvider.currentWeather!,
          weatherProvider.currentLocation!,
        );
        print('✅ TodayScreen: 天气提醒刷新完成，新增提醒数量: ${newAlerts.length}');
        for (int i = 0; i < newAlerts.length; i++) {
          final alert = newAlerts[i];
          print('✅ 新增提醒 $i: ${alert.title} - ${alert.cityName}');
        }
        if (mounted) {
          setState(() {}); // 刷新UI显示提醒
        }
      }

      print('✅ TodayScreen: 当前定位和天气数据刷新完成');
    } catch (e) {
      print('❌ TodayScreen: 刷新当前定位和天气数据失败: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// 启动定时刷新
  void _startPeriodicRefresh() {
    _stopPeriodicRefresh(); // 先停止现有的定时器

    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      print('⏰ TodayScreen: 定时刷新触发');
      _performPeriodicRefresh();
    });

    print('⏰ TodayScreen: 定时刷新已启动，间隔 ${_refreshInterval.inMinutes} 分钟');
  }

  /// 停止定时刷新
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('⏰ TodayScreen: 定时刷新已停止');
  }

  /// 执行定时刷新
  Future<void> _performPeriodicRefresh() async {
    // 如果应用在后台或正在刷新中，跳过定时刷新
    if (_isAppInBackground || _isRefreshing) {
      print('⏰ TodayScreen: 应用在后台或正在刷新中，跳过定时刷新');
      return;
    }

    // 如果页面不可见，跳过定时刷新
    if (!_isVisible) {
      print('⏰ TodayScreen: 页面不可见，跳过定时刷新');
      return;
    }

    try {
      _isRefreshing = true;
      print('⏰ TodayScreen: 开始执行定时刷新');

      final weatherProvider = context.read<WeatherProvider>();

      // 刷新天气数据
      await weatherProvider.refreshWeatherData();

      // 定时刷新时分析天气提醒（30分钟一次）
      if (weatherProvider.currentWeather != null &&
          weatherProvider.currentLocation != null) {
        print('⏰ TodayScreen: 定时刷新天气提醒');
        final newAlerts = await _alertService.analyzeWeather(
          weatherProvider.currentWeather!,
          weatherProvider.currentLocation!,
        );
        print('⏰ TodayScreen: 定时刷新天气提醒完成，新增提醒数量: ${newAlerts.length}');
        if (mounted) {
          setState(() {}); // 刷新UI显示提醒
        }
      }

      print('⏰ TodayScreen: 定时刷新完成');
    } catch (e) {
      print('❌ TodayScreen: 定时刷新失败: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    // 停止定时刷新
    _stopPeriodicRefresh();

    WidgetsBinding.instance.removeObserver(this);
    // 移除定位变化监听器
    print('📍 TodayScreen: 开始移除定位变化监听器');
    LocationChangeNotifier().removeListener(this);
    print('📍 TodayScreen: 定位变化监听器移除完成');

    // 移除页面激活监听器
    PageActivationObserver().removeListener(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📍 TodayScreen: 应用从后台恢复');
        _isAppInBackground = false;
        // 恢复定时刷新
        _startPeriodicRefresh();

        // 延迟刷新，避免立即刷新造成卡顿
        // 从后台恢复时只刷新数据，不分析提醒（由定时刷新处理）
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isVisible && !_isRefreshing && mounted) {
            print('📍 TodayScreen: 准备刷新天气数据（不分析提醒）');
            _refreshWeatherDataOnly();
          } else {
            print('📍 TodayScreen: 页面不可见或正在刷新，跳过后台恢复刷新');
          }
        });
        break;

      case AppLifecycleState.paused:
        print('📍 TodayScreen: 应用进入后台');
        _isAppInBackground = true;
        // 暂停定时刷新以节省资源
        _stopPeriodicRefresh();
        break;

      case AppLifecycleState.detached:
        print('📍 TodayScreen: 应用被分离');
        _isAppInBackground = true;
        _stopPeriodicRefresh();
        break;

      default:
        break;
    }
  }

  /// 只刷新天气数据，不分析提醒（用于后台恢复）
  /// 注意：后台恢复不执行刷新，由定时刷新机制处理
  Future<void> _refreshWeatherDataOnly() async {
    // 后台恢复时不立即刷新，避免重复
    // 定时刷新机制会在30分钟后自动刷新
    print('🔄 TodayScreen: 后台恢复，跳过立即刷新（由定时器处理）');
    return;
  }

  /// 定位成功回调
  @override
  void onLocationSuccess(LocationModel newLocation) {
    print('📍 TodayScreen: 收到定位成功通知 ${newLocation.district}');
    print(
      '📍 TodayScreen: 定位详情 - 城市: ${newLocation.city}, 区县: ${newLocation.district}, 省份: ${newLocation.province}',
    );
    print('📍 TodayScreen: 页面可见状态: $_isVisible');

    // 如果页面可见且不在刷新中，刷新天气数据
    // 注意：不在此处分析提醒，避免重复通知
    if (_isVisible && !_isRefreshing) {
      print('📍 TodayScreen: 页面可见，准备刷新天气数据');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _refreshWeatherData();
        // 刷新UI以显示更新的数据
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      print('📍 TodayScreen: 页面不可见或正在刷新中，跳过刷新');
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
    // 防止重复刷新
    if (_isRefreshing) {
      print('🔄 TodayScreen: 正在刷新中，跳过重复请求');
      return;
    }

    try {
      _isRefreshing = true;
      print('🔄 TodayScreen: 开始刷新天气数据');
      final weatherProvider = context.read<WeatherProvider>();
      print('🔄 TodayScreen: 调用 WeatherProvider.refreshWeatherData()');
      await weatherProvider.refreshWeatherData();
      print('✅ TodayScreen: 天气数据刷新完成');
    } catch (e) {
      print('❌ TodayScreen: 刷新天气数据失败: $e');
      print('❌ TodayScreen: 错误堆栈: ${StackTrace.current}');
    } finally {
      _isRefreshing = false;
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

    // 触发页面激活通知
    triggerPageActivation();

    // 简化逻辑：直接尝试恢复，由WeatherProvider内部判断是否需要恢复
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print(
        'TodayScreen didUpdateWidget - calling restoreCurrentLocationWeather',
      );
      final weatherProvider = context.read<WeatherProvider>();
      weatherProvider.restoreCurrentLocationWeather();
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
                    // iOS触觉反馈
                    if (Platform.isIOS) {
                      HapticFeedback.mediumImpact();
                    }

                    await weatherProvider.refreshWeatherData();

                    // iOS触觉反馈 - 刷新完成
                    if (Platform.isIOS) {
                      HapticFeedback.lightImpact();
                    }

                    // 手动刷新时分析提醒（但不发送重复通知）
                    if (weatherProvider.currentWeather != null &&
                        weatherProvider.currentLocation != null) {
                      print('🔄 TodayScreen: 手动刷新天气提醒');
                      final newAlerts = await _alertService.analyzeWeather(
                        weatherProvider.currentWeather!,
                        weatherProvider.currentLocation!,
                      );
                      print(
                        '🔄 TodayScreen: 手动刷新天气提醒完成，新增提醒数量: ${newAlerts.length}',
                      );

                      // iOS触觉反馈 - 有新提醒
                      if (Platform.isIOS && newAlerts.isNotEmpty) {
                        HapticFeedback.heavyImpact();
                      }

                      if (mounted) {
                        setState(() {}); // 刷新UI显示提醒
                      }
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
                        AppColors.cardSpacingWidget,
                        // 农历信息
                        _buildLunarInfo(),
                        AppColors.cardSpacingWidget,
                        // 宜忌信息
                        _buildYiJiInfo(),
                        AppColors.cardSpacingWidget,
                        // 即将到来的节气
                        _buildUpcomingSolarTerms(),
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
                                borderRadius: BorderRadius.circular(8),
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

              // 农历日期和节气 - Material Design 3
              const SizedBox(height: 12),
              _buildLunarAndSolarTerm(weather),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建农历和节气节日信息（头部区域）- Tag样式
  Widget _buildLunarAndSolarTerm(dynamic weather) {
    try {
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(DateTime.now());
      final nongLi = weather?.current?.nongLi;

      // 收集所有要显示的标签
      final tags = <Widget>[];

      // 农历日期
      if (nongLi != null) {
        tags.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                color: context.read<ThemeProvider>().getColor(
                  'headerTextSecondary',
                ),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                nongLi,
                style: TextStyle(
                  color: context.read<ThemeProvider>().getColor(
                    'headerTextSecondary',
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }

      // 节气（如果有）- 不要图标
      if (lunarInfo.solarTerm != null && lunarInfo.solarTerm!.isNotEmpty) {
        tags.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lunarInfo.solarTerm!,
              style: TextStyle(
                color: context.read<ThemeProvider>().getColor(
                  'headerTextSecondary',
                ),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }

      // 传统节日（如果有）- 显示所有节日
      if (lunarInfo.festivals.isNotEmpty) {
        for (final festival in lunarInfo.festivals) {
          tags.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                festival,
                style: TextStyle(
                  color: context.read<ThemeProvider>().getColor(
                    'headerTextSecondary',
                  ),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }
      }

      // 使用Wrap布局，支持自动换行
      return Wrap(
        spacing: 8, // 标签间距
        runSpacing: 6, // 行间距
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center, // 垂直居中对齐
        children: tags,
      );
    } catch (e) {
      print('❌ 构建农历节气信息失败: $e');
      // 如果失败，显示基础农历信息
      final nongLi = weather?.current?.nongLi;
      if (nongLi != null) {
        return Text(
          nongLi,
          style: TextStyle(
            color: context.read<ThemeProvider>().getColor(
              'headerTextSecondary',
            ),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        );
      }
      return const SizedBox.shrink();
    }
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

    // 添加详细的调试日志
    print('🔍 _buildWeatherAlertCard: 当前城市: $currentCity');
    print('🔍 _buildWeatherAlertCard: 获取到的提醒数量: ${alerts.length}');

    // 打印所有提醒的详细信息
    for (int i = 0; i < alerts.length; i++) {
      final alert = alerts[i];
      print(
        '🔍 提醒 $i: id=${alert.id}, title=${alert.title}, cityName=${alert.cityName}, shouldShow=${alert.shouldShow}, isExpired=${alert.isExpired}, isRead=${alert.isRead}',
      );
    }

    // 检查所有提醒（包括不显示的）
    final allAlerts = _alertService.alerts;
    print('🔍 _buildWeatherAlertCard: 服务中所有提醒数量: ${allAlerts.length}');
    for (int i = 0; i < allAlerts.length; i++) {
      final alert = allAlerts[i];
      print(
        '🔍 所有提醒 $i: id=${alert.id}, title=${alert.title}, cityName=${alert.cityName}, shouldShow=${alert.shouldShow}, isExpired=${alert.isExpired}, isRead=${alert.isRead}',
      );
    }

    // 如果没有提醒，返回空组件
    if (alerts.isEmpty) {
      print('🔍 _buildWeatherAlertCard: 没有提醒，返回空组件');
      return const SizedBox.shrink();
    }

    print('🔍 _buildWeatherAlertCard: 有提醒，显示提醒卡片');
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

  /// 构建农历信息卡片
  Widget _buildLunarInfo() {
    try {
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(DateTime.now());
      return LunarInfoWidget(lunarInfo: lunarInfo);
    } catch (e) {
      print('❌ 获取农历信息失败: $e');
      return const SizedBox.shrink();
    }
  }

  /// 构建宜忌信息卡片
  Widget _buildYiJiInfo() {
    try {
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(DateTime.now());
      return YiJiWidget(lunarInfo: lunarInfo);
    } catch (e) {
      print('❌ 获取宜忌信息失败: $e');
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
      print('❌ 获取节气信息失败: $e');
      return const SizedBox.shrink();
    }
  }
}
