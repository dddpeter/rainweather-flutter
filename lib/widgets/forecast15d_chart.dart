import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';

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
              Text(
                '15日温度趋势',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.dividerColor,
                          strokeWidth: 0.5,
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
                          interval: 2,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < chartData.length) {
                              final day = chartData[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  day['date'],
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
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
                          interval: 10,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}℃',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: AppColors.borderColor,
                        width: 0.5,
                      ),
                    ),
                    minX: 0,
                    maxX: (chartData.length - 1).toDouble(),
                    minY: _getMinTemperature(chartData) - 5,
                    maxY: _getMaxTemperature(chartData) + 5,
                    lineBarsData: [
                      // 最高温度线
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value['maxTemp'],
                          );
                        }).toList(),
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
                              strokeColor: AppColors.cardBackground,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                      // 最低温度线
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value['minTemp'],
                          );
                        }).toList(),
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
                              strokeColor: AppColors.cardBackground,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final day = chartData[index];
                              final isMaxTemp = touchedSpot.barIndex == 0;
                              return LineTooltipItem(
                                isMaxTemp
                                    ? '最高: ${day['maxTemp']}℃'
                                    : '最低: ${day['minTemp']}℃',
                                TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: '\n${day['date']}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 图例
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('最高温度', AppColors.highTemp),
                  const SizedBox(width: 24),
                  _buildLegendItem('最低温度', AppColors.lowTemp),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
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
