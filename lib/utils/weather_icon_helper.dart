import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import 'package:flutter/material.dart';

/// 天气图标工具类
/// 提供统一的天气图标获取和空气质量相关的公共方法
class WeatherIconHelper {
  /// 获取中文天气图标路径
  ///
  /// [weatherType] 天气类型，如"晴"、"多云"等
  /// [isNight] 是否为夜间
  ///
  /// 返回图标相对于 assets/images/ 的路径
  static String getChineseWeatherIcon(String weatherType, bool isNight) {
    final iconMap = isNight
        ? AppConstants.chineseNightWeatherImages
        : AppConstants.chineseWeatherImages;
    return iconMap[weatherType] ?? iconMap['晴'] ?? '晴.png';
  }

  /// 根据小时数判断是否为夜间
  ///
  /// [hour] 小时数（0-23）
  ///
  /// 返回true表示夜间（18:00-6:00），false表示白天（6:00-18:00）
  static bool isNightByHour(int hour) {
    return hour < 6 || hour >= 18;
  }

  /// 从时间字符串中提取小时数
  ///
  /// [timeStr] 时间字符串，如 "08:00"、"14:30" 等
  ///
  /// 返回小时数（0-23），解析失败返回12（默认白天）
  static int getHourValue(String timeStr) {
    try {
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.isNotEmpty) {
          return int.parse(parts[0]);
        }
      }
      return 12; // 默认白天
    } catch (e) {
      return 12;
    }
  }

  /// 根据时段名称判断是否为夜间
  ///
  /// [period] 时段名称，如 "上午"、"下午"
  ///
  /// 注意：数据结构中上午使用pm数据（夜间），下午使用am数据（白天）
  static bool isNightByPeriod(String period) {
    return period == '上午';
  }

  /// 构建天气图标Widget
  ///
  /// [weatherType] 天气类型
  /// [isNight] 是否为夜间
  /// [size] 图标大小
  ///
  /// 返回带错误处理的Image.asset组件
  static Widget buildWeatherIcon(
    String weatherType,
    bool isNight,
    double size,
  ) {
    final iconPath = getChineseWeatherIcon(weatherType, isNight);

    return Image.asset(
      'assets/images/$iconPath',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // 加载失败时显示默认图标
        return Image.asset(
          'assets/images/不清楚.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      },
    );
  }

  /// 获取空气质量等级文本
  ///
  /// [aqi] AQI数值
  ///
  /// 返回空气质量等级文本
  static String getAirQualityLevelText(int aqi) {
    if (aqi <= 50) return '优';
    if (aqi <= 100) return '良';
    if (aqi <= 150) return '轻度污染';
    if (aqi <= 200) return '中度污染';
    if (aqi <= 300) return '重度污染';
    return '严重污染';
  }

  /// 获取空气质量颜色
  ///
  /// [aqi] AQI数值
  ///
  /// 返回对应等级的颜色
  static Color getAirQualityColor(int aqi) {
    if (aqi <= 50) return AppColors.airExcellent; // 优
    if (aqi <= 100) return AppColors.airGood; // 良
    if (aqi <= 150) return AppColors.airLight; // 轻度污染
    if (aqi <= 200) return AppColors.airModerate; // 中度污染
    if (aqi <= 300) return AppColors.airHeavy; // 重度污染
    return AppColors.airSevere; // 严重污染
  }

  /// 构建空气质量指标Widget
  ///
  /// [aqi] AQI数值
  /// [iconSize] 图标大小
  /// [fontSize] 文字大小
  ///
  /// 返回包含图标和AQI数值的Row组件
  static Widget buildAirQualityIndicator({
    required int aqi,
    double iconSize = 12,
    double fontSize = 11,
  }) {
    final color = getAirQualityColor(aqi);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.air, color: color, size: iconSize),
        const SizedBox(width: 4),
        Text(
          'AQI $aqi',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
