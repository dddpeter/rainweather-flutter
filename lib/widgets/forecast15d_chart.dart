import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/chart_styles.dart';

class Forecast15dChart extends StatelessWidget {
  final List<DailyWeather>? forecast15d;

  const Forecast15dChart({super.key, this.forecast15d});

  @override
  Widget build(BuildContext context) {
    if (forecast15d == null || forecast15d!.isEmpty) {
      return const SizedBox.shrink();
    }

    // 准备图表数据
    final chartData = _prepareChartData(forecast15d!);

    return SizedBox(
      height: 280,
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
                    Icons.trending_up,
                    color: AppColors.warning,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '15日温度趋势',
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
                      // 最高温度线
                      ChartStyles.createLineChartBarData(
                        spots: chartData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value['maxTemp'],
                          );
                        }).toList(),
                        color: AppColors.highTemp,
                        isCurved: true,
                        showDataLabels: true,
                        showBelowArea: false,
                      ),
                      // 最低温度线
                      ChartStyles.createLineChartBarData(
                        spots: chartData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value['minTemp'],
                          );
                        }).toList(),
                        color: AppColors.lowTemp,
                        isCurved: true,
                        showDataLabels: true,
                        showBelowArea: false,
                      ),
                    ];

                    return LineChart(
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
                              reservedSize:
                                  ChartStyles.bottomTitlesReservedSize,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < chartData.length) {
                                  final day = chartData[value.toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      day['date'],
                                      style: ChartStyles.getAxisLabelStyle(),
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
                              interval: 10,
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
                        maxX: (chartData.length - 1).toDouble(),
                        minY: _getMinTemperature(chartData) - 5,
                        maxY: _getMaxTemperature(chartData) + 5,
                        lineBarsData: lineBarsData,
                        // 显示数据标签
                        lineTouchData: ChartStyles.getM3TouchDataWithLabels(),
                        showingTooltipIndicators:
                            ChartStyles.generateShowingIndicators(
                              lineBarsData: lineBarsData,
                            ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // 图例
              ChartStyles.buildLegendContainer(
                items: [
                  MapEntry('最高温度', AppColors.highTemp),
                  MapEntry('最低温度', AppColors.lowTemp),
                ],
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _prepareChartData(List<DailyWeather> forecast) {
    return forecast.take(15).map((day) {
      final maxTemp = _parseTemperature(day.temperature_am ?? '0');
      final minTemp = _parseTemperature(day.temperature_pm ?? '0');
      final date = _formatDate(day.forecasttime ?? '');

      return {
        'maxTemp': maxTemp.toDouble(),
        'minTemp': minTemp.toDouble(),
        'date': date,
      };
    }).toList();
  }

  int _parseTemperature(String tempStr) {
    try {
      return int.parse(tempStr.replaceAll('°', ''));
    } catch (e) {
      return 0;
    }
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length >= 2) {
          return '${parts[0]}/${parts[1]}';
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  double _getMinTemperature(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0;
    return data
        .map((d) => d['minTemp'] as double)
        .reduce((a, b) => a < b ? a : b);
  }

  double _getMaxTemperature(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0;
    return data
        .map((d) => d['maxTemp'] as double)
        .reduce((a, b) => a > b ? a : b);
  }
}
