import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ai_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/typewriter_text_widget.dart';

/// 健康管家页面
class HealthAdvisorScreen extends StatefulWidget {
  const HealthAdvisorScreen({super.key});

  @override
  State<HealthAdvisorScreen> createState() => _HealthAdvisorScreenState();
}

class _HealthAdvisorScreenState extends State<HealthAdvisorScreen> {
  String _selectedGroup = 'general';
  String? _healthAdvice;
  bool _isLoading = false;

  /// 去掉Markdown格式符号，保留纯文本
  String _cleanMarkdownText(String text) {
    return text
        .replaceAll('**', '') // 去掉粗体符号
        .replaceAll('*', '') // 去掉剩余的星号
        .replaceAll('###', '') // 去掉H3标题符号
        .replaceAll('##', '') // 去掉H2标题符号
        .replaceAll('#', ''); // 去掉H1标题符号
  }

  final Map<String, Map<String, dynamic>> _userGroups = {
    'general': {
      'label': '一般人群',
      'icon': Icons.person,
      'color': Color(0xFF4CAF50),
    },
    'elderly': {
      'label': '老年人',
      'icon': Icons.elderly,
      'color': Color(0xFFFF9800),
    },
    'children': {
      'label': '儿童',
      'icon': Icons.child_care,
      'color': Color(0xFF2196F3),
    },
    'allergy': {
      'label': '过敏体质',
      'icon': Icons.healing,
      'color': Color(0xFFE91E63),
    },
  };

  @override
  void initState() {
    super.initState();
    _loadHealthAdvice();
  }

  Future<void> _loadHealthAdvice() async {
    setState(() {
      _isLoading = true;
    });

    final weatherProvider = context.read<WeatherProvider>();
    final weather = weatherProvider.currentWeather;
    final current = weather?.current?.current;
    final air = weather?.current?.air;

    if (current == null) {
      setState(() {
        _healthAdvice = '暂无天气数据，无法生成健康建议';
        _isLoading = false;
      });
      return;
    }

    try {
      final prompt = AIService().buildHealthAdvisorPrompt(
        currentWeather: current.weather ?? '晴',
        temperature: current.temperature ?? '--',
        feelsLike: current.feelstemperature ?? '--',
        aqi: air?.AQI ?? '--',
        aqiLevel: air?.levelIndex ?? '未知',
        humidity: current.humidity ?? '--',
        windPower: current.windpower ?? '--',
        userGroup: _selectedGroup,
      );

      final advice = await AIService().generateSmartAdvice(prompt);

      if (mounted) {
        setState(() {
          _healthAdvice = advice ?? '生成健康建议失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _healthAdvice = '生成健康建议失败：${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    AppColors.setThemeProvider(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('健康管家'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 人群选择卡片
              Card(
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
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: AppColors.accentBlue,
                            size: AppConstants.sectionTitleIconSize,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '选择人群',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: AppConstants.sectionTitleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 人群选择按钮
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _userGroups.entries.map((entry) {
                          final isSelected = _selectedGroup == entry.key;
                          final groupColor = entry.value['color'] as Color;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGroup = entry.key;
                              });
                              _loadHealthAdvice();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? groupColor.withOpacity(0.15)
                                    : AppColors.backgroundSecondary.withOpacity(
                                        0.3,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? groupColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    entry.value['icon'] as IconData,
                                    color: isSelected
                                        ? groupColor
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.value['label'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? groupColor
                                          : AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // AI健康建议卡片
              _isLoading
                  ? Card(
                      elevation: AppColors.cardElevation,
                      shadowColor: AppColors.cardShadowColor,
                      color: AppColors.materialCardColor,
                      surfaceTintColor: Colors.transparent,
                      shape: AppColors.cardShape,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.accentBlue,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '正在为您生成专属健康建议...',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Card(
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
                            // 标题栏
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: const Color(0xFFE91E63),
                                  size: AppConstants.sectionTitleIconSize,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '健康建议',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
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
                            // 内容（打字机效果，去掉Markdown符号）
                            if (_healthAdvice != null)
                              TypewriterTextWidget(
                                text: _cleanMarkdownText(_healthAdvice!),
                                charDelay: const Duration(milliseconds: 30),
                                lineDelay: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600, // AI内容加粗
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              // 重新生成按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadHealthAdvice,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('重新生成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
