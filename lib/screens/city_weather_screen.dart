import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/weather_chart.dart';
import '../widgets/hourly_weather_widget.dart';
import '../services/weather_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/sun_moon_widget.dart';
import '../widgets/life_index_widget.dart';
import 'hourly_screen.dart';

class CityWeatherScreen extends StatefulWidget {
  final String cityName;

  const CityWeatherScreen({super.key, required this.cityName});

  @override
  State<CityWeatherScreen> createState() => _CityWeatherScreenState();
}

class _CityWeatherScreenState extends State<CityWeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 获取指定城市的天气数据（包含日出日落和生活指数数据）
      context.read<WeatherProvider>().getWeatherForCity(widget.cityName);
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
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Consumer<WeatherProvider>(
                builder: (context, weatherProvider, child) {
                  if (weatherProvider.isLoading &&
                      weatherProvider.currentWeather == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
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
                              widget.cityName,
                            ),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        weatherProvider.getWeatherForCity(widget.cityName),
                    color: AppColors.primaryBlue,
                    backgroundColor: AppColors.backgroundSecondary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildTopWeatherSection(weatherProvider),
                          const SizedBox(height: 16),
                          SunMoonWidget(weatherProvider: weatherProvider),
                          const SizedBox(height: 16),
                          LifeIndexWidget(weatherProvider: weatherProvider),
                          const SizedBox(height: 16),
                          _buildHourlyWeather(weatherProvider),
                          const SizedBox(height: 16),
                          _buildTemperatureChart(weatherProvider),
                          const SizedBox(height: 16),
                          _buildWeatherDetails(weatherProvider),
                          const SizedBox(
                            height: 80,
                          ), // Space for bottom buttons
                        ],
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

  Widget _buildTopWeatherSection(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final current = weather?.current?.current;

    return Container(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              // City name and navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.titleBarIconColor,
                        size: AppColors.titleBarIconSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.cityName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40, // 占位保持对称
                    height: 40,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weather icon, weather text and temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weatherProvider.getWeatherIcon(current?.weather ?? '晴'),
                    style: TextStyle(
                      fontSize: 72,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    current?.weather ?? '晴',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${current?.temperature ?? '--'}℃',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weather details in 2 columns
              if (current != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.water_drop,
                        '湿度',
                        '${current.humidity ?? '--'}%',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.air,
                        '风力',
                        '${current.winddir ?? '--'}${current.windpower ?? ''}',
                        AppColors.accentGreen, // 使用主题色
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.compress,
                        '气压',
                        '${current.airpressure ?? '--'}hpa',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.visibility,
                        '能见度',
                        '${current.visibility ?? '--'}km',
                        AppColors.accentGreen, // 使用主题色
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.thermostat,
                        '体感温度',
                        '${current.feelstemperature ?? '--'}℃',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.eco,
                        '空气指数',
                        '${weather?.current?.air?.AQI ?? '--'}',
                        AppColors.accentGreen, // 使用主题色
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactWeatherDetail(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(WeatherProvider weatherProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '7日温度趋势',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: WeatherChart(
                  dailyForecast: weatherProvider.dailyForecast,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyWeather(WeatherProvider weatherProvider) {
    final weatherService = WeatherService.getInstance();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: HourlyWeatherWidget(
        hourlyForecast: weatherProvider.currentWeather?.forecast24h,
        weatherService: weatherService,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HourlyScreen()),
          );
        },
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final air = weather?.current?.air ?? weather?.air;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.titleBarDecorIconColor,
                    size: AppColors.titleBarDecorIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '详细信息',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (air != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.air,
                        '空气质量',
                        '${air.AQI ?? '--'} (${air.levelIndex ?? '未知'})',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (weather?.current?.current != null)
                      Expanded(
                        child: _buildCompactDetailItem(
                          Icons.thermostat,
                          '体感温度',
                          '${weather!.current!.current!.feelstemperature ?? '--'}℃',
                          AppColors.textPrimary, // 使用主文字色确保可见性
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (weather?.current?.current != null) ...[
                // 第一行：湿度和气压
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.water_drop,
                        '湿度',
                        '${weather!.current!.current!.humidity ?? '--'}%',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.compress,
                        '气压',
                        '${weather.current!.current!.airpressure ?? '--'}hpa',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 第二行：风力和能见度
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.air,
                        '风力',
                        '${weather.current!.current!.winddir ?? '--'} ${weather.current!.current!.windpower ?? ''}',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDetailItem(
                        Icons.visibility,
                        '能见度',
                        '${weather.current!.current!.visibility ?? '--'}km',
                        AppColors.textPrimary, // 使用主文字色确保可见性
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
