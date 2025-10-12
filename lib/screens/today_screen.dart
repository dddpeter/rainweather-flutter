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
import '../models/weather_model.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/life_index_widget.dart';
import '../widgets/weather_animation_widget.dart';
import '../widgets/weather_alert_widget.dart';
import '../widgets/commute_advice_widget.dart';
import '../services/weather_alert_service.dart';
import '../services/database_service.dart';
import '../services/location_change_notifier.dart';
import '../services/page_activation_observer.dart';
import '../services/lunar_service.dart';
import '../widgets/lunar_info_widget.dart';
import '../widgets/weather_details_widget.dart';
import 'hourly_screen.dart';

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

        return Consumer<WeatherProvider>(
          builder: (context, weatherProvider, child) {
            return Container(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Builder(
                builder: (context) {
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
                          // 通勤提醒卡片（通勤建议，不包含气象预警和天气提醒）
                          const CommuteAdviceWidget(),
                          // 只有在有通勤建议时才显示间距
                          if (weatherProvider.commuteAdvices.isNotEmpty)
                            AppColors.cardSpacingWidget,
                          // 空气质量卡片
                          _buildAirQualityCard(weatherProvider),
                          AppColors.cardSpacingWidget,
                          // 24小时天气
                          _buildHourlyWeather(weatherProvider),
                          AppColors.cardSpacingWidget,
                          // 使用缓存数据时，显示上午/下午分时段信息
                          if (weatherProvider.isUsingCachedData)
                            _buildTimePeriodDetails(weatherProvider),
                          // 详细信息卡片（非缓存时显示）
                          if (!weatherProvider.isUsingCachedData)
                            WeatherDetailsWidget(
                              weather: weatherProvider.currentWeather,
                            ),
                          AppColors.cardSpacingWidget,
                          // 生活指数
                          LifeIndexWidget(weatherProvider: weatherProvider),
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
                  // 左侧占位（保持对称）
                  const SizedBox(width: 40),
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
                          // 数据状态指示器
                          if (weatherProvider.isUsingCachedData ||
                              weatherProvider.isBackgroundRefreshing)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (weatherProvider
                                      .isBackgroundRefreshing) ...[
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              context
                                                  .read<ThemeProvider>()
                                                  .getColor(
                                                    'headerTextSecondary',
                                                  ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (weatherProvider.isUsingCachedData)
                                    Icon(
                                      Icons.history,
                                      size: 10,
                                      color: context
                                          .read<ThemeProvider>()
                                          .getColor('headerTextSecondary'),
                                    ),
                                  const SizedBox(width: 4),
                                  FutureBuilder<String>(
                                    future: _getCacheAgeText(weatherProvider),
                                    builder: (context, snapshot) {
                                      String text;
                                      if (weatherProvider
                                          .isBackgroundRefreshing) {
                                        text = '正在更新...';
                                      } else if (snapshot.hasData) {
                                        text = snapshot.data!;
                                      } else {
                                        text = '缓存数据';
                                      }

                                      return Text(
                                        text,
                                        style: TextStyle(
                                          color: context
                                              .read<ThemeProvider>()
                                              .getColor('headerTextSecondary'),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      );
                                    },
                                  ),
                                ],
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

              // AI智能天气摘要
              if (weatherProvider.weatherSummary != null ||
                  weatherProvider.isGeneratingSummary) ...[
                const SizedBox(height: 16),
                _buildAIWeatherSummary(weatherProvider),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建AI智能天气摘要
  Widget _buildAIWeatherSummary(WeatherProvider weatherProvider) {
    // 使用金色/琥珀色系，在深蓝背景上更醒目
    const aiColor = Color(0xFFFFB300); // 琥珀色
    final themeProvider = context.read<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [aiColor.withOpacity(0.15), aiColor.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: aiColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: aiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome, color: aiColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI智能助手',
                      style: TextStyle(
                        color: aiColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (weatherProvider.isGeneratingSummary)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(aiColor),
                        ),
                      ),
                  ],
                ),
                if (weatherProvider.weatherSummary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    weatherProvider.weatherSummary!,
                    style: TextStyle(
                      color: themeProvider.getColor('headerTextSecondary'),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
                  // AQI数值（缩小尺寸，与后面文字高度一致）
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$aqi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
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
                      _buildScaleLabel('0', AppColors.airExcellent),
                      _buildScaleLabel('50', AppColors.airGood),
                      _buildScaleLabel('100', AppColors.airLight),
                      _buildScaleLabel('150', AppColors.airModerate),
                      _buildScaleLabel('200', AppColors.airHeavy),
                      _buildScaleLabel('300+', AppColors.airSevere),
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
  Widget _buildScaleLabel(String text, Color color) {
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

  /// 获取缓存年龄的友好文字描述
  Future<String> _getCacheAgeText(WeatherProvider weatherProvider) async {
    try {
      // 从SQLite获取缓存时间
      if (weatherProvider.currentLocation == null) {
        return '缓存数据';
      }

      final weatherKey =
          '${weatherProvider.currentLocation!.district}:${AppConstants.weatherAllKey}';
      final databaseService = DatabaseService.getInstance();
      final db = await databaseService.database;
      final result = await db.query(
        'weather_cache',
        columns: ['created_at'],
        where: 'key = ?',
        whereArgs: [weatherKey],
      );

      if (result.isEmpty) {
        return '缓存数据';
      }

      final createdAt = result.first['created_at'] as int;
      final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final ageMinutes = DateTime.now().difference(cacheDateTime).inMinutes;

      if (ageMinutes < 60) {
        return '缓存 ${ageMinutes}分钟前';
      } else if (ageMinutes < 1440) {
        // 小于24小时
        final hours = (ageMinutes / 60).floor();
        return '缓存 ${hours}小时前';
      } else {
        // 超过24小时
        final days = (ageMinutes / 1440).floor();
        return '缓存 ${days}天前';
      }
    } catch (e) {
      return '缓存数据';
    }
  }

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

  /// 构建上午/下午分时段信息（使用缓存数据时）
  Widget _buildTimePeriodDetails(WeatherProvider weatherProvider) {
    // 从15天预报中获取今天的数据
    final forecast15d = weatherProvider.forecast15d;
    if (forecast15d == null || forecast15d.isEmpty) {
      return const SizedBox.shrink();
    }

    // 找到今天的预报数据（通常是第一个或第二个）
    DailyWeather? todayForecast;
    try {
      // 尝试从预报数据中找到今天
      for (var day in forecast15d) {
        if (day.forecasttime != null) {
          final forecastDate = DateTime.parse(day.forecasttime!);
          final now = DateTime.now();
          if (forecastDate.year == now.year &&
              forecastDate.month == now.month &&
              forecastDate.day == now.day) {
            todayForecast = day;
            break;
          }
        }
      }
      // 如果没找到，使用第一个
      todayForecast ??= forecast15d.first;
    } catch (e) {
      todayForecast = forecast15d.first;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: Row(
        children: [
          // 上午
          Expanded(
            child: _buildPeriodCard(
              '上午',
              todayForecast.weather_pm ?? '--',
              todayForecast.temperature_pm ?? '--',
              todayForecast.winddir_pm ?? '--',
              todayForecast.windpower_pm ?? '--',
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          // 下午
          Expanded(
            child: _buildPeriodCard(
              '下午',
              todayForecast.weather_am ?? '--',
              todayForecast.temperature_am ?? '--',
              todayForecast.winddir_am ?? '--',
              todayForecast.windpower_am ?? '--',
              const Color(0xFF64DD17), // 绿色（避免使用蓝色系）
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时段卡片
  Widget _buildPeriodCard(
    String period,
    String weather,
    String temperature,
    String windDir,
    String windPower,
    Color accentColor,
  ) {
    // 判断是白天还是夜间（根据时段）
    // 注意：上午使用pm数据（夜间），下午使用am数据（白天）
    final isNight = period == '上午';

    // 获取中文天气图标路径
    final iconMap = isNight
        ? AppConstants.chineseNightWeatherImages
        : AppConstants.chineseWeatherImages;
    final iconPath = iconMap[weather] ?? iconMap['晴'] ?? '晴.png';

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // 时段标题（符合 MD3 规范）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8), // 标题和图标的间隙
            // 天气PNG图标（48px）
            Image.asset(
              'assets/images/$iconPath',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // 加载失败时显示默认图标
                return Image.asset(
                  'assets/images/不清楚.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                );
              },
            ),
            const SizedBox(height: 4), // 图标和天气描述的距离（更近）
            // 天气描述（再缩小）
            Text(
              weather,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2), // 天气和温度的距离（更近）
            // 温度（再缩小）
            Text(
              '$temperature℃',
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 风向风力
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.air, color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$windDir $windPower',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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
        // 格式化农历日期，确保月份有"月"字
        String formattedNongLi = nongLi;
        // 如果格式是"八十八"这种，需要添加"月"字变成"八月十八"
        // 正则匹配：数字+数字的格式
        final match = RegExp(
          r'^(正|二|三|四|五|六|七|八|九|十|冬|腊)(初|十|廿|卅)',
        ).hasMatch(nongLi);
        if (match && !nongLi.contains('月')) {
          // 在第一个汉字后面添加"月"
          if (nongLi.length >= 2) {
            final firstChar = nongLi[0];
            final rest = nongLi.substring(1);
            formattedNongLi = '$firstChar月$rest';
          }
        }

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
                formattedNongLi,
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

  Widget _buildAlertButton(WeatherProvider weatherProvider) {
    // 获取天气提醒（智能提醒，仅当前定位城市）
    final currentCity = _getDisplayCity(weatherProvider.currentLocation);
    final smartAlerts = _alertService.getAlertsForCity(
      currentCity,
      weatherProvider.currentLocation,
    );

    // 获取通勤提醒
    final commuteAdvices = weatherProvider.commuteAdvices;

    // 计算总提醒数
    final totalCount = smartAlerts.length + commuteAdvices.length;

    // 调试信息
    print(
      'TodayScreen _buildAlertButton: 天气提醒数量=${smartAlerts.length}, 通勤提醒数量=${commuteAdvices.length}',
    );

    if (totalCount > 0) {
      return CompactWeatherAlertWidget(
        alerts: smartAlerts,
        commuteCount: commuteAdvices.length,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeatherAlertDetailScreen(
                alerts: smartAlerts,
                commuteAdvices: commuteAdvices,
              ),
            ),
          );
        },
      );
    }

    return const SizedBox(width: 40); // 占位保持对称
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
