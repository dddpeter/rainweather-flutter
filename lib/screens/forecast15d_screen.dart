import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../widgets/forecast15d_chart.dart';

class Forecast15dScreen extends StatefulWidget {
  const Forecast15dScreen({super.key});

  @override
  State<Forecast15dScreen> createState() => _Forecast15dScreenState();
}

class _Forecast15dScreenState extends State<Forecast15dScreen> {
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
          child: Consumer<WeatherProvider>(
            builder: (context, weatherProvider, child) {
              if (weatherProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentBlue,
                  ),
                );
              }

              if (weatherProvider.error != null) {
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
                        '加载失败',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weatherProvider.error!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => weatherProvider.refresh15DayForecast(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }

              final forecast15d = weatherProvider.forecast15d;

              if (forecast15d == null || forecast15d.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无15日预报数据',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
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
                              '15日预报',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: weatherProvider.isLoading
                                  ? null
                                  : () => weatherProvider.refresh15DayForecast(),
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
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${weatherProvider.currentLocation?.district ?? '未知地区'} 未来15天天气预报',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Temperature Trend Chart
                  Forecast15dChart(forecast15d: forecast15d),
                  // Forecast List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: forecast15d.length,
                      itemBuilder: (context, index) {
                        final day = forecast15d[index];
                        return _buildForecastCard(day, weatherProvider, index);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForecastCard(DailyWeather day, WeatherProvider weatherProvider, int index) {
    final isToday = index == 0;
    final isTomorrow = index == 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date and week
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isToday 
                          ? AppColors.accentBlue.withOpacity(0.2)
                          : AppColors.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday 
                            ? AppColors.accentBlue.withOpacity(0.5)
                            : AppColors.accentGreen.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isToday ? '今天' : isTomorrow ? '明天' : day.week ?? '',
                      style: TextStyle(
                        color: isToday ? AppColors.accentBlue : AppColors.accentGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.forecasttime ?? '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (day.sunrise_sunset != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      day.sunrise_sunset!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Weather info - compact horizontal layout
            Expanded(
              child: Row(
                children: [
                  // Morning weather
                  Expanded(
                    child: _buildCompactWeatherPeriod(
                      '上午',
                      day.weather_am ?? '晴',
                      day.temperature_am ?? '--',
                      day.weather_am_pic ?? 'd00',
                      day.winddir_am ?? '',
                      day.windpower_am ?? '',
                      weatherProvider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Divider
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.dividerColor,
                  ),
                  const SizedBox(width: 8),
                  // Evening weather
                  Expanded(
                    child: _buildCompactWeatherPeriod(
                      '下午',
                      day.weather_pm ?? '晴',
                      day.temperature_pm ?? '--',
                      day.weather_pm_pic ?? 'n00',
                      day.winddir_pm ?? '',
                      day.windpower_pm ?? '',
                      weatherProvider,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactWeatherPeriod(
    String period,
    String weather,
    String temperature,
    String weatherPic,
    String windDir,
    String windPower,
    WeatherProvider weatherProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Weather icon
            Text(
              weatherProvider.getWeatherIcon(weather),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            // Temperature
            Text(
              '$temperature°',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Weather description
        Text(
          weather,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Wind info
        if (windDir.isNotEmpty || windPower.isNotEmpty)
          Text(
            '$windDir$windPower',
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontSize: 9,
            ),
          ),
      ],
    );
  }

}
