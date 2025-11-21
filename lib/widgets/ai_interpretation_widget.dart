import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/ai_service.dart';
import '../models/lunar_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLunarInterpretation();
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

    // 检查缓存：如果是同一天且已有缓存，且不强制刷新，则直接返回
    if (!forceRefresh &&
        _cachedInterpretationDate != null &&
        _lunarInterpretation != null &&
        _cachedInterpretationDate!.year == selectedDate.year &&
        _cachedInterpretationDate!.month == selectedDate.month &&
        _cachedInterpretationDate!.day == selectedDate.day) {
      return;
    }

    setState(() {
      _isLoadingInterpretation = true;
    });

    try {
      final prompt = _aiService.buildLunarYiJiPrompt(
        goodThings: widget.lunarInfo.goodThings.isEmpty
            ? '诸事不宜'
            : widget.lunarInfo.goodThings.join('、'),
        badThings: widget.lunarInfo.badThings.isEmpty
            ? '百无禁忌'
            : widget.lunarInfo.badThings.join('、'),
        lunarDate: widget.lunarInfo.lunarDate,
        isHuangDaoDay: widget.lunarInfo.isHuangDaoDay,
        solarTerm: widget.lunarInfo.solarTerm ?? '无节气',
      );

      final interpretation = await _aiService.generateSmartAdvice(prompt);

      if (mounted) {
        setState(() {
          _lunarInterpretation = interpretation;
          _cachedInterpretationDate = selectedDate; // 保存缓存日期
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
        // AI渐变色：使用常量
        final aiGradient = themeProvider.isLightTheme
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.aiGradientBlueDark.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientBlueMid.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientBlueLight.withOpacity(AppColors.aiGradientOpacity),
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.aiGradientAmberDark.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientAmberMid.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientAmberLight.withOpacity(AppColors.aiGradientOpacity),
                ],
                stops: const [0.0, 0.5, 1.0],
              );
    
        // 文字颜色：使用常量，确保高对比度
        final textColor = themeProvider.isLightTheme
            ? AppColors.aiTextColorLight
            : AppColors.aiTextColorDark;
    
        // 图标颜色：与文字颜色一致
        final iconColor = textColor;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenHorizontalPadding,
            ),
            child: Card(
              elevation: AppColors.cardElevation,
              shadowColor: AppColors.cardShadowColor,
              color: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shape: AppColors.cardShape,
              child: Container(
                decoration: BoxDecoration(
                  gradient: aiGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
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
                          // AI标签：使用白色背景+深色文字，确保高对比度
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                themeProvider.isLightTheme 
                                    ? AppColors.labelWhiteBgOpacityLight 
                                    : AppColors.labelWhiteBgOpacityDark
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: textColor.withOpacity(AppColors.labelBorderOpacity),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: textColor, // 使用高对比度颜色
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: textColor, // 使用高对比度颜色
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
            ),
          ),
        );
      },
    );
  }
}