import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isLightTheme = false;

  AppThemeMode get themeMode => _themeMode;
  bool get isLightTheme => _isLightTheme;

  ThemeProvider() {
    // 初始化默认主题状态
    _updateTheme();
    _loadThemeFromPrefs();
    // 监听系统主题变化
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themeMode == AppThemeMode.system) {
        _updateTheme();
        notifyListeners();
      }
    };
  }

  // 亮色主题配色 - 基于#8edafc亮蓝色
  static const Map<String, Color> lightColors = {
    'primary': Color(0xFF012d78), // 深蓝色主色
    'primaryDark': Color(0xFF001A4D), // 更深的蓝色
    'accent': Color(0xFF8edafc), // 指定的亮蓝色
    'background': Color(0xFFF0F8FF), // 基于#8edafc的浅蓝背景
    'surface': Color(0xFFFFFFFF), // 纯白表面
    'textPrimary': Color(0xFF001A4D), // 深蓝色文字，高对比度
    'textSecondary': Color(0xFF003366), // 深蓝色次要文字
    'textTertiary': Color(0xFF4A5568), // 中等深度的文字
    'border': Color(0xFFB8D9F5), // 基于#8edafc的浅边框
    'glassBackground': Color(0x20FFFFFF), // 亮色半透明
    'cardBackground': Color(0xFFFFFFFF), // 纯白卡片背景
    'currentTagCardBackground': Color(0xFFE3F2FD), // 当前tag卡片背景（浅蓝色）
    'cardBorder': Color(0xFFE1F5FE), // 浅蓝边框
    'buttonShadow': Color(0x15000000), // 浅阴影
    'bottomNavSelectedBg': Colors.transparent, // 底部导航选中背景（透明）
    'bottomNavSelectedText': Color(0xFF8edafc), // 底部导航选中文字颜色（浅蓝色）
    'tagBackground': Color(0xFFE8F5E8), // 标签背景色（灰色偏绿）
    'tagTextOnPrimary': Color(0xFF1976D2), // 主色背景上的标签文字（深蓝色）
    'tagBorder': Color(0xFF1976D2), // 标签边框色（深蓝色）
    'error': Color(0xFFD32F2F), // 错误色
    'success': Color(0xFF2E7D32), // 成功色
    'warning': Color(0xFFE65100), // 警告色
    'highTemp': Color(0xFFD32F2F), // 高温色
    'lowTemp': Color(0xFF8edafc), // 使用指定的亮蓝色
    'currentTag': Color(0xFFFFFFFF), // 当前tag颜色（白色文字）
    'currentTagBackground': Color(0xFFE53E3E), // 当前tag背景色（红色不透明）
    'currentTagBorder': Color(0xFFE53E3E), // 当前tag边框色（红色不透明）
    // 日出日落颜色 - 亮色主题
    'sunrise': Color(0xFFFF9800), // 鲜艳的日出橙色
    'sunset': Color(0xFFC2185B), // 深红色日落
    'moon': Color(0xFF673AB7), // 深紫色月亮
  };

  // 暗色主题配色 - 基于#012d78深蓝色
  static const Map<String, Color> darkColors = {
    'primary': Color(0xFF4A90E2), // 基于#012d78的亮蓝色
    'primaryDark': Color(0xFF012d78), // 指定的深蓝色
    'accent': Color(0xFF8edafc), // 指定的亮蓝色
    'background': Color(0xFF0A1B3D), // 基于#012d78的深背景
    'surface': Color(0xFF1A2F5D), // 基于#012d78的稍亮表面
    'textPrimary': Color(0xFFFFFFFF), // 纯白色文字
    'textSecondary': Color(0xFFE8F4FD), // 接近#8edafc的亮色文字
    'textTertiary': Color(0xFFB8D9F5), // 中等亮度的文字
    'border': Color(0xFF2D4A7D), // 基于主色的边框
    'glassBackground': Color(0x30FFFFFF),
    'cardBackground': Color(0x25FFFFFF), // 半透明白色卡片
    'currentTagCardBackground': Color(0x40FFFFFF), // 当前tag卡片背景（更亮的半透明）
    'cardBorder': Color(0x35FFFFFF), // 卡片边框
    'buttonShadow': Color(0x30000000),
    'bottomNavSelectedBg': Colors.transparent, // 底部导航选中背景（透明）
    'bottomNavSelectedText': Color(0x80FFFFFF), // 底部导航选中文字颜色（半透明白色）
    'tagBackground': Color(0xFF4A90E2), // 标签背景色（亮蓝色）
    'tagTextOnPrimary': Color(0xFFE8F4FD), // 主色背景上的标签文字（浅蓝色）
    'tagBorder': Color(0xFF4A90E2), // 标签边框色（亮蓝色）
    'error': Color(0xFFFF6B6B), // 错误色
    'success': Color(0xFF4CAF50), // 成功色
    'warning': Color(0xFFFFB74D), // 警告色
    'highTemp': Color(0xFFFF5722),
    'lowTemp': Color(0xFF8edafc), // 使用指定的亮蓝色
    'currentTag': Color(0xFFFFFFFF), // 当前tag颜色（白色文字）
    'currentTagBackground': Color(0xFF4A90E2), // 当前tag背景色（亮蓝色不透明）
    'currentTagBorder': Color(0xFF4A90E2), // 当前tag边框色（亮蓝色不透明）
    // 日出日落颜色 - 暗色主题
    'sunrise': Color(0xFFFFB74D), // 明亮的日出黄色
    'sunset': Color(0xFFE91E63), // 深红色日落
    'moon': Color(0xFFB39DDB), // 柔和的月光紫色
  };

  Color getColor(String colorName) {
    try {
      return _isLightTheme ? lightColors[colorName]! : darkColors[colorName]!;
    } catch (e) {
      // 如果出现异常，返回默认的暗色主题颜色
      return darkColors[colorName] ?? const Color(0xFF4A90E2);
    }
  }

  LinearGradient get primaryGradient {
    if (_isLightTheme) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8edafc), // 指定的亮蓝色
          Color(0xFFE1F5FE), // 浅蓝色渐变
        ],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF012d78), // 指定的深蓝色
          Color(0xFF0A1B3D), // 基于深蓝色的渐变
        ],
      );
    }
  }

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _updateTheme();
    _saveThemeToPrefs();
    notifyListeners();
  }

  void _updateTheme() {
    switch (_themeMode) {
      case AppThemeMode.light:
        _isLightTheme = true;
        break;
      case AppThemeMode.dark:
        _isLightTheme = false;
        break;
      case AppThemeMode.system:
        // 检测系统主题
        _isLightTheme = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
        break;
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 2; // 默认跟随系统
    _themeMode = AppThemeMode.values[themeIndex];
    _updateTheme();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
  }

  String getThemeModeText() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return '亮色主题';
      case AppThemeMode.dark:
        return '暗色主题';
      case AppThemeMode.system:
        return '跟随系统';
    }
  }
}
