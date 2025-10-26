import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';
import 'extreme_weather_painters.dart';
import 'freezing_rain_painter.dart';
import 'night_weather_painters.dart';
import '../utils/weather_animation_colors.dart';
import '../providers/theme_provider.dart';

class WeatherAnimationWidget extends StatefulWidget {
  final String weatherType;
  final double size;
  final bool isPlaying;

  const WeatherAnimationWidget({
    super.key,
    required this.weatherType,
    this.size = 200.0,
    this.isPlaying = true,
  });

  @override
  State<WeatherAnimationWidget> createState() => _WeatherAnimationWidgetState();
}

class _WeatherAnimationWidgetState extends State<WeatherAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _cloudController;

  late Animation<double> _mainAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _cloudAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // 主动画控制器
    _mainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // 粒子动画控制器
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 云朵动画控制器
    _cloudController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _mainAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _cloudAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cloudController, curve: Curves.linear));

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _mainController.repeat(reverse: true);
    _particleController.repeat();
    _cloudController.repeat();
  }

  @override
  void didUpdateWidget(WeatherAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _mainController.stop();
        _particleController.stop();
        _cloudController.stop();
      }
    }
  }

  @override
  void dispose() {
    print('🔄 WeatherAnimationWidget dispose called');
    _mainController.dispose();
    _particleController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听主题变化
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 更新天气动画颜色工具类的主题提供者
        WeatherAnimationColors.setThemeProvider(themeProvider);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildWeatherAnimation(),
        );
      },
    );
  }

  /// 判断当前是否为夜晚（18:00-6:00）
  bool get _isNighttime {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  Widget _buildWeatherAnimation() {
    // 根据天气类型和时间选择动画
    switch (widget.weatherType) {
      case '晴':
        return _isNighttime
            ? _buildClearNightAnimation()
            : _buildSunnyAnimation();
      case '多云':
        return _isNighttime
            ? _buildCloudyNightAnimation()
            : _buildCloudyAnimation();
      case '晴间多云':
      case '多云转晴':
      case '晴转多云':
        return _isNighttime
            ? _buildPartlyCloudyNightAnimation()
            : _buildPartlyCloudyAnimation();
      case '少云':
        return _isNighttime
            ? _buildFewCloudsNightAnimation()
            : _buildFewCloudsAnimation();
      case '阴':
        return _buildOvercastAnimation();
      case '毛毛雨':
        return _buildDrizzleAnimation();
      case '小雨':
        return _buildLightRainAnimation();
      case '阵雨':
        return _buildShowerRainAnimation();
      case '中雨':
        return _buildMediumRainAnimation();
      case '大雨':
        return _buildHeavyRainAnimation(60);
      case '暴雨':
        return _buildHeavyRainAnimation(120);
      case '大暴雨':
        return _buildHeavyRainAnimation(200);
      case '特大暴雨':
        return _buildExtremeHeavyRainAnimation();
      case '雷阵雨':
        return _buildThunderstormAnimation();
      case '雷阵雨伴有冰雹':
        return _buildThunderstormWithHailAnimation();
      case '小雪':
        return _buildLightSnowAnimation();
      case '阵雪':
        return _buildShowerSnowAnimation();
      case '中雪':
        return _buildMediumSnowAnimation();
      case '大雪':
        return _buildHeavySnowAnimation();
      case '暴雪':
        return _buildBlizzardAnimation();
      case '雨夹雪':
      case '雨雪天气':
        return _buildSleetAnimation();
      case '冻雨':
        return _buildFreezingRainAnimation();
      case '轻雾':
        return _buildFogAnimation(0.3);
      case '雾':
        return _buildFogAnimation(0.5);
      case '浓雾':
        return _buildFogAnimation(0.7);
      case '强浓雾':
        return _buildFogAnimation(0.9);
      case '霾':
        return _buildHazeAnimation(20);
      case '中度霾':
        return _buildHazeAnimation(35);
      case '重度霾':
        return _buildHazeAnimation(50);
      case '严重霾':
        return _buildHazeAnimation(70);
      case '浮尘':
        return _buildFloatingDustAnimation();
      case '扬沙':
        return _buildBlowingSandAnimation();
      case '沙尘暴':
        return _buildDustStormAnimation();
      case '强沙尘暴':
        return _buildSevereDustStormAnimation();
      case '冰雹':
        return _buildHailAnimation();
      case '雨凇':
        return _buildRainGlazeAnimation();
      case '雪':
        return _buildSnowAnimation();
      case '平静':
        return _buildSunnyAnimation();
      default:
        return _buildSunnyAnimation();
    }
  }

  // 晴天动画
  Widget _buildSunnyAnimation() {
    return AnimatedBuilder(
      animation: _mainAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: SunnyPainter(_mainAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 多云动画
  Widget _buildCloudyAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _cloudAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: CloudyPainter(_mainAnimation.value, _cloudAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 少云动画
  Widget _buildPartlyCloudyAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _cloudAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: PartlyCloudyPainter(
            _mainAnimation.value,
            _cloudAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 少云动画
  Widget _buildFewCloudsAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _cloudAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: FewCloudsPainter(
            _mainAnimation.value,
            _cloudAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 阴天动画
  Widget _buildOvercastAnimation() {
    return AnimatedBuilder(
      animation: _cloudAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: OvercastPainter(_cloudAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // ==================== 夜间动画 ====================

  // 晴朗夜空动画（月亮+星星）
  Widget _buildClearNightAnimation() {
    return AnimatedBuilder(
      animation: _mainAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: MoonPainter(_mainAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 多云夜空动画（月亮+云）
  Widget _buildCloudyNightAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _cloudAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: CloudyNightPainter(
            _mainAnimation.value,
            _cloudAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 少云夜空动画（月亮+少量云）
  Widget _buildPartlyCloudyNightAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _cloudAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: PartlyCloudyNightPainter(
            _mainAnimation.value,
            _cloudAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 很少云夜空动画（月亮+一小朵云）
  Widget _buildFewCloudsNightAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _cloudAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: FewCloudsNightPainter(
            _mainAnimation.value,
            _cloudAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 毛毛雨动画 - 最轻的雨
  Widget _buildDrizzleAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: DrizzlePainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 小雨动画
  Widget _buildLightRainAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: RainPainter(_mainAnimation.value, _particleAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 阵雨动画
  Widget _buildShowerRainAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ShowerRainPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 中雨动画
  Widget _buildMediumRainAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: MediumRainPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 暴风雨动画
  // Widget _buildStormAnimation() {
  //   return AnimatedBuilder(
  //     animation: Listenable.merge([_mainAnimation, _particleController]),
  //     builder: (context, child) {
  //       return CustomPaint(
  //         painter: StormPainter(_mainAnimation.value, _particleAnimation.value),
  //         size: Size(widget.size, widget.size),
  //       );
  //     },
  //   );
  // }

  // 雪天动画
  // 小雪动画
  Widget _buildLightSnowAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: LightSnowPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 阵雪动画
  Widget _buildShowerSnowAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ShowerSnowPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  Widget _buildSnowAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: SnowPainter(_mainAnimation.value, _particleAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 中雪动画
  Widget _buildMediumSnowAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: MediumSnowPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 雨夹雪动画
  Widget _buildSleetAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: SleetPainter(_mainAnimation.value, _particleAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 雾天动画
  Widget _buildFogAnimation(double intensity) {
    return AnimatedBuilder(
      animation: _mainAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: FogPainter(_mainAnimation.value, intensity),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 霾动画 - 黄色，粒子数量表示强度
  Widget _buildHazeAnimation(int particleCount) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: HazePainter(
            _mainAnimation.value,
            _particleAnimation.value,
            particleCount,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 浮尘动画 - 粒子少、小、无漩涡
  Widget _buildFloatingDustAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: FloatingDustPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 扬沙动画 - 粒子小、少、1个漩涡
  Widget _buildBlowingSandAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: BlowingSandPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 沙尘暴动画 - 粒子少、2个漩涡
  Widget _buildDustStormAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: DustStormPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 强沙尘暴动画 - 粒子多、大、3个漩涡
  Widget _buildSevereDustStormAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: SevereDustStormPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 冻雨动画
  Widget _buildFreezingRainAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: FreezingRainPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 冰雹动画
  Widget _buildHailAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: HailPainter(_mainAnimation.value, _particleAnimation.value),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 雨凇动画
  Widget _buildRainGlazeAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: RainGlazePainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 大雨动画
  Widget _buildHeavyRainAnimation([int particleCount = 50]) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: HeavyRainPainter(
            _mainAnimation.value,
            _particleAnimation.value,
            particleCount,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 特大暴雨动画 - 更极端的视觉效果
  Widget _buildExtremeHeavyRainAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ExtremeHeavyRainPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 极端暴雨动画
  // Widget _buildExtremeRainAnimation() {
  //   return AnimatedBuilder(
  //     animation: Listenable.merge([_mainAnimation, _particleController]),
  //     builder: (context, child) {
  //       return CustomPaint(
  //         painter: ExtremeRainPainter(
  //           _mainAnimation.value,
  //           _particleAnimation.value,
  //         ),
  //         size: Size(widget.size, widget.size),
  //       );
  //     },
  //   );
  // }

  // 雷阵雨动画
  Widget _buildThunderstormAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ThunderstormPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 雷阵雨伴有冰雹动画
  Widget _buildThunderstormWithHailAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ThunderstormWithHailPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 大雪动画
  Widget _buildHeavySnowAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: HeavySnowPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  // 暴雪动画
  Widget _buildBlizzardAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: BlizzardPainter(
            _mainAnimation.value,
            _particleAnimation.value,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }
}

// 晴天绘制器
class SunnyPainter extends CustomPainter {
  final double animationValue;

  SunnyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.25; // 缩小圆形

    // 绘制太阳 - 使用主题感知的颜色
    final sunPaint = Paint()
      ..color = WeatherAnimationColors.sunColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sunPaint);

    // 绘制太阳光芒
    final rayPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.sunRayColor,
        0.6,
      )
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30.0 + animationValue * 360.0) * math.pi / 180.0;
      final startRadius = radius + 10;
      final endRadius = radius + 20; // 光长度为原来的2/3 (30 * 2/3 = 20)

      final startX = center.dx + math.cos(angle) * startRadius;
      final startY = center.dy + math.sin(angle) * startRadius;
      final endX = center.dx + math.cos(angle) * endRadius;
      final endY = center.dy + math.sin(angle) * endRadius;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 多云绘制器
class CloudyPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  CloudyPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 先绘制太阳（在云的后面）
    final sunPaint = Paint()
      ..color = AppColors.sunrise.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final sunCenter = Offset(center.dx, center.dy - 10); // 太阳在云上方
    canvas.drawCircle(sunCenter, 25, sunPaint);

    // 再绘制云朵 - 四朵天蓝色云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(
      center.dx + math.sin(cloudAnimationValue * 2 * math.pi) * 15,
      center.dy - 15,
    );
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(
      center.dx - 30 + math.cos(cloudAnimationValue * 2 * math.pi) * 10,
      center.dy + 5,
    );
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 右侧云朵
    final rightCloudCenter = Offset(
      center.dx + 30 + math.sin(cloudAnimationValue * 1.5 * math.pi) * 10,
      center.dy + 10,
    );
    _drawCloud(canvas, rightCloudCenter, 18, cloudPaint);

    // 上方云朵
    final topCloudCenter = Offset(
      center.dx + math.cos(cloudAnimationValue * 1.8 * math.pi) * 20,
      center.dy - 35,
    );
    _drawCloud(canvas, topCloudCenter, 16, cloudPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 少云绘制器
class PartlyCloudyPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  PartlyCloudyPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 先绘制太阳（在云的后面）
    final sunPaint = Paint()
      ..color = AppColors.sunrise.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final sunCenter = Offset(center.dx, center.dy - 20); // 太阳在云上方
    canvas.drawCircle(sunCenter, 25, sunPaint);

    // 再绘制云朵 - 两朵天蓝色云一大一小
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.7,
      )
      ..style = PaintingStyle.fill;

    // 大云朵
    final mainCloudCenter = Offset(
      center.dx + math.sin(cloudAnimationValue * 2 * math.pi) * 15,
      center.dy + 5, // 往下移动
    );
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 小云朵
    final smallCloudCenter = Offset(
      center.dx - 25 + math.cos(cloudAnimationValue * 1.5 * math.pi) * 10,
      center.dy + 15, // 往下移动
    );
    _drawCloud(canvas, smallCloudCenter, 18, cloudPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 少云绘制器
class FewCloudsPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  FewCloudsPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 先绘制太阳（在云的后面）
    final sunPaint = Paint()
      ..color = AppColors.sunrise.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final sunCenter = Offset(center.dx, center.dy - 15); // 太阳在云上方
    canvas.drawCircle(sunCenter, 25, sunPaint);

    // 再绘制云朵 - 一朵天蓝色云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.7,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(
      center.dx + math.sin(cloudAnimationValue * 2 * math.pi) * 15,
      center.dy + 10, // 往下移动
    );
    _drawCloud(canvas, mainCloudCenter, 18, cloudPaint); // 云朵调小
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 阴天绘制器
class OvercastPainter extends CustomPainter {
  final double animationValue;

  OvercastPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 绘制云朵 - 使用阴天专用的更深颜色
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.overcastCloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(
      center.dx + math.sin(animationValue * 2 * math.pi) * 15,
      center.dy - 15,
    );
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(
      center.dx - 30 + math.cos(animationValue * 2 * math.pi) * 10,
      center.dy + 5,
    );
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 右侧云朵
    final rightCloudCenter = Offset(
      center.dx + 30 + math.sin(animationValue * 1.5 * math.pi) * 10,
      center.dy + 10,
    );
    _drawCloud(canvas, rightCloudCenter, 18, cloudPaint);

    // 上方云朵
    final topCloudCenter = Offset(
      center.dx + math.cos(animationValue * 1.8 * math.pi) * 20,
      center.dy - 35,
    );
    _drawCloud(canvas, topCloudCenter, 16, cloudPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 雨天绘制器
class RainPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  RainPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 小雨云朵较小，使用主题感知的颜色
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, cloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制雨滴 - 调整位置，使用主题感知的颜色
    final rainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.7,
      )
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 25; i++) {
      final x = (i * 12.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 15) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 0.3, y + 1.5), rainPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 暴风雨绘制器
class StormPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  StormPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.9,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(size.width / 2 - 25, size.height * 0.15);
    _drawCloud(canvas, leftCloudCenter, 22, cloudPaint);

    // 右侧云朵
    final rightCloudCenter = Offset(size.width / 2 + 25, size.height * 0.25);
    _drawCloud(canvas, rightCloudCenter, 20, cloudPaint);

    // 上方云朵
    final topCloudCenter = Offset(size.width / 2, size.height * 0.1);
    _drawCloud(canvas, topCloudCenter, 18, cloudPaint);

    // 绘制闪电
    final lightningPaint = Paint()
      ..color = AppColors.warning
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    if (animationValue > 0.5) {
      final lightningPath = Path();
      lightningPath.moveTo(size.width / 2, size.height * 0.3);
      lightningPath.lineTo(size.width / 2 + 10, size.height * 0.5);
      lightningPath.lineTo(size.width / 2 - 5, size.height * 0.6);
      lightningPath.lineTo(size.width / 2 + 15, size.height * 0.8);

      canvas.drawPath(lightningPath, lightningPaint);
    }

    // 绘制雨滴
    final rainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.8,
      )
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 60; i++) {
      final x = (i * 6.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 1, y + 2.5), rainPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 雪天绘制器
class SnowPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  SnowPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 小雪单朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.7,
      )
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, cloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.9,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 25, size.height * 0.12);
    _drawCloud(canvas, leftSmallCloud, 12, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 30, size.height * 0.28);
    _drawCloud(canvas, rightSmallCloud, 10, darkCloudPaint);

    // 绘制雪花 - 增加数量，调整位置，提高透明度，使用主题感知的颜色
    final snowPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        1.0,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final x = (i * 30.0 + particleAnimationValue * 35) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 20) %
              (size.height * 0.484) +
          size.height * 0.3;

      _drawSnowflake(canvas, Offset(x, y), snowPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, Paint paint) {
    // 绘制六角雪花形状 - 小雪版本（比暴雪小）
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // 绘制六条主射线
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final endX = center.dx + math.cos(angle) * 2;
      final endY = center.dy + math.sin(angle) * 2;

      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }

    // 绘制中心点
    canvas.drawCircle(center, 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 中雪绘制器
class MediumSnowPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  MediumSnowPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 中雪两朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(size.width / 2 - 15, size.height * 0.15);
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 绘制雪花 - 数量介于小雪和暴雪之间，大小和小雪一样，使用主题感知的颜色
    final snowPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        1.0,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final x = (i * 25.0 + particleAnimationValue * 30) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 18) %
              (size.height * 0.484) +
          size.height * 0.3;

      _drawSnowflake(canvas, Offset(x, y), snowPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, Paint paint) {
    // 绘制六角雪花形状 - 中雪版本（和小雪一样大小）
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // 绘制六条主射线
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final endX = center.dx + math.cos(angle) * 2;
      final endY = center.dy + math.sin(angle) * 2;

      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }

    // 绘制中心点
    canvas.drawCircle(center, 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 大雪绘制器
class HeavySnowPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  HeavySnowPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 大雪多朵云，参考暴雪设计
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.9,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(size.width / 2 - 20, size.height * 0.15);
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 右侧云朵
    final rightCloudCenter = Offset(size.width / 2 + 20, size.height * 0.25);
    _drawCloud(canvas, rightCloudCenter, 18, cloudPaint);

    // 绘制雪花 - 大雪版本，比暴雪粒子少一些，使用主题感知的颜色
    final snowPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        1.0,
      )
      ..style = PaintingStyle.fill;

    // 减少粒子数量：暴雪30个，大雪20个
    for (int i = 0; i < 20; i++) {
      final x = (i * 20.0 + particleAnimationValue * 35) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 18) %
              (size.height * 0.484) +
          size.height * 0.3;

      _drawSnowflake(canvas, Offset(x, y), snowPaint);
    }

    // 绘制雪花堆积效果，使用主题感知的颜色
    final accumulationPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.7,
      )
      ..style = PaintingStyle.fill;

    // 减少堆积区域：暴雪3个，大雪2个
    for (int i = 0; i < 2; i++) {
      final x = i * size.width / 2;
      final height = 4.0 + math.sin(animationValue * 2 * math.pi + i) * 1.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.85, size.width / 2, height),
          const Radius.circular(3),
        ),
        accumulationPaint,
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, Paint paint) {
    // 绘制六角雪花形状 - 大雪版本（比暴雪稍小）
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    // 绘制六条主射线
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final endX = center.dx + math.cos(angle) * 2.5;
      final endY = center.dy + math.sin(angle) * 2.5;

      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }

    // 绘制中心点
    canvas.drawCircle(center, 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 暴雪绘制器
class BlizzardPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  BlizzardPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 暴雪多朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.9,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(size.width / 2 - 20, size.height * 0.15);
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 右侧云朵
    final rightCloudCenter = Offset(size.width / 2 + 20, size.height * 0.25);
    _drawCloud(canvas, rightCloudCenter, 18, cloudPaint);

    // 绘制密集的雪花 - 暴雪版本，使用主题感知的颜色
    final snowPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        1.0,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (i * 15.0 + particleAnimationValue * 40) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 15) %
              (size.height * 0.484) +
          size.height * 0.3;

      _drawSnowflake(canvas, Offset(x, y), snowPaint);
    }

    // 绘制雪花堆积效果，使用主题感知的颜色
    final accumulationPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.7,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final x = i * size.width / 3;
      final height = 5.0 + math.sin(animationValue * 2 * math.pi + i) * 2.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.85, size.width / 3, height),
          const Radius.circular(3),
        ),
        accumulationPaint,
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, Paint paint) {
    // 绘制六角雪花形状 - 暴雪版本（最大）
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // 绘制六条主射线
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final endX = center.dx + math.cos(angle) * 3;
      final endY = center.dy + math.sin(angle) * 3;

      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }

    // 绘制中心点
    canvas.drawCircle(center, 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 雨凇绘制器
class RainGlazePainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  RainGlazePainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 雨凇单朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制雨滴到雪花的渐变粒子
    for (int i = 0; i < 30; i++) {
      final x = (i * 12.0 + particleAnimationValue * 20) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 15) %
              (size.height * 0.484) +
          size.height * 0.3;

      // 计算粒子在下降过程中的位置比例（0-1）
      final particleProgress = (y - size.height * 0.3) / (size.height * 0.484);

      // 根据位置决定绘制雨滴还是雪花
      if (particleProgress < 0.3) {
        // 前30%绘制雨滴
        final rainPaint = Paint()
          ..color = WeatherAnimationColors.withOpacity(
            WeatherAnimationColors.rainColor,
            0.8,
          )
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(x, y), Offset(x + 1, y + 3), rainPaint);
      } else if (particleProgress < 0.7) {
        // 中间40%绘制过渡效果（雨滴逐渐变短）
        final transitionPaint = Paint()
          ..color = WeatherAnimationColors.withOpacity(
            WeatherAnimationColors.rainColor,
            0.6,
          )
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        final lineLength = 3.0 * (1.0 - (particleProgress - 0.3) / 0.4);
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 0.5, y + lineLength),
          transitionPaint,
        );
      } else {
        // 后30%绘制雪花
        final snowPaint = Paint()
          ..color = WeatherAnimationColors.withOpacity(
            WeatherAnimationColors.snowColor,
            1.0,
          )
          ..style = PaintingStyle.fill;

        _drawSnowflake(canvas, Offset(x, y), snowPaint);
      }
    }

    // 绘制地面结冰效果
    final iceAccumulationPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.6,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final x = i * size.width / 4;
      final height = 3.0 + math.sin(animationValue * 3 * math.pi + i) * 1.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.85, size.width / 4, height),
          const Radius.circular(2),
        ),
        iceAccumulationPaint,
      );
    }

    // 绘制冰面反光效果
    final reflectionPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.3,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final x = i * size.width / 2;
      final width = 20.0 + math.sin(animationValue * 2 * math.pi + i) * 10.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.87, width, 1),
          const Radius.circular(0.5),
        ),
        reflectionPaint,
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, Paint paint) {
    // 绘制六角雪花形状 - 雨凇版本
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // 绘制六条主射线
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final endX = center.dx + math.cos(angle) * 2;
      final endY = center.dy + math.sin(angle) * 2;

      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }

    // 绘制中心点
    canvas.drawCircle(center, 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 雨夹雪绘制器
class SleetPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  SleetPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 雨夹雪两朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(size.width / 2 - 15, size.height * 0.15);
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 绘制雨滴和雪花混合 - 调整位置
    for (int i = 0; i < 18; i++) {
      final x = (i * 20.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 18) %
              (size.height * 0.484) +
          size.height * 0.3;

      if (i % 4 == 0) {
        // 雪花 - 减少雪花比例
        final snowPaint = Paint()
          ..color = WeatherAnimationColors.withOpacity(
            WeatherAnimationColors.snowColor,
            1.0,
          )
          ..style = PaintingStyle.fill;
        _drawSnowflake(canvas, Offset(x, y), snowPaint);
      } else {
        // 雨滴
        final rainPaint = Paint()
          ..color = WeatherAnimationColors.withOpacity(
            WeatherAnimationColors.rainColor,
            0.8,
          )
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(x, y), Offset(x + 1, y + 2.5), rainPaint);
      }
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, Paint paint) {
    // 绘制六角雪花形状 - 雨夹雪版本（比暴雪小，比小雪大）
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    // 绘制六条主射线
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final endX = center.dx + math.cos(angle) * 2.5;
      final endY = center.dy + math.sin(angle) * 2.5;

      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }

    // 绘制中心点
    canvas.drawCircle(center, 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 雾天绘制器
class FogPainter extends CustomPainter {
  final double animationValue;
  final double intensity; // 雾的强度 (0.0-1.0)

  FogPainter(this.animationValue, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制雾层 - 使用主题感知的颜色
    final fogPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.fogColor,
        0.5,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.2 + i * size.height * 0.15;
      final width =
          size.width * (0.8 + 0.2 * math.sin(animationValue * 2 * math.pi + i));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, y),
            width: width,
            height: 20,
          ),
          const Radius.circular(10),
        ),
        fogPaint,
      );
    }

    // 绘制主题色波浪线表示强度
    _drawThemeWaves(canvas, size);
  }

  void _drawThemeWaves(Canvas canvas, Size size) {
    // 根据强度调整波浪线数量 - 减少数量
    final waveCount = (1 + intensity * 3).round();

    final wavePaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.8,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < waveCount; i++) {
      final y = size.height * 0.3 + i * size.height * 0.15; // 增加间距
      final path = Path();

      // 创建波浪形效果
      for (double x = 0; x <= size.width; x += 3) {
        final waveY =
            y +
            6 *
                math.sin(
                  (x / size.width) * 3 * math.pi +
                      animationValue * 2 * math.pi +
                      i * 0.5,
                );
        if (x == 0) {
          path.moveTo(x, waveY);
        } else {
          path.lineTo(x, waveY);
        }
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 霾绘制器 - 黄色，粒子数量表示强度
class HazePainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;
  final int particleCount;

  HazePainter(
    this.animationValue,
    this.particleAnimationValue,
    this.particleCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制霾层 - 使用主题感知的颜色
    final hazePaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.fogColor,
        0.4,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.2 + i * size.height * 0.15;
      final width =
          size.width * (0.8 + 0.2 * math.sin(animationValue * 2 * math.pi + i));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, y),
            width: width,
            height: 20,
          ),
          const Radius.circular(10),
        ),
        hazePaint,
      );
    }

    // 绘制主题色粒子点
    final particlePaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.6,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      // 添加随机偏移
      final randomOffsetX =
          math.sin(i * 1.5 + particleAnimationValue * 2 * math.pi) * 15.0;
      final randomOffsetY =
          math.cos(i * 2.1 + particleAnimationValue * 1.8 * math.pi) * 12.0;

      final x =
          (i * 15.0 + particleAnimationValue * 20 + randomOffsetX) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.6 +
              i * 8.0 +
              randomOffsetY) %
          size.height;
      final particleSize =
          1.5 + math.sin(animationValue * 3 * math.pi + i) * 0.8;

      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 浮尘绘制器 - 粒子少、小、无漩涡
class FloatingDustPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  FloatingDustPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制浮尘粒子 - 少、小
    final dustPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      // 添加轻微随机偏移，和扬沙类似
      final randomOffsetX =
          math.sin(i * 2.1 + animationValue * 2.8 * math.pi) * 12.0;
      final randomOffsetY =
          math.cos(i * 1.8 + animationValue * 2.2 * math.pi) * 10.0;

      // 速度比扬沙慢一些
      final x =
          (i * 8.0 + particleAnimationValue * 25 + randomOffsetX) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.7 +
              i * 18 +
              randomOffsetY) %
          size.height;
      final particleSize =
          1.2 + math.sin(animationValue * 2 * math.pi + i) * 0.6;

      canvas.drawCircle(Offset(x, y), particleSize, dustPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 扬沙绘制器 - 粒子小、少、1个漩涡
class BlowingSandPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  BlowingSandPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制扬沙粒子 - 小、少
    final dustPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      // 添加轻微随机偏移
      final randomOffsetX =
          math.sin(i * 2.1 + animationValue * 2.8 * math.pi) * 12.0;
      final randomOffsetY =
          math.cos(i * 1.8 + animationValue * 2.2 * math.pi) * 10.0;

      final x =
          (i * 8.0 + particleAnimationValue * 40 + randomOffsetX) % size.width;
      final y =
          (particleAnimationValue * size.height + i * 18 + randomOffsetY) %
          size.height;
      final particleSize =
          1.2 + math.sin(animationValue * 2 * math.pi + i) * 0.6;

      canvas.drawCircle(Offset(x, y), particleSize, dustPaint);
    }

    // 绘制1个白色风漩涡
    final swirlPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.7,
      )
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.4;
    final radius = 10.0 + math.sin(animationValue * 3 * math.pi) * 3.0;

    _drawWindSwirl(canvas, Offset(centerX, centerY), radius, swirlPaint);
  }

  void _drawWindSwirl(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    final turns = 1.5;

    for (double t = 0; t <= turns * 2 * math.pi; t += 0.1) {
      final r = radius * (1 - t / (turns * 2 * math.pi));
      final x = center.dx + r * math.cos(t + animationValue * 2 * math.pi);
      final y = center.dy + r * math.sin(t + animationValue * 2 * math.pi);

      if (t == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 沙尘暴绘制器 - 粒子少、2个漩涡
class DustStormPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  DustStormPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制沙尘粒子 - 少
    final dustPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 60; i++) {
      // 添加随机偏移，打破规律性
      final randomOffsetX =
          math.sin(i * 1.7 + animationValue * 3 * math.pi) * 20.0;
      final randomOffsetY =
          math.cos(i * 2.3 + animationValue * 2.5 * math.pi) * 15.0;

      final x =
          (i * 8.0 + particleAnimationValue * 45 + randomOffsetX) % size.width;
      final y =
          (particleAnimationValue * size.height + i * 16 + randomOffsetY) %
          size.height;
      final particleSize =
          1.5 + math.sin(animationValue * 2 * math.pi + i) * 0.8;

      canvas.drawCircle(Offset(x, y), particleSize, dustPaint);
    }

    // 绘制2个白色风漩涡
    final swirlPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 第一个漩涡
    final centerX1 = size.width * 0.3;
    final centerY1 = size.height * 0.35;
    final radius1 = 12.0 + math.sin(animationValue * 3 * math.pi) * 4.0;
    _drawWindSwirl(canvas, Offset(centerX1, centerY1), radius1, swirlPaint);

    // 第二个漩涡
    final centerX2 = size.width * 0.7;
    final centerY2 = size.height * 0.45;
    final radius2 = 10.0 + math.sin(animationValue * 3 * math.pi + 1) * 3.0;
    _drawWindSwirl(canvas, Offset(centerX2, centerY2), radius2, swirlPaint);
  }

  void _drawWindSwirl(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    final turns = 1.5;

    for (double t = 0; t <= turns * 2 * math.pi; t += 0.1) {
      final r = radius * (1 - t / (turns * 2 * math.pi));
      final x = center.dx + r * math.cos(t + animationValue * 2 * math.pi);
      final y = center.dy + r * math.sin(t + animationValue * 2 * math.pi);

      if (t == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 强沙尘暴绘制器 - 粒子多、大、3个漩涡
class SevereDustStormPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  SevereDustStormPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制沙尘粒子 - 多、大
    final dustPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 120; i++) {
      // 添加更强的随机偏移，创造更混乱的效果
      final randomOffsetX =
          math.sin(i * 1.3 + animationValue * 4 * math.pi) * 30.0;
      final randomOffsetY =
          math.cos(i * 1.9 + animationValue * 3.5 * math.pi) * 25.0;

      final x =
          (i * 6.0 + particleAnimationValue * 60 + randomOffsetX) % size.width;
      final y =
          (particleAnimationValue * size.height + i * 12 + randomOffsetY) %
          size.height;
      final particleSize =
          1.8 + math.sin(animationValue * 2 * math.pi + i) * 0.8;

      canvas.drawCircle(Offset(x, y), particleSize, dustPaint);
    }

    // 绘制3个白色风漩涡
    final swirlPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.9,
      )
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // 第一个漩涡 - 左上
    final centerX1 = size.width * 0.25;
    final centerY1 = size.height * 0.3;
    final radius1 = 15.0 + math.sin(animationValue * 3 * math.pi) * 5.0;
    _drawWindSwirl(canvas, Offset(centerX1, centerY1), radius1, swirlPaint);

    // 第二个漩涡 - 中心
    final centerX2 = size.width * 0.5;
    final centerY2 = size.height * 0.4;
    final radius2 = 12.0 + math.sin(animationValue * 3 * math.pi + 1) * 4.0;
    _drawWindSwirl(canvas, Offset(centerX2, centerY2), radius2, swirlPaint);

    // 第三个漩涡 - 右下
    final centerX3 = size.width * 0.75;
    final centerY3 = size.height * 0.5;
    final radius3 = 14.0 + math.sin(animationValue * 3 * math.pi + 2) * 4.5;
    _drawWindSwirl(canvas, Offset(centerX3, centerY3), radius3, swirlPaint);
  }

  void _drawWindSwirl(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    final turns = 1.5;

    for (double t = 0; t <= turns * 2 * math.pi; t += 0.1) {
      final r = radius * (1 - t / (turns * 2 * math.pi));
      final x = center.dx + r * math.cos(t + animationValue * 2 * math.pi);
      final y = center.dy + r * math.sin(t + animationValue * 2 * math.pi);

      if (t == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 冰雹绘制器
class HailPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  HailPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 冰雹单朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制冰雹颗粒
    final hailPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 绘制冰雹阴影
    final hailShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = (i * 12.0 + particleAnimationValue * 20) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 15) %
              (size.height * 0.484) +
          size.height * 0.3;

      // 冰雹大小变化 - 减小尺寸
      final hailSize = 1.0 + math.sin(animationValue * 4 * math.pi + i) * 1.0;

      // 绘制阴影
      canvas.drawCircle(Offset(x + 0.5, y + 0.5), hailSize, hailShadowPaint);

      // 绘制冰雹
      canvas.drawCircle(Offset(x, y), hailSize, hailPaint);
    }

    // 绘制冰雹撞击地面的效果
    final impactPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.6,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 20.0) % size.width;
      final y = size.height * 0.8;
      final impactSize = 1.0 + math.sin(animationValue * 8 * math.pi + i) * 1.5;

      // 绘制撞击水花
      canvas.drawCircle(Offset(x, y), impactSize, impactPaint);
    }

    // 绘制冰雹轨迹线
    final trailPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.3,
      )
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 30; i++) {
      final x = (i * 8.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      // 绘制轨迹线
      canvas.drawLine(Offset(x, y), Offset(x + 0.5, y + 2), trailPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 大雨绘制器
class HeavyRainPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;
  final int particleCount;

  HeavyRainPainter(
    this.animationValue,
    this.particleAnimationValue,
    this.particleCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 大雨单朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制密集的雨滴 - 根据粒子数量调整视觉效果
    final rainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        particleCount > 200 ? 0.9 : 0.8, // 特大暴雨更不透明
      )
      ..strokeWidth = particleCount > 200
          ? 3.0
          : 2.5 // 特大暴雨更粗
      ..style = PaintingStyle.stroke;

    // 根据粒子数量调整间距
    final spacing = particleCount > 200 ? 3.0 : 4.0;

    for (int i = 0; i < particleCount; i++) {
      final x = (i * spacing) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      // 根据粒子数量调整雨滴长度
      final rainLength = particleCount > 200 ? 4.0 : 3.0;
      canvas.drawLine(Offset(x, y), Offset(x + 1, y + rainLength), rainPaint);
    }

    // 绘制雨滴溅起的水花 - 根据粒子数量调整水花效果
    final splashPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        particleCount > 200 ? 0.6 : 0.4, // 特大暴雨水花更明显
      )
      ..style = PaintingStyle.fill;

    // 根据粒子数量调整水花数量
    final splashCount = particleCount > 200 ? 30 : 20;
    final splashSpacing = particleCount > 200 ? 15.0 : 20.0;

    for (int i = 0; i < splashCount; i++) {
      final x = (i * splashSpacing) % size.width;
      final y = size.height * 0.8;
      final splashSize =
          (particleCount > 200 ? 3.0 : 2.0) +
          math.sin(animationValue * 4 * math.pi + i) * 1.0;

      canvas.drawCircle(Offset(x, y), splashSize, splashPaint);
    }

    // 特大暴雨和大暴雨添加额外的雨帘效果
    if (particleCount > 150) {
      final curtainPaint = Paint()
        ..color = WeatherAnimationColors.withOpacity(
          WeatherAnimationColors.rainColor,
          0.2,
        )
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 3; i++) {
        final x = i * size.width / 2;
        final height = size.height * 0.4;
        final curtainRect = Rect.fromLTWH(x, size.height * 0.3, 2, height);
        canvas.drawRect(curtainRect, curtainPaint);
      }
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 毛毛雨绘制器 - 最轻的雨
class DrizzlePainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  DrizzlePainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 毛毛雨云朵较小，使用主题感知的颜色
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.6,
      )
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, cloudCenter, 20, cloudPaint);

    // 绘制毛毛雨滴 - 非常轻，几乎看不见
    final rainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.4,
      )
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 15; i++) {
      final x = (i * 15.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 20) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 0.2, y + 1), rainPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 阵雨绘制器
class ShowerRainPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  ShowerRainPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 阵雨云朵，使用主题感知的颜色
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, cloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制阵雨雨滴 - 间歇性，密度变化
    final rainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.8,
      )
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 阵雨效果：根据动画值调整粒子数量
    final intensity = (math.sin(animationValue * 3 * math.pi) + 1) / 2;
    final particleCount = (35 * intensity).round() + 10; // 10-45个粒子

    for (int i = 0; i < particleCount; i++) {
      final x = (i * 5.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 8) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 0.6, y + 2), rainPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 小雪绘制器
class LightSnowPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  LightSnowPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 小雪云朵较小
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, cloudCenter, 25, cloudPaint);

    // 绘制小雪雪花 - 数量少，飘得慢
    final snowPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.9,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final x = (i * 20.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 * 0.5 + i * 15) %
              (size.height * 0.484) +
          size.height * 0.3;

      _drawSnowflake(canvas, Offset(x, y), 1.5, snowPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    // 绘制简单的六角星形雪花
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = center.dx + math.cos(angle) * size;
      final y = center.dy + math.sin(angle) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 阵雪绘制器
class ShowerSnowPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  ShowerSnowPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 阵雪云朵
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, cloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制阵雪雪花 - 间歇性，密度变化
    final snowPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.snowColor,
        0.9,
      )
      ..style = PaintingStyle.fill;

    // 阵雪效果：根据动画值调整粒子数量，减少粒子数目
    final intensity = (math.sin(animationValue * 2 * math.pi) + 1) / 2;
    final particleCount = (15 * intensity).round() + 8; // 8-23个粒子，比原来少

    for (int i = 0; i < particleCount; i++) {
      final x = (i * 18.0) % size.width; // 增加间距
      final y =
          (particleAnimationValue * size.height * 0.484 * 0.8 + i * 15) %
              (size.height * 0.484) +
          size.height * 0.3;

      _drawSnowflake(canvas, Offset(x, y), 2.0, snowPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, double size, Paint paint) {
    // 绘制六角雪花形状 - 阵雪版本
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // 绘制六条主射线
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final endX = center.dx + math.cos(angle) * size;
      final endY = center.dy + math.sin(angle) * size;

      canvas.drawLine(center, Offset(endX, endY), linePaint);

      // 在每条射线上添加分支
      final branchLength = size * 0.4;
      final branchX1 = center.dx + math.cos(angle) * size * 0.6;
      final branchY1 = center.dy + math.sin(angle) * size * 0.6;
      final branchX2 = center.dx + math.cos(angle + math.pi / 6) * branchLength;
      final branchY2 = center.dy + math.sin(angle + math.pi / 6) * branchLength;
      final branchX3 = center.dx + math.cos(angle - math.pi / 6) * branchLength;
      final branchY3 = center.dy + math.sin(angle - math.pi / 6) * branchLength;

      canvas.drawLine(
        Offset(branchX1, branchY1),
        Offset(branchX2, branchY2),
        linePaint,
      );
      canvas.drawLine(
        Offset(branchX1, branchY1),
        Offset(branchX3, branchY3),
        linePaint,
      );
    }

    // 绘制中心点
    canvas.drawCircle(center, size * 0.15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 中雨绘制器
class MediumRainPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  MediumRainPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 中雨云朵，使用主题感知的颜色
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, cloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制中雨雨滴 - 比小雨多，比大雨少
    final rainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.8,
      )
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 40; i++) {
      final x = (i * 6.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 10) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 0.8, y + 2.5), rainPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 特大暴雨绘制器 - 参考暴雨效果，调整粒子和地面水花
class ExtremeHeavyRainPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  ExtremeHeavyRainPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 参考暴雨的云朵布局，保持一致性
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.8,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 绘制更深色的小云朵
    final darkCloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudShadowColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制密集的雨滴 - 比暴雨更密集，但比原来少一些
    final rainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.9,
      )
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 160; i++) {
      // 调整粒子数量，与暴雨区分
      final x = (i * 3.0) % size.width; // 调整间距
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 10) %
              (size.height * 0.484) +
          size.height * 0.3;

      // 根据粒子数量调整雨滴长度
      final rainLength = 4.0;
      canvas.drawLine(Offset(x, y), Offset(x + 1, y + rainLength), rainPaint);
    }

    // 绘制雨滴溅起的水花 - 比暴雨更明显
    final splashPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.7, // 提高水花透明度
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 35; i++) {
      // 增加水花数量
      final x = (i * 15.0) % size.width;
      final y = size.height * 0.8;
      final splashSize = 3.5 + math.sin(animationValue * 4 * math.pi + i) * 1.5;

      canvas.drawCircle(Offset(x, y), splashSize, splashPaint);
    }

    // 特大暴雨添加雨帘效果
    final curtainPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.25,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final x = i * size.width / 3;
      final height = size.height * 0.4;
      final curtainRect = Rect.fromLTWH(x, size.height * 0.3, 2, height);
      canvas.drawRect(curtainRect, curtainPaint);
    }

    // 绘制地面水流效果 - 新增特效
    final waterFlowPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.rainColor,
        0.5,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final x = i * size.width / 5;
      final height = 2.0 + math.sin(animationValue * 2 * math.pi + i) * 1.0;
      final waterRect = Rect.fromLTWH(
        x,
        size.height * 0.85,
        size.width / 5,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(waterRect, const Radius.circular(1)),
        waterFlowPaint,
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx - radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.7, center.dy),
        radius: radius * 0.8,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.5),
        radius: radius * 0.6,
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
