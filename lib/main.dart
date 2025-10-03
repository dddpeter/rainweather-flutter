import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/today_screen.dart';
import 'screens/hourly_screen.dart';
import 'screens/forecast15d_screen.dart';
import 'screens/city_weather_screen.dart';
import 'models/city_model.dart';
import 'constants/app_colors.dart';
import 'services/location_service.dart';

void main() {
  runApp(const RainWeatherApp());
}

class RainWeatherApp extends StatelessWidget {
  const RainWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: MaterialApp(
        title: 'Rain Weather',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          fontFamily: 'JetBrainsMono',
          scaffoldBackgroundColor: AppColors.backgroundPrimary,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.backgroundPrimary,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentBlue,
            secondary: AppColors.accentGreen,
            surface: AppColors.backgroundSecondary,
            background: AppColors.backgroundPrimary,
            onPrimary: AppColors.textPrimary,
            onSecondary: AppColors.textPrimary,
            onSurface: AppColors.textPrimary,
            onBackground: AppColors.textPrimary,
          ),
          // 自定义颜色扩展
          extensions: const <ThemeExtension<dynamic>>[
            _AppThemeExtension(
              cardBackground: AppColors.cardBackground,
              glassBackground: AppColors.glassBackground,
              borderColor: AppColors.borderColor,
              dividerColor: AppColors.dividerColor,
              successColor: AppColors.success,
              warningColor: AppColors.warning,
              errorColor: AppColors.error,
              infoColor: AppColors.info,
            ),
          ],
        ),
        home: const SplashScreen(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          border: Border(
            top: BorderSide(
              color: AppColors.borderColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.backgroundSecondary,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.today),
              label: '今日天气',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule),
              label: '24小时',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: '15日预报',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_city),
              label: '主要城市',
            ),
          ],
        ),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
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
                        const Text(
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
                                  icon: const Icon(
                                    Icons.add_location,
                                    color: AppColors.accentGreen,
                                    size: 24,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: AppColors.backgroundSecondary,
                                        title: const Text(
                                          '清理缓存',
                                          style: TextStyle(color: AppColors.textPrimary),
                                        ),
                                        content: const Text(
                                          '确定要清理所有缓存的天气数据吗？这将删除所有本地缓存，下次加载时需要重新获取数据。',
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text(
                                              '取消',
                                              style: TextStyle(color: AppColors.textSecondary),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              weatherProvider.clearAllCache();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('缓存已清理'),
                                                  backgroundColor: AppColors.accentBlue,
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              '确定',
                                              style: TextStyle(color: AppColors.accentBlue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete_sweep,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  onPressed: weatherProvider.isLoading
                                      ? null
                                      : () => weatherProvider.forceRefreshWithLocation(),
                                  icon: weatherProvider.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.refresh,
                                          color: AppColors.textPrimary,
                                          size: 24,
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
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentBlue,
                        ),
                      );
                    }

                    final cities = weatherProvider.mainCities;
                    if (cities.isEmpty) {
                      return const Center(
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '删除城市',
                                  style: TextStyle(
                                    color: Colors.white,
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '取消',
                                  style: TextStyle(
                                    color: Colors.white,
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
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
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
                                            const Icon(
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
                                      style: const TextStyle(
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
                                      ? const Padding(
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
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.accentBlue,
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
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          // 温度
          Text(
            '${current.temperature ?? '--'}°',
            style: const TextStyle(
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
              style: const TextStyle(
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
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 11,
                    ),
                  ),
                if (current.windpower != null)
                  Text(
                    '${current.winddir ?? ''}${current.windpower}',
                    style: const TextStyle(
                      color: AppColors.accentBlue,
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
          title: const Text(
            '添加城市',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '搜索城市名称（如：北京、上海）',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accentBlue),
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppColors.accentBlue,
                    ),
                  )
                else if (searchResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                      minHeight: 0,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
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
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            trailing: isMainCity
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.accentGreen,
                                    size: 20,
                                  )
                                : const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.accentBlue,
                                    size: 20,
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
                                  const SnackBar(
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
                  const Padding(
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
              child: const Text(
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
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
          const SnackBar(
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
        title: const Text(
          '删除城市',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '确定要从主要城市中删除 "${city.name}" 吗？',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
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
                  const SnackBar(
                    content: Text('删除城市失败，请重试'),
                    backgroundColor: AppColors.error,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            },
            child: const Text(
              '删除',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

}

/// 自定义主题扩展
class _AppThemeExtension extends ThemeExtension<_AppThemeExtension> {
  final Color cardBackground;
  final Color glassBackground;
  final Color borderColor;
  final Color dividerColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color infoColor;

  const _AppThemeExtension({
    required this.cardBackground,
    required this.glassBackground,
    required this.borderColor,
    required this.dividerColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.infoColor,
  });

  @override
  _AppThemeExtension copyWith({
    Color? cardBackground,
    Color? glassBackground,
    Color? borderColor,
    Color? dividerColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? infoColor,
  }) {
    return _AppThemeExtension(
      cardBackground: cardBackground ?? this.cardBackground,
      glassBackground: glassBackground ?? this.glassBackground,
      borderColor: borderColor ?? this.borderColor,
      dividerColor: dividerColor ?? this.dividerColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      infoColor: infoColor ?? this.infoColor,
    );
  }

  @override
  _AppThemeExtension lerp(_AppThemeExtension? other, double t) {
    if (other is! _AppThemeExtension) {
      return this;
    }
    return _AppThemeExtension(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
    );
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
  bool _permissionGranted = false;
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
          _permissionGranted = true;
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
        decoration: const BoxDecoration(
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
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.wb_sunny,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // 应用名称
                          const Text(
                            '知雨天气2',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '智能天气预报应用',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontFamily: 'JetBrainsMono',
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
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'JetBrainsMono',
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '初始化失败',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '应用初始化失败，您可以重试或跳过权限直接使用。',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontFamily: 'JetBrainsMono',
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
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white70,
                              ),
                              child: const Text('跳过'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _requestPermissionAgain,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('重试'),
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