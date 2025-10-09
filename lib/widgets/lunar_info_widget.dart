import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lunar_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/theme_provider.dart';

/// 农历信息卡片组件
class LunarInfoWidget extends StatelessWidget {
  final LunarInfo lunarInfo;

  const LunarInfoWidget({Key? key, required this.lunarInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        surfaceTintColor: Colors.transparent,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16), // 与其他卡片一致
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 - 与详细信息卡片样式一致
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '农历信息',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 农历日期和干支（只使用橙色和绿色两种颜色）
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.calendar_today,
                      '农历',
                      _formatLunarDate(
                        lunarInfo.lunarMonth,
                        lunarInfo.lunarDay,
                      ),
                      const Color(0xFFFFB74D), // 橙色
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.spa,
                      '生肖',
                      '${lunarInfo.yearAnimal}年',
                      const Color(0xFF64DD17), // 绿色
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.auto_awesome,
                      '星座',
                      lunarInfo.constellation,
                      const Color(0xFFFFB74D), // 橙色
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.spa_outlined,
                      '干支',
                      lunarInfo.dayGanZhi,
                      const Color(0xFF64DD17), // 绿色
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化农历日期，确保有"月"字
  String _formatLunarDate(String lunarMonth, String lunarDay) {
    // 如果月份已经包含"月"字，直接拼接
    if (lunarMonth.contains('月')) {
      return '$lunarMonth$lunarDay';
    }
    // 否则添加"月"字
    return '$lunarMonth月$lunarDay';
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Builder(
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        // 与详细信息卡片完全一致的透明度
        final backgroundOpacity = themeProvider.isLightTheme ? 0.15 : 0.25;
        final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.2 : 0.3;

        return Container(
          decoration: BoxDecoration(
            color: iconColor.withOpacity(backgroundOpacity), // 根据主题调整透明度
            borderRadius: BorderRadius.circular(4), // 与详细信息卡片一致
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(iconBackgroundOpacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 宜忌卡片组件
class YiJiWidget extends StatelessWidget {
  final LunarInfo lunarInfo;

  const YiJiWidget({Key? key, required this.lunarInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        surfaceTintColor: Colors.transparent,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16), // 与其他卡片一致
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 - 与详细信息卡片样式一致
              Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '宜忌提醒',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 宜 - 与今日提醒样式一致
              _buildYiJiItem(
                Icons.check_circle_rounded,
                '宜',
                lunarInfo.goodThings.isEmpty
                    ? '诸事不宜'
                    : lunarInfo.goodThings.join('、'),
                AppColors.accentGreen,
              ),
              const SizedBox(height: 12),

              // 忌 - 与今日提醒样式一致
              _buildYiJiItem(
                Icons.cancel_rounded,
                '忌',
                lunarInfo.badThings.isEmpty
                    ? '百无禁忌'
                    : lunarInfo.badThings.join('、'),
                AppColors.error,
              ),

              // 黄道吉日标识
              if (lunarInfo.isHuangDaoDay) ...[
                const SizedBox(height: 12),
                _buildYiJiItem(
                  Icons.star_rounded,
                  '黄道吉日',
                  '今日为黄道吉日，诸事宜',
                  AppColors.warning,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYiJiItem(IconData icon, String label, String text, Color color) {
    return Builder(
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        // 与今日提醒卡片完全一致的透明度
        final backgroundOpacity = themeProvider.isLightTheme ? 0.08 : 0.25;
        final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.12 : 0.3;

        return Container(
          padding: const EdgeInsets.all(12), // 与今日提醒一致
          decoration: BoxDecoration(
            color: color.withOpacity(backgroundOpacity),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ), // 与今日提醒一致
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(iconBackgroundOpacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 18), // 与今日提醒一致
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold, // 与今日提醒一致
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 节气节日列表组件
class SolarTermListWidget extends StatelessWidget {
  final List<SolarTermInfo> solarTerms;
  final String title;

  const SolarTermListWidget({
    Key? key,
    required this.solarTerms,
    this.title = '即将到来的节气',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (solarTerms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: Card(
        elevation: AppColors.cardElevation,
        shadowColor: AppColors.cardShadowColor,
        color: AppColors.materialCardColor,
        surfaceTintColor: Colors.transparent,
        shape: AppColors.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 - 与详细信息卡片样式一致
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    color: AppColors.accentBlue,
                    size: AppConstants.sectionTitleIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 节气列表
              ...solarTerms.map((term) => _buildSolarTermItem(term)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolarTermItem(SolarTermInfo term) {
    final daysFromNow = term.daysFromNow();
    final isToday = term.isToday();

    return Builder(
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        // 与详细信息卡片完全一致的透明度
        final backgroundOpacity = themeProvider.isLightTheme ? 0.15 : 0.25;
        final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.2 : 0.3;

        final itemColor = isToday
            ? AppColors.warning
            : AppColors.accentBlue; // 换成蓝色

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(backgroundOpacity),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // 表情符号
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(iconBackgroundOpacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(term.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 8),

              // 节气信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          term.name,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '今天',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      term.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 日期和倒计时
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${term.date.month}/${term.date.day}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isToday && daysFromNow >= 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      daysFromNow == 0
                          ? '今天'
                          : daysFromNow == 1
                          ? '明天'
                          : '${daysFromNow}天',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
