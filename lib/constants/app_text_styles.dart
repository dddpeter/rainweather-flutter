import 'package:flutter/material.dart';

/// AppTextStyles - 统一的字体样式系统
///
/// 设计原则：
/// - 使用系统默认字体，保持原生体验
/// - 清晰的字体大小层级：12/14/16/18/20/24/28/32
/// - 字重层次：Regular(400)/Medium(500)/SemiBold(600)/Bold(700)
/// - 适中的行高：1.2-1.5 倍字体大小
/// - 优化的字间距
class AppTextStyles {
  AppTextStyles._(); // 私有构造函数，防止实例化

  // ==================== 字体家族 ====================
  // 使用思源黑体 (Noto Sans CJK SC)
  // - 统一的跨平台字体体验
  // - 优秀的中文显示效果
  // - 多种字重支持
  static const String fontFamily = 'NotoSansSC';

  // ==================== 标题样式 ====================

  /// 超大标题 - 32sp, Bold
  /// 用途：页面主标题、特殊强调内容
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    decoration: TextDecoration.none,
  );

  /// 大标题 - 28sp, Bold
  /// 用途：主要区块标题
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    decoration: TextDecoration.none,
  );

  /// 中等标题 - 24sp, SemiBold
  /// 用途：卡片标题、区块标题
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    decoration: TextDecoration.none,
  );

  /// 大标题 - 20sp, SemiBold
  /// 用途：天气温度大数字、重要信息
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
    decoration: TextDecoration.none,
  );

  /// 中标题 - 18sp, SemiBold
  /// 用途：页面标题、卡片标题
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  /// 小标题 - 16sp, Medium
  /// 用途：列表标题、区块名称
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  // ==================== 正文样式 ====================

  /// 大正文 - 16sp, Regular
  /// 用途：主要正文内容
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    decoration: TextDecoration.none,
  );

  /// 中正文 - 14sp, Regular
  /// 用途：常规正文内容
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    decoration: TextDecoration.none,
  );

  /// 小正文 - 12sp, Regular
  /// 用途：次要正文内容
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );

  // ==================== 标签样式 ====================

  /// 大标签 - 16sp, Medium
  /// 用途：按钮文字、重要标签
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    decoration: TextDecoration.none,
  );

  /// 中标签 - 14sp, Medium
  /// 用途：标签、按钮文字
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );

  /// 小标签 - 12sp, Medium
  /// 用途：小标签、提示文字
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.3,
    decoration: TextDecoration.none,
  );

  // ==================== 特殊用途样式 ====================

  /// 天气温度超大数字 - 48sp, Light
  /// 用途：主页温度显示
  static const TextStyle temperatureLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    height: 1.1,
    letterSpacing: -1,
    decoration: TextDecoration.none,
  );

  /// 天气温度中等数字 - 36sp, Light
  /// 用途：卡片温度显示
  static const TextStyle temperatureMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w300,
    height: 1.1,
    letterSpacing: -0.5,
    decoration: TextDecoration.none,
  );

  /// 天气温度小数字 - 24sp, Light
  /// 用途：列表温度显示
  static const TextStyle temperatureSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w300,
    height: 1.2,
    letterSpacing: -0.3,
    decoration: TextDecoration.none,
  );

  /// 数字样式 - 18sp, Medium (等宽数字)
  /// 用途：数据展示、统计数字
  static const TextStyle number = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
    decoration: TextDecoration.none,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 辅助说明文字 - 11sp, Regular
  /// 用途：提示、说明文字
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.3,
    decoration: TextDecoration.none,
  );

  /// 链接文字 - 14sp, Medium
  /// 用途：可点击的链接文字
  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    decoration: TextDecoration.underline,
    decorationColor: Color(0xFF4A90E2),
  );

  // ==================== Material Design 3 对应 ====================

  /// 转换为 Material TextTheme
  static TextTheme get textTheme => const TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: headlineLarge,
    titleMedium: headlineMedium,
    titleSmall: headlineSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
