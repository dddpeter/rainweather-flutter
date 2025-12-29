import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/ai_service.dart';
import '../models/lunar_model.dart';
import 'base_card.dart';

/// AI解读组件
class AIInterpretationWidget extends StatefulWidget {
  final LunarInfo lunarInfo;
  final DateTime selectedDate;

  const AIInterpretationWidget({
    super.key,
    required this.lunarInfo,
    required this.selectedDate,
  });

  @override
  State<AIInterpretationWidget> createState() => _AIInterpretationWidgetState();
}

class _AIInterpretationWidgetState extends State<AIInterpretationWidget> {
  final AIService _aiService = AIService();
  String? _lunarInterpretation;
  bool _isLoadingInterpretation = false;
  DateTime? _cachedInterpretationDate;
  String? _cachedLunarInfo; // 缓存农历信息，用于判断是否需要重新解读

  @override
  void initState() {
    super.initState();
    // 清除缓存以确保使用新的提示词设置
    _clearCache();
    _loadLunarInterpretation();
  }

  /// 清除缓存
  void _clearCache() {
    _cachedInterpretationDate = null;
    _cachedLunarInfo = null;
    _lunarInterpretation = null;
  }

  /// 去掉Markdown格式符号，保留纯文本
  String _cleanMarkdownText(String text) {
    return text
        .replaceAll('**', '') // 去掉粗体符号
        .replaceAll('*', '') // 去掉剩余的星号
        .replaceAll('###', '') // 去掉H3标题符号
        .replaceAll('##', '') // 去掉H2标题符号
        .replaceAll('#', ''); // 去掉H1标题符号
  }

  /// 加载黄历AI解读（基于选中日期）
  Future<void> _loadLunarInterpretation({bool forceRefresh = false}) async {
    if (_isLoadingInterpretation) return;

    final selectedDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    // 创建当前农历信息的字符串表示，用于缓存比较
    final currentLunarInfo = '${widget.lunarInfo.goodThings.join(',')}|${widget.lunarInfo.badThings.join(',')}|${widget.lunarInfo.lunarDate}|${widget.lunarInfo.isHuangDaoDay}|${widget.lunarInfo.solarTerm ?? ''}';

    // 检查缓存：如果是同一天、农历信息相同且已有缓存，且不强制刷新，则直接返回
    if (!forceRefresh &&
        _cachedInterpretationDate != null &&
        _lunarInterpretation != null &&
        _cachedInterpretationDate!.year == selectedDate.year &&
        _cachedInterpretationDate!.month == selectedDate.month &&
        _cachedInterpretationDate!.day == selectedDate.day &&
        _cachedLunarInfo == currentLunarInfo) {
      return;
    }

    setState(() {
      _isLoadingInterpretation = true;
    });

    try {
      final prompt = '''请根据以下农历信息，提供一份简洁、实用且符合现代汉语习惯的黄历解读：

日期信息：
- 公历：${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日
- 农历：${widget.lunarInfo.lunarDate}
- 干支：${widget.lunarInfo.yearGanZhi}年 ${widget.lunarInfo.monthGanZhi}月 ${widget.lunarInfo.dayGanZhi}日
- 星宿：${widget.lunarInfo.starName}（${widget.lunarInfo.starLuck}）
${widget.lunarInfo.solarTerm != null ? '- 节气：${widget.lunarInfo.solarTerm}' : ''}

宜忌事项：
${widget.lunarInfo.goodThings.isEmpty ? '- 宜：诸事不宜' : '- 宜：${widget.lunarInfo.goodThings.join('、')}'}
${widget.lunarInfo.badThings.isEmpty ? '- 忌：百无禁忌' : '- 忌：${widget.lunarInfo.badThings.join('、')}'}
${widget.lunarInfo.isHuangDaoDay ? '- 特殊：今日为黄道吉日，诸事大吉' : ''}

请提供：
1. 整体运势分析（180-270字）
2. 今日重点关注和提醒（100-135字）
3. 适合的活动建议（100-135字）
4. 需要注意的事项（100-135字）

要求：
- 使用现代、自然的汉语表达，避免过于古板或传统的说法
- 内容要简洁实用，贴近现代生活
- 语言要温暖积极，给人以正能量
- 如果是黄道吉日，要特别强调吉祥寓意

特别要求：
- 行事建议要更符合现代汉语习惯，使用现代人常用的表达方式
- 避免过于传统的说法，改用更自然的现代表达
- 建议要具体实用，贴近当代人的实际生活
- 特别提示要温暖亲切，符合现代人的语言习惯
''';

      final interpretation = await _aiService.generateSmartAdvice(prompt);

      if (mounted) {
        setState(() {
          _lunarInterpretation = interpretation;
          _cachedInterpretationDate = selectedDate; // 保存缓存日期
          _cachedLunarInfo = currentLunarInfo; // 保存缓存农历信息
          _isLoadingInterpretation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInterpretation = false;
        });
      }
    }
  }

  /// 获取日期标签
  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    
    if (selected == today) {
      return '今日';
    } else if (selected == today.add(const Duration(days: 1))) {
      return '明日';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return '昨日';
    } else {
      return '${widget.selectedDate.month}月${widget.selectedDate.day}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isLight = themeProvider.isLightTheme;

        // 文字颜色：使用优化的AI配色方案
        final textColor = AIColorScheme.getAITextColor(isLight);

        // 图标颜色：与文字颜色一致
        final iconColor = textColor;

        // AI标签颜色
        final aiLabelColor = AIColorScheme.getAILabelColor(isLight);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenHorizontalPadding,
            ),
            child: AICard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      // 标题栏
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: iconColor,
                            size: AppConstants.sectionTitleIconSize,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_getDateLabel()}黄历解读',
                            style: TextStyle(
                              color: textColor,
                              fontSize: AppConstants.sectionTitleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // AI标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                isLight
                                    ? AppColors.labelWhiteBgOpacityLight
                                    : AppColors.labelWhiteBgOpacityDark
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: aiLabelColor.withOpacity(AIColorScheme.labelBorderOpacity),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: aiLabelColor,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: aiLabelColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // AI解读内容
                      if (_isLoadingInterpretation)
                        Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: textColor),
                              const SizedBox(height: 12),
                              Text(
                                '正在生成黄历解读...',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_lunarInterpretation != null)
                        Text(
                          _cleanMarkdownText(_lunarInterpretation!),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            '暂无解读内容',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                            ),
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
}