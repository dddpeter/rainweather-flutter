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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 计算图表宽度：每个数据点约50px的间距，最小为屏幕宽度
                    final chartWidth = (chartData.length * 50.0).clamp(
                      constraints.maxWidth,
                      double.infinity,
                    );

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        height: constraints.maxHeight,
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

                            return Stack(
                              children: [
                                // 图表主体
                                LineChart(
                                  LineChartData(
                                    gridData: ChartStyles.getGridData(
                                      showVertical: true,
                                      horizontalInterval: 5,
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                          reservedSize: 23, // 为右侧预留空间
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: ChartStyles
                                              .bottomTitlesReservedSize,
                                          interval: 2,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() <
                                                    chartData.length) {
                                              final day =
                                                  chartData[value.toInt()];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  day['date'],
                                                  style:
                                                      ChartStyles.getAxisLabelStyle(),
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
                                          reservedSize: ChartStyles
                                              .leftTitlesReservedSize,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${value.toInt()}℃',
                                              style:
                                                  ChartStyles.getYAxisLabelStyle(),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: ChartStyles.getBorderData(),
                                    minX: 0,
                                    maxX: (chartData.length - 1).toDouble(),
                                    minY: _getMinTemperature(chartData) - 5,
                                    maxY:
                                        _getMaxTemperature(chartData) +
                                        8, // 增加顶部空间，为图标和温度值预留位置
                                    lineBarsData: lineBarsData,
                                    // 禁用默认的数据标签显示，使用自定义的天气图标+温度
                                    lineTouchData: LineTouchData(
                                      enabled: false,
                                    ),
                                  ),
                                ),
                                // 天气图标叠加层
                                _buildWeatherIconsOverlay(chartData),
                              ],
                            );
                          },
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
        'weatherAm': day.weather_am ?? '晴', // 白天天气（高温）
        'weatherPm': day.weather_pm ?? '晴', // 夜间天气（低温）
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

  /// 构建天气图标叠加层
  Widget _buildWeatherIconsOverlay(List<Map<String, dynamic>> chartData) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;

        // 计算图表实际绘制区域（去除左侧Y轴、右侧预留空间和底部X轴的空间）
        final leftPadding = ChartStyles.leftTitlesReservedSize;
        final rightPadding = 23.0; // 与rightTitles的reservedSize保持一致
        final bottomPadding = ChartStyles.bottomTitlesReservedSize;
        final availableWidth = chartWidth - leftPadding - rightPadding;
        final availableHeight = chartHeight - bottomPadding;

        // 温度范围（与图表的 minY/maxY 保持一致）
        final minTemp = _getMinTemperature(chartData) - 5;
        final maxTemp = _getMaxTemperature(chartData) + 8; // 与图表 maxY 保持一致
        final tempRange = maxTemp - minTemp;

        List<Widget> icons = [];

        // 为每个数据点添加天气图标
        for (int i = 0; i < chartData.length; i++) {
          final day = chartData[i];

          // 计算X坐标（在曲线数据点上）
          final xRatio = chartData.length > 1
              ? i / (chartData.length - 1)
              : 0.5;
          final xPos = leftPadding + (availableWidth * xRatio);

          // 高温点的天气图标（12点天气 - weather_am）
          final highTemp = day['maxTemp'] as double;
          final highTempYRatio = (maxTemp - highTemp) / tempRange;
          final highTempYPos = availableHeight * highTempYRatio;

          // 获取白天天气图标
          final dayWeatherIcon = _getChineseWeatherIcon(
            day['weatherAm'] ?? '晴',
            false,
          );

          icons.add(
            Positioned(
              left: xPos - 12, // 图标宽度的一半
              top: highTempYPos - 32, // 在高温点上方
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/$dayWeatherIcon',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(width: 24, height: 24);
                    },
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '${highTemp.toInt()}',
                    style: TextStyle(
                      color: AppColors.highTemp,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        // 白色描边效果（四个方向）
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(-0.8, -0.8),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(0.8, -0.8),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(0.8, 0.8),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(-0.8, 0.8),
                          blurRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          // 低温点的天气图标（0点天气 - weather_pm）
          final lowTemp = day['minTemp'] as double;
          final lowTempYRatio = (maxTemp - lowTemp) / tempRange;
          final lowTempYPos = availableHeight * lowTempYRatio;

          // 获取夜间天气图标
          final nightWeatherIcon = _getChineseWeatherIcon(
            day['weatherPm'] ?? '晴',
            true,
          );

          icons.add(
            Positioned(
              left: xPos - 12, // 图标宽度的一半
              top: lowTempYPos + 12, // 在低温点下方
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/$nightWeatherIcon',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(width: 24, height: 24);
                    },
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '${lowTemp.toInt()}',
                    style: TextStyle(
                      color: AppColors.lowTemp,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        // 白色描边效果（四个方向）
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(-0.8, -0.8),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(0.8, -0.8),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(0.8, 0.8),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: AppColors.cardBackground,
                          offset: const Offset(-0.8, 0.8),
                          blurRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(children: icons);
      },
    );
  }

  /// 获取中文天气图标路径
  String _getChineseWeatherIcon(String weatherType, bool isNight) {
    final iconMap = isNight
        ? AppConstants.chineseNightWeatherImages
        : AppConstants.chineseWeatherImages;
    return iconMap[weatherType] ?? iconMap['晴'] ?? '晴.png';
  }
}
