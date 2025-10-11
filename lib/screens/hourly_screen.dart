import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/location_model.dart';
import '../services/weather_service.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/hourly_list.dart';
import '../widgets/floating_action_island.dart';
import '../widgets/app_drawer.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';

class HourlyScreen extends StatefulWidget {
  const HourlyScreen({super.key});

  @override
  State<HourlyScreen> createState() => _HourlyScreenState();
}

class _HourlyScreenState extends State<HourlyScreen>
    with WidgetsBindingObserver {
  Key _chartKey = UniqueKey();
  Key _listKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().initializeWeather();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // 应用恢复时刷新数据
      context.read<WeatherProvider>().refresh24HourForecast();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面显示时刷新24小时预报数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 更新key强制重建子组件
        setState(() {
          _chartKey = UniqueKey();
          _listKey = UniqueKey();
        });

        // 刷新24小时预报数据
        context.read<WeatherProvider>().refresh24HourForecast();
      }
    });
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
            return Scaffold(
              drawer: const AppDrawer(),
              floatingActionButton: _buildFloatingActionIsland(weatherProvider),
              body: Container(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Builder(
                    builder: (context) {
                      if (weatherProvider.isLoading &&
                          weatherProvider.currentWeather == null) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textPrimary,
                          ),
                        );
                      }

                      if (weatherProvider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
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
                                onPressed: () => _handleRefreshWithFeedback(
                                  context,
                                  weatherProvider,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        );
                      }

                      final weather = weatherProvider.currentWeather;
                      final location = weatherProvider.currentLocation;
                      final hourlyForecast = weather?.forecast24h ?? [];

                      return RefreshIndicator(
                        onRefresh: () async {
                          // iOS触觉反馈
                          if (Platform.isIOS) {
                            HapticFeedback.mediumImpact();
                          }
                          await weatherProvider.refreshWeatherData();
                          if (Platform.isIOS) {
                            HapticFeedback.lightImpact();
                          }
                        },
                        color: AppColors.primaryBlue,
                        backgroundColor: AppColors.backgroundSecondary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppConstants.screenHorizontalPadding,
                              16.0,
                              AppConstants.screenHorizontalPadding,
                              16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                _buildHeader(location, weatherProvider),
                                AppColors.cardSpacingWidget,

                                // 24小时温度趋势图
                                HourlyChart(
                                  key: _chartKey,
                                  hourlyForecast: hourlyForecast,
                                ),
                                AppColors.cardSpacingWidget,

                                // 24小时天气列表
                                HourlyList(
                                  key: _listKey,
                                  hourlyForecast: hourlyForecast,
                                  weatherService: WeatherService.getInstance(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    LocationModel? location,
    WeatherProvider weatherProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDisplayCity(location),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '24小时预报',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Text(
            _getCurrentTime(),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getDisplayCity(LocationModel? location) {
    if (location == null) {
      return AppConstants.defaultCity;
    }
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

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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

  /// 构建浮动操作岛
  Widget _buildFloatingActionIsland(WeatherProvider weatherProvider) {
    final themeProvider = context.read<ThemeProvider>();

    return FloatingActionIsland(
      mainIcon: Icons.menu_rounded,
      mainTooltip: '快捷操作',
      actions: [
        // 刷新
        IslandAction(
          icon: Icons.refresh_rounded,
          label: '刷新',
          onTap: () async {
            // iOS触觉反馈
            if (Platform.isIOS) {
              HapticFeedback.mediumImpact();
            }

            await weatherProvider.forceRefreshWithLocation();

            // iOS触觉反馈 - 刷新完成
            if (Platform.isIOS) {
              HapticFeedback.lightImpact();
            }
          },
          backgroundColor: AppColors.primaryBlue,
        ),
        // 设置
        IslandAction(
          icon: Icons.settings_rounded,
          label: '设置',
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          backgroundColor: AppColors.primaryBlue,
        ),
        // 主题切换
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
      ],
    );
  }
}
