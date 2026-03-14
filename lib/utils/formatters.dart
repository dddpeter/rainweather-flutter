/// 格式化工具类
/// 
/// 提供统一的数值、字符串格式化方法
class Formatters {
  /// 格式化数值
  /// 
  /// 将数值转换为整数显示，null 返回默认值
  static String formatNumber(dynamic value, {String defaultValue = '--'}) {
    if (value == null) return defaultValue;

    if (value is String) {
      final numValue = double.tryParse(value);
      if (numValue != null) {
        return numValue.toInt().toString();
      }
      return value.isEmpty ? defaultValue : value;
    }

    if (value is num) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  /// 格式化温度
  static String formatTemperature(dynamic value, {String defaultValue = '--'}) {
    final formatted = formatNumber(value, defaultValue: defaultValue);
    if (formatted == defaultValue) return formatted;
    return '$formatted°';
  }

  /// 格式化湿度
  static String formatHumidity(dynamic value, {String defaultValue = '--'}) {
    final formatted = formatNumber(value, defaultValue: defaultValue);
    if (formatted == defaultValue) return formatted;
    return '$formatted%';
  }

  /// 格式化气压
  static String formatPressure(dynamic value, {String defaultValue = '--'}) {
    final formatted = formatNumber(value, defaultValue: defaultValue);
    if (formatted == defaultValue) return formatted;
    return '$formatted hPa';
  }

  /// 格式化能见度
  static String formatVisibility(dynamic value, {String defaultValue = '--'}) {
    final formatted = formatNumber(value, defaultValue: defaultValue);
    if (formatted == defaultValue) return formatted;
    return '$formatted km';
  }

  /// 格式化风速
  static String formatWindSpeed(dynamic value, {String defaultValue = '--'}) {
    final formatted = formatNumber(value, defaultValue: defaultValue);
    if (formatted == defaultValue) return formatted;
    return '$formatted km/h';
  }

  /// 格式化百分比
  static String formatPercentage(dynamic value, {String defaultValue = '--'}) {
    final formatted = formatNumber(value, defaultValue: defaultValue);
    if (formatted == defaultValue) return formatted;
    return '$formatted%';
  }
}
