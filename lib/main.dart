import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
// import 'providers/weather_provider_refactored.dart';
import 'screens/today_screen.dart';
import 'screens/hourly_screen.dart';
import 'screens/forecast15d_screen.dart';
import 'screens/main_cities_screen.dart';
import 'screens/app_splash_screen.dart';
import 'widgets/floating_action_island.dart';
import 'widgets/app_drawer.dart';
import 'widgets/weather_alert_widget.dart';
import 'screens/outfit_advisor_screen.dart';
import 'screens/health_advisor_screen.dart';
import 'screens/extreme_weather_alert_screen.dart';
// import 'screens/radar_screen.dart'; // 已移除雷达图功能
import 'services/weather_alert_service.dart';
import 'services/weather_share_service.dart';
import 'constants/app_colors.dart';
import 'constants/theme_extensions.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/smart_cache_service.dart';
import 'services/baidu_location_service.dart';
import 'services/amap_location_service.dart';
import 'services/tencent_location_service.dart';
import 'services/page_activation_observer.dart';
import 'services/weather_widget_service.dart';
import 'widgets/custom_bottom_navigation_v2.dart';
import 'utils/app_state_manager.dart';
import 'utils/app_recovery_manager.dart';
import 'utils/global_exception_handler.dart';
import 'utils/logger.dart';
import 'utils/error_handler.dart';

// 全局路由观察者
final PageActivationObserver _pageActivationObserver = PageActivationObserver();

// 全局导航器 Key（用于通知点击等场景的导航）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 应用在后台的时间戳
DateTime? _appInBackgroundSince;

/// 启动后台缓存清理任务
void _startBackgroundCacheCleaner() {
  print('🧹 启动后台缓存清理任务（每30分钟）');

  // 每30分钟清理一次过期缓存
  Timer.periodic(const Duration(minutes: 30), (timer) async {
    try {
      await SmartCacheService().clearExpiredCache();
    } catch (e) {
      print('❌ 后台缓存清理失败: $e');
    }
  });
}

/// 路由观察者，用于监听页面切换
class _RouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final PageActivationObserver _pageActivationObserver;

  _RouteObserver(this._pageActivationObserver);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  void _handleRouteChange(Route<dynamic> route) {
    final routeName = route.settings.name ?? route.runtimeType.toString();
    print('🔄 RouteObserver: 路由变化 - $routeName');

    // 通知页面激活
    _pageActivationObserver.notifyPageActivated(routeName);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局异常处理器
  GlobalExceptionHandler().initialize();
  Logger.separator(title: 'RainWeather 启动');

  // 🚀 预加载智能缓存到内存
  try {
    Logger.d('预加载智能缓存...');
    await SmartCacheService().preloadCommonData();
    Logger.s('智能缓存预加载完成');
  } catch (e, stackTrace) {
    Logger.e('智能缓存预加载失败', error: e, stackTrace: stackTrace);
    ErrorHandler.handleError(
      e,
      stackTrace: stackTrace,
      context: 'Main.SmartCachePreload',
      type: AppErrorType.cache,
    );
  }

  // 🧹 启动后台缓存清理任务
  _startBackgroundCacheCleaner();

  // 初始化通知服务并请求权限
  try {
    Logger.d('初始化通知服务');
    final notificationService = NotificationService.instance;
    await notificationService.initialize();

    // 创建通知渠道（Android）
    await notificationService.createNotificationChannels();

    // 请求通知权限
    final permissionGranted = await notificationService.requestPermissions();
    Logger.i('通知权限请求结果: $permissionGranted');

    if (!permissionGranted) {
      Logger.w('通知权限未授予，部分功能可能无法使用');
    }
  } catch (e, stackTrace) {
    Logger.e('通知服务初始化失败', error: e, stackTrace: stackTrace);
    ErrorHandler.handleError(
      e,
      stackTrace: stackTrace,
      context: 'Main.NotificationService',
      type: AppErrorType.permission,
    );
  }

  // 初始化定位服务
  // 全局设置腾讯定位服务
  try {
    Logger.d('全局设置腾讯定位服务');
    final tencentLocationService = TencentLocationService.getInstance();
    await tencentLocationService.setGlobalPrivacyAgreement();
    Logger.s('腾讯定位服务设置成功');
  } catch (e, stackTrace) {
    Logger.e('腾讯定位服务设置失败', error: e, stackTrace: stackTrace);
    ErrorHandler.handleError(
      e,
      stackTrace: stackTrace,
      context: 'Main.TencentLocationService',
      type: AppErrorType.location,
    );
  }

  // 全局设置百度定位隐私政策同意
  try {
    Logger.d('全局设置百度定位隐私政策同意');
    final baiduLocationService = BaiduLocationService.getInstance();
    await baiduLocationService.setGlobalPrivacyAgreement();
    Logger.s('百度定位隐私政策同意设置成功');
  } catch (e, stackTrace) {
    Logger.e('百度定位隐私政策同意设置失败', error: e, stackTrace: stackTrace);
    ErrorHandler.handleError(
      e,
      stackTrace: stackTrace,
      context: 'Main.BaiduLocationService',
      type: AppErrorType.location,
    );
  }

  // 全局设置高德地图API Key
  try {
    Logger.d('全局设置高德地图API Key');
    final amapLocationService = AMapLocationService.getInstance();
    await amapLocationService.setGlobalAPIKey();
    Logger.s('高德地图API Key设置成功');
  } catch (e, stackTrace) {
    Logger.e('高德地图API Key设置失败', error: e, stackTrace: stackTrace);
    ErrorHandler.handleError(
      e,
      stackTrace: stackTrace,
      context: 'Main.AmapLocationService',
      type: AppErrorType.location,
    );
  }

  // 请求定位权限（参照demo）
  try {
    Logger.d('请求定位权限');
    final locationService = LocationService.getInstance();
    await locationService.requestLocationPermission();
    Logger.s('定位权限请求完成');
  } catch (e, stackTrace) {
    Logger.e('定位权限请求失败', error: e, stackTrace: stackTrace);
    ErrorHandler.handleError(
      e,
      stackTrace: stackTrace,
      context: 'Main.LocationPermission',
      type: AppErrorType.permission,
    );
  }

  runApp(const RainWeatherApp());
}

class RainWeatherApp extends StatefulWidget {
  const RainWeatherApp({super.key});

  @override
  State<RainWeatherApp> createState() => _RainWeatherAppState();
}

class _RainWeatherAppState extends State<RainWeatherApp>
    with WidgetsBindingObserver {
  static const Duration _backgroundTimeout = Duration(minutes: 30); // 30分钟超时

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

    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台
        _appInBackgroundSince = DateTime.now();
        print('📱 App entered background at: $_appInBackgroundSince');
        break;

      case AppLifecycleState.resumed:
        // 应用回到前台
        final now = DateTime.now();
        if (_appInBackgroundSince != null) {
          final backgroundDuration = now.difference(_appInBackgroundSince!);
          print(
            '📱 App resumed after being in background for: $backgroundDuration',
          );

          // 如果在后台时间超过设定的超时时间，则重启应用
          if (backgroundDuration > _backgroundTimeout) {
            print(
              '⏰ App was in background for more than $_backgroundTimeout, restarting...',
            );
            _restartApp();
          }
        }
        _appInBackgroundSince = null;
        break;

      default:
        break;
    }
  }

  void _restartApp() {
    // 重置应用状态管理器
    AppStateManager().reset();

    // 重新初始化应用状态
    // 使用pushAndRemoveUntil确保完全重启应用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RainWeatherApp()),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // 设置主题提供者到AppColors
          AppColors.setThemeProvider(themeProvider);

          return AnimatedTheme(
            data: themeProvider.themeMode == AppThemeMode.light
                ? _buildLightTheme(themeProvider)
                : themeProvider.themeMode == AppThemeMode.dark
                ? _buildDarkTheme(themeProvider)
                : (WidgetsBinding
                              .instance
                              .platformDispatcher
                              .platformBrightness ==
                          Brightness.light
                      ? _buildLightTheme(themeProvider)
                      : _buildDarkTheme(themeProvider)),
            duration: const Duration(milliseconds: 300), // 动画持续时间
            curve: Curves.easeInOut, // 动画曲线
            child: Builder(
              builder: (context) {
                return MaterialApp(
                  navigatorKey: navigatorKey, // 全局导航器 Key
                  title: '知雨天气2',
                  debugShowCheckedModeBanner: false,
                  // 中文本地化支持
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('zh', 'CN'), // 简体中文
                    Locale('en', 'US'), // 英文
                  ],
                  locale: const Locale('zh', 'CN'), // 默认中文
                  theme: _buildLightTheme(themeProvider),
                  darkTheme: _buildDarkTheme(themeProvider),
                  themeMode: _getThemeMode(themeProvider.themeMode),
                  navigatorObservers: [_RouteObserver(_pageActivationObserver)],
                  home: const AppSplashScreen(), // 保留启动页面确保正确初始化
                );
              },
            ),
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(AppThemeMode appThemeMode) {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeData _buildLightTheme(ThemeProvider themeProvider) {
    return ThemeData(
      primarySwatch: MaterialColor(0xFF012d78, {
        50: const Color(0xFFE3F2FD),
        100: const Color(0xFFBBDEFB),
        200: const Color(0xFF90CAF9),
        300: const Color(0xFF64B5F6),
        400: const Color(0xFF42A5F5),
        500: const Color(0xFF012d78),
        600: const Color(0xFF1E88E5),
        700: const Color(0xFF1976D2),
        800: const Color(0xFF1565C0),
        900: const Color(0xFF0D47A1),
      }),
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color.fromARGB(255, 192, 216, 236), // 浅蓝背景
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 192, 216, 236),
        foregroundColor: Color(0xFF001A4D), // 深蓝色文字
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF012d78), // 深蓝色主色
        secondary: Color(0xFF8edafc), // 亮蓝色
        surface: Color(0xFFFFFFFF),
        background: Color.fromARGB(255, 192, 216, 236),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFF001A4D),
        onSurface: Color(0xFF001A4D), // 深蓝色文字
        onBackground: Color(0xFF001A4D), // 深蓝色文字
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension.light(), // 添加自定义主题扩展
      ],
    );
  }

  ThemeData _buildDarkTheme(ThemeProvider themeProvider) {
    return ThemeData(
      primarySwatch: MaterialColor(0xFF4A90E2, {
        50: const Color(0xFFE3F2FD),
        100: const Color(0xFFBBDEFB),
        200: const Color(0xFF90CAF9),
        300: const Color(0xFF64B5F6),
        400: const Color(0xFF42A5F5),
        500: const Color(0xFF4A90E2),
        600: const Color(0xFF1E88E5),
        700: const Color(0xFF1976D2),
        800: const Color(0xFF1565C0),
        900: const Color(0xFF0D47A1),
      }),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A1B3D), // 基于#012d78的深背景
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1B3D),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4A90E2), // 基于#012d78的亮蓝色
        secondary: Color(0xFF8edafc), // 指定的亮蓝色
        surface: Color(0xFF1A2F5D), // 基于#012d78的稍亮表面
        background: Color(0xFF0A1B3D),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFF001A4D),
        onSurface: Color(0xFFFFFFFF),
        onBackground: Color(0xFFFFFFFF),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension.dark(), // 添加自定义主题扩展
      ],
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageActivationObserver _pageActivationObserver =
      PageActivationObserver();

  final List<Widget> _screens = [
    const TodayScreen(),
    const HourlyScreen(),
    const Forecast15dScreen(),
    const MainCitiesScreen(),
  ];

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

    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台，使用统一恢复策略管理
        print('🔄 MainScreen: App进入后台');

        // 进入后台时更新小组件
        _updateWidgetOnPause();

        // 使用恢复管理器保存状态
        AppRecoveryManager().handlePause();
        break;

      case AppLifecycleState.resumed:
        // 应用从后台恢复，使用统一恢复策略
        print('🔄 MainScreen: App从后台恢复');

        final weatherProvider = context.read<WeatherProvider>();

        // 使用恢复管理器处理恢复
        AppRecoveryManager().handleResume(weatherProvider);

        // 应用恢复时也更新小组件
        _updateWidgetOnPause();
        break;

      case AppLifecycleState.detached:
        print('🔄 MainScreen: App被分离');
        // 标记正常关闭
        AppRecoveryManager().handleShutdown();
        break;

      default:
        break;
    }
  }

  /// 应用进入后台时更新小组件
  void _updateWidgetOnPause() {
    try {
      final weatherProvider = context.read<WeatherProvider>();

      // ⚠️ 重要：只更新当前定位的数据，不更新城市数据
      // 小组件应该始终显示当前定位的天气，而不是用户浏览的城市天气
      if (weatherProvider.currentLocationWeather != null &&
          weatherProvider.originalLocation != null) {
        final widgetService = WeatherWidgetService.getInstance();

        print('📱 MainScreen: 进入后台时准备更新小组件');
        print(
          '   当前显示的数据: ${weatherProvider.currentWeather?.current?.current?.temperature}℃ (可能是城市数据)',
        );
        print(
          '   定位数据: ${weatherProvider.currentLocationWeather?.current?.current?.temperature}℃',
        );
        print('   是否显示城市数据: ${weatherProvider.isShowingCityWeather}');
        print('   将使用定位数据更新小组件 ✅');

        widgetService.updateWidget(
          weatherData: weatherProvider.currentLocationWeather!,
          location: weatherProvider.originalLocation!,
        );
        print('📱 MainScreen: 小组件已更新（使用定位数据）');
      }
    } catch (e) {
      print('❌ MainScreen: 更新小组件失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听主题变化，确保整个MainScreen在主题切换时重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        // 在构建时通知TodayScreen被激活（应用启动时）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageActivationObserver.notifyPageActivated('TodayScreen');
        });

        return Scaffold(
          drawer: const AppDrawer(),
          body: IndexedStack(index: _currentIndex, children: _screens),
          resizeToAvoidBottomInset: false,
          bottomNavigationBar: CustomBottomNavigationV2(
            currentIndex: _currentIndex,
            onTap: (index) {
              // 通知页面停用（当前页面）
              switch (_currentIndex) {
                case 0:
                  _pageActivationObserver.notifyPageDeactivated('TodayScreen');
                  break;
                case 1:
                  _pageActivationObserver.notifyPageDeactivated('HourlyScreen');
                  break;
                case 2:
                  _pageActivationObserver.notifyPageDeactivated(
                    'Forecast15dScreen',
                  );
                  break;
                case 3:
                  _pageActivationObserver.notifyPageDeactivated(
                    'MainCitiesScreen',
                  );
                  break;
              }

              setState(() {
                _currentIndex = index;
              });

              // 通知页面激活（新页面）
              switch (index) {
                case 0:
                  _pageActivationObserver.notifyPageActivated('TodayScreen');
                  break;
                case 1:
                  _pageActivationObserver.notifyPageActivated('HourlyScreen');
                  break;
                case 2:
                  _pageActivationObserver.notifyPageActivated(
                    'Forecast15dScreen',
                  );
                  break;
                case 3:
                  _pageActivationObserver.notifyPageActivated(
                    'MainCitiesScreen',
                  );
                  break;
              }

              // 通知WeatherProvider当前标签页变化
              context.read<WeatherProvider>().setCurrentTabIndex(index);

              // 如果切换到今日天气页面（索引0），且是首次进入，进行定位
              if (index == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context
                      .read<WeatherProvider>()
                      .performLocationAfterEntering();
                });
              }
            },
            items: const [
              BottomNavigationItem(icon: Icons.today, label: '今日天气'),
              BottomNavigationItem(icon: Icons.schedule, label: '24小时'),
              BottomNavigationItem(icon: Icons.calendar_today, label: '15日预报'),
              BottomNavigationItem(icon: Icons.location_city, label: '主要城市'),
            ],
          ),
          floatingActionButton: _buildFloatingActionIsland(),
        );
      },
    );
  }

  /// 构建浮动操作岛（根据当前页面显示不同操作）
  Widget _buildFloatingActionIsland() {
    return Consumer2<WeatherProvider, ThemeProvider>(
      builder: (context, weatherProvider, themeProvider, child) {
        print('🏝️ MainScreen: 当前tab索引 = $_currentIndex');

        // 根据当前页面显示不同的操作
        List<IslandAction> actions = [];

        // 所有页面都有刷新、设置、主题切换
        actions.addAll([
          IslandAction(
            icon: Icons.refresh_rounded,
            label: _currentIndex == 0 ? '刷新天气' : '刷新',
            onTap: () async {
              await weatherProvider.forceRefreshWithLocation();
            },
            backgroundColor: AppColors.primaryBlue,
          ),
          IslandAction(
            icon: Icons.settings_rounded,
            label: '设置',
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            backgroundColor: AppColors.primaryBlue,
          ),
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
        ]);

        // 今日天气页面专属功能
        if (_currentIndex == 0) {
          actions.addAll([
            // AI智能助手
            IslandAction(
              icon: Icons.auto_awesome,
              label: 'AI助手',
              onTap: () {
                weatherProvider.generateWeatherSummary(forceRefresh: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('正在重新生成AI摘要...'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                );
              },
              backgroundColor: const Color(0xFFFFB300),
            ),
            // 综合提醒
            IslandAction(
              icon: Icons.notifications_active,
              label: '综合提醒',
              onTap: () {
                final alertService = WeatherAlertService.instance;
                final currentLocation = weatherProvider.currentLocation;
                final district =
                    currentLocation?.district ?? currentLocation?.city ?? '未知';

                final smartAlerts = alertService.getAlertsForCity(
                  district,
                  currentLocation,
                );
                final commuteAdvices = weatherProvider.commuteAdvices;

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
              backgroundColor: AppColors.error,
            ),
            // 分享天气
            IslandAction(
              icon: Icons.share,
              label: '分享天气',
              onTap: () async {
                final weather = weatherProvider.currentWeather;
                final location = weatherProvider.currentLocation;
                final themeProvider = context.read<ThemeProvider>();
                final sunMoonIndexData = weatherProvider.sunMoonIndexData;

                if (weather == null || location == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('天气数据加载中，请稍后再试'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                // 生成并保存天气海报（传入紫外线数据）
                await WeatherShareService.instance.generateAndSavePoster(
                  context: context,
                  weather: weather,
                  location: location,
                  themeProvider: themeProvider,
                  sunMoonIndexData: sunMoonIndexData,
                );
              },
              backgroundColor: AppColors.accentGreen,
            ),
            // 智能穿搭顾问
            IslandAction(
              icon: Icons.checkroom_rounded,
              label: '穿搭顾问',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OutfitAdvisorScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF9C27B0),
            ),
            // 健康管家
            IslandAction(
              icon: Icons.favorite_rounded,
              label: '健康管家',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthAdvisorScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFFE91E63),
            ),
            // 异常天气预警
            IslandAction(
              icon: Icons.warning_rounded,
              label: '异常预警',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExtremeWeatherAlertScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFFFF5722),
            ),
            // 天气雷达图功能已移除
          ]);
        }

        print('🏝️ MainScreen: 浮动岛功能总数 = ${actions.length}');
        for (var i = 0; i < actions.length; i++) {
          print('  ${i + 1}. ${actions[i].label}');
        }

        return FloatingActionIsland(
          mainIcon: Icons.menu_rounded,
          mainTooltip: '快捷操作',
          actions: actions,
        );
      },
    );
  }
}
