import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/chart_styles.dart';
import '../constants/app_constants.dart';
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
          // High temperature line (12点天气)
          ChartStyles.createLineChartBarData(
            spots: _getHighTemperatureSpots(),
            color: AppColors.highTemp,
            isCurved: true,
            showDataLabels: true,
            showBelowArea: false,
          ),
          // Low temperature line (0点天气)
          ChartStyles.createLineChartBarData(
            spots: _getLowTemperatureSpots(),
            color: AppColors.lowTemp,
            isCurved: true,
            showDataLabels: true,
            showBelowArea: false,
          ),
        ];

        return Padding(
            padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0, // 增加右侧padding，确保最后一组数据完整显示
            top: 8.0,
            bottom: 0,
          ),

          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // 图表主体
                    LineChart(
                      LineChartData(
                        gridData: ChartStyles.getGridData(
                          showVertical: false,
                          horizontalInterval: 5,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                              reservedSize: 40, // 为右侧预留空间，确保最后一组数据完整显示
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize:
                                  ChartStyles.bottomTitlesReservedSize,
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
                        // 禁用默认的数据标签显示，使用自定义的天气图标+温度
                        lineTouchData: LineTouchData(enabled: false),
                      ),
                    ),
                    // 天气图标叠加层
                    _buildWeatherIconsOverlay(context),
                  ],
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

  /// 构建天气图标叠加层
  Widget _buildWeatherIconsOverlay(BuildContext context) {
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

        // 温度范围
        final minTemp = _getMinTemperature() - 5;
        final maxTemp = _getMaxTemperature() + 5;
        final tempRange = maxTemp - minTemp;

        List<Widget> icons = [];

        // 为每个数据点添加天气图标
        for (int i = 0; i < dailyForecast!.length; i++) {
          final day = dailyForecast![i];

          // 计算X坐标（在曲线数据点上）
          final xRatio = dailyForecast!.length > 1
              ? i / (dailyForecast!.length - 1)
              : 0.5;
          final xPos = leftPadding + (availableWidth * xRatio);

          // 高温点的天气图标（12点天气 - weather_am）
          final highTemp = _parseTemperature(day.temperature_am ?? '');
          final highTempYRatio = (maxTemp - highTemp) / tempRange;
          final highTempYPos = availableHeight * highTempYRatio;

          // 获取白天天气图标
          final dayWeatherIcon = _getChineseWeatherIcon(
            day.weather_am ?? '晴',
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
          final lowTemp = _parseTemperature(day.temperature_pm ?? '');
          final lowTempYRatio = (maxTemp - lowTemp) / tempRange;
          final lowTempYPos = availableHeight * lowTempYRatio;

          // 获取夜间天气图标
          final nightWeatherIcon = _getChineseWeatherIcon(
            day.weather_pm ?? '晴',
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
                  const SizedBox(width: 2),
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
