import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';
import 'extreme_weather_painters.dart';
import 'freezing_rain_painter.dart';
import 'night_weather_painters.dart';
import '../utils/weather_animation_colors.dart';
import '../providers/theme_provider.dart';

// ==================== 天气动画配置 ====================

/// 天气动画配置
///
/// 将所有天气类型的动画配置集中管理
class WeatherAnimationConfig {
  /// Painter类型
  final CustomPainter Function(double mainAnimation, double particleAnimation, double cloudAnimation) createPainter;

  /// 是否使用主动画
  final bool useMainAnimation;

  /// 是否使用粒子动画
  final bool useParticleAnimation;

  /// 是否使用云朵动画
  final bool useCloudAnimation;

  const WeatherAnimationConfig({
    required this.createPainter,
    this.useMainAnimation = true,
    this.useParticleAnimation = false,
    this.useCloudAnimation = false,
  });
}

/// 天气类型映射表
final Map<String, WeatherAnimationConfig> _weatherAnimationMap = {
  // ==================== 晴天类 ====================
  '晴': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => SunnyPainter(main),
    useMainAnimation: true,
  ),
  '平静': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => SunnyPainter(main),
    useMainAnimation: true,
  ),

  // ==================== 多云类 ====================
  '多云': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => CloudyPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '晴间多云': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => PartlyCloudyPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '多云转晴': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => PartlyCloudyPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '晴转多云': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => PartlyCloudyPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '少云': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FewCloudsPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),

  // ==================== 阴天类 ====================
  '阴': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => OvercastPainter(cloud),
    useCloudAnimation: true,
  ),

  // ==================== 雨类 ====================
  '毛毛雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => DrizzlePainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '小雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => RainPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '阵雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => ShowerRainPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '中雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => MediumRainPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '大雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HeavyRainPainter(main, particle, 60),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '暴雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HeavyRainPainter(main, particle, 120),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '大暴雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HeavyRainPainter(main, particle, 200),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '特大暴雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => ExtremeHeavyRainPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '雷阵雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => ThunderstormPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '雷阵雨伴有冰雹': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => ThunderstormWithHailPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),

  // ==================== 雪类 ====================
  '雪': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => SnowPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '小雪': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => LightSnowPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '阵雪': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => ShowerSnowPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '中雪': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => MediumSnowPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '大雪': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HeavySnowPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '暴雪': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => BlizzardPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),

  // ==================== 混合天气类 ====================
  '雨夹雪': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => SleetPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '雨雪天气': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => SleetPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '冻雨': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FreezingRainPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '冰雹': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HailPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '雨凇': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => RainGlazePainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),

  // ==================== 雾类 ====================
  '轻雾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FogPainter(main, 0.3),
    useMainAnimation: true,
  ),
  '雾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FogPainter(main, 0.5),
    useMainAnimation: true,
  ),
  '浓雾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FogPainter(main, 0.7),
    useMainAnimation: true,
  ),
  '强浓雾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FogPainter(main, 0.9),
    useMainAnimation: true,
  ),

  // ==================== 霾类 ====================
  '霾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HazePainter(main, particle, 20),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '中度霾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HazePainter(main, particle, 35),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '重度霾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HazePainter(main, particle, 50),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '严重霾': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => HazePainter(main, particle, 70),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),

  // ==================== 沙尘类 ====================
  '浮尘': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FloatingDustPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '扬沙': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => BlowingSandPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '沙尘暴': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => DustStormPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),
  '强沙尘暴': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => SevereDustStormPainter(main, particle),
    useMainAnimation: true,
    useParticleAnimation: true,
  ),

  // ==================== 夜间天气 ====================
  '晴_夜': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => MoonPainter(main),
    useMainAnimation: true,
  ),
  '多云_夜': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => CloudyNightPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '晴间多云_夜': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => PartlyCloudyNightPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '多云转晴_夜': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => PartlyCloudyNightPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '晴转多云_夜': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => PartlyCloudyNightPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
  '少云_夜': WeatherAnimationConfig(
    createPainter: (main, particle, cloud) => FewCloudsNightPainter(main, cloud),
    useMainAnimation: true,
    useCloudAnimation: true,
  ),
};

/// 获取天气动画配置
WeatherAnimationConfig? _getWeatherAnimationConfig(String weatherType, {bool isNight = false}) {
  final key = isNight ? '${weatherType}_夜' : weatherType;
  return _weatherAnimationMap[key] ?? _weatherAnimationMap[weatherType];
}

class WeatherAnimationWidget extends StatefulWidget {
  final String weatherType;
  final double size;
  final bool isPlaying;
  final bool? forceNightMode; // 强制夜间模式（测试用）

  const WeatherAnimationWidget({
    super.key,
    required this.weatherType,
    this.size = 200.0,
    this.isPlaying = true,
    this.forceNightMode,
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
    // 如果强制指定了夜间模式，则使用强制值
    if (widget.forceNightMode != null) {
      return widget.forceNightMode!;
    }
    // 否则根据时间判断
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  Widget _buildWeatherAnimation() {
    // 使用内部配置获取动画配置
    final config = _getWeatherAnimationConfig(widget.weatherType, isNight: _isNighttime);

    if (config == null) {
      // 默认返回晴天动画
      return _buildAnimationFromConfig(_weatherAnimationMap['晴']!);
    }

    return _buildAnimationFromConfig(config);
  }

  /// 根据配置构建动画
  Widget _buildAnimationFromConfig(WeatherAnimationConfig config) {
    // 合并动画
    final animations = <Listenable>[];
    if (config.useMainAnimation) animations.add(_mainAnimation);
    if (config.useParticleAnimation) animations.add(_particleController);
    if (config.useCloudAnimation) animations.add(_cloudAnimation);

    final animation = animations.length == 1
        ? animations.first
        : Listenable.merge(animations);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: config.createPainter(
            _mainAnimation.value,
            _particleAnimation.value,
            _cloudAnimation.value,
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
    final radius = size.width * 0.25;

    // 使用辅助函数绘制带光芒的太阳
    _drawSunWithRays(canvas, center, radius, animationValue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 辅助函数：绘制带光芒的太阳
void _drawSunWithRays(
  Canvas canvas,
  Offset sunCenter,
  double sunRadius,
  double animationValue,
) {
  // 绘制太阳主体
  final sunPaint = Paint()
    ..color = WeatherAnimationColors.sunColor
    ..style = PaintingStyle.fill;

  canvas.drawCircle(sunCenter, sunRadius, sunPaint);

  // 计算旋转过程中的动态变化（0到1循环）
  final rotationPhase = (animationValue % 1.0);
  final dynamicFactor = 1.0 + rotationPhase * 0.1; // 增加10%

  // 绘制太阳光芒
  final rayPaint = Paint()
    ..color = WeatherAnimationColors.withOpacity(
      WeatherAnimationColors.sunRayColor,
      0.6,
    )
    ..strokeWidth =
        3.0 *
        dynamicFactor // 动态变化粗细
    ..style = PaintingStyle.stroke;

  for (int i = 0; i < 12; i++) {
    final angle = (i * 30.0 + animationValue * 360.0) * math.pi / 180.0;
    final startRadius = sunRadius + 10;
    final endRadius = sunRadius + 20 * dynamicFactor; // 动态变化长度

    final startX = sunCenter.dx + math.cos(angle) * startRadius;
    final startY = sunCenter.dy + math.sin(angle) * startRadius;
    final endX = sunCenter.dx + math.cos(angle) * endRadius;
    final endY = sunCenter.dy + math.sin(angle) * endRadius;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
  }
}

// 多云绘制器
class CloudyPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  CloudyPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 先绘制太阳（带光芒，在云的后面）
    final sunCenter = Offset(center.dx, center.dy - 10);
    final sunRadius = size.width * 0.25;

    // 使用辅助函数绘制带光芒的太阳
    _drawSunWithRays(canvas, sunCenter, sunRadius, animationValue);

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

    // 先绘制太阳（带光芒，在云的后面）
    final sunCenter = Offset(center.dx, center.dy - 20);
    final sunRadius = size.width * 0.25;

    // 使用辅助函数绘制带光芒的太阳
    _drawSunWithRays(canvas, sunCenter, sunRadius, animationValue);

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

    // 先绘制太阳（带光芒，在云的后面）
    final sunCenter = Offset(center.dx, center.dy - 15);
    final sunRadius = size.width * 0.25;

    // 使用辅助函数绘制带光芒的太阳
    _drawSunWithRays(canvas, sunCenter, sunRadius, animationValue);

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

    // 绘制黄色粒子点
    final particlePaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        const Color(0xFFFFB300), // 金黄色粒子
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
