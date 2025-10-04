import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/weather_model.dart';
import '../providers/theme_provider.dart';

class WeatherAlertsScreen extends StatelessWidget {
  final List<WeatherAlert> alerts;

  const WeatherAlertsScreen({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        AppColors.setThemeProvider(themeProvider);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppColors.titleBarIconColor,
                            size: AppColors.titleBarIconSize,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '气象预警',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${alerts.length}条预警',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Alerts List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _buildAlertCard(alert);
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

  Widget _buildAlertCard(WeatherAlert alert) {
    final levelColor = _getAlertLevelColor(alert.level);
    final levelBgColor = levelColor.withOpacity(0.15);

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: levelColor, width: 2),
      ),
      margin: const EdgeInsets.only(bottom: AppConstants.cardSpacing),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Type and Level
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: levelBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAlertIcon(alert.type),
                    color: levelColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.type ?? '未知类型',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: levelColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${alert.level ?? "未知"}预警',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            alert.city ?? '',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Publish Time
            if (alert.publishTime != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '发布时间：${alert.publishTime}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Content
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.borderColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                alert.content ?? '暂无详细内容',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertLevelColor(String? level) {
    if (level == null) return AppColors.textSecondary;

    switch (level) {
      case '红色':
        return const Color(0xFFD32F2F); // 红色 - 最严重
      case '橙色':
        return const Color(0xFFFF6F00); // 橙色 - 严重
      case '黄色':
        return const Color(0xFFF57C00); // 黄色 - 较重
      case '蓝色':
        return const Color(0xFF1976D2); // 蓝色 - 一般
      default:
        return AppColors.warning;
    }
  }

  IconData _getAlertIcon(String? type) {
    if (type == null) return Icons.warning_rounded;

    if (type.contains('暴雨') || type.contains('雨')) {
      return Icons.water_drop_rounded;
    } else if (type.contains('地质') ||
        type.contains('滑坡') ||
        type.contains('泥石流')) {
      return Icons.landslide_rounded;
    } else if (type.contains('大雾') || type.contains('雾')) {
      return Icons.foggy;
    } else if (type.contains('雷') || type.contains('电')) {
      return Icons.thunderstorm_rounded;
    } else if (type.contains('台风') || type.contains('风')) {
      return Icons.air_rounded;
    } else if (type.contains('高温') || type.contains('温')) {
      return Icons.thermostat_rounded;
    } else if (type.contains('寒') || type.contains('冰') || type.contains('雪')) {
      return Icons.ac_unit_rounded;
    } else {
      return Icons.warning_rounded;
    }
  }
}
