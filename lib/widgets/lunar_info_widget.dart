import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lunar_model.dart';
import '../screens/lao_huang_li_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/theme_provider.dart';

/// 农历信息卡片组件
class LunarInfoWidget extends StatelessWidget {
  final LunarInfo lunarInfo;

  const LunarInfoWidget({super.key, required this.lunarInfo});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  isFirstColumn: true,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildInfoRow(
                  Icons.spa,
                  '生肖',
                  '${lunarInfo.yearAnimal}年',
                  const Color(0xFF64DD17), // 绿色
                  isFirstColumn: false,
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
                  isFirstColumn: true,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildInfoRow(
                  Icons.spa_outlined,
                  '干支',
                  lunarInfo.dayGanZhi,
                  const Color(0xFF64DD17), // 绿色
                  isFirstColumn: false,
                ),
              ),
            ],
          ),
        ],
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
    Color iconColor, {
    bool isFirstColumn = false,
  }) {
    return Builder(
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );

        // 根据所在列和主题决定颜色
        Color finalIconColor;
        Color backgroundColor;
        Color textColor;
        double iconBackgroundOpacity;

        // 背景色的基础颜色（橙色或绿色）
        final baseColor = isFirstColumn
            ? const Color(0xFFFFB74D) // 第一列橙色
            : const Color(0xFF64DD17); // 第二列绿色

        if (themeProvider.isLightTheme) {
          // 亮色模式：图标主题深蓝色，背景保持橙/绿半透明，文字主题深蓝
          finalIconColor = const Color(0xFF012d78); // 图标主题深蓝色
          backgroundColor = baseColor.withOpacity(0.25); // 背景保持橙/绿半透明
          textColor = const Color(0xFF012d78); // 主题深蓝字
          iconBackgroundOpacity = 0.2;
        } else {
          // 暗色模式：图标白色，背景橙/绿半透明，文字白色
          finalIconColor = Colors.white; // 图标白色
          backgroundColor = baseColor.withOpacity(0.25); // 背景橙/绿半透明
          textColor = AppColors.textPrimary; // 白字
          iconBackgroundOpacity = 0.3;
        }

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor, // 根据主题调整颜色
            borderRadius: BorderRadius.circular(4), // 与详细信息卡片一致
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  themeProvider.isLightTheme ? 0.08 : 0.15,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
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
                        color: finalIconColor.withOpacity(
                          iconBackgroundOpacity,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(icon, color: finalIconColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor, // 使用配对的文字颜色
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
                    color: textColor, // 使用配对的文字颜色
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

/// 宜忌卡片组件 - 美化版
class YiJiWidget extends StatelessWidget {
  final LunarInfo lunarInfo;

  const YiJiWidget({super.key, required this.lunarInfo});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isLight = themeProvider.isLightTheme;

    // 准备宜忌数据
    final goodItems = lunarInfo.goodThings.isEmpty
        ? ['诸事不宜']
        : lunarInfo.goodThings;
    final badItems = lunarInfo.badThings.isEmpty
        ? ['百无禁忌']
        : lunarInfo.badThings;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLight
                        ? [
                            AppColors.accentBlue.withOpacity(0.15),
                            AppColors.accentBlue.withOpacity(0.08),
                          ]
                        : [
                            AppColors.accentBlue.withOpacity(0.25),
                            AppColors.accentBlue.withOpacity(0.15),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: AppColors.accentBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '宜忌提醒',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppConstants.sectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 黄历详情入口 - 优化样式
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LaoHuangLiScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLight
                          ? [
                              AppColors.accentBlue.withOpacity(0.12),
                              AppColors.accentBlue.withOpacity(0.06),
                            ]
                          : [
                              AppColors.accentBlue.withOpacity(0.2),
                              AppColors.accentBlue.withOpacity(0.1),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentBlue.withOpacity(
                        isLight ? 0.3 : 0.4,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_note,
                        color: AppColors.accentBlue,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '黄历详情',
                        style: TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 宜忌卡片 - 使用渐变卡片设计，固定高度
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 宜卡片
                Expanded(
                  child: _buildYiJiCard(
                    context,
                    isGood: true,
                    items: goodItems,
                    icon: Icons.check_circle_rounded,
                    color: AppColors.accentGreen,
                    isLight: isLight,
                  ),
                ),
                const SizedBox(width: 12),
                // 忌卡片
                Expanded(
                  child: _buildYiJiCard(
                    context,
                    isGood: false,
                    items: badItems,
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    isLight: isLight,
                  ),
                ),
              ],
            ),
          ),

          // 黄道吉日标识 - 特殊样式
          if (lunarInfo.isHuangDaoDay) ...[
            const SizedBox(height: 12),
            _buildHuangDaoDayCard(isLight),
          ],
        ],
      ),
    );
  }

  /// 构建宜忌卡片
  Widget _buildYiJiCard(
    BuildContext context, {
    required bool isGood,
    required List<String> items,
    required IconData icon,
    required Color color,
    required bool isLight,
  }) {
    final label = isGood ? '宜' : '忌';
    final displayText = items.join('、');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  color.withOpacity(0.12),
                  color.withOpacity(0.05),
                ]
              : [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isLight ? 0.25 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isLight ? 0.15 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // 标签行
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isLight
                      ? color.withOpacity(0.15)
                      : color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 内容文字 - 使用Expanded填充剩余空间
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                displayText,
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建黄道吉日卡片
  Widget _buildHuangDaoDayCard(bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  const Color(0xFFFFF8E1), // 金色系亮色
                  const Color(0xFFFFECB3),
                ]
              : [
                  const Color(0xFFFFB300).withOpacity(0.2),
                  const Color(0xFFFF8F00).withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB300).withOpacity(isLight ? 0.4 : 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(isLight ? 0.2 : 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            color: const Color(0xFFFFB300),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '黄道吉日',
            style: TextStyle(
              color: const Color(0xFFFFB300),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 16,
            width: 1,
            color: const Color(0xFFFFB300).withOpacity(0.5),
          ),
          const SizedBox(width: 12),
          Text(
            '诸事宜',
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 节气节日列表组件

/// 节气节日列表组件
class SolarTermListWidget extends StatelessWidget {
  final List<SolarTermInfo> solarTerms;
  final String title;

  const SolarTermListWidget({
    super.key,
    required this.solarTerms,
    this.title = '即将到来的节气',
  });

  @override
  Widget build(BuildContext context) {
    if (solarTerms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
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

        // 根据主题决定颜色
        Color iconColor;
        Color backgroundColor;
        Color textColor;
        double iconBackgroundOpacity;

        // 背景色的基础颜色（太阳红色或琥珀金色）
        final baseColor = themeProvider.isLightTheme
            ? const Color(0xFFE53935) // 亮色模式：太阳红色
            : const Color(0xFFFFB300); // 暗色模式：琥珀金色

        if (themeProvider.isLightTheme) {
          // 亮色模式：图标主题深蓝色，背景太阳红半透明，文字主题深蓝
          iconColor = const Color(0xFF012d78); // 图标主题深蓝色
          backgroundColor = baseColor.withOpacity(0.25); // 背景太阳红半透明
          textColor = const Color(0xFF012d78); // 主题深蓝字
          iconBackgroundOpacity = 0.2;
        } else {
          // 暗色模式：图标白色，背景琥珀金半透明，文字白色
          iconColor = Colors.white; // 图标白色
          backgroundColor = baseColor.withOpacity(0.25); // 背景琥珀金半透明
          textColor = AppColors.textPrimary; // 白字
          iconBackgroundOpacity = 0.3;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  themeProvider.isLightTheme ? 0.08 : 0.15,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // 表情符号
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(iconBackgroundOpacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  term.emoji,
                  style: TextStyle(fontSize: 20, color: iconColor),
                ),
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
                            color: textColor, // 使用配对的文字颜色
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
                        color: textColor, // 使用配对的文字颜色
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
                      color: textColor, // 使用配对的文字颜色
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
                        color: textColor, // 使用配对的文字颜色
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
