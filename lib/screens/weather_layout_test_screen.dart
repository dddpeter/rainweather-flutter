import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/weather_animation_widget.dart';

/// 天气布局测试屏幕
/// 用于测试7个字的天气汉字显示效果
class WeatherLayoutTestScreen extends StatelessWidget {
  const WeatherLayoutTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('天气布局测试'),
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTestCard('短天气（2-3字）', '晴'),
            const SizedBox(height: 16),
            _buildTestCard('中等天气（4-5字）', '多云转晴'),
            const SizedBox(height: 16),
            _buildTestCard('长天气（6-7字）', '小雨转中雨'),
            const SizedBox(height: 16),
            _buildTestCard('最长天气（7字）', '雷阵雨转多云'),
            const SizedBox(height: 16),
            _buildTestCard('极端长天气（8字）', '雷阵雨转多云转晴'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(String title, String weatherText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 新的布局结构
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧天气动画区域 - 45%宽度，右对齐
              Flexible(
                flex: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    WeatherAnimationWidget(
                      weatherType: weatherText,
                      size: 120, // 从100增大到120
                      isPlaying: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // 右侧温度和天气汉字区域 - 55%宽度，左对齐
              Flexible(
                flex: 55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '25℃',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherText,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 24, // 从28减小到24
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 显示字符数
          Text(
            '字符数: ${weatherText.length}',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
