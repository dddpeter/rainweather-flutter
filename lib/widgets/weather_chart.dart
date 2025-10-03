import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';

class WeatherChart extends StatelessWidget {
  final List<DailyWeather>? dailyForecast;

  const WeatherChart({
    super.key,
    this.dailyForecast,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyForecast == null || dailyForecast!.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textTertiary,
              strokeWidth: 1,
            );
          },
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
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < dailyForecast!.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      _formatDate(dailyForecast![value.toInt()].forecasttime ?? ''),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: (dailyForecast!.length - 1).toDouble(),
        minY: _getMinTemperature() - 5,
        maxY: _getMaxTemperature() + 5,
        lineBarsData: [
          // High temperature line
          LineChartBarData(
            spots: _getHighTemperatureSpots(),
            isCurved: true,
            color: AppColors.highTemp,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.highTemp,
                  strokeWidth: 2,
                  strokeColor: AppColors.textPrimary,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // Low temperature line
          LineChartBarData(
            spots: _getLowTemperatureSpots(),
            isCurved: true,
            color: AppColors.lowTemp,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.lowTemp,
                  strokeWidth: 2,
                  strokeColor: AppColors.textPrimary,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
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
