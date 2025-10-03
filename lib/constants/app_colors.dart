import 'package:flutter/material.dart';

/// 应用颜色配置 - 基于知雨天气图标配色方案
class AppColors {
  // 主要颜色 - 基于图标配色
  /// 深蓝色背景 - 图标主背景色 #1A4A8C
  static const Color primaryBlue = Color(0xFF1A4A8C);
  
  /// 白色 - 图标文字颜色
  static const Color primaryWhite = Color(0xFFFFFFFF);
  
  /// 浅蓝色 - 图标装饰色 #66CCFF
  static const Color accentBlue = Color(0xFF66CCFF);
  
  /// 浅绿色 - 组件细节点缀色
  static const Color accentGreen = Color(0xFF81C784);
  
  /// 深绿色 - 更深层次的绿色
  static const Color deepGreen = Color(0xFF4CAF50);
  
  /// 浅绿色 - 更亮的绿色
  static const Color lightGreen = Color(0xFFA5D6A7);

  // 背景色系
  /// 主背景色 - 深蓝渐变起始
  static const Color backgroundPrimary = Color(0xFF0A0E27);
  
  /// 次背景色 - 深蓝渐变结束
  static const Color backgroundSecondary = Color(0xFF1A1F3A);
  
  /// 卡片背景色 - 半透明深蓝
  static const Color cardBackground = Color(0xFF1E2B5C);
  
  /// 玻璃效果背景色
  static const Color glassBackground = Color(0x40000000);

  // 文字颜色
  /// 主要文字颜色
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// 次要文字颜色
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% 透明度
  
  /// 辅助文字颜色
  static const Color textTertiary = Color(0x80FFFFFF); // 50% 透明度

  // 边框和分割线
  /// 边框颜色
  static const Color borderColor = Color(0x33FFFFFF); // 20% 透明度
  
  /// 分割线颜色
  static const Color dividerColor = Color(0x1AFFFFFF); // 10% 透明度

  // 状态颜色
  /// 成功色 - 绿色
  static const Color success = Color(0xFF4CAF50);
  
  /// 警告色 - 橙色
  static const Color warning = Color(0xFFFF9800);
  
  /// 错误色 - 红色
  static const Color error = Color(0xFFF44336);
  
  /// 信息色 - 蓝色
  static const Color info = Color(0xFF2196F3);

  // 渐变色
  /// 主背景渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundPrimary, backgroundSecondary],
  );
  
  /// 卡片渐变
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardBackground, Color(0xFF2A3F73)],
  );
  
  /// 按钮渐变 - 蓝色系
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, primaryBlue],
  );
  
  /// 按钮渐变 - 绿色系
  static const LinearGradient greenButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, deepGreen],
  );

  // 阴影颜色
  /// 卡片阴影
  static const Color cardShadow = Color(0x1A000000);
  
  /// 按钮阴影
  static const Color buttonShadow = Color(0x33000000);

  // 天气相关颜色
  /// 晴天颜色
  static const Color sunnyColor = Color(0xFFFFD54F);
  
  /// 多云颜色
  static const Color cloudyColor = Color(0xFFBDBDBD);
  
  /// 雨天颜色
  static const Color rainyColor = Color(0xFF64B5F6);
  
  /// 雪天颜色
  static const Color snowyColor = Color(0xFFE1F5FE);
  
  /// 雾天颜色
  static const Color foggyColor = Color(0xFF9E9E9E);

  // 空气质量颜色
  /// 优
  static const Color airExcellent = Color(0xFF4CAF50);
  
  /// 良
  static const Color airGood = Color(0xFF8BC34A);
  
  /// 轻度污染
  static const Color airLight = Color(0xFFFFC107);
  
  /// 中度污染
  static const Color airModerate = Color(0xFFFF9800);
  
  /// 重度污染
  static const Color airHeavy = Color(0xFFF44336);
  
  /// 严重污染
  static const Color airSevere = Color(0xFF9C27B0);

  // 温度颜色
  /// 高温
  static const Color highTemp = Color(0xFFFF5722);
  
  /// 中温
  static const Color midTemp = Color(0xFFFFC107);
  
  /// 低温
  static const Color lowTemp = Color(0xFF2196F3);
}
