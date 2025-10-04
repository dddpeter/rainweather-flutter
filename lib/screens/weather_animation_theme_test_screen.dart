import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../widgets/weather_animation_widget.dart';
import '../providers/theme_provider.dart';

/// 天气动画主题测试屏幕
class WeatherAnimationThemeTestScreen extends StatefulWidget {
  const WeatherAnimationThemeTestScreen({super.key});

  @override
  State<WeatherAnimationThemeTestScreen> createState() =>
      _WeatherAnimationThemeTestScreenState();
}

class _WeatherAnimationThemeTestScreenState
    extends State<WeatherAnimationThemeTestScreen> {
  final List<String> _weatherTypes = [
    '晴',
    '多云',
    '晴间多云',
    '多云转晴',
    '晴转多云',
    '少云',
    '小雨',
    '中雨',
    '大雪',
    '暴雪',
    '小雪',
    '中雪',
    '雷阵雨',
    '雾',
    '霾',
    '阴',
    '沙尘暴',
  ];

  int _currentWeatherIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('天气动画主题测试'),
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              final themeProvider = context.read<ThemeProvider>();
              final newMode = themeProvider.isLightTheme
                  ? AppThemeMode.dark
                  : AppThemeMode.light;
              themeProvider.setThemeMode(newMode);
            },
            icon: Icon(
              context.watch<ThemeProvider>().isLightTheme
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: '切换主题',
          ),
        ],
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主题信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        themeProvider.isLightTheme
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '当前主题: ${themeProvider.isLightTheme ? "亮色" : "暗色"}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 天气类型选择
                Text(
                  '天气类型: ${_weatherTypes[_currentWeatherIndex]}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // 天气动画展示
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: WeatherAnimationWidget(
                      weatherType: _weatherTypes[_currentWeatherIndex],
                      size: 150,
                      isPlaying: true,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 切换按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentWeatherIndex =
                              (_currentWeatherIndex -
                                  1 +
                                  _weatherTypes.length) %
                              _weatherTypes.length;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('上一个'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentWeatherIndex =
                              (_currentWeatherIndex + 1) % _weatherTypes.length;
                        });
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('下一个'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 说明文字
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主题适配说明',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 亮色主题：使用深色动画元素，确保在浅色背景上清晰可见\n'
                        '• 暗色主题：使用浅色动画元素，确保在深色背景上清晰可见\n'
                        '• 切换主题时，动画颜色会自动调整\n'
                        '• 修复了雪类天气在亮色主题下的可见性问题\n'
                        '• 修复了雾、霾、阴天的主题适配问题\n'
                        '• 修复了雾霾动画中粒子和线条的亮色主题可见性\n'
                        '• 优化了亮色主题下的蓝色系颜色深度\n'
                        '• 所有动画的云朵都使用天蓝色系（亮色主题）\n'
                        '• 雷阵雨、冻雨、冰雹等极端天气云朵也使用天蓝色\n'
                        '• 阴天使用矢车菊蓝云朵颜色，体现阴沉感\n'
                        '• 暗色主题保持原有的浅蓝色云朵\n'
                        '• 所有天气类型都支持主题适配',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
