import 'package:flutter/material.dart';
import '../widgets/weather_animation_widget.dart';
import '../constants/app_colors.dart';

class ExtremeWeatherTestScreen extends StatefulWidget {
  const ExtremeWeatherTestScreen({super.key});

  @override
  State<ExtremeWeatherTestScreen> createState() =>
      _ExtremeWeatherTestScreenState();
}

class _ExtremeWeatherTestScreenState extends State<ExtremeWeatherTestScreen> {
  final List<Map<String, dynamic>> extremeWeatherTypes = [
    {
      'name': '大雨',
      'description': '密集雨滴 + 水花效果',
      'features': ['80个雨滴', '2.5px线条', '水花溅起', '厚重云朵'],
    },
    {
      'name': '暴雨',
      'description': '极密集雨滴 + 雨帘效果',
      'features': ['120个雨滴', '3.0px线条', '雨帘效果', '大量水花'],
    },
    {
      'name': '大暴雨',
      'description': '极密集雨滴 + 雨帘效果',
      'features': ['120个雨滴', '3.0px线条', '雨帘效果', '大量水花'],
    },
    {
      'name': '特大暴雨',
      'description': '极密集雨滴 + 雨帘效果',
      'features': ['120个雨滴', '3.0px线条', '雨帘效果', '大量水花'],
    },
    {
      'name': '雷阵雨',
      'description': '闪电 + 密集雨滴',
      'features': ['频繁闪电', '100个雨滴', '分支闪电', '撞击水花'],
    },
    {
      'name': '雷阵雨伴有冰雹',
      'description': '闪电 + 雨滴 + 冰雹',
      'features': ['闪电效果', '雨滴', '冰雹颗粒', '混合效果'],
    },
    {
      'name': '中雪',
      'description': '密集雪花 + 积雪效果',
      'features': ['60个雪花', '六角形状', '积雪效果', '轨迹变化'],
    },
    {
      'name': '大雪',
      'description': '密集雪花 + 积雪效果',
      'features': ['60个雪花', '六角形状', '积雪效果', '轨迹变化'],
    },
    {
      'name': '暴雪',
      'description': '密集雪花 + 积雪效果',
      'features': ['60个雪花', '六角形状', '积雪效果', '轨迹变化'],
    },
    {
      'name': '冰雹',
      'description': '冰雹颗粒 + 阴影效果',
      'features': ['50个冰雹', '阴影效果', '轨迹线', '撞击效果'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('极端天气动画测试'),
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: extremeWeatherTypes.map((weather) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: AppColors.cardElevation,
              shadowColor: AppColors.cardShadowColor,
              color: AppColors.materialCardColor,
              shape: AppColors.cardShape,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 天气名称和描述
                    Row(
                      children: [
                        // 大尺寸动画
                        WeatherAnimationWidget(
                          weatherType: weather['name'],
                          size: 80,
                          isPlaying: true,
                        ),
                        const SizedBox(width: 16),
                        // 信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weather['name'],
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                weather['description'],
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 特性列表
                    Text(
                      '动画特性:',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (weather['features'] as List<String>).map((
                        feature,
                      ) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
