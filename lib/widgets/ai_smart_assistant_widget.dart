import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/weather_alert_service.dart';
import '../models/commute_advice_model.dart';
import 'weather_alert_widget.dart';
import 'typewriter_text_widget.dart';

/// 增强版AI智能助手组件 - 整合天气摘要和通勤提醒
class AISmartAssistantWidget extends StatefulWidget {
  final String? cityName;

  const AISmartAssistantWidget({super.key, this.cityName});

  @override
  State<AISmartAssistantWidget> createState() => _AISmartAssistantWidgetState();
}

class _AISmartAssistantWidgetState extends State<AISmartAssistantWidget> {
  String? _lastWeatherDataKey; // 记录上次的天气数据key
  bool _hasTriggeredGeneration = false; // 标记是否已触发过生成

  @override
  void dispose() {
    _hasTriggeredGeneration = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Selector 只监听天气摘要相关状态
    return Selector<
      WeatherProvider,
      ({String? weatherSummary, bool isGeneratingSummary, String? weatherKey})
    >(
      selector: (context, weatherProvider) {
        final currentWeather = weatherProvider.currentWeather;
        // 构建唯一key：天气+温度+时间
        final currentDataKey = currentWeather != null
            ? '${currentWeather.current?.current?.weather ?? ''}_'
                  '${currentWeather.current?.current?.temperature ?? ''}_'
                  '${currentWeather.current?.current?.reporttime ?? ''}'
            : null;

        return (
          weatherSummary: weatherProvider.weatherSummary,
          isGeneratingSummary: weatherProvider.isGeneratingSummary,
          weatherKey: currentDataKey,
        );
      },
      builder: (context, data, child) {
        // 只在天气数据真正改变时才触发AI生成
        if (data.weatherKey != null && data.weatherKey != _lastWeatherDataKey) {
          _lastWeatherDataKey = data.weatherKey;
          _hasTriggeredGeneration = false; // 重置触发标记
        }

        // 只触发一次生成
        if (data.weatherKey != null &&
            !_hasTriggeredGeneration &&
            (data.weatherSummary == null || data.weatherSummary!.isEmpty) &&
            !data.isGeneratingSummary) {
          _hasTriggeredGeneration = true;

          // 延时触发，避免在build过程中修改状态
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                final wp = context.read<WeatherProvider>();
                print('🚀 AISmartAssistantWidget: 天气数据变化，触发AI摘要生成');
                wp.generateWeatherSummary();
              } catch (e) {
                print('❌ AISmartAssistantWidget: 触发AI生成失败 - $e');
              }
            }
          });
        }
        final themeProvider = context.read<ThemeProvider>();

        // 调试日志
        print(
          '🔄 AISmartAssistantWidget build: weatherSummary=${data.weatherSummary != null && data.weatherSummary!.isNotEmpty ? data.weatherSummary!.substring(0, data.weatherSummary!.length > 20 ? 20 : data.weatherSummary!.length) : 'null'}..., isGenerating=${data.isGeneratingSummary}',
        );

        // 使用 context.read 获取通勤建议，避免在 Selector 中监听列表引用变化
        final weatherProvider = context.read<WeatherProvider>();
        final advices = weatherProvider.commuteAdvices;
        final hasCommuteAdvices = advices.isNotEmpty;

        // AI渐变色：使用常量
        final aiGradient = themeProvider.isLightTheme
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.aiGradientLightDark.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientLightMid.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientLightLight.withOpacity(AppColors.aiGradientOpacity),
                ],
                stops: const [0.0, 0.5, 1.0], // 渐变停止点，让渐变更平滑明显
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.aiGradientDarkDark.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientDarkMid.withOpacity(AppColors.aiGradientOpacity),
                  AppColors.aiGradientDarkLight.withOpacity(AppColors.aiGradientOpacity),
                ],
                stops: const [0.0, 0.5, 1.0], // 渐变停止点，让渐变更平滑明显
              );
        
        // 文字颜色：使用常量，确保高对比度
        final textColor = themeProvider.isLightTheme
            ? AppColors.aiTextColorLight
            : AppColors.aiTextColorDark;
        
        // 图标颜色：与文字颜色一致
        final iconColor = textColor;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenHorizontalPadding,
          ),
          child: Card(
            elevation: AppColors.cardElevation,
            shadowColor: AppColors.cardShadowColor,
            color: Colors.transparent, // 使用透明，让渐变背景显示
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
                    // 标题行
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          // 图标（使用高对比度颜色）
                          Icon(
                            Icons.auto_awesome,
                            color: iconColor, // 使用高对比度图标颜色
                            size: AppConstants.sectionTitleIconSize,
                          ),
                          const SizedBox(width: 8),
                          // 标题
                          Text(
                            'AI智能助手',
                            style: TextStyle(
                              color: textColor, // 使用高对比度文字颜色
                              fontSize: AppConstants.sectionTitleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 功能数量标签：使用白色背景+深色文字，确保高对比度
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                themeProvider.isLightTheme 
                                    ? AppColors.labelWhiteBgOpacityLight 
                                    : AppColors.labelWhiteBgOpacityDark
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: textColor.withOpacity(AppColors.labelBorderOpacity),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              hasCommuteAdvices ? '2项' : '1项',
                              style: TextStyle(
                                color: textColor, // 使用高对比度文字颜色
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
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
                    ),

                    const SizedBox(height: 16),

                    // 天气摘要（始终显示）
                    _buildWeatherSummary(
                      data.weatherSummary,
                      data.isGeneratingSummary,
                    ),

                    // 通勤提醒（如果有的话）
                    if (hasCommuteAdvices) ...[
                      const SizedBox(height: 16),
                      // 使用 Selector 来精确监听通勤建议的变化
                      Selector<WeatherProvider, List<CommuteAdviceModel>>(
                        selector: (context, weatherProvider) =>
                            weatherProvider.commuteAdvices,
                        builder: (context, commuteAdvices, child) {
                          return _buildCommuteAdvicesSection(commuteAdvices);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建天气摘要
  Widget _buildWeatherSummary(
    String? weatherSummary,
    bool isGeneratingSummary,
  ) {
    // 根据生成状态显示不同内容，确保总有默认值
    String summary;
    try {
      if (isGeneratingSummary) {
        summary = '正在生成天气摘要...';
      } else if (weatherSummary != null && weatherSummary.isNotEmpty) {
        summary = weatherSummary;
      } else {
        summary = '天气摘要生成中，请稍候...';
      }
    } catch (e) {
      print('❌ _buildWeatherSummary: 处理摘要文本失败 - $e');
      summary = '天气摘要加载中...';
    }

    ThemeProvider? themeProvider;
    try {
      themeProvider = context.read<ThemeProvider>();
    } catch (e) {
      print('❌ _buildWeatherSummary: 获取ThemeProvider失败 - $e');
    }

    // 使用默认值防止null
    final isLightTheme = themeProvider?.isLightTheme ?? true;

    // 文字颜色：使用常量，确保在AI渐变背景上清晰可见
    final textColor = isLightTheme
        ? AppColors.aiTextColorLight
        : AppColors.aiTextColorDark;

    return Container(
      // 只保留左右padding，去掉上下padding
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // 去掉背景色和阴影，直接显示在AI渐变背景上
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 加载指示器（仅在生成时显示）
          if (isGeneratingSummary) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // 摘要文本（打字机效果）
          Expanded(
            child: TypewriterTextWidget(
              text: summary,
              charDelay: const Duration(milliseconds: 30),
              lineDelay: const Duration(milliseconds: 200),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600, // AI内容加粗
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建通勤提醒部分
  Widget _buildCommuteAdvicesSection(List<dynamic> advices) {
    // 安全检查：如果列表为空，返回空容器
    if (advices.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedAdvices = List.from(advices);
    sortedAdvices.sort((a, b) => a.priority.compareTo(b.priority));

    // 始终只显示第一条（最重要的）
    final displayAdvice = sortedAdvices.first;

    ThemeProvider? themeProvider;
    try {
      themeProvider = context.read<ThemeProvider>();
    } catch (e) {
      print('❌ _buildCommuteAdvicesSection: 获取ThemeProvider失败 - $e');
    }

    final isLightTheme = themeProvider?.isLightTheme ?? true;

    // 文字颜色：使用常量，确保在AI渐变背景上清晰可见
    final iconColor = isLightTheme
        ? AppColors.aiTextColorLight
        : AppColors.aiTextColorDark;
    final textColor = isLightTheme
        ? AppColors.aiTextColorLight
        : AppColors.aiTextColorDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 通勤提醒标题
        Row(
          children: [
            Icon(Icons.commute_rounded, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(
              '通勤提醒',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  isLightTheme 
                      ? AppColors.labelWhiteBgOpacityLight 
                      : AppColors.labelWhiteBgOpacityDark
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: textColor.withOpacity(AppColors.labelBorderOpacity),
                  width: 1,
                ),
              ),
              child: Text(
                '${advices.length}条',
                style: TextStyle(
                  color: textColor, // 使用高对比度文字颜色
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 通勤建议（只显示第一条，显示4行：标题1行+内容3行）
        _buildCommuteAdviceItem(displayAdvice, advices),
      ],
    );
  }

  /// 构建单个通勤建议项
  /// [advice] 当前显示的建议对象
  /// [allAdvices] 所有建议列表（用于跳转页面）
  Widget _buildCommuteAdviceItem(dynamic advice, List<dynamic> allAdvices) {
    final levelColor = advice.getLevelColor();
    final levelName = advice.getLevelName();

    WeatherProvider? weatherProvider;
    WeatherAlertService? alertService;
    ThemeProvider? themeProvider;

    try {
      weatherProvider = context.read<WeatherProvider>();
      alertService = WeatherAlertService.instance;
      themeProvider = context.read<ThemeProvider>();
    } catch (e) {
      print('❌ _buildCommuteAdviceItem: 获取Provider失败 - $e');
    }

    final isLightTheme = themeProvider?.isLightTheme ?? true;

    // 文字颜色：使用高对比度颜色，确保在AI渐变背景上清晰可见
    final textColor = isLightTheme
        ? AppColors.aiTextColorLight // 亮色模式：使用 AppColors 常量
        : AppColors.aiTextColorDark; // 暗色模式：使用 AppColors 常量

    // AI标签颜色
    final aiColor = isLightTheme
        ? AppColors.aiLabelColorLight
        : AppColors.aiLabelColorDark;

    return InkWell(
      onTap: weatherProvider != null && alertService != null
          ? () {
              try {
                // 点击打开综合提醒页面
                final currentLocation = weatherProvider!.currentLocation;
                final currentCity =
                    currentLocation?.district ?? currentLocation?.city ?? '未知';
                // 获取天气提醒（智能提醒）
                final smartAlerts = alertService!.getAlertsForCity(
                  currentCity,
                  currentLocation,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherAlertDetailScreen(
                      alerts: smartAlerts,
                      commuteAdvices: allAdvices.cast(),
                    ),
                  ),
                );
              } catch (e) {
                print('❌ _buildCommuteAdviceItem: 打开提醒页面失败 - $e');
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // 通勤提醒背景色：与AI大卡片协调，不使用黄色系
          // 亮色模式：使用柔和的青色（与蓝色渐变协调）
          // 暗色模式：使用柔和的绿色（与金琥珀色渐变协调，非黄色系）
          color: isLightTheme
              ? AppColors.commuteCardBgLight.withOpacity(AppColors.commuteCardBgOpacity)
              : AppColors.commuteCardBgDark.withOpacity(AppColors.commuteCardBgOpacity),
          borderRadius: BorderRadius.circular(12),
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
                                  color: textColor,
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
                                  color: aiColor.withOpacity(AppColors.aiLabelBgOpacity),
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
                  // 始终显示内容（打字机效果）
                  const SizedBox(height: 8),
                  TypewriterTextWidget(
                    text: advice.content,
                    charDelay: const Duration(milliseconds: 30),
                    lineDelay: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600, // AI内容加粗
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
