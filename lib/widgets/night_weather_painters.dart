import 'package:flutter/material.dart';
import 'dart:math' as math;

// ==================== 夜间绘制器 ====================

/// 月亮绘制器（晴朗夜空）
class MoonPainter extends CustomPainter {
  final double animationValue;

  MoonPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.22;

    // 绘制月亮主体（新月形状）
    final moonPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final path = Path();
    // 绘制新月形状（右侧的月牙）
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 3,
      -math.pi * 0.7,
    );
    path.addArc(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.3, center.dy),
        radius: radius,
      ),
      -math.pi / 3 + math.pi,
      math.pi * 0.7,
    );
    path.close();

    canvas.drawPath(path, moonPaint);

    // 绘制月亮内部的暗色区域（月影）
    final shadowPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.15, center.dy),
        radius: radius * 0.8,
      ),
      shadowPaint,
    );

    // 绘制星星（带闪烁效果）
    final starPositions = [
      Offset(center.dx - size.width * 0.3, center.dy - size.height * 0.25),
      Offset(center.dx + size.width * 0.35, center.dy - size.height * 0.35),
      Offset(center.dx - size.width * 0.35, center.dy + size.height * 0.3),
      Offset(center.dx + size.width * 0.3, center.dy + size.height * 0.25),
      Offset(center.dx, center.dy - size.height * 0.4),
    ];

    for (final starPos in starPositions) {
      // 闪烁效果
      final starOpacity =
          (math.sin(
                    animationValue * 2 * math.pi +
                        (starPos.dx + starPos.dy) * 0.01,
                  ) +
                  1) /
              2 *
              0.3 +
          0.4;

      final starPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(starOpacity)
        ..style = PaintingStyle.fill;

      _drawStar(canvas, starPos, 3, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 - math.pi / 2;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
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

/// 多云夜空绘制器（月亮+云）
class CloudyNightPainter extends CustomPainter {
  final double animationValue;
  final double cloudAnimationValue;

  CloudyNightPainter(this.animationValue, this.cloudAnimationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.18;

    // 先绘制月亮（在云后面）
    final moonPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 3,
      -math.pi * 0.7,
    );
    path.addArc(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.3, center.dy),
        radius: radius,
      ),
      -math.pi / 3 + math.pi,
      math.pi * 0.7,
    );
    path.close();

    canvas.drawPath(path, moonPaint);

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
    final radius = size.width * 0.2;

    // 绘制月亮
    final moonPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 3,
      -math.pi * 0.7,
    );
    path.addArc(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.3, center.dy),
        radius: radius,
      ),
      -math.pi / 3 + math.pi,
      math.pi * 0.7,
    );
    path.close();

    canvas.drawPath(path, moonPaint);

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
    final radius = size.width * 0.22;

    // 绘制月亮
    final moonPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 3,
      -math.pi * 0.7,
    );
    path.addArc(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.3, center.dy),
        radius: radius,
      ),
      -math.pi / 3 + math.pi,
      math.pi * 0.7,
    );
    path.close();

    canvas.drawPath(path, moonPaint);

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
