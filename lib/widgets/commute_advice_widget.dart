import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
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
            child: Column(
              children: [
                // 标题栏（可点击展开/收起）
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.commute_rounded,
                            color: AppColors.warning,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 标题和提示
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '通勤出行提醒',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${advices.length}条出行建议',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 展开/收起图标
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // 建议列表（展开时显示）
                if (_isExpanded)
                  Column(
                    children: [
                      Divider(height: 1, color: AppColors.cardBorder),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: advices.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.cardBorder.withOpacity(0.5),
                        ),
                        itemBuilder: (context, index) {
                          final advice = advices[index];
                          return _buildAdviceItem(advice);
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建单个建议项
  Widget _buildAdviceItem(advice) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Text(advice.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.content,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
