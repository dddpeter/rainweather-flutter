import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/weather_animation_widget.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

class WeatherAnimationTestScreen extends StatefulWidget {
  const WeatherAnimationTestScreen({super.key});

  @override
  State<WeatherAnimationTestScreen> createState() =>
      _WeatherAnimationTestScreenState();
}

class _WeatherAnimationTestScreenState
    extends State<WeatherAnimationTestScreen> {
  final List<String> weatherTypes = [
    '晴',
    '多云',
    '晴间多云',
    '多云转晴',
    '晴转多云',
    '少云',
    '阴',
    '小雨',
    '中雨',
    '大雨',
    '暴雨',
    '大暴雨',
    '特大暴雨',
    '阵雨',
    '雷阵雨',
    '雷阵雨伴有冰雹',
    '冻雨',
    '毛毛雨',
    '小雪',
    '中雪',
    '大雪',
    '暴雪',
    '阵雪',
    '雨夹雪',
    '雨雪天气',
    '雾',
    '浓雾',
    '强浓雾',
    '轻雾',
    '霾',
    '中度霾',
    '重度霾',
    '严重霾',
    '浮尘',
    '扬沙',
    '沙尘暴',
    '强沙尘暴',
    '冰雹',
    '雨凇',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('天气动画测试'),
            backgroundColor: AppColors.backgroundPrimary,
            foregroundColor: AppColors.textPrimary,
          ),
          backgroundColor: AppColors.backgroundPrimary,
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: weatherTypes.length,
            itemBuilder: (context, index) {
              final weatherType = weatherTypes[index];
              return Card(
                elevation: AppColors.cardElevation,
                shadowColor: AppColors.cardShadowColor,
                color: themeProvider.getColor('headerBackground'),
                shape: AppColors.cardShape,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 天气动画
                      WeatherAnimationWidget(
                        weatherType: weatherType,
                        size: 70,
                        isPlaying: true,
                      ),
                      const SizedBox(height: 6),
                      // 天气类型名称
                      Text(
                        weatherType,
                        style: TextStyle(
                          color: themeProvider.getColor('headerTextPrimary'),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
