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

/// 辅助方法：绘制锐五角星
void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
  // 创建一个路径用于绘制五角星
  final path = Path();

  // 外圆半径和内圆半径（形成锐五角星）
  final outerRadius = radius;
  final innerRadius = radius * 0.38; // 内圆半径更小，形成更尖锐的角

  // 计算五个外顶点和五个内顶点
  for (int i = 0; i < 5; i++) {
    // 外顶点
    final outerAngle = (i * 2 * math.pi / 5) - (math.pi / 2); // 从顶部开始
    final outerX = center.dx + outerRadius * math.cos(outerAngle);
    final outerY = center.dy + outerRadius * math.sin(outerAngle);

    if (i == 0) {
      path.moveTo(outerX, outerY);
    } else {
      path.lineTo(outerX, outerY);
    }

    // 内顶点
    final innerAngle = (i * 2 * math.pi / 5) - (math.pi / 2) + (math.pi / 5);
    final innerX = center.dx + innerRadius * math.cos(innerAngle);
    final innerY = center.dy + innerRadius * math.sin(innerAngle);
    path.lineTo(innerX, innerY);
  }

  path.close();

  // 绘制填充的五角星
  canvas.drawPath(path, paint);
}

/// 辅助方法：绘制星星（统一的星星绘制）
void _drawNightStars(
  Canvas canvas,
  Offset center,
  Size size,
  double animationValue, {
  double minRadius = 0.35,
  double maxRadius = 0.48,
}) {
  // 使用固定的星星位置，确保不会随机旋转
  final baseDistance = size.width * 0.50; // 增加基础距离，离月亮更远，确保不重叠
  final minStarDistance = size.width * 0.12; // 星星之间的最小距离，避免重叠（减小）

  // 预定义的星星配置（大小和颜色）
  final configs = [
    (4.0, 1.5, 0xFFFFFFFF), // 大星星 白色
    (3.0, 1.2, 0xFFFFF9E3), // 中星星 淡黄
    (3.5, 1.3, 0xFFE1F5FE), // 中大星星 淡蓝
    (2.5, 1.0, 0xFFFFFFFF), // 小星星 白色
    (4.5, 1.5, 0xFFFFE0B2), // 大星星 亮黄
    (3.2, 1.2, 0xFFB3E5FC), // 中星星 亮蓝
    (2.2, 1.0, 0xFFFFF4B3), // 小星星 淡金
    (3.8, 1.4, 0xFFCFD8DC), // 中星星 淡青
  ];

  final starData = <({Offset pos, double size, int color})>[];
  final existingPositions = <Offset>[]; // 记录已有星星位置，用于检查重叠

  // 生成8颗星星，固定分布在月亮周围
  for (int i = 0; i < 8; i++) {
    // 基于索引生成固定角度（不均匀分布，更自然）
    final angle = (i * 0.785) + (i * 0.1); // 每个星星大约45度间隔，但有些微偏移
    // 固定距离变化，范围更大
    final distance = baseDistance * (0.85 + (i % 4) * 0.2); // 4种不同距离循环

    // 计算位置（考虑椭圆，高度方向缩放）
    final x = center.dx + distance * math.cos(angle);
    final y = center.dy + distance * math.sin(angle) * 0.9;
    final pos = Offset(x, y);

    // 检查是否与已有星星距离太近
    bool tooClose = false;
    for (final existingPos in existingPositions) {
      final starDistance = (pos - existingPos).distance;
      if (starDistance < minStarDistance) {
        tooClose = true;
        break;
      }
    }

    // 如果距离太近，跳过这颗星星
    if (tooClose) continue;

    // 获取配置
    final config = configs[i % configs.length];
    // 基于位置生成固定的大小变化（避免完全随机）
    final sizeVariation = ((x + y) % 100) / 100.0; // 基于位置的伪随机
    final starSize = config.$1 + (sizeVariation * config.$2);

    starData.add((pos: pos, size: starSize, color: config.$3));
    existingPositions.add(pos);
  }

  for (final star in starData) {
    // 基础闪烁效果
    final baseOpacity =
        (math.sin(
                  animationValue * 2 * math.pi +
                      (star.pos.dx + star.pos.dy) * 0.01,
                ) +
                1) /
            2 *
            0.3 +
        0.4;

    // 随机突然亮闪效果（某些星星会突然变得很亮）
    // 基于星星位置创建一个固定的"种子"，然后基于时间生成随机亮闪
    final starSeed = (star.pos.dx + star.pos.dy).abs();
    final flashPhase = (animationValue * 0.5 + starSeed * 0.001) % 1.0;

    // 偶尔（低概率）产生极亮的闪光
    double flashIntensity = 0.0;
    if (flashPhase < 0.02) {
      // 2%的时间会产生闪光
      // 闪光强度从0到1再到0
      final flashProgress = flashPhase / 0.02;
      if (flashProgress < 0.5) {
        flashIntensity = flashProgress * 2; // 0 to 1
      } else {
        flashIntensity = (1 - flashProgress) * 2; // 1 to 0
      }
    }

    // 组合基础闪烁和闪光
    final finalOpacity = math.min(1.0, baseOpacity + flashIntensity * 0.6);

    final starPaint = Paint()
      ..color = Color(star.color).withOpacity(finalOpacity)
      ..style = PaintingStyle.fill;

    _drawStar(canvas, star.pos, star.size, starPaint);
  }
}

/// 月亮绘制器（晴朗夜空）
class MoonPainter extends CustomPainter {
  final double animationValue;

  MoonPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35; // 增大月亮

    // 先绘制星星（放在月亮后面一层）
    _drawNightStars(canvas, center, size, animationValue);

    // 再绘制月亮（覆盖星星）
    _drawMoon(canvas, center, radius);

    // 手动绘制额外的星星，增加随机度（注释掉原代码）
    /*
    final starData = [
      (
        pos: Offset(
          center.dx - size.width * 0.42,
          center.dy - size.height * 0.38,
        ),
        size: 4.2,
        color: 0xFFFFFFFF,
      ),
      (
        pos: Offset(
          center.dx + size.width * 0.38,
          center.dy - size.height * 0.42,
        ),
        size: 2.3,
        color: 0xFFFFF9E3,
      ),
      (
        pos: Offset(
          center.dx - size.width * 0.45,
          center.dy + size.height * 0.38,
        ),
        size: 3.7,
        color: 0xFFE0F2F1,
      ),
      (
        pos: Offset(
          center.dx + size.width * 0.4,
          center.dy + size.height * 0.32,
        ),
        size: 2.8,
        color: 0xFFFFFFFF,
      ),
      (
        pos: Offset(center.dx, center.dy - size.height * 0.48),
        size: 3.5,
        color: 0xFFFFEB3B,
      ),
      (
        pos: Offset(
          center.dx - size.width * 0.25,
          center.dy - size.height * 0.45,
        ),
        size: 1.8,
        color: 0xFFE1F5FE,
      ),
      (
        pos: Offset(
          center.dx + size.width * 0.28,
          center.dy + size.height * 0.44,
        ),
        size: 3.2,
        color: 0xFFFFF9E3,
      ),
      (
        pos: Offset(center.dx - size.width * 0.35, center.dy),
        size: 2.5,
        color: 0xFFFFFFFF,
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
    */
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
    final radius = size.width * 0.33; // 增大月亮

    // 先绘制星星（放在月亮后面一层）
    _drawNightStars(
      canvas,
      center,
      size,
      animationValue,
      minRadius: 0.38,
      maxRadius: 0.5,
    );

    // 再绘制月亮
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
    final radius = size.width * 0.32; // 增大月亮

    // 先绘制星星（放在月亮后面一层）
    _drawNightStars(
      canvas,
      center,
      size,
      animationValue,
      minRadius: 0.38,
      maxRadius: 0.48,
    );

    // 再绘制月亮
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
    final radius = size.width * 0.34; // 增大月亮

    // 先绘制星星（放在月亮后面一层）
    _drawNightStars(
      canvas,
      center,
      size,
      animationValue,
      minRadius: 0.38,
      maxRadius: 0.48,
    );

    // 再绘制月亮
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
