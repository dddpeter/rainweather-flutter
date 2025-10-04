import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/weather_model.dart';
import '../providers/theme_provider.dart';

class WeatherAlertsScreen extends StatefulWidget {
  final List<WeatherAlert> alerts;

  const WeatherAlertsScreen({super.key, required this.alerts});

  @override
  State<WeatherAlertsScreen> createState() => _WeatherAlertsScreenState();
}

class _WeatherAlertsScreenState extends State<WeatherAlertsScreen> {
  // 记录每个预警卡片的展开状态
  late List<bool> _expandedStates;

  @override
  void initState() {
    super.initState();
    // 初始化所有卡片为收起状态
    _expandedStates = List.filled(widget.alerts.length, false);
  }

  // 按发布时间排序（越新越靠前）
  List<WeatherAlert> get sortedAlerts {
    final sorted = List<WeatherAlert>.from(widget.alerts);
    sorted.sort((a, b) {
      if (a.publishTime == null && b.publishTime == null) return 0;
      if (a.publishTime == null) return 1;
      if (b.publishTime == null) return -1;

      try {
        final timeA = DateTime.parse(a.publishTime!.replaceAll('/', '-'));
        final timeB = DateTime.parse(b.publishTime!.replaceAll('/', '-'));
        return timeB.compareTo(timeA); // 降序：新的在前
      } catch (e) {
        return b.publishTime!.compareTo(a.publishTime!);
      }
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = sortedAlerts;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        AppColors.setThemeProvider(themeProvider);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Header - Material Design 3
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                    child: Row(
                      children: [
                        // M3: Standard icon button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // M3: Headline medium
                        Text(
                          '气象预警',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28, // M3: Headline medium
                            fontWeight: FontWeight.w400, // M3: Regular
                            letterSpacing: 0,
                          ),
                        ),
                        const Spacer(),
                        // M3: Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(
                              0.12,
                            ), // M3: 12% opacity
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // M3: Fully rounded
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: AppColors.error,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${alerts.length}',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
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
                        return _buildAlertCard(alert, index);
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

  Widget _buildAlertCard(WeatherAlert alert, int index) {
    final levelColor = _getAlertLevelColor(alert.level);
    final levelBgColor = levelColor.withOpacity(0.15);
    final isExpanded = _expandedStates[index];
    final content = alert.content ?? '暂无详细内容';

    // M3: 定高设置（收起时）
    const double collapsedHeight = 80.0; // 预警内容区域的固定高度

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

            // Content - M3: 可展开内容
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedStates[index] = !_expandedStates[index];
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.borderColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 内容文本
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: SizedBox(
                        height: collapsedHeight,
                        child: Stack(
                          children: [
                            Text(
                              content,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.6,
                              ),
                              maxLines: 3, // 收起时显示3行
                              overflow: TextOverflow.ellipsis,
                            ),
                            // 渐变遮罩
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.borderColor.withOpacity(0.0),
                                      AppColors.borderColor.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondChild: Text(
                        content,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4), // 缩小间距
                    // M3: 展开/收起指示器
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded ? '收起' : '展开全部',
                                style: TextStyle(
                                  color: levelColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: levelColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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
