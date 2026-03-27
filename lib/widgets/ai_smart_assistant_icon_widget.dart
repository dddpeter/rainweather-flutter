import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../constants/app_colors.dart';
import '../models/commute_advice_model.dart';

/// AI智能助手图标组件 - 点击图标显示完整内容对话框
///
/// 特性：
/// 1. 显示为图标按钮
/// 2. 点击弹出对话框显示完整AI内容（天气摘要 + 通勤提醒）
class AISmartAssistantIconWidget extends StatefulWidget {
  final String? cityName;

  const AISmartAssistantIconWidget({super.key, this.cityName});

  @override
  State<AISmartAssistantIconWidget> createState() => _AISmartAssistantIconWidgetState();
}

class _AISmartAssistantIconWidgetState extends State<AISmartAssistantIconWidget> {
  bool _isLoading = false;

  Future<void> _showContentDialog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取天气摘要
      final weatherProvider = context.read<WeatherProvider>();
      String? weatherSummary = weatherProvider.weatherSummary;
      bool isGeneratingSummary = weatherProvider.isGeneratingSummary;

      // 如果没有摘要且不在生成中，尝试生成
      if ((weatherSummary == null || weatherSummary.isEmpty) && !isGeneratingSummary) {
        await weatherProvider.generateWeatherSummary();
        // 等待生成完成
        int attempts = 0;
        while (attempts < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          weatherSummary = weatherProvider.weatherSummary;
          if (weatherSummary != null && weatherSummary.isNotEmpty) {
            break;
          }
          attempts++;
        }
      }

      // 获取通勤建议
      final commuteAdvices = weatherProvider.commuteAdvices;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 显示对话框
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 500,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.screenBackgroundGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI智能助手',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 天气摘要
                          Text(
                            '天气摘要',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            weatherSummary != null && weatherSummary.isNotEmpty
                                ? weatherSummary
                                : '暂无天气摘要',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          // 通勤提醒
                          if (commuteAdvices.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              '通勤提醒',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...commuteAdvices.map((advice) => _buildCommuteAdviceItem(advice)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // 底部关闭按钮
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('关闭'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCommuteAdviceItem(CommuteAdviceModel advice) {
    final levelColor = advice.getLevelColor();
    final levelName = advice.getLevelName();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(advice.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  levelName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  advice.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            advice.content,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.auto_awesome,
        color: AppColors.textSecondary,
        size: 24,
      ),
      onPressed: _isLoading ? null : _showContentDialog,
      tooltip: 'AI智能助手',
    );
  }
}
