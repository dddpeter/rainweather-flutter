import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/today_screen.dart';
import 'screens/hourly_screen.dart';
import 'screens/forecast15d_screen.dart';
import 'screens/city_weather_screen.dart';
import 'models/city_model.dart';
import 'constants/app_colors.dart';
import 'services/location_service.dart';
import 'widgets/custom_bottom_navigation_v2.dart';

void main() {
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
          
          return MaterialApp(
            title: 'Rain Weather',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(themeProvider),
            darkTheme: _buildDarkTheme(themeProvider),
            themeMode: _getThemeMode(themeProvider.themeMode),
            home: const SplashScreen(),
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
      scaffoldBackgroundColor: const Color(0xFFF0F8FF), // 浅蓝背景
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF0F8FF),
        foregroundColor: Color(0xFF001A4D), // 深蓝色文字
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF012d78), // 深蓝色主色
        secondary: Color(0xFF8edafc), // 亮蓝色
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFF0F8FF),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFF001A4D),
        onSurface: Color(0xFF001A4D), // 深蓝色文字
        onBackground: Color(0xFF001A4D), // 深蓝色文字
      ),
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: CustomBottomNavigationV2(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationItem(
            icon: Icons.today,
            label: '今日天气',
          ),
          BottomNavigationItem(
            icon: Icons.schedule,
            label: '24小时',
          ),
          BottomNavigationItem(
            icon: Icons.calendar_today,
            label: '15日预报',
          ),
          BottomNavigationItem(
            icon: Icons.location_city,
            label: '主要城市',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens for other tabs

class MainCitiesScreen extends StatelessWidget {
  const MainCitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
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
                                IconButton(
                                  onPressed: () => _showAddCityDialog(context, weatherProvider),
                                  icon: Icon(
                                    Icons.add_location,
                                    color: AppColors.titleBarIconColor,
                                    size: AppColors.titleBarIconSize,
                                  ),
                                ),
                                IconButton(
                                  onPressed: weatherProvider.isLoading
                                      ? null
                                      : () => weatherProvider.forceRefreshWithLocation(),
                                  icon: weatherProvider.isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                                          ),
                                        )
                                      : Icon(
                                          Icons.refresh,
                                          color: AppColors.titleBarIconColor,
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
                    if (weatherProvider.isLoadingCities) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentBlue,
                        ),
                      );
                    }

                    final cities = weatherProvider.mainCities;
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

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cities.length,
                      onReorder: (oldIndex, newIndex) async {
                        // Handle reordering
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        
                        // Get current location city name
                        final currentLocationName = weatherProvider.getCurrentLocationCityName();
                        
                        // Don't allow reordering if trying to move current location
                        if (cities[oldIndex].name == currentLocationName) {
                          return;
                        }
                        
                        // Create new list with reordered cities
                        final List<CityModel> reorderedCities = List.from(cities);
                        final city = reorderedCities.removeAt(oldIndex);
                        reorderedCities.insert(newIndex, city);
                        
                        // Update sort order
                        await weatherProvider.updateCitiesSortOrder(reorderedCities);
                      },
                      itemBuilder: (context, index) {
                        final city = cities[index];
                        final cityWeather = weatherProvider.getCityWeather(city.name);
                        final isCurrentLocation = weatherProvider.getCurrentLocationCityName() == city.name;
                        
                        return Dismissible(
                          key: Key('${city.id}_dismissible'),
                          direction: isCurrentLocation ? DismissDirection.none : DismissDirection.endToStart,
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
                              borderRadius: BorderRadius.circular(16),
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
                                  AppColors.textSecondary.withOpacity(0.8),
                                  AppColors.textSecondary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
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
                            if (direction == DismissDirection.endToStart) {
                              return await _showDeleteCityDialog(context, weatherProvider, city);
                            }
                            return false;
                          },
                          child: Container(
                            key: Key(city.id),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cardBorder,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Row(
                                children: [
                                  // 定位图标（如果是当前定位城市）
                                  if (isCurrentLocation) ...[
                                    GestureDetector(
                                      onTap: () async {
                                        // 点击定位图标，更新当前位置数据
                                        await _updateCurrentLocation(context, weatherProvider);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGreen.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.accentGreen.withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.my_location,
                                              color: AppColors.accentGreen,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '当前位置',
                                              style: TextStyle(
                                                color: AppColors.accentGreen,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      city.name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: cityWeather != null
                                  ? _buildCityWeatherInfo(cityWeather, weatherProvider)
                                  : weatherProvider.isLoadingCitiesWeather
                                      ? Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '加载中...',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                              onTap: () {
                                // Navigate to city weather screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CityWeatherScreen(cityName: city.name),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityWeatherInfo(dynamic cityWeather, WeatherProvider weatherProvider) {
    final current = cityWeather?.current?.current;
    if (current == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // 天气图标
          Text(
            weatherProvider.getWeatherIcon(current.weather ?? '晴'),
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          // 温度
          Text(
            '${current.temperature ?? '--'}°',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          // 天气描述
          Expanded(
            child: Text(
              current.weather ?? '晴',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
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
  void _showAddCityDialog(BuildContext context, WeatherProvider weatherProvider) {
    final TextEditingController searchController = TextEditingController();
    List<CityModel> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: AppColors.dialogShape,
          title: Text(
            '添加城市',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // 固定高度防止溢出
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '搜索城市名称（如：北京、上海）',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.accentBlue),
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
                      setState(() {
                        searchResults = [];
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
                        final isMainCity = weatherProvider.mainCities.any((c) => c.id == city.id);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isMainCity 
                                ? AppColors.accentGreen.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isMainCity 
                                ? Border.all(color: AppColors.accentGreen.withOpacity(0.3))
                                : null,
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              city.name,
                              style: TextStyle(
                                color: isMainCity 
                                    ? AppColors.accentGreen 
                                    : AppColors.textPrimary,
                                fontWeight: isMainCity ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '城市ID: ${city.id}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            trailing: isMainCity
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppColors.accentGreen,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.titleBarDecorIconColor,
                                    size: AppColors.titleBarDecorIconSize,
                                  ),
                            onTap: isMainCity ? null : () async {
                              final success = await weatherProvider.addMainCity(city);
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已添加城市: ${city.name}'),
                                    backgroundColor: AppColors.accentGreen,
                                    duration: const Duration(milliseconds: 1500),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('添加城市失败，请重试'),
                                    backgroundColor: AppColors.error,
                                    duration: Duration(milliseconds: 1500),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete city dialog
  /// 更新当前位置数据
  Future<void> _updateCurrentLocation(BuildContext context, WeatherProvider weatherProvider) async {
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
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

  Future<bool> _showDeleteCityDialog(BuildContext context, WeatherProvider weatherProvider, CityModel city) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: AppColors.dialogShape,
        title: Text(
          '删除城市',
          style: TextStyle(color: AppColors.textPrimary),
        ),
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
            child: Text(
              '删除',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = true;
  String _statusMessage = '正在初始化...';
  bool _showPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // 等待动画完成
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 检查权限
      setState(() {
        _statusMessage = '检查定位权限...';
      });
      
      final context = this.context;
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      final locationService = LocationService.getInstance();
      
      // 检查权限状态，但不强制请求权限
      final permissionStatus = await locationService.checkLocationPermission();
      
      if (!mounted) return;
      
      if (permissionStatus == LocationPermissionResult.granted) {
        setState(() {
          _statusMessage = '权限已获取，正在加载天气数据...';
        });
      } else {
        setState(() {
          _statusMessage = '权限未获取，使用北京天气...';
        });
      }
      
      // 无论是否有权限都初始化天气数据
      await weatherProvider.initializeWeather();
      
      if (!mounted) return;
      
      setState(() {
        _statusMessage = '加载完成';
      });
      
      // 延迟一下再跳转到主界面
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '初始化失败，请重试';
        _showPermissionDialog = true;
      });
    }
  }

  void _requestPermissionAgain() async {
    setState(() {
      _showPermissionDialog = false;
      _statusMessage = '重新请求权限...';
    });
    
    await _initializeApp();
  }

  void _skipPermission() {
    setState(() {
      _showPermissionDialog = false;
      _statusMessage = '跳过权限，使用默认位置...';
    });
    
    // 直接跳转到主界面，让应用使用默认位置
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 和动画
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          // 应用图标
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.cardBorder,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.wb_sunny,
                              size: 60,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // 应用名称
                          Text(
                            '知雨天气2',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '智能天气预报应用',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 60),
              
              // 加载指示器
              if (_isLoading) ...[
                CircularProgressIndicator(
                  color: AppColors.textPrimary,
                ),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              // 权限对话框
              if (_showPermissionDialog) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 48,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '初始化失败',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '应用初始化失败，您可以重试或跳过权限直接使用。',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _skipPermission,
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.cardBackground,
                                foregroundColor: AppColors.textSecondary,
                              ),
                              child: Text('跳过'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _requestPermissionAgain,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: AppColors.textPrimary,
                              ),
                              child: Text('重试'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}