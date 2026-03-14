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
import '../widgets/ai_smart_assistant_widget.dart';
import '../services/weather_alert_service.dart';
import '../services/database_service.dart';
import '../services/location_change_notifier.dart';
import '../services/page_activation_observer.dart';
import '../services/lunar_service.dart';
import '../widgets/lunar_info_widget.dart';
import '../widgets/air_quality_card.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';
import '../widgets/error_dialog.dart';
import 'hourly_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with
        WidgetsBindingObserver,
        LocationChangeListener,
        PageActivationMixin,
        AutomaticKeepAliveClientMixin {
  bool _isVisible = false;
  bool _needsRestore = false; // 是否需要恢复定位数据
  final WeatherAlertService _alertService = WeatherAlertService.instance;
  bool _isRefreshing = false; // 防止重复刷新

  @override
  bool get wantKeepAlive => true; // 保持页面状态

  // 定时刷新相关
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 30); // 30分钟刷新一次
  bool _isAppInBackground = false; // 应用是否在后台

  // 滚动控制相关
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化天气提醒服务
    _alertService.initialize();

    // 添加定位变化监听器
    Logger.d('开始注册定位变化监听器', tag: 'TodayScreen');
    LocationChangeNotifier().addListener(this);
    Logger.d('定位变化监听器注册完成', tag: 'TodayScreen');
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 检查是否需要恢复定位数据（移出 build 方法，避免递归重建）
    final data = context.watch<WeatherProvider>();
    final navigator = Navigator.of(context);
    final canPop = navigator.canPop();

    // 更新可见性状态
    final newIsVisible = !canPop;
    if (_isVisible != newIsVisible) {
      _isVisible = newIsVisible;
    }

    // 检查是否需要恢复定位数据
    _needsRestore = _shouldRestore(data);

    if (_needsRestore) {
      // 使用 post frame callback 避免在 build 期间调用 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _needsRestore) {
          context.read<WeatherProvider>().restoreCurrentLocationWeather();
          _needsRestore = false;
        }
      });
    }
  }

  /// 检查是否需要恢复定位数据
  bool _shouldRestore(WeatherProvider data) {
    final isTodayTab = data.currentTabIndex == 0;
    return isTodayTab &&
        data.currentLocationWeather != null &&
        data.originalLocation != null &&
        data.isShowingCityWeather;
  }

  /// 页面被激活时调用（类似Vue的activated）
  @override
  void onPageActivated() {
    Logger.d('页面被激活，开始刷新天气提醒', tag: 'TodayScreen');
    _isVisible = true;

    // 延迟执行，确保页面完全激活
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshWeatherAlertsOnActivation();
    });
  }

  /// 页面被停用时调用（类似Vue的deactivated）
  @override
  void onPageDeactivated() {
    Logger.d('页面被停用', tag: 'TodayScreen');
    _isVisible = false;
  }

  /// 页面激活时刷新天气提醒
  /// 注意：页面激活时不分析新提醒，只刷新UI显示已有提醒
  Future<void> _refreshWeatherAlertsOnActivation() async {
    try {
      Logger.d('页面激活，刷新UI显示提醒', tag: 'TodayScreen');

      // 只刷新UI，不重新分析提醒（避免重复通知）
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Logger.e('页面激活刷新失败', tag: 'TodayScreen', error: e);
    }
  }

  /// 刷新当前定位和天气数据
  Future<void> _refreshCurrentLocationAndWeather({
    bool skipAlertAnalysis = false,
  }) async {
    // 防止重复刷新
    if (_isRefreshing) {
      Logger.d('正在刷新中，跳过重复请求', tag: 'TodayScreen');
      return;
    }

    try {
      _isRefreshing = true;
      Logger.d('开始定位和刷新天气数据', tag: 'TodayScreen');

      final weatherProvider = context.read<WeatherProvider>();

      // 调用新的定位方法（内部会检查是否首次定位）
      await weatherProvider.performLocationAfterEntering();

      // 刷新天气提醒（只在不跳过的情况下）
      if (!skipAlertAnalysis &&
          weatherProvider.currentWeather != null &&
          weatherProvider.currentLocation != null) {
        Logger.d('开始刷新天气提醒', tag: 'TodayScreen');
        final newAlerts = await _alertService.analyzeWeather(
          weatherProvider.currentWeather!,
          weatherProvider.currentLocation!,
        );
        Logger.s('天气提醒刷新完成，新增提醒数量: ${newAlerts.length}', tag: 'TodayScreen');
        for (int i = 0; i < newAlerts.length; i++) {
          final alert = newAlerts[i];
          Logger.d(
            '新增提醒 $i: ${alert.title} - ${alert.cityName}',
            tag: 'TodayScreen',
          );
        }
        if (mounted) {
          setState(() {}); // 刷新UI显示提醒
        }
      }

      Logger.s('当前定位和天气数据刷新完成', tag: 'TodayScreen');
    } catch (e) {
      Logger.e('刷新当前定位和天气数据失败', tag: 'TodayScreen', error: e);
    } finally {
      _isRefreshing = false;
    }
  }

  /// 启动定时刷新
  void _startPeriodicRefresh() {
    _stopPeriodicRefresh(); // 先停止现有的定时器

    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      Logger.d('定时刷新触发', tag: 'TodayScreen');
      _performPeriodicRefresh();
    });

    Logger.i('定时刷新已启动，间隔 ${_refreshInterval.inMinutes} 分钟', tag: 'TodayScreen');
  }

  /// 停止定时刷新
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    Logger.d('定时刷新已停止', tag: 'TodayScreen');
  }

  /// 执行定时刷新
  Future<void> _performPeriodicRefresh() async {
    // 如果应用在后台或正在刷新中，跳过定时刷新
    if (_isAppInBackground || _isRefreshing) {
Logger.d('应用在后台或正在刷新中，跳过定时刷新', tag: 'TodayScreen');
      return;
    }

    // 如果页面不可见，跳过定时刷新
    if (!_isVisible) {
Logger.d('页面不可见，跳过定时刷新', tag: 'TodayScreen');
      return;
    }

    try {
      _isRefreshing = true;
Logger.d('开始执行定时刷新', tag: 'TodayScreen');

      final weatherProvider = context.read<WeatherProvider>();

      // 刷新天气数据
      await weatherProvider.refreshWeatherData();

      // 定时刷新时分析天气提醒（30分钟一次）
      if (weatherProvider.currentWeather != null &&
          weatherProvider.currentLocation != null) {
        Logger.d('定时刷新天气提醒', tag: 'TodayScreen');
        final newAlerts = await _alertService.analyzeWeather(
          weatherProvider.currentWeather!,
          weatherProvider.currentLocation!,
        );
        Logger.d('定时刷新天气提醒完成，新增提醒数量: ${newAlerts.length}', tag: 'TodayScreen');
        if (mounted) {
          setState(() {}); // 刷新UI显示提醒
        }
      }

Logger.d('定时刷新完成', tag: 'TodayScreen');
    } catch (e) {
      Logger.e('定时刷新失败', tag: 'TodayScreen', error: e);
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    // 停止定时刷新
    _stopPeriodicRefresh();

    // 销毁ScrollController
    _scrollController.dispose();

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
        if (mounted) {
          ErrorToast.show(
            context: context,
            message: '定位失败: $error',
            errorType: AppErrorType.location,
          );
        }
      });
    } else {
      print('❌ TodayScreen: 页面不可见，跳过显示错误信息');
    }
  }

  /// 刷新天气数据
  Future<void> _refreshWeatherData() async {
    // 防止重复刷新
    if (_isRefreshing) {
      Logger.d('正在刷新中，跳过重复请求', tag: 'TodayScreen');
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
    super.build(context); // 必须调用以支持AutomaticKeepAlive
    // 使用Selector精确监听需要的状态，避免不必要的重建
    return Selector<ThemeProvider, ThemeProvider>(
      selector: (context, themeProvider) => themeProvider,
      builder: (context, themeProvider, child) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Selector<
          WeatherProvider,
          ({
            WeatherModel? currentWeather,
            LocationModel? currentLocation,
            LocationModel? originalLocation,
            WeatherModel? currentLocationWeather,
            bool isShowingCityWeather,
            int currentTabIndex,
            bool isOffline,
          })
        >(
          selector: (context, weatherProvider) => (
            currentWeather: weatherProvider.currentWeather,
            currentLocation: weatherProvider.currentLocation,
            originalLocation: weatherProvider.originalLocation,
            currentLocationWeather: weatherProvider.currentLocationWeather,
            isShowingCityWeather: weatherProvider.isShowingCityWeather,
            currentTabIndex: weatherProvider.currentTabIndex,
            isOffline: weatherProvider.isOffline,
          ),
          builder: (context, data, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: AppColors.screenBackgroundGradient,
              ),
              child: Builder(
                builder: (context) {
                  if (data.currentWeather == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentBlue,
                      ),
                    );
                  }

                  final weatherProvider = context.read<WeatherProvider>();
                  if (weatherProvider.error != null &&
                      data.currentWeather == null) {
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
                            child: const Text('重试'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => _showErrorDialog(
                              context,
                              weatherProvider.error!,
                            ),
                            child: Text(
                              '查看详细错误信息',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
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

                      await weatherProvider.refreshWeatherData();

                      // 手动刷新时强制重新生成AI摘要
                      print('🔄 TodayScreen: 手动刷新，触发AI摘要生成');
                      weatherProvider.generateWeatherSummary(
                        forceRefresh: true,
                      );

                      // iOS触觉反馈 - 刷新完成
                      if (Platform.isIOS) {
                        HapticFeedback.lightImpact();
                      }

                      // 手动刷新时分析提醒（但不发送重复通知）
                      if (data.currentWeather != null &&
                          data.currentLocation != null) {
                        print('🔄 TodayScreen: 手动刷新天气提醒');
                        final newAlerts = await _alertService.analyzeWeather(
                          data.currentWeather!,
                          data.currentLocation!,
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
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildTopWeatherSection(weatherProvider),
                              AppColors.cardSpacingWidget,
                              // AI智能助手卡片（整合天气摘要和通勤提醒）
                              AISmartAssistantWidget(
                                key: const ValueKey('today_ai_smart_assistant'),
                              ),
                              AppColors.cardSpacingWidget,
                              // 空气质量卡片
                              AirQualityCard(weather: data.currentWeather),
                              AppColors.cardSpacingWidget,
                              // 24小时天气
                              _buildHourlyWeather(weatherProvider),
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
                      ],
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
        // 固定深蓝色背景（不区分亮暗模式）
        color: AppColors.weatherHeaderCardBackground,
        // 添加露营场景背景图片（透明化处理）
        image: const DecorationImage(
          image: AssetImage('assets/images/backgroud.png'),
          fit: BoxFit.cover,
          opacity: 0.25, // 优化：降低透明度，提升文字对比度和可读性
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
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
          child: Column(
            children: [
              // City name and menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 占位空间，保持居中
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: context.read<ThemeProvider>().getColor(
                                  'headerTextPrimary',
                                ),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getDisplayCity(location),
                                style: TextStyle(
                                  color: context.read<ThemeProvider>().getColor(
                                    'headerTextPrimary',
                                  ),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // 数据状态指示器
                          if (weatherProvider.isUsingCachedData ||
                              weatherProvider.isBackgroundRefreshing ||
                              weatherProvider.isOffline)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 离线提示
                                  if (weatherProvider.isOffline) ...[
                                    Icon(
                                      Icons.wifi_off,
                                      size: 10,
                                      color: Colors.orange.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '离线模式',
                                      style: TextStyle(
                                        color: Colors.orange.shade400,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // 刷新指示器
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
                                  // 缓存数据图标
                                  if (weatherProvider.isUsingCachedData)
                                    Icon(
                                      Icons.history,
                                      size: 10,
                                      color: context
                                          .read<ThemeProvider>()
                                          .getColor('headerTextSecondary'),
                                    ),
                                  const SizedBox(width: 4),
                                  // 缓存时间文本
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
              const SizedBox(height: 24), // 减小间距
              // Weather animation, weather text and temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
                children: [
                  // 左侧天气动画区域 - 主要视觉焦点
                  Flexible(
                    flex: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // 居中显示
                      mainAxisAlignment: MainAxisAlignment.start, // 顶部对齐
                      children: [
                        WeatherAnimationWidget(
                          weatherType: current?.weather ?? '晴',
                          size: 100, // 适中的动画尺寸
                          isPlaying: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 右侧温度和天气汉字区域 - 紧凑布局
                  Flexible(
                    flex: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${current?.temperature ?? '--'}',
                              style: TextStyle(
                                color: context.read<ThemeProvider>().getColor(
                                  'headerTextPrimary',
                                ),
                                fontSize: 56, // 增大温度字体
                                fontWeight: FontWeight.bold,
                                height: 1.0, // 紧凑行高
                              ),
                            ),
                            Text(
                              '℃',
                              style: TextStyle(
                                color: context.read<ThemeProvider>().getColor(
                                  'headerTextPrimary',
                                ),
                                fontSize: 40,
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
                                  color: context.read<ThemeProvider>().getColor(
                                    'headerTextSecondary',
                                  ),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '体感 ${current?.feelstemperature}℃',
                                  style: TextStyle(
                                    color: context
                                        .read<ThemeProvider>()
                                        .getColor('headerTextSecondary'),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6), // 减小间距
                        Text(
                          current?.weather ?? '晴',
                          style: TextStyle(
                            color: context.read<ThemeProvider>().getColor(
                              'headerTextSecondary',
                            ),
                            fontSize: 20, // 减小天气文字
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 简化的详细信息
              const SizedBox(height: 32),
              _buildSimplifiedDetails(weather),

              // 农历日期和节气 - Material Design 3
              const SizedBox(height: 32),
              _buildLunarAndSolarTerm(weather),
            ],
          ),
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

  /// 构建简化的详细信息（头部区域）
  Widget _buildSimplifiedDetails(dynamic weather) {
    if (weather?.current?.current == null) {
      return const SizedBox.shrink();
    }

    final current = weather.current.current;

    String _formatNumber(dynamic value) {
      if (value == null) return '--';
      if (value is String) return value;
      return value.toString();
    }

    return Row(
      children: [
        // 湿度
        Expanded(
          child: _buildSimpleInfoChip(
            Icons.water_drop,
            '湿度',
            '${_formatNumber(current.humidity)}%',
          ),
        ),
        const SizedBox(width: 8),
        // 风力
        Expanded(
          child: _buildSimpleInfoChip(
            Icons.air,
            '风力',
            '${current.winddir ?? '--'} ${current.windpower ?? ''}',
          ),
        ),
        const SizedBox(width: 8),
        // 气压
        Expanded(
          child: _buildSimpleInfoChip(
            Icons.compress,
            '气压',
            '${_formatNumber(current.airpressure)}hpa',
          ),
        ),
        const SizedBox(width: 8),
        // 能见度
        Expanded(
          child: _buildSimpleInfoChip(
            Icons.visibility,
            '能见度',
            '${_formatNumber(current.visibility)}km',
          ),
        ),
      ],
    );
  }

  /// 构建简单的信息标签
  Widget _buildSimpleInfoChip(IconData icon, String label, String value) {
    final themeProvider = context.read<ThemeProvider>();
    return Container(
      height: 60, // 固定高度，确保所有标签高度一致
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 第一行：图标 + 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: themeProvider.getColor('headerTextSecondary'),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: themeProvider.getColor('headerTextSecondary'),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 第二行：数值
          Text(
            value,
            style: TextStyle(
              color: themeProvider.getColor('headerTextSecondary'),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

  // 构建主题切换按钮 - 已移除
  // 现在使用顶部AppBar的主题切换按钮

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
          child: LunarInfoWidget(lunarInfo: lunarInfo),
        ),
      );
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
          child: YiJiWidget(lunarInfo: lunarInfo),
        ),
      );
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
          child: SolarTermListWidget(solarTerms: upcomingTerms, title: '即将到来的节气'),
        ),
      );
    } catch (e) {
      print('❌ 获取节气信息失败: $e');
      return const SizedBox.shrink();
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(BuildContext context, String error) {
    // 根据错误类型确定错误类型
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
        _handleRefreshWithFeedback(context, context.read<WeatherProvider>());
      },
      retryText: '重试',
    );
  }
}
