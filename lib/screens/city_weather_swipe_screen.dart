import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/hourly_list.dart';
import '../widgets/city_weather_screen_base.dart';

/// 城市天气滑动屏幕 - 使用PageView实现页面切换
/// 继承自CityWeatherScreenBase基类，复用公共逻辑
class CityWeatherSwipeScreen extends StatefulWidget {
  final String cityName;
  final String? cityId;

  const CityWeatherSwipeScreen({
    super.key,
    required this.cityName,
    this.cityId,
  });

  @override
  State<CityWeatherSwipeScreen> createState() => _CityWeatherSwipeScreenState();
}

class _CityWeatherSwipeScreenState extends CityWeatherScreenBase<CityWeatherSwipeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  int _currentPage = 0;
  final List<String> _pageTitles = [
    '当前天气',
    '24小时预报',
    '15日预报',
  ];

  @override
  void initControllers() {
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void disposeControllers() {
    _pageController.dispose();
    _animationController.dispose();
  }

  @override
  String getOldCityName(CityWeatherSwipeScreen oldWidget) {
    return oldWidget.cityName;
  }

  @override
  String get cityName => widget.cityName;

  @override
  String? get cityId => widget.cityId;

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget buildNavigationController(WeatherProvider weatherProvider) {
    // 检查状态
    if (weatherProvider.isLoading && weatherProvider.currentWeather == null) {
      return Column(
        children: [
          _buildPageIndicator(),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (weatherProvider.error != null) {
      return Column(
        children: [
          _buildPageIndicator(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.textPrimary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '加载失败',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weatherProvider.error!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => weatherProvider.getWeatherForCity(
                      cityName,
                      cityId: cityId,
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (weatherProvider.currentWeather == null) {
      return Column(
        children: [
          _buildPageIndicator(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.textPrimary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无天气数据',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '无法获取 "$cityName" 的天气信息',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => weatherProvider.getWeatherForCity(
                      cityName,
                      cityId: cityId,
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // 页面指示器
        _buildPageIndicator(),

        // 滑动页面内容
        Expanded(
          child: PageView(
            key: const PageStorageKey('city_weather_page_view'),
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              Container(
                key: const PageStorageKey('current_weather_page'),
                child: _buildCurrentWeatherPage(weatherProvider),
              ),
              Container(
                key: const PageStorageKey('hourly_forecast_page'),
                child: _buildHourlyForecastPage(weatherProvider),
              ),
              Container(
                key: const PageStorageKey('15day_forecast_page'),
                child: build15DayForecastPage(weatherProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建页面指示器
  Widget _buildPageIndicator() {
    final themeProvider = context.read<ThemeProvider>();
    // 使用与 AppBar 一致的颜色
    final iconColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.appBarBackground, // 使用与 AppBar 一致的背景色
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pageTitles.length, (index) {
          final isSelected = index == _currentPage;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 90, // 增加宽度，从70改为90
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4), // 稍微增加边距
                  decoration: BoxDecoration(
                    color: isSelected
                        ? iconColor.withOpacity(0.2) // 使用与 AppBar 一致的颜色
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? iconColor.withOpacity(0.5) // 使用与 AppBar 一致的颜色
                          : themeProvider.isLightTheme
                              ? AppColors.textSecondary // 亮色模式：使用次要文字色，提高对比度
                              : iconColor.withOpacity(0.3), // 暗色模式：使用半透明主题色
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: FittedBox( // 使用FittedBox确保文字不超出容器
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _pageTitles[index],
                        style: TextStyle(
                          color: isSelected
                              ? iconColor // 使用与 AppBar 一致的颜色
                              : themeProvider.isLightTheme
                                  ? AppColors.textSecondary // 亮色模式：使用次要文字色，提高对比度
                                  : iconColor.withOpacity(0.6), // 暗色模式：使用半透明主题色
                          fontSize: isSelected ? 14 : 12, // 稍微增大字体
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1, // 限制为一行
                        overflow: TextOverflow.ellipsis, // 超出时显示省略号
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  /// 第一个页面：当前天气（带头部）
  Widget _buildCurrentWeatherPage(WeatherProvider weatherProvider) {
    return buildCurrentWeatherPage(weatherProvider, showHeader: true);
  }

  /// 第二个页面：24小时预报
  Widget _buildHourlyForecastPage(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final hourlyForecast = weather?.forecast24h ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        await weatherProvider.getWeatherForCity(
          cityName,
          forceRefreshAI: true,
        );
      },
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 24小时温度趋势图
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenHorizontalPadding,
              ),
              child: HourlyChart(hourlyForecast: hourlyForecast),
            ),
            AppColors.cardSpacingWidget,

            // 24小时天气列表
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenHorizontalPadding,
              ),
              child: HourlyList(
                hourlyForecast: hourlyForecast,
                weatherService: WeatherService.getInstance(),
              ),
            ),
            AppColors.cardSpacingWidget,

            const SizedBox(height: 80), // Space for bottom buttons
          ],
        ),
      ),
    );
  }
}
