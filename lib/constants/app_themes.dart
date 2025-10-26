import 'package:flutter/material.dart';

/// 主题方案枚举
enum AppThemeScheme {
  blue, // 蓝色主题（当前默认）
  green, // 绿色主题
  amber, // 琥珀橙主题
  teal, // 青绿色主题
  purple, // 紫色主题
  rose, // 玫瑰金主题
}

/// 主题配色配置
class ThemeColorScheme {
  final Map<String, Color> lightColors;
  final Map<String, Color> darkColors;
  final String name;
  final IconData icon;
  final Color previewColor;

  // 渐变色配置
  final LinearGradient primaryGradientLight;
  final LinearGradient primaryGradientDark;
  final LinearGradient headerGradientLight;
  final LinearGradient headerGradientDark;

  const ThemeColorScheme({
    required this.lightColors,
    required this.darkColors,
    required this.name,
    required this.icon,
    required this.previewColor,
    required this.primaryGradientLight,
    required this.primaryGradientDark,
    required this.headerGradientLight,
    required this.headerGradientDark,
  });

  /// 根据亮暗模式获取主渐变
  LinearGradient getPrimaryGradient(bool isLight) {
    return isLight ? primaryGradientLight : primaryGradientDark;
  }

  /// 根据亮暗模式获取头部渐变
  LinearGradient getHeaderGradient(bool isLight) {
    return isLight ? headerGradientLight : headerGradientDark;
  }
}

/// 主题配置集合
class AppThemes {
  /// 蓝色主题（当前默认）- 基于#8edafc亮蓝色和#012d78深蓝色
  static const ThemeColorScheme blue = ThemeColorScheme(
    name: '蓝色主题',
    icon: Icons.palette_outlined,
    previewColor: Color(0xFF012d78),
    lightColors: {
      'primary': Color(0xFF012d78), // 深蓝色主色
      'primaryDark': Color(0xFF001A4D), // 更深的蓝色
      'accent': Color(0xFF8edafc), // 指定的亮蓝色
      'background': Color.fromARGB(255, 192, 216, 236), // 基于#8edafc的浅蓝背景
      'headerBackground': Color(0xFF012d78), // 头部背景 - 深蓝色
      'headerBackgroundSecondary': Color(0xFF001A4D),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFE8F4FD),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFFFFFFFF),
      'textPrimary': Color(0xFF001A4D), // 深蓝色文字，高对比度
      'textSecondary': Color(0xFF003366), // 深蓝色次要文字
      'textTertiary': Color(0xFF4A5568),
      'border': Color(0xFFB8D9F5),
      'glassBackground': Color(0x20FFFFFF),
      'cardBackground': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0xFFE3F2FD),
      'cardBorder': Color(0xFFE1F5FE),
      'buttonShadow': Color(0x15000000),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFF8edafc),
      'tagBackground': Color(0xFFE8F5E8),
      'tagTextOnPrimary': Color(0xFF1976D2),
      'tagBorder': Color(0xFF1976D2),
      'error': Color(0xFFD32F2F),
      'success': Color(0xFF2E7D32),
      'warning': Color(0xFFE65100),
      'highTemp': Color(0xFFD32F2F),
      'lowTemp': Color(0xFF8edafc),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagBackground': Color(0xFFE53E3E),
      'currentTagBorder': Color(0xFFE53E3E),
      'sunrise': Color(0xFFFF9800),
      'sunset': Color(0xFFC2185B),
      'moon': Color(0xFF673AB7),
      'sunIcon': Color(0xFFE53935),
    },
    darkColors: {
      'primary': Color(0xFF4A90E2),
      'primaryDark': Color(0xFF012d78),
      'accent': Color(0xFF8edafc),
      'background': Color(0xFF0A1B3D),
      'headerBackground': Color(0xFF1A2F5D),
      'headerBackgroundSecondary': Color(0xFF2D4A7D),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFE8F4FD),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFF1A2F5D),
      'textPrimary': Color(0xFFFFFFFF),
      'textSecondary': Color(0xFFE8F4FD),
      'textTertiary': Color(0xFFB8D9F5),
      'border': Color(0xFF2D4A7D),
      'glassBackground': Color(0x30FFFFFF),
      'cardBackground': Color(0x25FFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0x35FFFFFF),
      'buttonShadow': Color(0x30000000),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0x80FFFFFF),
      'tagBackground': Color(0xFF4A90E2),
      'tagTextOnPrimary': Color(0xFFE8F4FD),
      'tagBorder': Color(0xFF4A90E2),
      'error': Color(0xFFFF6B6B),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFB74D),
      'highTemp': Color(0xFFFF5722),
      'lowTemp': Color(0xFF8edafc),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagBackground': Color(0xFF4A90E2),
      'currentTagBorder': Color(0xFF4A90E2),
      'sunrise': Color(0xFFFFB74D),
      'sunset': Color(0xFFE91E63),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFFFFF),
    },
    primaryGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF8edafc), // 指定的亮蓝色
        Color(0xFFE1F5FE), // 浅蓝色渐变
      ],
    ),
    primaryGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF012d78), // 指定的深蓝色
        Color(0xFF0A1B3D), // 基于深蓝色的渐变
      ],
    ),
    headerGradientLight: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF012d78), // 主要头部背景 - 深蓝色
        Color(0xFF001A4D), // 次要头部背景 - 更深的蓝色
      ],
      stops: [0.0, 1.0],
    ),
    headerGradientDark: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A2F5D), // 深蓝色头部背景
        Color(0xFF2D4A7D), // 更深的蓝色
      ],
      stops: [0.0, 1.0],
    ),
  );

  /// 绿色主题 - 清新自然
  static const ThemeColorScheme green = ThemeColorScheme(
    name: '绿色主题',
    icon: Icons.eco_outlined,
    previewColor: Color(0xFF2E7D32),
    lightColors: {
      'primary': Color(0xFF1B5E20), // 深绿色主色
      'primaryDark': Color(0xFF0D3E11),
      'accent': Color(0xFF66BB6A), // 亮绿色
      'background': Color(0xFFE8F5E9),
      'headerBackground': Color(0xFF1B5E20),
      'headerBackgroundSecondary': Color(0xFF0D3E11),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFE8F5E9),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFFFFFFFF),
      'textPrimary': Color(0xFF0D3E11),
      'textSecondary': Color(0xFF1B5E20),
      'textTertiary': Color(0xFF4A5568),
      'border': Color(0xFFB2DFDB),
      'glassBackground': Color(0x20FFFFFF),
      'cardBackground': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0xFFC8E6C9),
      'cardBorder': Color(0xFFE0F2E1),
      'buttonShadow': Color(0x15000000),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFF66BB6A),
      'tagBackground': Color(0xFFE8F5E9),
      'tagTextOnPrimary': Color(0xFF1B5E20),
      'tagBorder': Color(0xFF1B5E20),
      'error': Color(0xFFD32F2F),
      'success': Color(0xFF2E7D32),
      'warning': Color(0xFFE65100),
      'highTemp': Color(0xFFD32F2F),
      'lowTemp': Color(0xFF66BB6A),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagBackground': Color(0xFF2E7D32),
      'currentTagBorder': Color(0xFF2E7D32),
      'sunrise': Color(0xFFFF9800),
      'sunset': Color(0xFFC2185B),
      'moon': Color(0xFF673AB7),
      'sunIcon': Color(0xFFE53935),
    },
    darkColors: {
      'primary': Color(0xFF4CAF50),
      'primaryDark': Color(0xFF1B5E20),
      'accent': Color(0xFF66BB6A),
      'background': Color(0xFF0D3E11),
      'headerBackground': Color(0xFF1B5E20),
      'headerBackgroundSecondary': Color(0xFF2E7D32),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFE8F5E9),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFF1B5E20),
      'textPrimary': Color(0xFFFFFFFF),
      'textSecondary': Color(0xFFE8F5E9),
      'textTertiary': Color(0xFFB2DFDB),
      'border': Color(0xFF2E7D32),
      'glassBackground': Color(0x30FFFFFF),
      'cardBackground': Color(0x25FFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0x35FFFFFF),
      'buttonShadow': Color(0x30000000),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0x80FFFFFF),
      'tagBackground': Color(0xFF4CAF50),
      'tagTextOnPrimary': Color(0xFFE8F5E9),
      'tagBorder': Color(0xFF4CAF50),
      'error': Color(0xFFFF6B6B),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFB74D),
      'highTemp': Color(0xFFFF5722),
      'lowTemp': Color(0xFF66BB6A),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagBackground': Color(0xFF4CAF50),
      'currentTagBorder': Color(0xFF4CAF50),
      'sunrise': Color(0xFFFFB74D),
      'sunset': Color(0xFFE91E63),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFFFFF),
    },
    primaryGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF66BB6A), // 亮绿色
        Color(0xFFE8F5E9), // 浅绿色渐变
      ],
    ),
    primaryGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1B5E20), // 深绿色
        Color(0xFF0D3E11), // 更深绿色渐变
      ],
    ),
    headerGradientLight: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1B5E20), // 主要头部背景 - 深绿色
        Color(0xFF0D3E11), // 次要头部背景 - 更深的绿色
      ],
      stops: [0.0, 1.0],
    ),
    headerGradientDark: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1B5E20), // 深绿色头部背景
        Color(0xFF2E7D32), // 更深的绿色
      ],
      stops: [0.0, 1.0],
    ),
  );

  /// 琥珀橙主题
  static const ThemeColorScheme amber = ThemeColorScheme(
    name: '琥珀橙',
    icon: Icons.wb_sunny,
    previewColor: Color(0xFFFFB300),
    lightColors: {
      'primary': Color(0xFFE65100), // 深橙色主色
      'primaryDark': Color(0xFFBF360C), // 更深的橙色
      'accent': Color(0xFFFFB300), // 琥珀黄色
      'background': Color.fromARGB(255, 255, 243, 224), // 浅橙背景
      'headerBackground': Color(0xFFE65100), // 头部背景 - 深橙色
      'headerBackgroundSecondary': Color(0xFFBF360C),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFFFE0B2),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFFFFFFFF),
      'textPrimary': Color(0xFFBF360C),
      'textSecondary': Color(0xFFE65100),
      'textTertiary': Color(0xFF5D4037),
      'border': Color(0xFFFFCCBC),
      'divider': Color(0xFFFFE0B2),
      'cardBackground': Color(0xFFFFFFFF),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFFE65100),
      'buttonText': Color(0xFFFFFFFF),
      'bottomNavBackground': Color(0xFFFFFFFF),
      'bottomNavSelected': Color(0xFFE65100),
      'bottomNavUnselected': Color(0xFF9E9E9E),
      'indicatorColor': Color(0xFFE65100),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFFE65100),
      'titleColor': Color(0xFFBF360C),
      'subtitleColor': Color(0xFF5D4037),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFFFFCCBC),
      'buttonShadow': Color(0x30E65100),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFFE65100),
      'tagBackground': Color(0xFFFFB300),
      'tagTextOnPrimary': Color(0xFFFFFFFF),
      'tagBorder': Color(0xFFFFB300),
      'error': Color(0xFFD32F2F),
      'success': Color(0xFF2E7D32),
      'warning': Color(0xFFFF6F00),
      'highTemp': Color(0xFFD32F2F),
      'lowTemp': Color(0xFF1976D2),
      'sunrise': Color(0xFFFFB300),
      'sunset': Color(0xFFE65100),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    darkColors: {
      'primary': Color(0xFFFFB300), // 琥珀黄色
      'primaryDark': Color(0xFFFF6F00), // 更深的橙色
      'accent': Color(0xFFFFD54F), // 亮琥珀黄
      'background': Color(0xFF263238), // 深灰色背景
      'headerBackground': Color(0xFF37474F),
      'headerBackgroundSecondary': Color(0xFF455A64),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFFFE0B2),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFF37474F),
      'textPrimary': Color(0xFFFFFFFF),
      'textSecondary': Color(0xFFFFE0B2),
      'textTertiary': Color(0xFFFFCCBC),
      'border': Color(0xFF546E7A),
      'divider': Color(0xFF455A64),
      'cardBackground': Color(0xFF263238),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFFFFB300),
      'buttonText': Color(0xFF263238),
      'bottomNavBackground': Color(0xFF37474F),
      'bottomNavSelected': Color(0xFFFFB300),
      'bottomNavUnselected': Color(0xFF78909C),
      'indicatorColor': Color(0xFFFFB300),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFFFFB300),
      'titleColor': Color(0xFFFFFFFF),
      'subtitleColor': Color(0xFFFFE0B2),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFF546E7A),
      'buttonShadow': Color(0x30FFB300),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFFFFB300),
      'tagBackground': Color(0xFFFFB300),
      'tagTextOnPrimary': Color(0xFF263238),
      'tagBorder': Color(0xFFFFB300),
      'error': Color(0xFFFF6B6B),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFCC80),
      'highTemp': Color(0xFFFF5722),
      'lowTemp': Color(0xFF64B5F6),
      'sunrise': Color(0xFFFFCC80),
      'sunset': Color(0xFFFF6B6B),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    primaryGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFB300), // 琥珀黄色
        Color(0xFFFFE082), // 浅琥珀黄渐变
      ],
    ),
    primaryGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE65100), // 深橙色
        Color(0xFFBF360C), // 更深橙色渐变
      ],
    ),
    headerGradientLight: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE65100), // 主要头部背景 - 深橙色
        Color(0xFFBF360C), // 次要头部背景 - 更深的橙色
      ],
      stops: [0.0, 1.0],
    ),
    headerGradientDark: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE65100), // 深橙色头部背景
        Color(0xFFFF6F00), // 更深的橙色
      ],
      stops: [0.0, 1.0],
    ),
  );

  /// 青绿色主题
  static const ThemeColorScheme teal = ThemeColorScheme(
    name: '青绿色',
    icon: Icons.water_drop,
    previewColor: Color(0xFF00BCD4),
    lightColors: {
      'primary': Color(0xFF00796B), // 深青绿色主色
      'primaryDark': Color(0xFF004D40), // 更深的青绿色
      'accent': Color(0xFF00BCD4), // 青蓝色
      'background': Color.fromARGB(255, 224, 242, 241), // 浅青色背景
      'headerBackground': Color(0xFF00796B), // 头部背景 - 深青绿色
      'headerBackgroundSecondary': Color(0xFF004D40),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFB2DFDB),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFFFFFFFF),
      'textPrimary': Color(0xFF004D40),
      'textSecondary': Color(0xFF00796B),
      'textTertiary': Color(0xFF455A64),
      'border': Color(0xFFB2DFDB),
      'divider': Color(0xFF80CBC4),
      'cardBackground': Color(0xFFFFFFFF),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFF00796B),
      'buttonText': Color(0xFFFFFFFF),
      'bottomNavBackground': Color(0xFFFFFFFF),
      'bottomNavSelected': Color(0xFF00796B),
      'bottomNavUnselected': Color(0xFF9E9E9E),
      'indicatorColor': Color(0xFF00796B),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFF00796B),
      'titleColor': Color(0xFF004D40),
      'subtitleColor': Color(0xFF455A64),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFFB2DFDB),
      'buttonShadow': Color(0x3000796B),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFF00796B),
      'tagBackground': Color(0xFF00BCD4),
      'tagTextOnPrimary': Color(0xFFFFFFFF),
      'tagBorder': Color(0xFF00BCD4),
      'error': Color(0xFFD32F2F),
      'success': Color(0xFF2E7D32),
      'warning': Color(0xFFE65100),
      'highTemp': Color(0xFFD32F2F),
      'lowTemp': Color(0xFF1976D2),
      'sunrise': Color(0xFFFFB74D),
      'sunset': Color(0xFFE91E63),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    darkColors: {
      'primary': Color(0xFF00BCD4), // 青蓝色
      'primaryDark': Color(0xFF00838F), // 更深的青蓝色
      'accent': Color(0xFF4DD0E1), // 亮青蓝色
      'background': Color(0xFF004D40), // 深青色背景
      'headerBackground': Color(0xFF00695C),
      'headerBackgroundSecondary': Color(0xFF00796B),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFB2DFDB),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFF00695C),
      'textPrimary': Color(0xFFFFFFFF),
      'textSecondary': Color(0xFFB2DFDB),
      'textTertiary': Color(0xFF80CBC4),
      'border': Color(0xFF00838F),
      'divider': Color(0xFF00796B),
      'cardBackground': Color(0xFF004D40),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFF00BCD4),
      'buttonText': Color(0xFF004D40),
      'bottomNavBackground': Color(0xFF00695C),
      'bottomNavSelected': Color(0xFF00BCD4),
      'bottomNavUnselected': Color(0xFF4DD0E1),
      'indicatorColor': Color(0xFF00BCD4),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFF00BCD4),
      'titleColor': Color(0xFFFFFFFF),
      'subtitleColor': Color(0xFFB2DFDB),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFF00838F),
      'buttonShadow': Color(0x3000BCD4),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFF00BCD4),
      'tagBackground': Color(0xFF00BCD4),
      'tagTextOnPrimary': Color(0xFF004D40),
      'tagBorder': Color(0xFF00BCD4),
      'error': Color(0xFFFF6B6B),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFB74D),
      'highTemp': Color(0xFFFF5722),
      'lowTemp': Color(0xFF64B5F6),
      'sunrise': Color(0xFFFFCC80),
      'sunset': Color(0xFFFF6B6B),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    primaryGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF00BCD4), // 青蓝色
        Color(0xFFB2DFDB), // 浅青色渐变
      ],
    ),
    primaryGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF00796B), // 深青绿色
        Color(0xFF004D40), // 更深青绿色渐变
      ],
    ),
    headerGradientLight: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF00796B), // 主要头部背景 - 深青绿色
        Color(0xFF004D40), // 次要头部背景 - 更深的青绿色
      ],
      stops: [0.0, 1.0],
    ),
    headerGradientDark: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF00796B), // 深青绿色头部背景
        Color(0xFF00838F), // 更深的青蓝色
      ],
      stops: [0.0, 1.0],
    ),
  );

  /// 紫色主题
  static const ThemeColorScheme purple = ThemeColorScheme(
    name: '紫色',
    icon: Icons.star_rounded,
    previewColor: Color(0xFF673AB7),
    lightColors: {
      'primary': Color(0xFF512DA8), // 深紫色主色
      'primaryDark': Color(0xFF311B92), // 更深的紫色
      'accent': Color(0xFF673AB7), // 紫色
      'background': Color.fromARGB(255, 243, 237, 255), // 浅紫背景
      'headerBackground': Color(0xFF512DA8), // 头部背景 - 深紫色
      'headerBackgroundSecondary': Color(0xFF311B92),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFE1BEE7),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFFFFFFFF),
      'textPrimary': Color(0xFF311B92),
      'textSecondary': Color(0xFF512DA8),
      'textTertiary': Color(0xFF5E35B1),
      'border': Color(0xFFE1BEE7),
      'divider': Color(0xFFCE93D8),
      'cardBackground': Color(0xFFFFFFFF),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFF512DA8),
      'buttonText': Color(0xFFFFFFFF),
      'bottomNavBackground': Color(0xFFFFFFFF),
      'bottomNavSelected': Color(0xFF512DA8),
      'bottomNavUnselected': Color(0xFF9E9E9E),
      'indicatorColor': Color(0xFF512DA8),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFF512DA8),
      'titleColor': Color(0xFF311B92),
      'subtitleColor': Color(0xFF5E35B1),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFFE1BEE7),
      'buttonShadow': Color(0x30512DA8),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFF512DA8),
      'tagBackground': Color(0xFF673AB7),
      'tagTextOnPrimary': Color(0xFFFFFFFF),
      'tagBorder': Color(0xFF673AB7),
      'error': Color(0xFFD32F2F),
      'success': Color(0xFF2E7D32),
      'warning': Color(0xFFE65100),
      'highTemp': Color(0xFFD32F2F),
      'lowTemp': Color(0xFF1976D2),
      'sunrise': Color(0xFFFFB74D),
      'sunset': Color(0xFFE91E63),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    darkColors: {
      'primary': Color(0xFF9575CD), // 亮紫色
      'primaryDark': Color(0xFF7986CB), // 更亮的紫色
      'accent': Color(0xFFB39DDB), // 浅紫色
      'background': Color(0xFF1A237E), // 深紫色背景
      'headerBackground': Color(0xFF3F51B5),
      'headerBackgroundSecondary': Color(0xFF283593),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFE1BEE7),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFF283593),
      'textPrimary': Color(0xFFFFFFFF),
      'textSecondary': Color(0xFFE1BEE7),
      'textTertiary': Color(0xFFCE93D8),
      'border': Color(0xFF5C6BC0),
      'divider': Color(0xFF3F51B5),
      'cardBackground': Color(0xFF1A237E),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFF9575CD),
      'buttonText': Color(0xFF1A237E),
      'bottomNavBackground': Color(0xFF283593),
      'bottomNavSelected': Color(0xFF9575CD),
      'bottomNavUnselected': Color(0xFFB39DDB),
      'indicatorColor': Color(0xFF9575CD),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFF9575CD),
      'titleColor': Color(0xFFFFFFFF),
      'subtitleColor': Color(0xFFE1BEE7),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFF5C6BC0),
      'buttonShadow': Color(0x309575CD),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFF9575CD),
      'tagBackground': Color(0xFF9575CD),
      'tagTextOnPrimary': Color(0xFF1A237E),
      'tagBorder': Color(0xFF9575CD),
      'error': Color(0xFFFF6B6B),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFB74D),
      'highTemp': Color(0xFFFF5722),
      'lowTemp': Color(0xFF64B5F6),
      'sunrise': Color(0xFFFFCC80),
      'sunset': Color(0xFFFF6B6B),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    primaryGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF673AB7), // 紫色
        Color(0xFFE1BEE7), // 浅紫色渐变
      ],
    ),
    primaryGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF512DA8), // 深紫色
        Color(0xFF311B92), // 更深紫色渐变
      ],
    ),
    headerGradientLight: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF512DA8), // 主要头部背景 - 深紫色
        Color(0xFF311B92), // 次要头部背景 - 更深的紫色
      ],
      stops: [0.0, 1.0],
    ),
    headerGradientDark: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF512DA8), // 深紫色头部背景
        Color(0xFF3F51B5), // 更深的紫蓝色
      ],
      stops: [0.0, 1.0],
    ),
  );

  /// 玫瑰金主题
  static const ThemeColorScheme rose = ThemeColorScheme(
    name: '玫瑰金',
    icon: Icons.favorite,
    previewColor: Color(0xFFEF5350),
    lightColors: {
      'primary': Color(0xFFD32F2F), // 深红色主色
      'primaryDark': Color(0xFFB71C1C), // 更深的红色
      'accent': Color(0xFFEF5350), // 玫瑰红
      'background': Color.fromARGB(255, 255, 235, 238), // 浅玫瑰背景
      'headerBackground': Color(0xFFD32F2F), // 头部背景 - 深红色
      'headerBackgroundSecondary': Color(0xFFB71C1C),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFFFCDD2),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFFFFFFFF),
      'textPrimary': Color(0xFFB71C1C),
      'textSecondary': Color(0xFFD32F2F),
      'textTertiary': Color(0xFFE53935),
      'border': Color(0xFFFFCDD2),
      'divider': Color(0xFFF8BBD0),
      'cardBackground': Color(0xFFFFFFFF),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFFD32F2F),
      'buttonText': Color(0xFFFFFFFF),
      'bottomNavBackground': Color(0xFFFFFFFF),
      'bottomNavSelected': Color(0xFFD32F2F),
      'bottomNavUnselected': Color(0xFF9E9E9E),
      'indicatorColor': Color(0xFFD32F2F),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFFD32F2F),
      'titleColor': Color(0xFFB71C1C),
      'subtitleColor': Color(0xFFE53935),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFFFFCDD2),
      'buttonShadow': Color(0x30D32F2F),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFFD32F2F),
      'tagBackground': Color(0xFFEF5350),
      'tagTextOnPrimary': Color(0xFFFFFFFF),
      'tagBorder': Color(0xFFEF5350),
      'error': Color(0xFFD32F2F),
      'success': Color(0xFF2E7D32),
      'warning': Color(0xFFE65100),
      'highTemp': Color(0xFFD32F2F),
      'lowTemp': Color(0xFF1976D2),
      'sunrise': Color(0xFFEF5350),
      'sunset': Color(0xFFE91E63),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    darkColors: {
      'primary': Color(0xFFEF5350), // 玫瑰红
      'primaryDark': Color(0xFFE53935), // 更深的玫瑰红
      'accent': Color(0xFFFFCDD2), // 浅玫瑰色
      'background': Color(0xFF880E4F), // 深玫瑰背景
      'headerBackground': Color(0xFFAD1457),
      'headerBackgroundSecondary': Color(0xFF880E4F),
      'headerTextPrimary': Color(0xFFFFFFFF),
      'headerTextSecondary': Color(0xFFFFCDD2),
      'headerIconColor': Color(0xFFFFFFFF),
      'surface': Color(0xFFAD1457),
      'textPrimary': Color(0xFFFFFFFF),
      'textSecondary': Color(0xFFFFCDD2),
      'textTertiary': Color(0xFFF8BBD0),
      'border': Color(0xFFC2185B),
      'divider': Color(0xFFE91E63),
      'cardBackground': Color(0xFF880E4F),
      'cardBackgroundTransparent': Color(0x40FFFFFF),
      'buttonBackground': Color(0xFFEF5350),
      'buttonText': Color(0xFF880E4F),
      'bottomNavBackground': Color(0xFFAD1457),
      'bottomNavSelected': Color(0xFFEF5350),
      'bottomNavUnselected': Color(0xFFFFCDD2),
      'indicatorColor': Color(0xFFEF5350),
      'shadowColor': Color(0x00000000),
      'iconColor': Color(0xFFEF5350),
      'titleColor': Color(0xFFFFFFFF),
      'subtitleColor': Color(0xFFFFCDD2),
      'currentTag': Color(0xFFFFFFFF),
      'currentTagCardBackground': Color(0x40FFFFFF),
      'cardBorder': Color(0xFFC2185B),
      'buttonShadow': Color(0x30EF5350),
      'bottomNavSelectedBg': Colors.transparent,
      'bottomNavSelectedText': Color(0xFFEF5350),
      'tagBackground': Color(0xFFEF5350),
      'tagTextOnPrimary': Color(0xFF880E4F),
      'tagBorder': Color(0xFFEF5350),
      'error': Color(0xFFFF6B6B),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFB74D),
      'highTemp': Color(0xFFFF5722),
      'lowTemp': Color(0xFF64B5F6),
      'sunrise': Color(0xFFFFCC80),
      'sunset': Color(0xFFFF6B6B),
      'moon': Color(0xFFB39DDB),
      'sunIcon': Color(0xFFFFB300),
    },
    primaryGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFEF5350), // 玫瑰红
        Color(0xFFFFCDD2), // 浅玫瑰红渐变
      ],
    ),
    primaryGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFD32F2F), // 深红色
        Color(0xFFB71C1C), // 更深红色渐变
      ],
    ),
    headerGradientLight: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFD32F2F), // 主要头部背景 - 深红色
        Color(0xFFB71C1C), // 次要头部背景 - 更深的红色
      ],
      stops: [0.0, 1.0],
    ),
    headerGradientDark: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFD32F2F), // 深红色头部背景
        Color(0xFFAD1457), // 更深的玫瑰红
      ],
      stops: [0.0, 1.0],
    ),
  );

  /// 获取主题方案
  static ThemeColorScheme getScheme(AppThemeScheme scheme) {
    switch (scheme) {
      case AppThemeScheme.blue:
        return blue;
      case AppThemeScheme.green:
        return green;
      case AppThemeScheme.amber:
        return amber;
      case AppThemeScheme.teal:
        return teal;
      case AppThemeScheme.purple:
        return purple;
      case AppThemeScheme.rose:
        return rose;
    }
  }

  /// 获取所有主题方案
  static List<ThemeColorScheme> get allSchemes => [
    blue,
    green,
    amber,
    teal,
    purple,
    rose,
  ];
}
