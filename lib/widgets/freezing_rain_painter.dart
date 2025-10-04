import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';
import '../utils/weather_animation_colors.dart';

// 冻雨绘制器
class FreezingRainPainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;

  FreezingRainPainter(this.animationValue, this.particleAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制云朵 - 冻雨两朵云
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
    final leftCloudCenter = Offset(size.width / 2 - 25, size.height * 0.15);
    _drawCloud(canvas, leftCloudCenter, 20, cloudPaint);

    // 绘制冻雨滴 - 透明雨滴
    final rainPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 60; i++) {
      final x = (i * 6.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      canvas.drawLine(Offset(x, y), Offset(x + 0.5, y + 2.5), rainPaint);
    }

    // 绘制冰晶效果 - 小冰晶
    final icePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (i * 12.0) % size.width;
      final y =
          (particleAnimationValue * size.height * 0.484 + i * 12) %
              (size.height * 0.484) +
          size.height * 0.3;

      // 绘制小冰晶
      canvas.drawCircle(Offset(x, y), 1.5, icePaint);
    }

    // 绘制地面结冰效果
    final iceAccumulationPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
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
      ..color = Colors.white.withOpacity(0.3)
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
