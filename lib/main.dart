import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/today_screen.dart';
import 'screens/hourly_screen.dart';
import 'screens/forecast15d_screen.dart';
import 'screens/app_splash_screen.dart';
import 'screens/main_cities_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/custom_bottom_navigation_v2.dart';
import 'widgets/main_app_bar.dart';
import 'services/page_activation_observer.dart';
import 'services/weather_widget_service.dart';
import 'services/app_route_observer.dart';
import 'services/app_initialization_service.dart';
import 'services/database_service.dart';
import 'services/weather_service.dart';
import 'services/smart_cache_service.dart';
import 'utils/app_recovery_manager.dart';
import 'utils/global_exception_handler.dart';
import 'utils/logger.dart';
import 'constants/app_colors.dart';
import 'constants/theme_extensions.dart';

// 全局路由观察者
final PageActivationObserver _pageActivationObserver = PageActivationObserver();

// 全局导航器 Key（用于通知点击等场景的导航）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 应用在后台的时间戳
DateTime? _appInBackgroundSince;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局异常处理器
  GlobalExceptionHandler().initialize();
  Logger.separator(title: 'RainWeather 启动');

  // 🚀 关键初始化：优先显示启动画面
  AppInitializationService().initializeCriticalServices();

  // 📱 立即启动应用，让用户看到启动画面
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
    // 清理数据库和服务资源
    _cleanupResources();
    super.dispose();
  }

  /// 清理应用资源
  void _cleanupResources() {
    try {
      // 关闭数据库连接
      DatabaseService.getInstance().close();
      Logger.d('数据库已关闭', tag: 'RainWeatherApp');

      // 释放天气服务资源
      WeatherService.getInstance().dispose();
      Logger.d('天气服务已释放', tag: 'RainWeatherApp');

      // 释放缓存服务资源
      SmartCacheService().dispose();
      Logger.d('缓存服务已释放', tag: 'RainWeatherApp');
    } catch (e) {
      Logger.e('清理资源失败', tag: 'RainWeatherApp', error: e);
    }
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
    // 重置应用状态管理器（通过 AppRecoveryManager）
    AppRecoveryManager().handleShutdown();

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
                  title: '智雨天气',
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
                  navigatorObservers: [
                    AppRouteObserver(_pageActivationObserver),
                  ],
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
      // 固定浅蓝背景，只随亮暗模式切换
      scaffoldBackgroundColor: const Color.fromARGB(255, 192, 216, 236),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 192, 216, 236),
        foregroundColor: Color(0xFF001A4D), // 深蓝色文字
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(decoration: TextDecoration.none),
        displayMedium: TextStyle(decoration: TextDecoration.none),
        displaySmall: TextStyle(decoration: TextDecoration.none),
        headlineLarge: TextStyle(decoration: TextDecoration.none),
        headlineMedium: TextStyle(decoration: TextDecoration.none),
        headlineSmall: TextStyle(decoration: TextDecoration.none),
        titleLarge: TextStyle(decoration: TextDecoration.none),
        titleMedium: TextStyle(decoration: TextDecoration.none),
        titleSmall: TextStyle(decoration: TextDecoration.none),
        bodyLarge: TextStyle(decoration: TextDecoration.none),
        bodyMedium: TextStyle(decoration: TextDecoration.none),
        bodySmall: TextStyle(decoration: TextDecoration.none),
        labelLarge: TextStyle(decoration: TextDecoration.none),
        labelMedium: TextStyle(decoration: TextDecoration.none),
        labelSmall: TextStyle(decoration: TextDecoration.none),
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(decoration: TextDecoration.none),
        displayMedium: TextStyle(decoration: TextDecoration.none),
        displaySmall: TextStyle(decoration: TextDecoration.none),
        headlineLarge: TextStyle(decoration: TextDecoration.none),
        headlineMedium: TextStyle(decoration: TextDecoration.none),
        headlineSmall: TextStyle(decoration: TextDecoration.none),
        titleLarge: TextStyle(decoration: TextDecoration.none),
        titleMedium: TextStyle(decoration: TextDecoration.none),
        titleSmall: TextStyle(decoration: TextDecoration.none),
        bodyLarge: TextStyle(decoration: TextDecoration.none),
        bodyMedium: TextStyle(decoration: TextDecoration.none),
        bodySmall: TextStyle(decoration: TextDecoration.none),
        labelLarge: TextStyle(decoration: TextDecoration.none),
        labelMedium: TextStyle(decoration: TextDecoration.none),
        labelSmall: TextStyle(decoration: TextDecoration.none),
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
          appBar: MainAppBar(
            currentIndex: _currentIndex,
            onTabChange: (index) => setState(() => _currentIndex = index),
          ),
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
        );
      },
    );
  }
}
