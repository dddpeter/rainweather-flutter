import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';
import '../utils/weather_animation_colors.dart';

// 极端暴雨绘制器
class ExtremeRainPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  ExtremeRainPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 暴雨多朵云
    final cloudPaint = Paint()
      ..color = WeatherAnimationColors.withOpacity(
        WeatherAnimationColors.cloudColor,
        0.95,
      )
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(size.width / 2, size.height * 0.2);
    _drawCloud(canvas, mainCloudCenter, 25, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(size.width / 2 - 25, size.height * 0.15);
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 右侧云朵
    final rightCloudCenter = Offset(size.width / 2 + 25, size.height * 0.25);
    _drawCloud(canvas, rightCloudCenter, 18, cloudPaint);

    // 上方云朵
    final topCloudCenter = Offset(size.width / 2, size.height * 0.1);
    _drawCloud(canvas, topCloudCenter, 16, cloudPaint);

    // 下方云朵
    final bottomCloudCenter = Offset(size.width / 2, size.height * 0.35);
    _drawCloud(canvas, bottomCloudCenter, 14, cloudPaint);

    // 绘制极密集的雨滴 - 调整位置
    final rainPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.9)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 120; i++) {
      final x = (i * 3.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 1, y + 3.5), rainPaint);
    }

    // 绘制雨帘效果
    final curtainPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final x = i * size.width / 4;
      final height =
          size.height *
          (0.3 + 0.1 * math.sin(animationValue * 2 * math.pi + i));

      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.3, 2, height),
        curtainPaint,
      );
    }

    // 绘制大量水花
    final splashPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final x = (i * 8.0) % size.width;
      final y = size.height * 0.8;
      final splashSize = 3.0 + math.sin(animationValue * 6 * math.pi + i) * 2.0;

      canvas.drawCircle(Offset(x, y), splashSize, splashPaint);
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

// 雷阵雨绘制器
class ThunderstormPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  ThunderstormPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 雷阵雨单朵云
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
        1.0,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制频繁的闪电
    final lightningPaint = Paint()
      ..color = AppColors.warning
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    if (animationValue > 0.3) {
      // 主闪电
      final lightningPath = Path();
      lightningPath.moveTo(size.width / 2, size.height * 0.2);
      lightningPath.lineTo(size.width / 2 + 15, size.height * 0.5);
      lightningPath.lineTo(size.width / 2 - 10, size.height * 0.65);
      lightningPath.lineTo(size.width / 2 + 20, size.height * 0.85);

      canvas.drawPath(lightningPath, lightningPaint);

      // 分支闪电
      if (animationValue > 0.6) {
        final branchPath = Path();
        branchPath.moveTo(size.width / 2 + 10, size.height * 0.4);
        branchPath.lineTo(size.width / 2 + 25, size.height * 0.6);

        canvas.drawPath(branchPath, lightningPaint);
      }
    }

    // 绘制密集的雨滴 - 调整位置
    final rainPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 100; i++) {
      final x = (i * 3.5) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 1, y + 3), rainPaint);
    }

    // 绘制雨滴溅起的水花
    final splashPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (i * 12.0) % size.width;
      final y = size.height * 0.8;
      final splashSize = 2.0 + math.sin(animationValue * 8 * math.pi + i) * 1.5;

      canvas.drawCircle(Offset(x, y), splashSize, splashPaint);
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

// 雷阵雨伴有冰雹绘制器
class ThunderstormWithHailPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  ThunderstormWithHailPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 雷阵雨伴有冰雹单朵云
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
        1.0,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制频繁的闪电
    final lightningPaint = Paint()
      ..color = AppColors.warning
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    if (animationValue > 0.3) {
      final lightningPath = Path();
      lightningPath.moveTo(size.width / 2, size.height * 0.2);
      lightningPath.lineTo(size.width / 2 + 15, size.height * 0.5);
      lightningPath.lineTo(size.width / 2 - 10, size.height * 0.65);
      lightningPath.lineTo(size.width / 2 + 20, size.height * 0.85);

      canvas.drawPath(lightningPath, lightningPaint);
    }

    // 绘制雨滴 - 调整位置
    final rainPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 80; i++) {
      final x = (i * 4.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 1, y + 3), rainPaint);
    }

    // 绘制冰雹 - 调整位置
    final hailPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 15.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 15) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawCircle(Offset(x, y), 2.0, hailPaint);
    }

    // 绘制水花
    final splashPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = (i * 15.0) % size.width;
      final y = size.height * 0.8;
      final splashSize = 2.0 + math.sin(animationValue * 6 * math.pi + i) * 1.0;

      canvas.drawCircle(Offset(x, y), splashSize, splashPaint);
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

// 大雪绘制器
class HeavySnowPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  HeavySnowPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 暴雪单朵云
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
        1.0,
      )
      ..style = PaintingStyle.fill;

    // 左侧小云朵
    final leftSmallCloud = Offset(size.width / 2 - 30, size.height * 0.15);
    _drawCloud(canvas, leftSmallCloud, 15, darkCloudPaint);

    // 右侧小云朵
    final rightSmallCloud = Offset(size.width / 2 + 35, size.height * 0.25);
    _drawCloud(canvas, rightSmallCloud, 12, darkCloudPaint);

    // 绘制密集的雪花 - 调整位置，提高透明度
    final snowPaint = Paint()
      ..color = Colors.white.withOpacity(1.0)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = (i * 18.0 + particleAnimationValue * 35) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 16) %
              (size.height * 0.484) +
          size.height * 0.3;

      _drawSnowflake(canvas, Offset(x, y), snowPaint);
    }

    // 绘制雪花堆积效果
    final accumulationPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
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
    // 绘制六角雪花形状 - 大雪版本（比暴雪小）
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
