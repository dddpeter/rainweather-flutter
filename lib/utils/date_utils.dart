/// 日期工具类
/// 
/// 提供统一的日期判断和格式化方法
class DateUtils {
  /// 判断是否为今天
  static bool isToday(String forecastTime) {
    if (forecastTime.isEmpty) return false;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final forecastDate = _parseForecastDate(forecastTime, now);

      return forecastDate != null &&
          forecastDate.year == today.year &&
          forecastDate.month == today.month &&
          forecastDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  /// 判断是否为明天
  static bool isTomorrow(String forecastTime) {
    if (forecastTime.isEmpty) return false;

    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final forecastDate = _parseForecastDate(forecastTime, now);

      return forecastDate != null &&
          forecastDate.year == tomorrow.year &&
          forecastDate.month == tomorrow.month &&
          forecastDate.day == tomorrow.day;
    } catch (e) {
      return false;
    }
  }

  /// 解析预报日期
  static DateTime? _parseForecastDate(String forecastTime, DateTime now) {
    if (forecastTime.contains('-')) {
      final parts = forecastTime.split(' ')[0].split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else if (parts.length == 2) {
        return DateTime(
          now.year,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } else if (forecastTime.contains('/')) {
      final parts = forecastTime.split(' ')[0].split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else if (parts.length == 2) {
        return DateTime(
          now.year,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    }
    return null;
  }

  /// 格式化日期为友好显示
  static String formatDate(String forecastTime, {String defaultText = ''}) {
    if (forecastTime.isEmpty) return defaultText;

    if (isToday(forecastTime)) {
      return '今天';
    } else if (isTomorrow(forecastTime)) {
      return '明天';
    }

    return forecastTime;
  }

  /// 获取星期几
  static String getWeekday(String forecastTime) {
    if (forecastTime.isEmpty) return '';

    try {
      final date = _parseForecastDate(forecastTime, DateTime.now());
      if (date == null) return '';

      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[date.weekday - 1];
    } catch (e) {
      return '';
    }
  }
}
