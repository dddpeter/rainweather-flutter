import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_colors.dart';

/// 图表统一样式配置 - Material Design 3
class ChartStyles {
  // ==================== Material Design 3 字体大小 ====================

  /// X轴标签字体大小 (M3: Label Small)
  static const double axisLabelFontSize = 11.0;

  /// Y轴标签字体大小 (M3: Label Small)
  static const double yAxisLabelFontSize = 11.0;

  /// 数据标签字体大小 (M3: Label Small - 更小以避免重叠)
  static const double dataLabelFontSize = 10.0;

  // ==================== Material Design 3 线条和网格 ====================

  /// 网格线透明度（M3: Surface variant with low opacity）
  static const double gridLineOpacity = 0.08;

  /// 网格线宽度
  static const double gridLineWidth = 0.5;

  /// 坐标轴线宽度 (M3: Outline)
  static const double axisLineWidth = 1.0;

  /// 坐标轴线透明度
  static const double axisLineOpacity = 0.38;

  // ==================== Material Design 3 数据点 ====================

  /// 数据点半径 (M3: 适中大小，避免与标签重叠)
  static const double dotRadius = 3.5;

  /// 数据点描边宽度
  static const double dotStrokeWidth = 1.5;

  /// 数据线宽度 (M3: 更明显)
  static const double lineWidth = 2.5;

  // ==================== 间距 ====================

  /// X轴标签预留空间
  static const double bottomTitlesReservedSize = 30.0;

  /// Y轴标签预留空间
  static const double leftTitlesReservedSize = 35.0;

  /// 数据标签与数据点的垂直间距
  static const double dataLabelVerticalOffset = 12.0;

  // ==================== 公共方法 ====================

  /// 获取网格线配置
  static FlGridData getGridData({
    bool showVertical = false,
    double? horizontalInterval,
  }) {
    return FlGridData(
      show: true,
      drawVerticalLine: showVertical,
      horizontalInterval: horizontalInterval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppColors.textSecondary.withOpacity(gridLineOpacity),
          strokeWidth: gridLineWidth,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: AppColors.textSecondary.withOpacity(gridLineOpacity),
          strokeWidth: gridLineWidth,
        );
      },
    );
  }

  /// 获取边框配置（显示X轴和Y轴线）
  static FlBorderData getBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        left: BorderSide(
          color: AppColors.textSecondary.withOpacity(axisLineOpacity),
          width: axisLineWidth,
        ),
        bottom: BorderSide(
          color: AppColors.textSecondary.withOpacity(axisLineOpacity),
          width: axisLineWidth,
        ),
        right: BorderSide.none,
        top: BorderSide.none,
      ),
    );
  }

  /// 获取X轴标签样式
  static TextStyle getAxisLabelStyle() {
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: axisLabelFontSize,
      fontWeight: FontWeight.w400,
    );
  }

  /// 获取Y轴标签样式
  static TextStyle getYAxisLabelStyle() {
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: yAxisLabelFontSize,
      fontWeight: FontWeight.w400,
    );
  }

  /// 获取数据标签样式
  static TextStyle getDataLabelStyle({Color? color}) {
    return TextStyle(
      color: color ?? AppColors.textPrimary,
      fontSize: dataLabelFontSize,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );
  }

  /// 获取标准数据点配置
  static FlDotData getDotData(Color color, {Color? strokeColor}) {
    return FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) {
        return FlDotCirclePainter(
          radius: dotRadius,
          color: color,
          strokeWidth: dotStrokeWidth,
          strokeColor: strokeColor ?? AppColors.cardBackground,
        );
      },
    );
  }

  /// 创建带数据标签的LineChartBarData
  static LineChartBarData createLineChartBarData({
    required List<FlSpot> spots,
    required Color color,
    Color? dotStrokeColor,
    bool isCurved = true,
    bool showDataLabels = true,
    bool showBelowArea = false,
    double? belowAreaOpacity = 0.1,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      color: color,
      barWidth: lineWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: dotRadius,
            color: color,
            strokeWidth: dotStrokeWidth,
            strokeColor: dotStrokeColor ?? AppColors.cardBackground,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: showBelowArea,
        color: showBelowArea ? color.withOpacity(belowAreaOpacity!) : null,
      ),
      show: true,
    );
  }

  /// 创建显示所有数据标签的LineTouchData配置
  /// 使用此方法可以让图表始终显示数据标签
  static LineTouchData getDataLabelsTouchData({
    required List<FlSpot> spots,
    required Color labelColor,
    String Function(double value)? formatLabel,
  }) {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: false, // 禁用内置触摸以保持标签显示
      touchTooltipData: LineTouchTooltipData(
        // Material Design 3: 使用 surface container high
        getTooltipColor: (touchedSpot) => Colors.transparent,
        tooltipBorder: const BorderSide(color: Colors.transparent),
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: 4,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            final value = touchedSpot.y;
            final label = formatLabel?.call(value) ?? '${value.toInt()}°';
            return LineTooltipItem(
              label,
              TextStyle(
                color: labelColor,
                fontSize: dataLabelFontSize,
                fontWeight: FontWeight.w600,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: AppColors.cardBackground,
                    offset: const Offset(0, 0),
                    blurRadius: 4,
                  ),
                  Shadow(
                    color: AppColors.cardBackground,
                    offset: const Offset(0, 0),
                    blurRadius: 8,
                  ),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }

  /// 获取触摸提示配置
  static LineTouchData getTouchData({
    required List<Map<String, dynamic>> chartData,
    required String Function(int index, double value, int barIndex)
    getTooltipText,
  }) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) =>
            AppColors.cardBackground.withOpacity(0.9),
        tooltipBorder: BorderSide(color: AppColors.borderColor, width: 1),
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            final index = touchedSpot.x.toInt();
            if (index >= 0 && index < chartData.length) {
              return LineTooltipItem(
                getTooltipText(index, touchedSpot.y, touchedSpot.barIndex),
                TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return null;
          }).toList();
        },
      ),
    );
  }

  /// 生成显示所有数据点标签的指示器列表
  /// 配合 LineChartData 的 showingTooltipIndicators 使用
  /// 现在默认显示所有数据点，不再使用间隔
  static List<ShowingTooltipIndicators> generateShowingIndicators({
    required List<LineChartBarData> lineBarsData,
    int interval = 1, // 默认显示所有数据点
  }) {
    final List<ShowingTooltipIndicators> result = [];

    for (int barIndex = 0; barIndex < lineBarsData.length; barIndex++) {
      final bar = lineBarsData[barIndex];
      // 为每个数据点创建指示器，现在显示所有数据点
      for (int spotIndex = 0; spotIndex < bar.spots.length; spotIndex++) {
        result.add(
          ShowingTooltipIndicators([
            LineBarSpot(bar, barIndex, bar.spots[spotIndex]),
          ]),
        );
      }
    }

    return result;
  }

  /// 获取Material Design 3风格的触摸配置（用于显示数据标签）
  static LineTouchData getM3TouchDataWithLabels() {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        // Material Design 3: 使用透明背景
        getTooltipColor: (touchedSpot) => Colors.transparent,
        tooltipBorder: const BorderSide(color: Colors.transparent),
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        tooltipMargin: 16, // 增加标签与数据点的距离
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            final value = touchedSpot.y;
            return LineTooltipItem(
              '${value.toInt()}°',
              TextStyle(
                color: touchedSpot.bar.color ?? AppColors.textPrimary,
                fontSize: dataLabelFontSize,
                fontWeight: FontWeight.w600,
                height: 1.0,
                // Material Design 3: 增强阴影效果，确保标签在任何情况下都清晰可见
                shadows: [
                  // 外层强阴影
                  Shadow(
                    color: AppColors.cardBackground.withOpacity(0.95),
                    offset: const Offset(0, 0),
                    blurRadius: 6,
                  ),
                  // 中层阴影
                  Shadow(
                    color: AppColors.cardBackground.withOpacity(0.85),
                    offset: const Offset(0, 0),
                    blurRadius: 4,
                  ),
                  // 内层阴影
                  Shadow(
                    color: AppColors.cardBackground.withOpacity(0.75),
                    offset: const Offset(0, 0),
                    blurRadius: 2,
                  ),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }

  // ==================== Material Design 3 图例组件 ====================

  /// 构建M3风格的图例项
  /// 用于多系列图表显示不同数据线的含义
  static Widget buildLegendItem({
    required String label,
    required Color color,
    double lineWidth = 16.0,
    double lineHeight = 3.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: lineWidth,
          height: lineHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建M3风格的水平图例行
  /// items: [(label, color), ...]
  static Widget buildHorizontalLegend({
    required List<MapEntry<String, Color>> items,
    double spacing = 20.0,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return Row(
      mainAxisAlignment: alignment,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildLegendItem(label: item.key, color: item.value),
            if (index < items.length - 1) SizedBox(width: spacing),
          ],
        );
      }).toList(),
    );
  }

  /// 构建M3风格的图例容器（带padding）
  static Widget buildLegendContainer({
    required List<MapEntry<String, Color>> items,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8.0),
  }) {
    return Padding(
      padding: padding,
      child: buildHorizontalLegend(items: items),
    );
  }
}
