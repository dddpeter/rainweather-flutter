import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/location_model.dart';
import '../services/weather_service.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/hourly_list.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';

class HourlyScreen extends StatefulWidget {
  const HourlyScreen({super.key});

  @override
  State<HourlyScreen> createState() => _HourlyScreenState();
}

class _HourlyScreenState extends State<HourlyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().initializeWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听主题变化，确保整个页面在主题切换时重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Scaffold(
          // 右下角浮动返回按钮（仅在作为二级页面时显示）
          floatingActionButton: Navigator.canPop(context)
              ? Container(
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
                  child: Material(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Consumer<WeatherProvider>(
                builder: (context, weatherProvider, child) {
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
                    onRefresh: () => weatherProvider.refreshWeatherData(),
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
                            HourlyChart(hourlyForecast: hourlyForecast),
                            AppColors.cardSpacingWidget,

                            // 24小时天气列表
                            HourlyList(
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
      // 显示刷新开始提示
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
              Text('正在刷新位置和天气数据...'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 执行强制刷新
      await weatherProvider.forceRefreshWithLocation();

      // 显示刷新完成提示
      if (context.mounted) {
        final location = weatherProvider.currentLocation;
        final locationName = location?.district ?? '当前位置';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新完成 - $locationName'),
            backgroundColor: AppColors.accentGreen,
            duration: Duration(milliseconds: 2000),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // 显示刷新失败提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: Duration(milliseconds: 2000),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
