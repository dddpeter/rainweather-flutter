import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 通勤建议组件
class CommuteAdviceWidget extends StatefulWidget {
  const CommuteAdviceWidget({super.key});

  @override
  State<CommuteAdviceWidget> createState() => _CommuteAdviceWidgetState();
}

class _CommuteAdviceWidgetState extends State<CommuteAdviceWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 使用嵌套 Consumer 同时监听主题和天气数据变化
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<WeatherProvider>(
          builder: (context, weatherProvider, child) {
            final advices = weatherProvider.commuteAdvices;

            // 如果没有通勤建议，不显示组件
            if (advices.isEmpty) {
              return const SizedBox.shrink();
            }

            // 未读的建议数量
            final unreadCount = advices.where((a) => !a.isRead).length;

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
                      // 标题行（可点击展开/收起）
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                          // 展开时标记全部为已读
                          if (_isExpanded && unreadCount > 0) {
                            weatherProvider.markAllCommuteAdvicesAsRead();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              // 图标
                              Icon(
                                Icons.commute_rounded,
                                color: AppColors.warning,
                                size: AppConstants.sectionTitleIconSize,
                              ),
                              const SizedBox(width: 8),
                              // 标题（固定文字）
                              Text(
                                '通勤提醒',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: AppConstants.sectionTitleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 建议数量标签（始终显示）
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${advices.length}条',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // 展开/收起图标（展开朝下，收起朝右）
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_right,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 建议列表（收起时显示第一条，展开时显示所有）
                      const SizedBox(height: 12),
                      ...() {
                        final sortedAdvices = List.from(advices);
                        sortedAdvices.sort(
                          (a, b) => a.priority.compareTo(b.priority),
                        );
                        // 收起时只显示第一条，展开时显示所有
                        final displayAdvices = _isExpanded
                            ? sortedAdvices
                            : [sortedAdvices.first];
                        return displayAdvices.map(
                          (advice) => _buildAdviceItem(advice, !_isExpanded),
                        );
                      }(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建单个建议项（参考生活指数卡片样式，收起时可点击展开）
  Widget _buildAdviceItem(advice, bool isCollapsed) {
    final levelColor = advice.getLevelColor();
    final levelBgColor = advice.getLevelBackgroundColor();
    final levelName = advice.getLevelName();

    // 参考生活指数卡片的透明度设置
    final themeProvider = context.read<ThemeProvider>();
    final backgroundOpacity = themeProvider.isLightTheme ? 0.15 : 0.25;
    final iconBackgroundOpacity = themeProvider.isLightTheme ? 0.2 : 0.3;

    return InkWell(
      onTap: isCollapsed
          ? () {
              // 收起时点击小卡片展开
              setState(() {
                _isExpanded = true;
              });
            }
          : null, // 展开时不响应点击
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: levelBgColor.withOpacity(backgroundOpacity),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标
            Text(advice.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 级别标签
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(iconBackgroundOpacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          levelName,
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                advice.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // AI标签（仅AI生成的建议显示）
                            if (advice.adviceType == 'ai_smart') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB300,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: const Color(0xFFFFB300),
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'AI',
                                      style: TextStyle(
                                        color: const Color(0xFFFFB300),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 收起时不显示详细内容，展开时显示
                  if (!isCollapsed) ...[
                    const SizedBox(height: 8),
                    Text(
                      advice.content,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
