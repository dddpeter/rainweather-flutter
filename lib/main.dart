import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/custom_bottom_navigation_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  final notificationService = NotificationService.instance;
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // 全局设置百度定位隐私政策同意
  try {
    print('🔧 全局设置百度定位隐私政策同意');
    final baiduLocationService = BaiduLocationService.getInstance();
    await baiduLocationService.setGlobalPrivacyAgreement();
    print('✅ 百度定位隐私政策同意设置成功');
  } catch (e) {
    print('❌ 百度定位隐私政策同意设置失败: $e');
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

class RainWeatherApp extends StatelessWidget {
  const RainWeatherApp({super.key});

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
                  title: 'Rain Weather',
                  debugShowCheckedModeBanner: false,
                  theme: _buildLightTheme(themeProvider),
                  darkTheme: _buildDarkTheme(themeProvider),
                  themeMode: _getThemeMode(themeProvider.themeMode),
                  home: const AppSplashScreen(), // 使用自定义启动页面，支持应用主题
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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TodayScreen(),
    const HourlyScreen(),
    const Forecast15dScreen(),
    const MainCitiesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听主题变化，确保整个MainScreen在主题切换时重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          resizeToAvoidBottomInset: false,
          bottomNavigationBar: CustomBottomNavigationV2(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
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
              });
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

class MainCitiesScreen extends StatelessWidget {
  const MainCitiesScreen({super.key});

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
                                    IconButton(
                                      onPressed: weatherProvider.isLoading
                                          ? null
                                          : () async {
                                              // 执行强制刷新（不显示Toast提示）
                                              await weatherProvider
                                                  .forceRefreshWithLocation();
                                            },
                                      icon: weatherProvider.isLoading
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
                            // 显示刷新提示
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.textPrimary,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('正在刷新主要城市天气数据...'),
                                    ],
                                  ),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }

                            await weatherProvider.refreshMainCitiesWeather();

                            // 显示刷新完成提示
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('主要城市天气数据刷新完成'),
                                  backgroundColor: AppColors.accentGreen,
                                  duration: Duration(milliseconds: 1500),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
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
                                  (currentLocationName != null &&
                                      currentLocationName == city.name) ||
                                  city.id == 'virtual_current_location';

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
                                                              // 调试信息
                                                              Builder(
                                                                builder: (context) {
                                                                  print(
                                                                    '🎯 Showing location icon for: ${city.name}',
                                                                  );
                                                                  return const SizedBox.shrink();
                                                                },
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

  /// 构建城市预警图标（Material Design 3）
  Widget _buildCityAlertIcon(
    BuildContext context,
    dynamic cityWeather,
    String cityName,
  ) {
    if (cityWeather == null) {
      return const SizedBox.shrink();
    }

    final alerts = cityWeather.current?.alerts;
    final hasOriginalAlerts = alerts != null && alerts.isNotEmpty;

    if (!hasOriginalAlerts) {
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
                builder: (context) => WeatherAlertsScreen(alerts: alerts),
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
    final TextEditingController searchController = TextEditingController();
    List<CityModel> searchResults = [];
    bool isSearching = false;

    // 直辖市和省会城市列表
    final defaultCityNames = [
      '北京', '上海', '天津', '重庆', // 直辖市
      '哈尔滨', '长春', '沈阳', '呼和浩特', '石家庄', '太原', '西安', // 北方省会
      '济南', '郑州', '南京', '武汉', '杭州', '合肥', '福州', '南昌', // 中部省会
      '长沙', '贵阳', '成都', '广州', '昆明', '南宁', '海口', // 南方省会
      '兰州', '西宁', '银川', '乌鲁木齐', '拉萨', // 西部省会
    ];

    // 预加载默认城市
    isSearching = true;
    final allDefaultCities = <CityModel>[];
    for (final cityName in defaultCityNames) {
      final results = await weatherProvider.searchCities(cityName);
      if (results.isNotEmpty) {
        // 找到精确匹配的城市
        final exactMatch = results.firstWhere(
          (city) => city.name == cityName,
          orElse: () => results.first,
        );
        allDefaultCities.add(exactMatch);
      }
    }
    searchResults = allDefaultCities;
    isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                      final results = await weatherProvider.searchCities(value);
                      setState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    } else {
                      // 恢复显示默认城市
                      setState(() {
                        isSearching = true;
                      });
                      final allDefaultCities = <CityModel>[];
                      for (final cityName in defaultCityNames) {
                        final results = await weatherProvider.searchCities(
                          cityName,
                        );
                        if (results.isNotEmpty) {
                          final exactMatch = results.firstWhere(
                            (city) => city.name == cityName,
                            orElse: () => results.first,
                          );
                          allDefaultCities.add(exactMatch);
                        }
                      }
                      setState(() {
                        searchResults = allDefaultCities;
                        isSearching = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppColors.accentBlue,
                    ),
                  )
                else if (searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final city = searchResults[index];
                        final isMainCity = weatherProvider.mainCities.any(
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
                                    final success = await weatherProvider
                                        .addMainCity(city);
                                    if (success) {
                                      // 刷新UI显示已添加状态
                                      setState(() {});
                                      // 显示添加成功提示（在弹窗内使用轻量级提示）
                                    } else {
                                      // 显示添加失败提示
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text('添加城市失败，请重试'),
                                            backgroundColor: AppColors.error,
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete city dialog

  /// 更新当前位置数据
  Future<void> _updateCurrentLocation(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) async {
    try {
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text('正在更新位置信息...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // 强制刷新位置和天气数据（清理缓存）
      await weatherProvider.forceRefreshWithLocation();

      // 重新加载主要城市列表
      await weatherProvider.loadMainCities();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('位置信息已更新'),
            backgroundColor: AppColors.accentGreen,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新位置失败: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(milliseconds: 1500),
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
