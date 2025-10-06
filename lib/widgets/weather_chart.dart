import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/chart_styles.dart';
import '../providers/theme_provider.dart';

class WeatherChart extends StatelessWidget {
  final List<DailyWeather>? dailyForecast;

  const WeatherChart({super.key, this.dailyForecast});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (dailyForecast == null || dailyForecast!.isEmpty) {
          return Center(
            child: Text(
              '暂无数据',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        // 准备图表数据
        final lineBarsData = [
          // High temperature line
          ChartStyles.createLineChartBarData(
            spots: _getHighTemperatureSpots(),
            color: AppColors.highTemp,
            isCurved: true,
            showDataLabels: true,
            showBelowArea: false,
          ),
          // Low temperature line
          ChartStyles.createLineChartBarData(
            spots: _getLowTemperatureSpots(),
            color: AppColors.lowTemp,
            isCurved: true,
            showDataLabels: true,
            showBelowArea: false,
          ),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: ChartStyles.getGridData(
                      showVertical: false,
                      horizontalInterval: 5,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: ChartStyles.bottomTitlesReservedSize,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < dailyForecast!.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  _formatDate(
                                    dailyForecast![value.toInt()]
                                            .forecasttime ??
                                        '',
                                  ),
                                  style: ChartStyles.getAxisLabelStyle(),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          reservedSize: ChartStyles.leftTitlesReservedSize,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}℃',
                              style: ChartStyles.getYAxisLabelStyle(),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: ChartStyles.getBorderData(),
                    minX: 0,
                    maxX: (dailyForecast!.length - 1).toDouble(),
                    minY: _getMinTemperature() - 5,
                    maxY: _getMaxTemperature() + 5,
                    lineBarsData: lineBarsData,
                    // 显示数据标签
                    lineTouchData: ChartStyles.getM3TouchDataWithLabels(),
                    showingTooltipIndicators:
                        ChartStyles.generateShowingIndicators(
                          lineBarsData: lineBarsData,
                        ),
                  ),
                ),
              ),
              // 图例
              ChartStyles.buildLegendContainer(
                items: [
                  MapEntry('最高温度', AppColors.highTemp),
                  MapEntry('最低温度', AppColors.lowTemp),
                ],
                padding: const EdgeInsets.only(top: 4, bottom: 4),
              ),
            ],
          ),
        );
      },
    );
  }

  List<FlSpot> _getHighTemperatureSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < dailyForecast!.length; i++) {
      double temp = _parseTemperature(dailyForecast![i].temperature_am ?? '');
      spots.add(FlSpot(i.toDouble(), temp));
    }
    return spots;
  }

  List<FlSpot> _getLowTemperatureSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < dailyForecast!.length; i++) {
      double temp = _parseTemperature(dailyForecast![i].temperature_pm ?? '');
      spots.add(FlSpot(i.toDouble(), temp));
    }
    return spots;
  }

  double _parseTemperature(String tempStr) {
    // Parse temperature string like "高温 25℃" or "低温 15℃"
    String cleanStr = tempStr
        .replaceAll('高温', '')
        .replaceAll('低温', '')
        .replaceAll('℃', '')
        .replaceAll(' ', '');
    return double.tryParse(cleanStr) ?? 0.0;
  }

  double _getMinTemperature() {
    double min = double.infinity;
    for (var day in dailyForecast!) {
      double low = _parseTemperature(day.temperature_pm ?? '');
      if (low < min) min = low;
    }
    return min;
  }

  double _getMaxTemperature() {
    double max = double.negativeInfinity;
    for (var day in dailyForecast!) {
      double high = _parseTemperature(day.temperature_am ?? '');
      if (high > max) max = high;
    }
    return max;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '--';
    try {
      // Parse date string like "2024-01-15 14:00:00"
      DateTime date = DateTime.parse(dateStr.split(' ')[0]);
      return '${date.month}-${date.day}';
    } catch (e) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }
}
