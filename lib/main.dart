import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/today_screen.dart';
import 'screens/hourly_screen.dart';
import 'screens/forecast15d_screen.dart';
import 'screens/city_weather_tabs_screen.dart';
import 'screens/weather_alerts_screen.dart';
import 'screens/app_splash_screen.dart';
import 'widgets/city_card_skeleton.dart';
import 'models/city_model.dart';
import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'constants/theme_extensions.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/baidu_location_service.dart';
import 'services/amap_location_service.dart';
import 'services/tencent_location_service.dart';
import 'services/location_change_notifier.dart';
import 'services/page_activation_observer.dart';
import 'services/weather_widget_service.dart';
import 'models/location_model.dart';
import 'models/weather_model.dart';
import 'widgets/custom_bottom_navigation_v2.dart';
import 'utils/city_name_matcher.dart';
import 'utils/app_state_manager.dart';
import 'utils/app_recovery_manager.dart';

// 全局路由观察者
final PageActivationObserver _pageActivationObserver = PageActivationObserver();

// 应用在后台的时间戳
DateTime? _appInBackgroundSince;

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

  // 初始化通知服务并请求权限
  try {
    print('🔔 初始化通知服务');
    final notificationService = NotificationService.instance;
    await notificationService.initialize();

    // 创建通知渠道（Android）
    await notificationService.createNotificationChannels();

    // 请求通知权限
    final permissionGranted = await notificationService.requestPermissions();
    print('🔔 通知权限请求结果: $permissionGranted');

    if (!permissionGranted) {
      print('⚠️ 通知权限未授予，部分功能可能无法使用');
    }
  } catch (e) {
    print('❌ 通知服务初始化失败: $e');
  }

  // 全局设置腾讯定位服务
  try {
    print('🔧 全局设置腾讯定位服务');
    final tencentLocationService = TencentLocationService.getInstance();
    await tencentLocationService.setGlobalPrivacyAgreement();
    print('✅ 腾讯定位服务设置成功');
  } catch (e) {
    print('❌ 腾讯定位服务设置失败: $e');
  }

  // 全局设置百度定位隐私政策同意
  try {
    print('🔧 全局设置百度定位隐私政策同意');
    final baiduLocationService = BaiduLocationService.getInstance();
    await baiduLocationService.setGlobalPrivacyAgreement();
    print('✅ 百度定位隐私政策同意设置成功');
  } catch (e) {
    print('❌ 百度定位隐私政策同意设置失败: $e');
  }

  // 全局设置高德地图API Key
  try {
    print('🔧 全局设置高德地图API Key');
    final amapLocationService = AMapLocationService.getInstance();
    await amapLocationService.setGlobalAPIKey();
    print('✅ 高德地图API Key设置成功');
  } catch (e) {
    print('❌ 高德地图API Key设置失败: $e');
  }

  // 请求定位权限（参照demo）
  try {
    print('🔧 请求定位权限');
    final locationService = LocationService.getInstance();
    await locationService.requestLocationPermission();
    print('✅ 定位权限请求完成');
  } catch (e) {
    print('❌ 定位权限请求失败: $e');
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

      // 确保有数据时才更新
      if (weatherProvider.currentWeather != null &&
          weatherProvider.currentLocation != null) {
        final widgetService = WeatherWidgetService.getInstance();
        widgetService.updateWidget(
          weatherData: weatherProvider.currentWeather!,
          location: weatherProvider.currentLocation!,
        );
        print('📱 MainScreen: 进入后台时更新小组件');
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
          floatingActionButton: _currentIndex == 0
              ? Consumer<WeatherProvider>(
                  builder: (context, weatherProvider, child) {
                    return Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: weatherProvider.isLoading
                                  ? AppColors.glassBackground.withOpacity(0.8)
                                  : AppColors.glassBackground,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.borderColor,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: weatherProvider.isLoading
                                    ? null
                                    : () async {
                                        // 执行强制刷新（不显示Toast提示）
                                        await weatherProvider
                                            .forceRefreshWithLocation();
                                      },
                                child: Center(
                                  child: weatherProvider.isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.textPrimary,
                                                ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.refresh,
                                          color: AppColors.textPrimary,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}

// Placeholder screens for other tabs

class MainCitiesScreen extends StatefulWidget {
  const MainCitiesScreen({super.key});

  @override
  State<MainCitiesScreen> createState() => _MainCitiesScreenState();
}

class _MainCitiesScreenState extends State<MainCitiesScreen>
    with LocationChangeListener {
  @override
  void initState() {
    super.initState();
    // 添加定位变化监听器
    LocationChangeNotifier().addListener(this);
    // 调试：打印当前监听器状态
    LocationChangeNotifier().debugPrintStatus();
  }

  @override
  void dispose() {
    // 移除定位变化监听器
    LocationChangeNotifier().removeListener(this);
    super.dispose();
  }

  /// 定位成功回调（主要城市页面不响应今日天气页面的定位）
  @override
  void onLocationSuccess(LocationModel newLocation) {
    print('📍 MainCitiesScreen: 收到定位成功通知 ${newLocation.district}');
    print('📍 MainCitiesScreen: 主要城市页面只响应自己的定位图标，忽略此通知');
    // 主要城市页面只有点击定位图标才会更新第一个卡片
  }

  /// 定位失败回调（主要城市页面不响应今日天气页面的定位失败）
  @override
  void onLocationFailed(String error) {
    print('❌ MainCitiesScreen: 收到定位失败通知 $error');
    print('❌ MainCitiesScreen: 主要城市页面只响应自己的定位图标，忽略此通知');
    // 主要城市页面只有点击定位图标失败时才提示
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
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '主要城市',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Consumer<WeatherProvider>(
                              builder: (context, weatherProvider, child) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showAddCityDialog(
                                        context,
                                        weatherProvider,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        '添加城市',
                                        style: TextStyle(
                                          color: AppColors.titleBarIconColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // 刷新图标 - 只刷新列表数据，不进行定位
                                    IconButton(
                                      onPressed:
                                          weatherProvider.isLoading ||
                                              weatherProvider
                                                  .isLocationRefreshing
                                          ? null
                                          : () async {
                                              // 只刷新主要城市天气，不重新定位
                                              await weatherProvider
                                                  .refreshMainCitiesWeather();
                                            },
                                      icon:
                                          weatherProvider.isLoading ||
                                              weatherProvider
                                                  .isLocationRefreshing
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.textPrimary),
                                              ),
                                            )
                                          : Icon(
                                              Icons.refresh,
                                              color:
                                                  AppColors.titleBarIconColor,
                                              size: AppColors.titleBarIconSize,
                                            ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '长按拖拽可调整城市顺序，左滑可删除城市（当前位置城市除外）',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cities List
                  Expanded(
                    child: Consumer<WeatherProvider>(
                      builder: (context, weatherProvider, child) {
                        final cities = weatherProvider.mainCities;
                        final isLoading = weatherProvider.isLoadingCities;

                        // 首次进入主要城市列表时主动刷新天气数据
                        if (cities.isNotEmpty &&
                            !weatherProvider
                                .hasPerformedInitialMainCitiesRefresh) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            weatherProvider.performInitialMainCitiesRefresh();
                          });
                        }

                        // 首次加载（没有数据）：显示加载圈
                        if (isLoading && cities.isEmpty) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentBlue,
                            ),
                          );
                        }

                        // 刷新中（有数据）：显示骨架屏，避免页面抖动
                        if ((isLoading ||
                                weatherProvider.isLoadingCitiesWeather) &&
                            cities.isNotEmpty) {
                          return CityCardSkeletonList(itemCount: cities.length);
                        }

                        // 没有数据且不在加载：显示空状态
                        if (cities.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_city_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '暂无主要城市',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // 正常显示城市列表
                        return RefreshIndicator(
                          onRefresh: () async {
                            await weatherProvider.refreshMainCitiesWeather();
                          },
                          color: AppColors.primaryBlue,
                          backgroundColor: AppColors.backgroundSecondary,
                          child: ReorderableListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppConstants.screenHorizontalPadding,
                            ),
                            itemCount: cities.length,
                            onReorder: (oldIndex, newIndex) async {
                              // Handle reordering
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }

                              // Get current location city name
                              final currentLocationName = weatherProvider
                                  .getCurrentLocationCityName();

                              // Don't allow reordering if trying to move current location
                              if (cities[oldIndex].name ==
                                  currentLocationName) {
                                return;
                              }

                              // Create new list with reordered cities
                              final List<CityModel> reorderedCities = List.from(
                                cities,
                              );
                              final city = reorderedCities.removeAt(oldIndex);
                              reorderedCities.insert(newIndex, city);

                              // Update sort order
                              await weatherProvider.updateCitiesSortOrder(
                                reorderedCities,
                              );
                            },
                            itemBuilder: (context, index) {
                              final city = cities[index];
                              final cityWeather = weatherProvider
                                  .getCityWeather(city.name);
                              // 判断是否是当前城市：名称匹配或者是虚拟当前城市
                              final currentLocationName = weatherProvider
                                  .getCurrentLocationCityName();
                              final isCurrentLocation =
                                  CityNameMatcher.isCurrentLocationCity(
                                    city.name,
                                    currentLocationName,
                                    city.id,
                                  );

                              // 调试信息
                              print('🔍 City: ${city.name}, ID: ${city.id}');
                              print(
                                '🔍 Current location name: $currentLocationName',
                              );
                              print(
                                '🔍 Is current location: $isCurrentLocation',
                              );

                              return Dismissible(
                                key: ValueKey(
                                  'dismissible_${city.id}_${city.name}_${index}',
                                ),
                                direction: isCurrentLocation
                                    ? DismissDirection.none
                                    : DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.error.withOpacity(0.8),
                                        AppColors.error,
                                      ],
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        color: AppColors.textPrimary,
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '删除城市',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondaryBackground: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.textSecondary.withOpacity(
                                          0.8,
                                        ),
                                        AppColors.textSecondary,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cancel_outlined,
                                        color: AppColors.textPrimary,
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '取消',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    // 禁止删除当前位置城市（因为它会自动重新出现）
                                    if (isCurrentLocation) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('当前位置城市无法删除'),
                                            backgroundColor:
                                                AppColors.textSecondary,
                                            duration: Duration(
                                              milliseconds: 1500,
                                            ),
                                          ),
                                        );
                                      }
                                      return false;
                                    }
                                    // 禁止删除虚拟当前城市
                                    if (city.id == 'virtual_current_location') {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('当前位置城市无法删除'),
                                            backgroundColor:
                                                AppColors.textSecondary,
                                            duration: Duration(
                                              milliseconds: 1500,
                                            ),
                                          ),
                                        );
                                      }
                                      return false;
                                    }
                                    return await _showDeleteCityDialog(
                                      context,
                                      weatherProvider,
                                      city,
                                    );
                                  }
                                  return false;
                                },
                                child: Padding(
                                  key: ValueKey(
                                    'padding_${city.id}_${city.name}_${index}',
                                  ),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    elevation: AppColors.cardElevation,
                                    shadowColor: AppColors.cardShadowColor,
                                    color: AppColors.materialCardColor,
                                    shape: AppColors.cardShape,
                                    child: InkWell(
                                      onTap: () {
                                        // Navigate to city weather screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CityWeatherTabsScreen(
                                                  cityName: city.name,
                                                ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Title
                                                  Row(
                                                    children: [
                                                      // 城市名称和定位图标
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              city.name,
                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .textPrimary,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            // 定位图标（如果是当前定位城市）
                                                            if (isCurrentLocation) ...[
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Material(
                                                                color: Colors
                                                                    .transparent,
                                                                child: InkWell(
                                                                  onTap: () async {
                                                                    // 点击定位图标，更新当前位置数据
                                                                    await _updateCurrentLocation(
                                                                      context,
                                                                      weatherProvider,
                                                                    );
                                                                  },
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors
                                                                          .accentGreen
                                                                          .withOpacity(
                                                                            0.15,
                                                                          ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: AppColors
                                                                            .accentGreen
                                                                            .withOpacity(
                                                                              0.6,
                                                                            ),
                                                                        width:
                                                                            1.5,
                                                                      ),
                                                                      // 添加阴影效果
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: AppColors.accentGreen.withOpacity(
                                                                            0.2,
                                                                          ),
                                                                          blurRadius:
                                                                              4,
                                                                          offset: const Offset(
                                                                            0,
                                                                            2,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .my_location,
                                                                          color:
                                                                              AppColors.accentGreen,
                                                                          size:
                                                                              16,
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              6,
                                                                        ),
                                                                        Text(
                                                                          '当前位置',
                                                                          style: TextStyle(
                                                                            color:
                                                                                AppColors.accentGreen,
                                                                            fontSize:
                                                                                11,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      // 预警图标
                                                      _buildCityAlertIcon(
                                                        context,
                                                        cityWeather,
                                                        city.name,
                                                      ),
                                                    ],
                                                  ),
                                                  // Subtitle
                                                  if (cityWeather != null ||
                                                      weatherProvider
                                                          .isLoadingCitiesWeather)
                                                    const SizedBox(height: 8),
                                                  if (cityWeather != null)
                                                    _buildCityWeatherInfo(
                                                      cityWeather,
                                                      weatherProvider,
                                                    )
                                                  else if (weatherProvider
                                                      .isLoadingCitiesWeather)
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  AppColors
                                                                      .textSecondary,
                                                                ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          '加载中...',
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .textSecondary,
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
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建城市气象预警图标（原始预警，来自天气API）
  Widget _buildCityAlertIcon(
    BuildContext context,
    dynamic cityWeather,
    String cityName,
  ) {
    if (cityWeather == null) {
      return const SizedBox.shrink();
    }

    // 获取气象预警（原始预警数据，来自天气API）
    final alerts = cityWeather.current?.alerts;

    // 过滤掉过期的预警
    final validAlerts = _filterExpiredAlerts(alerts);
    final hasValidAlerts = validAlerts.isNotEmpty;

    if (!hasValidAlerts) {
      return const SizedBox.shrink();
    }

    // Icon button without badge
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WeatherAlertsScreen(alerts: validAlerts),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8), // Material Design 3 标准
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
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

  Widget _buildCityWeatherInfo(
    dynamic cityWeather,
    WeatherProvider weatherProvider,
  ) {
    final current = cityWeather?.current?.current;
    if (current == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // 天气图标
          Text(
            weatherProvider.getWeatherIcon(current.weather ?? '晴'),
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          // 温度
          Text(
            '${current.temperature ?? '--'}℃',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          // 天气描述
          Expanded(
            child: Text(
              current.weather ?? '晴',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 湿度和风力
          if (current.humidity != null || current.windpower != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (current.humidity != null)
                  Text(
                    '湿度 ${current.humidity}%',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 11,
                    ),
                  ),
                if (current.windpower != null)
                  Text(
                    '${current.winddir ?? ''}${current.windpower}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Show add city dialog
  void _showAddCityDialog(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) async {
    showDialog(
      context: context,
      builder: (context) => _AddCityDialog(weatherProvider: weatherProvider),
    );
  }

  /// 更新当前位置数据
  Future<void> _updateCurrentLocation(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) async {
    try {
      print('📍 点击定位图标，开始定位并更新第一个卡片');

      // 只定位并更新第一个卡片（当前定位城市）
      final success = await weatherProvider
          .refreshFirstCityLocationAndWeather();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '定位成功，已更新为 ${weatherProvider.currentLocation?.district ?? "当前位置"}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('定位失败，保持显示之前的数据'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 更新位置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('定位失败，保持显示原有数据'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteCityDialog(
    BuildContext context,
    WeatherProvider weatherProvider,
    CityModel city,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundSecondary,
            shape: AppColors.dialogShape,
            title: Text('删除城市', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              '确定要从主要城市中删除 "${city.name}" 吗？',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                  final success = await weatherProvider.removeMainCity(city.id);
                  if (success && context.mounted) {
                    // 使用Toast显示删除成功信息
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已删除城市: ${city.name}'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(milliseconds: 1500),
                      ),
                    );
                  } else if (context.mounted) {
                    // 删除失败也显示Toast
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('删除城市失败，请重试'),
                        backgroundColor: AppColors.error,
                        duration: Duration(milliseconds: 1500),
                      ),
                    );
                  }
                },
                child: Text('删除', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Add City Dialog Widget
class _AddCityDialog extends StatefulWidget {
  final WeatherProvider weatherProvider;

  const _AddCityDialog({required this.weatherProvider});

  @override
  State<_AddCityDialog> createState() => _AddCityDialogState();
}

class _AddCityDialogState extends State<_AddCityDialog> {
  final TextEditingController searchController = TextEditingController();
  List<CityModel> searchResults = [];
  bool isSearching = false;
  bool isInitialLoading = true;

  // 直辖市和省会城市列表
  final defaultCityNames = [
    '北京', '上海', '天津', '重庆', // 直辖市
    '哈尔滨', '长春', '沈阳', '呼和浩特', '石家庄', '太原', '西安', // 北方省会
    '济南', '郑州', '南京', '武汉', '杭州', '合肥', '福州', '南昌', // 中部省会
    '长沙', '贵阳', '成都', '广州', '昆明', '南宁', '海口', // 南方省会
    '兰州', '西宁', '银川', '乌鲁木齐', '拉萨', // 西部省会
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultCities();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// 预加载默认城市
  Future<void> _loadDefaultCities() async {
    setState(() {
      isInitialLoading = true;
    });

    final allDefaultCities = <CityModel>[];
    for (final cityName in defaultCityNames) {
      final results = await widget.weatherProvider.searchCities(cityName);
      if (results.isNotEmpty) {
        // 找到精确匹配的城市
        final exactMatch = results.firstWhere(
          (city) => city.name == cityName,
          orElse: () => results.first,
        );
        allDefaultCities.add(exactMatch);
      }
    }

    if (mounted) {
      setState(() {
        searchResults = allDefaultCities;
        isInitialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Material Design 3: 弹窗样式
      backgroundColor: AppColors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 3,
      icon: Icon(
        Icons.add_location_alt_rounded,
        color: AppColors.accentGreen,
        size: 32,
      ),
      title: Column(
        children: [
          Text(
            '添加城市',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '直辖市 · 省会',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // 固定高度防止溢出
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: '搜索城市名称（如：北京、上海）',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                filled: true,
                fillColor: AppColors.borderColor.withOpacity(0.05),
                // Material Design 3: 更大的圆角
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  setState(() {
                    isSearching = true;
                  });
                  final results = await widget.weatherProvider.searchCities(
                    value,
                  );
                  if (mounted) {
                    setState(() {
                      searchResults = results;
                      isSearching = false;
                    });
                  }
                } else {
                  // 恢复显示默认城市
                  _loadDefaultCities();
                }
              },
            ),
            const SizedBox(height: 16),
            if (isInitialLoading || isSearching)
              Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              )
            else if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final city = searchResults[index];
                    final isMainCity = widget.weatherProvider.mainCities.any(
                      (c) => c.id == city.id,
                    );

                    // Material Design 3: 列表项样式
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isMainCity
                            ? AppColors.accentGreen.withOpacity(0.15)
                            : AppColors.borderColor.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMainCity
                              ? AppColors.accentGreen
                              : AppColors.borderColor.withOpacity(0.2),
                          width: isMainCity ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Row(
                          children: [
                            Text(
                              city.name,
                              style: TextStyle(
                                color: isMainCity
                                    ? AppColors.accentGreen
                                    : AppColors.textPrimary,
                                fontWeight: isMainCity
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              city.id,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: isMainCity
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accentGreen,
                                size: 22,
                              )
                            : Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                        onTap: isMainCity
                            ? null
                            : () async {
                                final success = await widget.weatherProvider
                                    .addMainCity(city);
                                if (success) {
                                  // 刷新UI显示已添加状态
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  // 显示添加成功提示（在弹窗内使用轻量级提示）
                                } else {
                                  // 显示添加失败提示
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('添加城市失败，请重试'),
                                        backgroundColor: AppColors.error,
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    );
                  },
                ),
              )
            else if (searchController.text.isEmpty && searchResults.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '正在加载城市列表...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )
            else if (searchController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '未找到匹配的城市',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
