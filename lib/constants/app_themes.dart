import 'package:flutter/material.dart';

/// 主题方案枚举
enum AppThemeScheme {
  blue, // 蓝色主题（当前默认）
  green, // 绿色主题
  purple, // 紫色主题
  orange, // 橙色主题
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

  /// 获取主题方案
  static ThemeColorScheme getScheme(AppThemeScheme scheme) {
    switch (scheme) {
      case AppThemeScheme.blue:
        return blue;
      case AppThemeScheme.green:
        return green;
      case AppThemeScheme.purple:
      case AppThemeScheme.orange:
        // 暂时使用蓝色主题占位，待实现
        return blue;
    }
  }

  // 临时占位（待实现紫色和橙色主题后移除）
  static ThemeColorScheme get purple => blue;
  static ThemeColorScheme get orange => blue;

  /// 获取所有主题方案
  static List<ThemeColorScheme> get allSchemes => [blue, green, purple, orange];
}

// TODO: 实现紫色和橙色主题
// const ThemeColorScheme purple = ...
// const ThemeColorScheme orange = ...
