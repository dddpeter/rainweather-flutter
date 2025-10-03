import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_chart.dart';
import '../widgets/hourly_weather_widget.dart';
import '../services/weather_service.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../models/location_model.dart';
import 'hourly_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().initializeWeather();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面显示时，恢复当前定位的天气数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().restoreCurrentLocationWeather();
    });
  }

  String _getDisplayCity(LocationModel? location) {
    if (location == null) {
      return AppConstants.defaultCity;
    }
    
    // 调试信息
    print('Location debug: district=${location.district}, city=${location.city}, province=${location.province}');
    
    // 优先显示district，如果为空则显示city，最后显示province
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          if (weatherProvider.isLoading && weatherProvider.currentWeather == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentBlue,
              ),
            );
          }

          if (weatherProvider.error != null && weatherProvider.currentWeather == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    weatherProvider.error!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => weatherProvider.refreshWeatherData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => weatherProvider.refreshWeatherData(),
            color: Colors.blue,
            backgroundColor: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildTopWeatherSection(weatherProvider),
                  const SizedBox(height: 16),
                  _buildTemperatureChart(weatherProvider),
                  const SizedBox(height: 16),
                  _buildHourlyWeather(weatherProvider),
                  const SizedBox(height: 16),
                  _buildWeatherDetails(weatherProvider),
                  const SizedBox(height: 16),
                  _buildLifeAdvice(weatherProvider),
                  const SizedBox(height: 80), // Space for bottom buttons
                ],
              ),
            ),
          );
        },
      ),
      ),
      floatingActionButton: Consumer<WeatherProvider>(
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
                          : () => weatherProvider.refreshWeatherData(),
                      child: Center(
                        child: weatherProvider.isLoading
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
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopWeatherSection(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final location = weatherProvider.currentLocation;
    final current = weather?.current?.current;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgroud.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // City name
              Center(
                child: Text(
                  _getDisplayCity(location),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        color: Colors.blue.withOpacity(0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Weather icon and temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weatherProvider.getWeatherIcon(current?.weather ?? '晴'),
                    style: const TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${current?.temperature ?? '--'}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Weather type
              Text(
                current?.weather ?? '晴',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
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
                        AppColors.accentGreen, // 绿色
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.air,
                        '风力',
                        '${current.winddir ?? '--'}${current.windpower ?? ''}',
                        AppColors.accentGreen, // 绿色
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
                        AppColors.accentGreen, // 绿色
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.visibility,
                        '能见度',
                        '${current.visibility ?? '--'}km',
                        AppColors.accentGreen, // 绿色
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
                        '${current.feelstemperature ?? '--'}°',
                        AppColors.accentGreen, // 绿色
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactWeatherDetail(
                        Icons.eco,
                        '空气指数',
                        '${weather?.current?.air?.AQI ?? '--'}',
                        _getAirQualityColor(weather?.current?.air?.AQI),
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

  Widget _buildCompactWeatherDetail(IconData icon, String label, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: color, 
                size: 18,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.8),
                    blurRadius: 6,
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: color.withOpacity(0.8),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get air quality color based on AQI value
  Color _getAirQualityColor(String? aqi) {
    if (aqi == null || aqi == '--') return AppColors.accentGreen;
    
    try {
      final aqiValue = int.parse(aqi);
      if (aqiValue <= 50) {
        return Colors.green; // 优
      } else if (aqiValue <= 100) {
        return Colors.yellow; // 良
      } else if (aqiValue <= 150) {
        return Colors.orange; // 轻度污染
      } else if (aqiValue <= 200) {
        return Colors.red; // 中度污染
      } else if (aqiValue <= 300) {
        return Colors.purple; // 重度污染
      } else {
        return Colors.deepPurple; // 严重污染
      }
    } catch (e) {
      return AppColors.accentGreen;
    }
  }

  Widget _buildWeatherDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(WeatherProvider weatherProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7日温度趋势',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: WeatherChart(
              dailyForecast: weatherProvider.dailyForecast,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyWeather(WeatherProvider weatherProvider) {
    final weatherService = WeatherService.getInstance();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HourlyScreen(),
            ),
          );
        },
        child: HourlyWeatherWidget(
          hourlyForecast: weatherProvider.currentWeather?.forecast24h,
          weatherService: weatherService,
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final air = weather?.current?.air ?? weather?.air;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF4FC3F7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '详细信息',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (air != null) ...[
            _buildEnhancedDetailItem(
              Icons.air,
              '空气质量',
              '${air.AQI ?? '--'} (${air.levelIndex ?? '未知'})',
              const Color(0xFF66BB6A),
            ),
            const SizedBox(height: 12),
          ],
          if (weather?.current?.current != null) ...[
            _buildEnhancedDetailItem(
              Icons.thermostat,
              '体感温度',
              '${weather!.current!.current!.feelstemperature ?? '--'}°',
              const Color(0xFF4FC3F7),
            ),
            const SizedBox(height: 12),
            _buildEnhancedDetailItem(
              Icons.navigation,
              '风向',
              weather.current!.current!.winddir ?? '--',
              const Color(0xFF66BB6A),
            ),
            const SizedBox(height: 12),
            _buildEnhancedDetailItem(
              Icons.air,
              '风力',
              weather.current!.current!.windpower ?? '--',
              const Color(0xFF4FC3F7),
            ),
            const SizedBox(height: 12),
            _buildEnhancedDetailItem(
              Icons.water_drop,
              '湿度',
              '${weather.current!.current!.humidity ?? '--'}%',
              const Color(0xFF66BB6A),
            ),
            const SizedBox(height: 12),
            _buildEnhancedDetailItem(
              Icons.compress,
              '气压',
              '${weather.current!.current!.airpressure ?? '--'}hpa',
              const Color(0xFF4FC3F7),
            ),
            const SizedBox(height: 12),
            _buildEnhancedDetailItem(
              Icons.visibility,
              '能见度',
              '${weather.current!.current!.visibility ?? '--'}km',
              const Color(0xFF66BB6A),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeAdvice(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    final tips = weather?.current?.tips ?? weather?.tips ?? '今天天气不错，适合外出活动';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFF66BB6A),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '生活建议',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF66BB6A).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: const Color(0xFF66BB6A),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tips,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
