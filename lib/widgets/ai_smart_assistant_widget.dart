import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 增强版AI智能助手组件 - 整合天气摘要和通勤提醒
class AISmartAssistantWidget extends StatefulWidget {
  final String? cityName;

  const AISmartAssistantWidget({super.key, this.cityName});

  @override
  State<AISmartAssistantWidget> createState() => _AISmartAssistantWidgetState();
}

class _AISmartAssistantWidgetState extends State<AISmartAssistantWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.read<WeatherProvider>();

    final advices = weatherProvider.commuteAdvices;
    final hasCommuteAdvices = advices.isNotEmpty;

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
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // 图标
                        Icon(
                          Icons.auto_awesome,
                          color: const Color(0xFFFFB300), // 金琥珀色
                          size: AppConstants.sectionTitleIconSize,
                        ),
                        const SizedBox(width: 8),
                        // 标题
                        Text(
                          'AI智能助手',
                          style: TextStyle(
                            color: Colors.white, // 白色文字
                            fontSize: AppConstants.sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 功能数量标签
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
                            hasCommuteAdvices ? '2项' : '1项',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // 展开/收起图标
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

                const SizedBox(height: 16),

                // 天气摘要（始终显示）
                _buildWeatherSummary(weatherProvider),

                // 通勤提醒（如果有的话）
                if (hasCommuteAdvices) ...[
                  const SizedBox(height: 16),
                  _buildCommuteAdvicesSection(advices, _isExpanded),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建天气摘要
  Widget _buildWeatherSummary(WeatherProvider weatherProvider) {
    final summary = weatherProvider.weatherSummary ?? '正在生成天气摘要...';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // 金琥珀色渐变背景
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB300).withOpacity(0.3), // 金琥珀色
            const Color(0xFFFFB300).withOpacity(0.1), // 浅金琥珀色
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        // 金琥珀色边框
        border: Border.all(
          color: const Color(0xFFFFB300).withOpacity(0.5),
          width: 1,
        ),
        // 金琥珀色阴影
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 摘要标题
          Row(
            children: [
              Icon(Icons.wb_sunny, color: const Color(0xFFFFB300), size: 16),
              const SizedBox(width: 6),
              Text(
                '天气摘要',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 摘要内容
          Text(
            summary,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// 构建通勤提醒部分
  Widget _buildCommuteAdvicesSection(List<dynamic> advices, bool isExpanded) {
    final sortedAdvices = List.from(advices);
    sortedAdvices.sort((a, b) => a.priority.compareTo(b.priority));

    // 收起时只显示第一条，展开时显示所有
    final displayAdvices = isExpanded ? sortedAdvices : [sortedAdvices.first];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 通勤提醒标题
        Row(
          children: [
            Icon(
              Icons.commute_rounded,
              color: const Color(0xFFFFB300),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '通勤提醒',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${advices.length}条',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 通勤建议列表
        ...displayAdvices.map(
          (advice) => _buildCommuteAdviceItem(advice, !isExpanded),
        ),
      ],
    );
  }

  /// 构建单个通勤建议项
  Widget _buildCommuteAdviceItem(dynamic advice, bool isCollapsed) {
    final levelColor = advice.getLevelColor();
    final levelName = advice.getLevelName();
    const aiColor = Color(0xFFFFB300); // 金琥珀色

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // 金琥珀色渐变背景
          gradient: LinearGradient(
            colors: [
              aiColor.withOpacity(0.3), // 金琥珀色
              aiColor.withOpacity(0.1), // 浅金琥珀色
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          // 金琥珀色边框
          border: Border.all(color: aiColor.withOpacity(0.5), width: 1),
          // 金琥珀色阴影
          boxShadow: [
            BoxShadow(
              color: aiColor.withOpacity(0.2),
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
                      // 级别标签
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
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // AI标签
                            if (advice.adviceType == 'ai_smart') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: aiColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: aiColor,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'AI',
                                      style: TextStyle(
                                        color: aiColor,
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
                        color: Colors.white70,
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
