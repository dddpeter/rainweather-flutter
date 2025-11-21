import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ai_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 智能穿搭顾问页面
class OutfitAdvisorScreen extends StatefulWidget {
  const OutfitAdvisorScreen({super.key});

  @override
  State<OutfitAdvisorScreen> createState() => _OutfitAdvisorScreenState();
}

class _OutfitAdvisorScreenState extends State<OutfitAdvisorScreen> {
  String? _outfitAdvice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOutfitAdvice();
  }

  Future<void> _loadOutfitAdvice() async {
    setState(() {
      _isLoading = true;
    });

    final weatherProvider = context.read<WeatherProvider>();
    final weather = weatherProvider.currentWeather;
    final current = weather?.current?.current;
    final forecast24h = weather?.forecast24h;
    final forecast15d = weather?.forecast15d;

    if (current == null) {
      setState(() {
        _outfitAdvice = '暂无天气数据，无法生成穿搭建议';
        _isLoading = false;
      });
      return;
    }

    try {
      // 获取24小时天气变化
      List<String> hourlyWeather = [];
      if (forecast24h != null && forecast24h.isNotEmpty) {
        hourlyWeather = forecast24h
            .take(8)
            .map((h) => '${h.forecasttime}${h.weather}${h.temperature}')
            .toList();
      }

      // 获取今日温度范围
      String? minTemp;
      String? maxTemp;
      if (forecast15d != null && forecast15d.isNotEmpty) {
        final today = forecast15d.firstWhere(
          (d) => _isToday(d.forecasttime ?? ''),
          orElse: () => forecast15d[0],
        );
        minTemp = today.temperature_pm;
        maxTemp = today.temperature_am;
      }

      final prompt = AIService().buildOutfitAdvisorPrompt(
        currentWeather: current.weather ?? '晴',
        temperature: current.temperature ?? '--',
        feelsLike: current.feelstemperature ?? '--',
        windPower: current.windpower ?? '--',
        humidity: current.humidity ?? '--',
        hourlyWeather: hourlyWeather,
        minTemp: minTemp,
        maxTemp: maxTemp,
      );

      final advice = await AIService().generateSmartAdvice(prompt);

      if (mounted) {
        setState(() {
          _outfitAdvice = advice ?? '生成穿搭建议失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _outfitAdvice = '生成穿搭建议失败：${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  bool _isToday(String forecastTime) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (forecastTime.contains('-')) {
        final parts = forecastTime.split(' ')[0].split('-');
        if (parts.length == 3) {
          final forecastDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          return forecastDate.year == today.year &&
              forecastDate.month == today.month &&
              forecastDate.day == today.day;
        }
      } else if (forecastTime.contains('/')) {
        final parts = forecastTime.split(' ')[0].split('/');
        if (parts.length == 2) {
          final forecastDate = DateTime(
            now.year,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
          return forecastDate.year == today.year &&
              forecastDate.month == today.month &&
              forecastDate.day == today.day;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        AppColors.setThemeProvider(themeProvider);

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.screenBackgroundGradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 4,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  // 半透明背景 - 基于主题色，已包含透明度
                  color: AppColors.appBarBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(
                  height: 0.5,
                  color: themeProvider.getColor('border').withOpacity(0.2),
                ),
              ),
              foregroundColor: themeProvider.isLightTheme
                  ? AppColors.primaryBlue
                  : AppColors.accentBlue,
              title: Text(
                '智能穿搭顾问',
                style: TextStyle(
                  color: themeProvider.isLightTheme
                      ? AppColors.primaryBlue
                      : AppColors.accentBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: themeProvider.isLightTheme
                      ? AppColors.primaryBlue
                      : AppColors.accentBlue,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.accentBlue),
                        const SizedBox(height: 16),
                        Text(
                          '正在为您生成专属穿搭建议...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // AI穿搭建议卡片
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
                                  Icons.checkroom,
                                  color: const Color(0xFFFFB300),
                                  size: AppConstants.sectionTitleIconSize,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '今日穿搭建议',
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
                            if (_outfitAdvice != null)
                              MarkdownBody(
                                data: _outfitAdvice!,
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
                                  onPressed: _loadOutfitAdvice,
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
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
