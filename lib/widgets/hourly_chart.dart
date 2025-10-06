import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/chart_styles.dart';
import '../providers/theme_provider.dart';

class HourlyChart extends StatelessWidget {
  final List<HourlyWeather>? hourlyForecast;

  const HourlyChart({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (hourlyForecast == null || hourlyForecast!.isEmpty) {
          return SizedBox(
            height: 200,
            child: Card(
              elevation: AppColors.cardElevation,
              shadowColor: AppColors.cardShadowColor,
              color: AppColors.materialCardColor,
              shape: AppColors.cardShape,
              child: Center(
                child: Text(
                  '暂无24小时数据',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }

        // 过滤显示当前时间前2小时、当前时间和当前时间后21小时的数据
        final filteredForecast = _filterHourlyForecast(hourlyForecast!);

        return SizedBox(
          height: 200,
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
                        Icons.show_chart,
                        color: AppColors.accentBlue,
                        size: AppConstants.sectionTitleIconSize,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '24小时温度趋势',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppConstants.sectionTitleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // 准备图表数据
                        final lineBarsData = [
                          ChartStyles.createLineChartBarData(
                            spots: _getTemperatureSpots(filteredForecast),
                            color: AppColors.temperatureChart,
                            isCurved: true,
                            showDataLabels: true,
                            showBelowArea: true,
                            belowAreaOpacity: 0.1,
                          ),
                        ];

                        return LineChart(
                          LineChartData(
                            gridData: ChartStyles.getGridData(
                              showVertical: false,
                              horizontalInterval: 5,
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize:
                                      ChartStyles.leftTitlesReservedSize,
                                  interval: 5,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}℃',
                                      style: ChartStyles.getYAxisLabelStyle(),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize:
                                      ChartStyles.bottomTitlesReservedSize,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 &&
                                        index < filteredForecast.length) {
                                      return Text(
                                        _formatTime(
                                          filteredForecast[index]
                                                  .forecasttime ??
                                              '',
                                        ),
                                        style: ChartStyles.getAxisLabelStyle(),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: ChartStyles.getBorderData(),
                            lineBarsData: lineBarsData,
                            minY: _getMinTemperature(filteredForecast) - 5,
                            maxY: _getMaxTemperature(filteredForecast) + 5,
                            // 显示数据标签
                            lineTouchData:
                                ChartStyles.getM3TouchDataWithLabels(),
                            showingTooltipIndicators:
                                ChartStyles.generateShowingIndicators(
                                  lineBarsData: lineBarsData,
                                ),
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

  List<FlSpot> _getTemperatureSpots(List<HourlyWeather> forecast) {
    List<FlSpot> spots = [];
    for (int i = 0; i < forecast.length; i++) {
      final temp = _parseTemperature(forecast[i].temperature ?? '');
      spots.add(FlSpot(i.toDouble(), temp));
    }
    return spots;
  }

  double _getMinTemperature(List<HourlyWeather> forecast) {
    double min = double.infinity;
    for (final hour in forecast) {
      final temp = _parseTemperature(hour.temperature ?? '');
      if (temp < min) min = temp;
    }
    return min == double.infinity ? 0 : min;
  }

  double _getMaxTemperature(List<HourlyWeather> forecast) {
    double max = double.negativeInfinity;
    for (final hour in forecast) {
      final temp = _parseTemperature(hour.temperature ?? '');
      if (temp > max) max = temp;
    }
    return max == double.negativeInfinity ? 0 : max;
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '--';
    try {
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          return '${hour.toString().padLeft(2, '0')}:00';
        }
      }
      return timeStr;
    } catch (e) {
      return timeStr.length > 5 ? timeStr.substring(0, 5) : timeStr;
    }
  }

  double _parseTemperature(String tempStr) {
    if (tempStr.isEmpty) return 0.0;
    try {
      final cleanStr = tempStr.replaceAll('℃', '').replaceAll('°', '');
      return double.parse(cleanStr);
    } catch (e) {
      return 0.0;
    }
  }

  /// 过滤逐小时预报数据，显示当前时间前2小时、当前时间和当前时间后21小时
  List<HourlyWeather> _filterHourlyForecast(List<HourlyWeather> forecast) {
    final now = DateTime.now();
    final currentHour = now.hour;

    // 计算时间范围：当前时间前2小时到当前时间后21小时
    final startHour = (currentHour - 2 + 24) % 24; // 前2小时
    final endHour = (currentHour + 21) % 24; // 后21小时

    List<HourlyWeather> filtered = [];

    for (final hour in forecast) {
      final timeStr = hour.forecasttime ?? '';
      if (timeStr.isEmpty) continue;

      try {
        // 解析时间字符串，支持 HH:mm 格式
        int? forecastHour;

        if (timeStr.contains(':')) {
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            forecastHour = int.parse(parts[0]);
          }
        }

        if (forecastHour == null) continue;

        // 检查是否在时间范围内（考虑跨天情况）
        bool shouldInclude = false;

        if (startHour <= endHour) {
          // 不跨天：startHour <= hour <= endHour
          shouldInclude = forecastHour >= startHour && forecastHour <= endHour;
        } else {
          // 跨天：hour >= startHour || hour <= endHour
          shouldInclude = forecastHour >= startHour || forecastHour <= endHour;
        }

        if (shouldInclude) {
          filtered.add(hour);
        }
      } catch (e) {
        // 解析失败，跳过这个数据
        continue;
      }
    }

    // 按时间排序
    filtered.sort((a, b) {
      final hourA = _parseHour(a.forecasttime ?? '');
      final hourB = _parseHour(b.forecasttime ?? '');
      return hourA.compareTo(hourB);
    });

    return filtered;
  }

  /// 解析时间字符串为小时数
  int _parseHour(String timeStr) {
    try {
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return int.parse(parts[0]);
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
