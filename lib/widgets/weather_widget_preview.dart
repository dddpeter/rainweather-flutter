import 'package:flutter/material.dart';
import '../widgets/weather_widget_config.dart';

/// 天气小组件预览组件
/// 用于在Flutter应用中预览小组件效果
class WeatherWidgetPreview extends StatelessWidget {
  const WeatherWidgetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WeatherWidgetConfig.widgetWidth,
      height: WeatherWidgetConfig.widgetHeight,
      decoration: BoxDecoration(
        color: WeatherWidgetConfig.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部区域：位置 + 当前温度 + 今日高低温度
            _buildTopSection(),

            const SizedBox(height: 16),

            // 24小时天气预报
            _buildHourlyForecast(),

            const SizedBox(height: 16),

            // 分隔线
            Container(height: 1, color: WeatherWidgetConfig.dividerColor),

            const SizedBox(height: 16),

            // 5日天气预报
            _buildDailyForecast(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Row(
      children: [
        // 左侧：位置和当前温度
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '北京市朝阳区',
                style: TextStyle(
                  color: WeatherWidgetConfig.textPrimaryColor,
                  fontSize: WeatherWidgetConfig.fontSizeLocation,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '9°',
                style: TextStyle(
                  color: WeatherWidgetConfig.textPrimaryColor,
                  fontSize: WeatherWidgetConfig.fontSizeCurrentTemp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 右侧：当前天气和今日温度
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud,
                  color: WeatherWidgetConfig.textPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '多云',
                  style: TextStyle(
                    color: WeatherWidgetConfig.textPrimaryColor,
                    fontSize: WeatherWidgetConfig.fontSizeCurrentWeather,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '最高 13°',
              style: TextStyle(
                color: WeatherWidgetConfig.textSecondaryColor,
                fontSize: WeatherWidgetConfig.fontSizeTodayTemp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '最低 4°',
              style: TextStyle(
                color: WeatherWidgetConfig.textSecondaryColor,
                fontSize: WeatherWidgetConfig.fontSizeTodayTemp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    final hourlyData = [
      {'time': '21时', 'temp': '9°', 'weather': Icons.cloud},
      {'time': '22时', 'temp': '9°', 'weather': Icons.cloud},
      {'time': '23时', 'temp': '9°', 'weather': Icons.cloud},
      {'time': '0时', 'temp': '9°', 'weather': Icons.cloud},
      {'time': '1时', 'temp': '8°', 'weather': Icons.cloud},
      {'time': '2时', 'temp': '8°', 'weather': Icons.cloud},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: hourlyData.map((data) {
        return Column(
          children: [
            Text(
              data['time'] as String,
              style: TextStyle(
                color: WeatherWidgetConfig.textSecondaryColor,
                fontSize: WeatherWidgetConfig.fontSizeHourlyTime,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              data['weather'] as IconData,
              color: WeatherWidgetConfig.textPrimaryColor,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              data['temp'] as String,
              style: TextStyle(
                color: WeatherWidgetConfig.textPrimaryColor,
                fontSize: WeatherWidgetConfig.fontSizeHourlyTemp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDailyForecast() {
    final dailyData = [
      {'weekday': '周六', 'weather': Icons.wb_sunny, 'high': '15°', 'low': '6°'},
      {'weekday': '周日', 'weather': Icons.wb_sunny, 'high': '13°', 'low': '4°'},
      {'weekday': '周一', 'weather': Icons.wb_sunny, 'high': '13°', 'low': '2°'},
      {'weekday': '周二', 'weather': Icons.wb_sunny, 'high': '11°', 'low': '3°'},
      {'weekday': '周三', 'weather': Icons.cloud, 'high': '16°', 'low': '6°'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: dailyData.map((data) {
        return Column(
          children: [
            Text(
              data['weekday'] as String,
              style: TextStyle(
                color: WeatherWidgetConfig.textPrimaryColor,
                fontSize: WeatherWidgetConfig.fontSizeDailyWeekday,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              data['weather'] as IconData,
              color: WeatherWidgetConfig.textPrimaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              data['low'] as String,
              style: TextStyle(
                color: WeatherWidgetConfig.textSecondaryColor,
                fontSize: WeatherWidgetConfig.fontSizeDailyTemp,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // 温度条
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WeatherWidgetConfig.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data['high'] as String,
              style: TextStyle(
                color: WeatherWidgetConfig.textSecondaryColor,
                fontSize: WeatherWidgetConfig.fontSizeDailyTemp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
