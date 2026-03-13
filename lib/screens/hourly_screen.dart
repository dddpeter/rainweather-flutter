import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/hourly_list.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';
import '../widgets/error_dialog.dart';

class HourlyScreen extends StatefulWidget {
  const HourlyScreen({super.key});

  @override
  State<HourlyScreen> createState() => _HourlyScreenState();
}

/// Selector 数据类：用于精确控制重建
class _HourlyScreenData {
  final bool isLoading;
  final String? error;
  final LocationModel? currentLocation;
  final List<HourlyWeather>? hourlyForecast;

  const _HourlyScreenData({
    required this.isLoading,
    this.error,
    this.currentLocation,
    required this.hourlyForecast,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _HourlyScreenData &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.currentLocation == currentLocation &&
        other.hourlyForecast?.length == hourlyForecast?.length;
  }

  @override
  int get hashCode =>
      isLoading.hashCode ^
      error.hashCode ^
      currentLocation.hashCode ^
      (hourlyForecast?.length ?? 0).hashCode;
}

class _HourlyScreenState extends State<HourlyScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  Key _chartKey = UniqueKey();
  Key _listKey = UniqueKey();

  @override
  bool get wantKeepAlive => true; // 保持页面状态

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
    super.build(context); // 必须调用以支持AutomaticKeepAlive
    // 使用Consumer监听主题变化，确保整个页面在主题切换时重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Selector<WeatherProvider, _HourlyScreenData>(
          selector: (context, provider) {
            return _HourlyScreenData(
              isLoading: provider.isLoading && provider.currentWeather == null,
              error: provider.error,
              currentLocation: provider.currentLocation,
              hourlyForecast: provider.currentWeather?.forecast24h ?? [],
            );
          },
          builder: (context, data, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: AppColors.screenBackgroundGradient,
              ),
              child: SafeArea(
                child: Builder(
                  builder: (context) {
                    if (data.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                        ),
                      );
                    }

                    if (data.error != null) {
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
                              data.error!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _handleRefreshWithFeedback(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: AppColors.textPrimary,
                              ),
                              child: const Text('重试'),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => _showErrorDialog(
                                context,
                                data.error!,
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

                    final location = data.currentLocation;
                    final hourlyForecast = data.hourlyForecast;

                    return RefreshIndicator(
                      onRefresh: () async {
                        // iOS触觉反馈
                        if (Platform.isIOS) {
                          HapticFeedback.mediumImpact();
                        }
                        await context.read<WeatherProvider>().refreshWeatherData();
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
                              _buildHeader(location),
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
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(LocationModel? location) {
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
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
                decorationStyle: TextDecorationStyle.solid,
                decorationThickness: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '24小时预报',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
                decorationStyle: TextDecorationStyle.solid,
                decorationThickness: 0,
              ),
            ),
          ],
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            // 使用 plain 效果：背景主题色半透明，文字主题色，边框主题色
            final themeColor = themeProvider.isLightTheme
                ? AppColors.primaryBlue
                : AppColors.accentBlue;
            final backgroundColor = themeColor.withOpacity(0.15); // 半透明背景
            final textColor = themeColor; // 主题色文字
            final borderColor = themeColor; // 主题色边框
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: Text(
                _getCurrentTime(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                  decorationStyle: TextDecorationStyle.solid,
                  decorationThickness: 0,
                ),
              ),
            );
          },
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
  Future<void> _handleRefreshWithFeedback(BuildContext context) async {
    try {
      // 执行强制刷新
      await context.read<WeatherProvider>().forceRefreshWithLocation();
    } catch (e) {
      // 静默处理错误，不显示Toast
      Logger.e('刷新失败', tag: 'HourlyScreen', error: e);
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
        _handleRefreshWithFeedback(context);
      },
      retryText: '重试',
    );
  }
}
