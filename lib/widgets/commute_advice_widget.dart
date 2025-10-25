import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/commute_advice_model.dart';

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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // ✨ AI智能助手专用渐变背景：深紫到深蓝
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4A148C).withOpacity(0.9), // 深紫
                        Color(0xFF1A237E).withOpacity(0.9), // 深蓝
                        Color(0xFF0D47A1).withOpacity(0.9), // 更深蓝
                      ],
                    ),
                    // 添加微妙的几何图案效果（金色光晕）
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFFB300).withOpacity(0.1), // 金色光晕
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
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
                                  color: const Color(0xFFFFB300), // 金琥珀色
                                  size: AppConstants.sectionTitleIconSize,
                                ),
                                const SizedBox(width: 8),
                                // 标题（固定文字）
                                Text(
                                  '通勤提醒',
                                  style: TextStyle(
                                    color: Colors.white, // 白色文字
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
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${advices.length}条',
                                    style: TextStyle(
                                      color: Colors.white70,
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
                                  color: Colors.white70,
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
              ),
            );
          },
        );
      },
    );
  }

  /// 构建单个建议项（AI智能助手风格，简洁文字展示）
  Widget _buildAdviceItem(CommuteAdviceModel advice, bool isCollapsed) {
    final levelColor = advice.getLevelColor();
    final levelName = advice.getLevelName();
    const aiColor = Color(0xFFFFB300); // 琥珀色

    // ✨ 使用和AI智能助手完全一致的样式：金琥珀色边框和渐变背景
    return InkWell(
      onTap: isCollapsed
          ? () {
              // 收起时点击展开
              setState(() {
                _isExpanded = true;
              });
            }
          : null, // 展开时不响应点击
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: aiColor.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标（emoji）
            Text(advice.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 级别标签 - 保留颜色
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          levelName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
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
                                  color: Colors.white, // 白色文字
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // AI标签（金琥珀色）
                            if (advice.adviceType == 'ai_smart') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB300,
                                  ).withOpacity(0.25),
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
                                        fontSize: 10,
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
                        color: Colors.white70, // 半透明白色
                        fontSize: 14,
                        height: 1.5,
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
