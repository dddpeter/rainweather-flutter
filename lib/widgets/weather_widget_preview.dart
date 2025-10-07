import 'package:flutter/material.dart';
import 'weather_widget_config.dart';

/// 天气小组件预览
/// 用于在应用内展示小组件的样式
class WeatherWidgetPreview extends StatelessWidget {
  final Map<String, dynamic> data;

  const WeatherWidgetPreview({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WeatherWidgetConfig.widgetWidth,
      height: WeatherWidgetConfig.widgetHeight,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WeatherWidgetConfig.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：日期、星期、农历
          _buildFirstRow(),

          const SizedBox(height: 12),

          // 第二行：时间和天气信息
          _buildSecondRow(),

          const SizedBox(height: 12),

          // 第三行：位置、空气、风力、降雨
          _buildThirdRow(),

          const SizedBox(height: 12),

          // 第四行：5日天气预报
          Expanded(child: _buildFourthRow()),
        ],
      ),
    );
  }

  /// 第一行：日期、星期、农历
  Widget _buildFirstRow() {
    return Row(
      children: [
        Text(
          data[WeatherWidgetConfig.keyDate] ?? '',
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeDate,
            color: WeatherWidgetConfig.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          data[WeatherWidgetConfig.keyWeekday] ?? '',
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeDate,
            color: WeatherWidgetConfig.textSecondaryColor,
          ),
        ),
        const Spacer(),
        Text(
          data[WeatherWidgetConfig.keyLunarDate] ?? '',
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeDate,
            color: WeatherWidgetConfig.textTertiaryColor,
          ),
        ),
      ],
    );
  }

  /// 第二行：时间和天气信息
  Widget _buildSecondRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 时间
        Text(
          data[WeatherWidgetConfig.keyTime] ?? '',
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeTime,
            color: WeatherWidgetConfig.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 16),

        // 天气图标
        _buildWeatherIcon(data[WeatherWidgetConfig.keyWeatherIcon] ?? ''),

        const SizedBox(width: 8),

        // 天气文字
        Text(
          data[WeatherWidgetConfig.keyWeatherText] ?? '',
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeWeather,
            color: WeatherWidgetConfig.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const Spacer(),

        // 温度
        Text(
          data[WeatherWidgetConfig.keyTemperature] ?? '',
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeTemperature,
            color: WeatherWidgetConfig.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 第三行：位置、空气、风力、降雨
  Widget _buildThirdRow() {
    return Row(
      children: [
        _buildInfoItem(
          Icons.location_on,
          data[WeatherWidgetConfig.keyLocation] ?? '',
        ),
        const SizedBox(width: 16),
        _buildInfoItem(Icons.air, data[WeatherWidgetConfig.keyAqi] ?? ''),
        const SizedBox(width: 16),
        _buildInfoItem(
          Icons.air_rounded,
          data[WeatherWidgetConfig.keyWind] ?? '',
        ),
        const SizedBox(width: 16),
        _buildInfoItem(
          Icons.water_drop,
          data[WeatherWidgetConfig.keyRainAlert] ?? '',
          color: _getRainAlertColor(
            data[WeatherWidgetConfig.keyRainAlert] ?? '',
          ),
        ),
      ],
    );
  }

  /// 第四行：5日天气预报
  Widget _buildFourthRow() {
    final forecast5d =
        data[WeatherWidgetConfig.keyForecast5d] as List<dynamic>? ?? [];

    if (forecast5d.isEmpty) {
      return const Center(
        child: Text(
          '暂无预报数据',
          style: TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeForecast,
            color: WeatherWidgetConfig.textTertiaryColor,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: forecast5d.map((item) {
        final day = item as Map<String, dynamic>;
        return _buildForecastItem(
          date: day['date'] ?? '',
          weekday: day['weekday'] ?? '',
          icon: day['weatherIcon'] ?? '',
          high: day['tempHigh'] ?? '',
          low: day['tempLow'] ?? '',
        );
      }).toList(),
    );
  }

  /// 信息项
  Widget _buildInfoItem(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? WeatherWidgetConfig.textSecondaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeInfo,
            color: color ?? WeatherWidgetConfig.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// 预报项
  Widget _buildForecastItem({
    required String date,
    required String weekday,
    required String icon,
    required String high,
    required String low,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          date,
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeForecast,
            color: WeatherWidgetConfig.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (weekday.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            weekday,
            style: const TextStyle(
              fontSize: 10,
              color: WeatherWidgetConfig.textTertiaryColor,
            ),
          ),
        ],
        const SizedBox(height: 4),
        _buildWeatherIcon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          high,
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeForecast,
            color: WeatherWidgetConfig.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          low,
          style: const TextStyle(
            fontSize: WeatherWidgetConfig.fontSizeForecast,
            color: WeatherWidgetConfig.textTertiaryColor,
          ),
        ),
      ],
    );
  }

  /// 天气图标
  Widget _buildWeatherIcon(String iconCode, {double size = 32}) {
    // 这里简化处理，实际应该根据iconCode显示对应的天气图标
    IconData iconData = Icons.wb_sunny;
    Color iconColor = Colors.orange;

    if (iconCode.contains('晴')) {
      iconData = Icons.wb_sunny;
      iconColor = Colors.orange;
    } else if (iconCode.contains('云') || iconCode.contains('阴')) {
      iconData = Icons.cloud;
      iconColor = Colors.grey;
    } else if (iconCode.contains('雨')) {
      iconData = Icons.umbrella;
      iconColor = Colors.blue;
    } else if (iconCode.contains('雪')) {
      iconData = Icons.ac_unit;
      iconColor = Colors.lightBlue;
    }

    return Icon(iconData, size: size, color: iconColor);
  }

  /// 获取降雨提醒颜色
  Color _getRainAlertColor(String alert) {
    if (alert.contains('带伞') || alert.contains('有雨')) {
      return Colors.red;
    } else if (alert.contains('可能')) {
      return Colors.orange;
    }
    return WeatherWidgetConfig.textSecondaryColor;
  }
}
