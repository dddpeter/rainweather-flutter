import 'package:flutter/material.dart';
import 'dart:math' as math;

// ==================== 夜间绘制器 ====================

/// 辅助方法：绘制月亮（统一的新月绘制）
void _drawMoon(Canvas canvas, Offset center, double radius) {
  // 使用 Path difference 创建圆形新月
  final moonPaint = Paint()
    ..color =
        const Color(0xFFFFF9E3) // 月亮的淡黄色
    ..style = PaintingStyle.fill;

  // 创建完整月亮的路径（圆形）
  final moonPath = Path()
    ..addOval(Rect.fromCircle(center: center, radius: radius));

  // 创建阴影路径（偏移的圆形）
  final shadowOffset = Offset(radius * 0.4, radius * 0.15);
  final shadowCenter = Offset(
    center.dx + shadowOffset.dx,
    center.dy - shadowOffset.dy,
  );
  final shadowPath = Path()
    ..addOval(Rect.fromCircle(center: shadowCenter, radius: radius * 0.98));

  // 使用 difference 创建新月（圆形）
  final crescentPath = Path.combine(
    PathOperation.difference,
    moonPath,
    shadowPath,
  );
  canvas.drawPath(crescentPath, moonPaint);
}

/// 月亮绘制器（晴朗夜空）
class MoonPainter extends CustomPainter {
  final double animationValue;

  MoonPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28; // 增大月亮

    // 绘制月亮（使用统一的绘制方法）
    _drawMoon(canvas, center, radius);

    // 绘制星星（带闪烁效果、随机大小和颜色）
    final starData = [
      (
        pos: Offset(
          center.dx - size.width * 0.3,
          center.dy - size.height * 0.25,
        ),
        size: 3.5,
        color: 0xFFFFFFFF,
      ),
      (
        pos: Offset(
          center.dx + size.width * 0.35,
          center.dy - size.height * 0.35,
        ),
        size: 2.5,
        color: 0xFFFFF9E3,
      ),
      (
        pos: Offset(
          center.dx - size.width * 0.35,
          center.dy + size.height * 0.3,
        ),
        size: 2.0,
        color: 0xFFE0F2F1,
      ),
      (
        pos: Offset(
          center.dx + size.width * 0.3,
          center.dy + size.height * 0.25,
        ),
        size: 3.0,
        color: 0xFFFFFFFF,
      ),
      (
        pos: Offset(center.dx, center.dy - size.height * 0.4),
        size: 4.0,
        color: 0xFFFFEB3B,
      ),
    ];

    for (final star in starData) {
      // 闪烁效果
      final starOpacity =
          (math.sin(
                    animationValue * 2 * math.pi +
                        (star.pos.dx + star.pos.dy) * 0.01,
                  ) +
                  1) /
              2 *
              0.3 +
          0.4;

      final starPaint = Paint()
        ..color = Color(star.color).withOpacity(starOpacity)
        ..style = PaintingStyle.fill;

      _drawStar(canvas, star.pos, star.size, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    // 绘制星星核心（小圆圈）
    canvas.drawCircle(center, radius * 0.4, paint);

    // 绘制4条尖锐的光芒线
    final rayLength = radius * 2;
    final rayPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 上下左右4个方向的光芒
    canvas.drawLine(center, Offset(center.dx, center.dy - rayLength), rayPaint);
    canvas.drawLine(center, Offset(center.dx, center.dy + rayLength), rayPaint);
    canvas.drawLine(center, Offset(center.dx - rayLength, center.dy), rayPaint);
    canvas.drawLine(center, Offset(center.dx + rayLength, center.dy), rayPaint);

    // 绘制斜向4条光芒（更短）
    final diagonalRayLength = radius * 1.5;
    canvas.drawLine(
      center,
      Offset(
        center.dx - diagonalRayLength * 0.707,
        center.dy - diagonalRayLength * 0.707,
      ),
      rayPaint,
    );
    canvas.drawLine(
      center,
      Offset(
        center.dx + diagonalRayLength * 0.707,
        center.dy - diagonalRayLength * 0.707,
      ),
      rayPaint,
    );
    canvas.drawLine(
      center,
      Offset(
        center.dx - diagonalRayLength * 0.707,
        center.dy + diagonalRayLength * 0.707,
      ),
      rayPaint,
    );
    canvas.drawLine(
      center,
      Offset(
        center.dx + diagonalRayLength * 0.707,
        center.dy + diagonalRayLength * 0.707,
      ),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 多云夜空绘制器（月亮+云）
class CloudyNightPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  CloudyNightPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.26; // 增大月亮

    // 先绘制月亮（在云后面，使用统一的绘制方法）
    _drawMoon(canvas, center, radius);

    // 绘制云朵（灰色）
    final cloudPaint = Paint()
      ..color = const Color(0xFFB0B0B0).withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // 主云朵
    final mainCloudCenter = Offset(
      center.dx + math.sin(cloudAnimationValue * 2 * math.pi) * 20,
      center.dy - 10,
    );
    _drawCloud(canvas, mainCloudCenter, 28, cloudPaint);

    // 左侧云朵
    final leftCloudCenter = Offset(
      center.dx - 35 + math.cos(cloudAnimationValue * 2 * math.pi) * 15,
      center.dy + 8,
    );
    _drawCloud(canvas, leftCloudCenter, 24, cloudPaint);

    // 右侧云朵
    final rightCloudCenter = Offset(
      center.dx + 35 + math.sin(cloudAnimationValue * 1.5 * math.pi) * 15,
      center.dy + 12,
    );
    _drawCloud(canvas, rightCloudCenter, 22, cloudPaint);
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

/// 少云夜空绘制器（月亮+少量云）
class PartlyCloudyNightPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  PartlyCloudyNightPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.25; // 增大月亮

    // 绘制月亮（使用统一的绘制方法）
    _drawMoon(canvas, center, radius);

    // 绘制少量云朵
    final cloudPaint = Paint()
      ..color = const Color(0xFFC8C8C8).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // 左侧一朵小云
    final cloudCenter = Offset(
      center.dx -
          size.width * 0.25 +
          math.cos(cloudAnimationValue * 2 * math.pi) * 10,
      center.dy + 15,
    );
    _drawCloud(canvas, cloudCenter, 18, cloudPaint);
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

/// 很少云夜空绘制器（月亮+一小朵云）
class FewCloudsNightPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  FewCloudsNightPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.27; // 增大月亮

    // 绘制月亮（使用统一的绘制方法）
    _drawMoon(canvas, center, radius);

    // 绘制一小朵云
    final cloudPaint = Paint()
      ..color = const Color(0xFFD8D8D8).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(
      center.dx -
          size.width * 0.3 +
          math.sin(cloudAnimationValue * math.pi) * 8,
      center.dy + 20,
    );
    _drawCloud(canvas, cloudCenter, 14, cloudPaint);
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
