import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ai_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 异常天气预警页面
class ExtremeWeatherAlertScreen extends StatefulWidget {
  const ExtremeWeatherAlertScreen({super.key});

  @override
  State<ExtremeWeatherAlertScreen> createState() =>
      _ExtremeWeatherAlertScreenState();
}

class _ExtremeWeatherAlertScreenState extends State<ExtremeWeatherAlertScreen> {
  String? _alertAdvice;
  bool _isLoading = false;
  String _riskLevel = '正常';
  Color _riskColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _loadExtremeWeatherAlert();
  }

  Future<void> _loadExtremeWeatherAlert() async {
    setState(() {
      _isLoading = true;
    });

    final weatherProvider = context.read<WeatherProvider>();
    final weather = weatherProvider.currentWeather;
    final current = weather?.current?.current;
    final alerts = weather?.current?.alerts;
    final forecast24h = weather?.forecast24h;

    if (current == null) {
      setState(() {
        _alertAdvice = '暂无天气数据，无法生成预警';
        _isLoading = false;
      });
      return;
    }

    try {
      // 获取24小时天气变化
      List<String> hourlyWeather = [];
      if (forecast24h != null && forecast24h.isNotEmpty) {
        hourlyWeather = forecast24h
            .take(6)
            .map((h) => '${h.forecasttime}${h.weather}')
            .toList();
      }

      // 获取官方预警信息
      String? alertsInfo;
      if (alerts != null && alerts.isNotEmpty) {
        alertsInfo = alerts.map((a) => '${a.level}${a.type}').join('、');
      }

      final prompt = AIService().buildExtremeWeatherAlertPrompt(
        currentWeather: current.weather ?? '晴',
        temperature: current.temperature ?? '--',
        windPower: current.windpower ?? '--',
        visibility: current.visibility ?? '--',
        alerts: alertsInfo,
        hourlyWeather: hourlyWeather,
      );

      final advice = await AIService().generateSmartAdvice(prompt);

      if (mounted) {
        // 从AI回复中提取风险等级
        String riskLevel = '正常';
        Color riskColor = const Color(0xFF4CAF50);

        if (advice != null) {
          if (advice.contains('高危')) {
            riskLevel = '高危';
            riskColor = const Color(0xFFD32F2F);
          } else if (advice.contains('中危')) {
            riskLevel = '中危';
            riskColor = const Color(0xFFF57C00);
          } else if (advice.contains('低危')) {
            riskLevel = '低危';
            riskColor = const Color(0xFFFFB300);
          }
        }

        setState(() {
          _alertAdvice = advice ?? '生成预警建议失败，请稍后重试';
          _riskLevel = riskLevel;
          _riskColor = riskColor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alertAdvice = '生成预警建议失败：${e.toString()}';
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
        title: const Text('异常天气预警'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.accentBlue),
                    const SizedBox(height: 16),
                    Text(
                      '正在分析天气异常情况...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 风险等级卡片
                    Card(
                      elevation: AppColors.cardElevation,
                      shadowColor: AppColors.cardShadowColor,
                      color: AppColors.materialCardColor,
                      surfaceTintColor: Colors.transparent,
                      shape: AppColors.cardShape,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _riskColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _riskLevel == '高危'
                                    ? Icons.warning
                                    : _riskLevel == '中危'
                                    ? Icons.error_outline
                                    : _riskLevel == '低危'
                                    ? Icons.info_outline
                                    : Icons.check_circle_outline,
                                color: _riskColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '风险等级',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _riskLevel,
                                    style: TextStyle(
                                      color: _riskColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // AI预警建议卡片
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
                            // 标题栏
                            Row(
                              children: [
                                Icon(
                                  Icons.shield,
                                  color: _riskColor,
                                  size: AppConstants.sectionTitleIconSize,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '安全分析',
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
                            // 内容
                            if (_alertAdvice != null)
                              MarkdownBody(
                                data: _alertAdvice!,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  strong: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h1: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h2: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  listBullet: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
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
                        onPressed: _isLoading ? null : _loadExtremeWeatherAlert,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('重新分析'),
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
