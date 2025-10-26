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

  @override
  Widget build(BuildContext context) {
    // 监听天气数据变化，只在数据真正改变时才触发AI生成
    final weatherProvider = context.read<WeatherProvider>();
    final currentWeather = weatherProvider.currentWeather;

    // 构建唯一key：天气+温度+时间
    final currentDataKey = currentWeather != null
        ? '${currentWeather.current?.current?.weather ?? ''}_'
              '${currentWeather.current?.current?.temperature ?? ''}_'
              '${currentWeather.current?.current?.reporttime ?? ''}'
        : null;

    // 只在天气数据真正改变时才触发AI生成
    if (currentDataKey != null && currentDataKey != _lastWeatherDataKey) {
      _lastWeatherDataKey = currentDataKey;

      // 延时触发，避免和build冲突
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final wp = context.read<WeatherProvider>();
          if (wp.weatherSummary == null || wp.weatherSummary!.isEmpty) {
            print('🚀 AISmartAssistantWidget: 天气数据变化，触发AI摘要生成');
            wp.generateWeatherSummary();
          } else {
            print('🚀 AISmartAssistantWidget: 已有缓存，跳过生成');
          }
        }
      });
    }

    // 使用 Selector 只监听天气摘要相关状态
    return Selector<
      WeatherProvider,
      ({String? weatherSummary, bool isGeneratingSummary})
    >(
      selector: (context, weatherProvider) => (
        weatherSummary: weatherProvider.weatherSummary,
        isGeneratingSummary: weatherProvider.isGeneratingSummary,
      ),
      builder: (context, data, child) {
        final themeProvider = context.read<ThemeProvider>();

        // 调试日志
        print(
          '🔄 AISmartAssistantWidget build: weatherSummary=${data.weatherSummary?.substring(0, 20)}..., isGenerating=${data.isGeneratingSummary}',
        );

        // 使用 context.read 获取通勤建议，避免在 Selector 中监听列表引用变化
        final weatherProvider = context.read<WeatherProvider>();
        final advices = weatherProvider.commuteAdvices;
        final hasCommuteAdvices = advices.isNotEmpty;

        // AI标签颜色：金琥珀色（暗色）/ 蓝色（亮色）
        final aiColor = themeProvider.isLightTheme
            ? const Color(0xFF004CFF)
            : const Color(0xFFFFB300);

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
                  // 标题行
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // 图标（使用主题蓝色）
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.accentBlue,
                          size: AppConstants.sectionTitleIconSize,
                        ),
                        const SizedBox(width: 8),
                        // 标题
                        Text(
                          'AI智能助手',
                          style: TextStyle(
                            color: AppColors.textPrimary,
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
                            color: AppColors.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasCommuteAdvices ? '2项' : '1项',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
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
                            color: aiColor.withOpacity(0.15),
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
        );
      },
    );
  }

  /// 构建天气摘要
  Widget _buildWeatherSummary(
    String? weatherSummary,
    bool isGeneratingSummary,
  ) {
    // 根据生成状态显示不同内容
    String summary;
    if (isGeneratingSummary) {
      summary = '正在生成天气摘要...';
    } else if (weatherSummary != null && weatherSummary.isNotEmpty) {
      summary = weatherSummary;
    } else {
      summary = '天气摘要生成中，请稍候...';
    }

    final themeProvider = context.read<ThemeProvider>();

    // 橙色系背景（天气摘要）
    final backgroundColor = const Color(0xFFFFB74D);
    final iconColor = themeProvider.isLightTheme
        ? const Color(0xFF012d78) // 亮色模式：主题深蓝
        : Colors.white; // 暗色模式：白色
    final textColor = themeProvider.isLightTheme
        ? const Color(0xFF012d78) // 亮色模式：主题深蓝
        : AppColors.textPrimary; // 暗色模式：白色

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        // 浮起效果阴影
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 摘要标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(
                    themeProvider.isLightTheme ? 0.2 : 0.3,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.wb_sunny, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '天气摘要',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 摘要内容
          Row(
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
        ],
      ),
    );
  }

  /// 构建通勤提醒部分
  Widget _buildCommuteAdvicesSection(List<dynamic> advices) {
    final sortedAdvices = List.from(advices);
    sortedAdvices.sort((a, b) => a.priority.compareTo(b.priority));

    // 始终只显示第一条（最重要的）
    final displayAdvice = sortedAdvices.first;
    final themeProvider = context.read<ThemeProvider>();

    // 绿色系背景（通勤提醒）
    final iconColor = themeProvider.isLightTheme
        ? const Color(0xFF012d78) // 亮色模式：主题深蓝
        : Colors.white; // 暗色模式：白色
    final textColor = themeProvider.isLightTheme
        ? const Color(0xFF012d78) // 亮色模式：主题深蓝
        : AppColors.textPrimary; // 暗色模式：白色

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 通勤提醒标题
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(
                  themeProvider.isLightTheme ? 0.2 : 0.3,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.commute_rounded, color: iconColor, size: 16),
            ),
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
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${advices.length}条',
                style: TextStyle(
                  color: AppColors.textSecondary,
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
    final weatherProvider = context.read<WeatherProvider>();
    final alertService = WeatherAlertService.instance;
    final themeProvider = context.read<ThemeProvider>();

    // 绿色系背景（通勤提醒）
    final backgroundColor = const Color(0xFF64DD17);
    final textColor = themeProvider.isLightTheme
        ? const Color(0xFF012d78) // 亮色模式：主题深蓝
        : AppColors.textPrimary; // 暗色模式：白色

    // AI标签颜色
    final aiColor = themeProvider.isLightTheme
        ? const Color(0xFF004CFF)
        : const Color(0xFFFFB300);

    return InkWell(
      onTap: () {
        // 点击打开综合提醒页面
        final currentLocation = weatherProvider.currentLocation;
        final currentCity =
            currentLocation?.district ?? currentLocation?.city ?? '未知';
        // 获取天气提醒（智能提醒）
        final smartAlerts = alertService.getAlertsForCity(
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
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          // 浮起效果阴影
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
                                  color: aiColor.withOpacity(0.15),
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
