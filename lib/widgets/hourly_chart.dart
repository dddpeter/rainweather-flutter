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

        // 过滤显示24小时预报数据（从当前时间之后的下一个整点开始）
        final filteredForecast = _filterHourlyForecast(hourlyForecast!);

        return SizedBox(
          height: 240,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 计算图表宽度：每个数据点约40px的间距，最小为屏幕宽度
                        final chartWidth = (filteredForecast.length * 40.0)
                            .clamp(constraints.maxWidth, double.infinity);

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: chartWidth,
                            height: constraints.maxHeight,
                            child: Builder(
                              builder: (context) {
                                // 准备图表数据
                                final lineBarsData = [
                                  ChartStyles.createLineChartBarData(
                                    spots: _getTemperatureSpots(
                                      filteredForecast,
                                    ),
                                    color: AppColors.temperatureChart,
                                    isCurved: true,
                                    showDataLabels: true,
                                    showBelowArea: true,
                                    belowAreaOpacity: 0.1,
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
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: ChartStyles
                                                  .leftTitlesReservedSize,
                                              interval: 5,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  '${value.toInt()}℃',
                                                  style:
                                                      ChartStyles.getYAxisLabelStyle(),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                              reservedSize: 25, // 为右侧预留空间
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
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index >= 0 &&
                                                    index <
                                                        filteredForecast
                                                            .length) {
                                                  return Text(
                                                    _formatTime(
                                                      filteredForecast[index]
                                                              .forecasttime ??
                                                          '',
                                                    ),
                                                    style:
                                                        ChartStyles.getAxisLabelStyle(),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: ChartStyles.getBorderData(),
                                        lineBarsData: lineBarsData,
                                        minY:
                                            _getMinTemperature(
                                              filteredForecast,
                                            ) -
                                            5,
                                        maxY:
                                            _getMaxTemperature(
                                              filteredForecast,
                                            ) +
                                            10, // 增加顶部空间，为图标和温度值预留位置
                                        // 禁用默认的数据标签显示，使用自定义温度显示
                                        lineTouchData: LineTouchData(
                                          enabled: false,
                                        ),
                                      ),
                                    ),
                                    // 温度值叠加层
                                    _buildTemperatureLabelsOverlay(
                                      filteredForecast,
                                    ),
                                  ],
                                );
                              },
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

  /// 构建温度值叠加层
  Widget _buildTemperatureLabelsOverlay(List<HourlyWeather> forecast) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;

        // 计算图表实际绘制区域（去除左侧Y轴、右侧预留空间和底部X轴的空间）
        final leftPadding = ChartStyles.leftTitlesReservedSize;
        final rightPadding = 25.0; // 与rightTitles的reservedSize保持一致
        final bottomPadding = ChartStyles.bottomTitlesReservedSize;
        final availableWidth = chartWidth - leftPadding - rightPadding;
        final availableHeight = chartHeight - bottomPadding;

        // 温度范围（与图表的 minY/maxY 保持一致）
        final minTemp = _getMinTemperature(forecast) - 5;
        final maxTemp = _getMaxTemperature(forecast) + 10; // 与图表 maxY 保持一致
        final tempRange = maxTemp - minTemp;

        List<Widget> labels = [];

        // 为每个数据点添加天气图标和温度标签
        for (int i = 0; i < forecast.length; i++) {
          final hourData = forecast[i];
          final temp = _parseTemperature(hourData.temperature ?? '');
          final weatherType = hourData.weather ?? '晴';
          final timeStr = hourData.forecasttime ?? '';

          // 判断是否为夜间
          final isNight = _isNightTime(timeStr);

          // 获取天气图标
          final weatherIcon = _getChineseWeatherIcon(weatherType, isNight);

          // 计算X坐标
          final xRatio = forecast.length > 1 ? i / (forecast.length - 1) : 0.5;
          final xPos = leftPadding + (availableWidth * xRatio);

          // 计算Y坐标
          final yRatio = (maxTemp - temp) / tempRange;
          final yPos = availableHeight * yRatio;

          labels.add(
            Positioned(
              left: xPos - 12, // 图标宽度的一半
              top: yPos - 48, // 在数据点上方（图标24px + 温度20px + 间距4px）
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 天气图标
                  Image.asset(
                    'assets/images/$weatherIcon',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(width: 24, height: 24);
                    },
                  ),
                  const SizedBox(height: 2),
                  // 温度值
                  Text(
                    '${temp.toInt()}',
                    style: TextStyle(
                      color: AppColors.temperatureChart,
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

        return Stack(children: labels);
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

  /// 判断是否为夜间（18:00-6:00）
  bool _isNightTime(String timeStr) {
    if (timeStr.isEmpty) return false;
    try {
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.isNotEmpty) {
          final hour = int.parse(parts[0]);
          return hour < 6 || hour >= 18;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取中文天气图标路径
  String _getChineseWeatherIcon(String weatherType, bool isNight) {
    final iconMap = isNight
        ? AppConstants.chineseNightWeatherImages
        : AppConstants.chineseWeatherImages;
    return iconMap[weatherType] ?? iconMap['晴'] ?? '晴.png';
  }

  /// 过滤24小时预报数据，从当前时间之后的下一个整点开始，覆盖24个小时
  List<HourlyWeather> _filterHourlyForecast(List<HourlyWeather> forecast) {
    // 24小时预报逻辑：从当前时间之后的下一个整点开始，覆盖24个小时
    // 例如：当前21:25，则显示22:00到次日21:00的24个小时

    final now = DateTime.now();
    final currentHour = now.hour;

    // 计算起始小时：当前时间之后的下一个整点
    final startHour = (currentHour + 1) % 24;

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

        // 检查是否在24小时范围内
        // 从startHour开始，连续24个小时（包含跨天）
        bool shouldInclude = false;

        if (startHour + 23 < 24) {
          // 不跨天：startHour <= hour <= startHour + 23
          shouldInclude =
              forecastHour >= startHour && forecastHour <= startHour + 23;
        } else {
          // 跨天：hour >= startHour || hour <= (startHour + 23) % 24
          final endHour = (startHour + 23) % 24;
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

    // API数据已经按照正确的时间顺序排列，不需要重新排序

    return filtered;
  }
}
