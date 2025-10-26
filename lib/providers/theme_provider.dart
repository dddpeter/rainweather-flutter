import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_themes.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  AppThemeScheme _themeScheme = AppThemeScheme.blue;
  bool _isLightTheme = false;

  AppThemeMode get themeMode => _themeMode;
  AppThemeScheme get themeScheme => _themeScheme;
  bool get isLightTheme => _isLightTheme;

  ThemeProvider() {
    // 初始化默认主题状态
    _updateTheme();
    _loadThemeFromPrefs();
    // 监听系统主题变化
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
          if (_themeMode == AppThemeMode.system) {
            _updateTheme();
            notifyListeners();
          }
        };
  }

  /// 切换主题方案
  void setThemeScheme(AppThemeScheme scheme) {
    _themeScheme = scheme;
    _saveThemeToPrefs();
    notifyListeners();
  }

  /// 获取当前主题的亮色配色
  Map<String, Color> get lightColors {
    return AppThemes.getScheme(_themeScheme).lightColors;
  }

  /// 获取当前主题的暗色配色
  Map<String, Color> get darkColors {
    return AppThemes.getScheme(_themeScheme).darkColors;
  }

  /// 获取颜色（从当前主题方案获取）
  Color getColor(String colorName) {
    try {
      return _isLightTheme ? lightColors[colorName]! : darkColors[colorName]!;
    } catch (e) {
      return darkColors[colorName] ?? const Color(0xFF4A90E2);
    }
  }

  /// 获取主渐变（根据当前主题方案动态获取）
  LinearGradient get primaryGradient {
    final scheme = AppThemes.getScheme(_themeScheme);
    return scheme.getPrimaryGradient(_isLightTheme);
  }

  /// 获取头部渐变（根据当前主题方案动态获取）
  LinearGradient get headerGradient {
    final scheme = AppThemes.getScheme(_themeScheme);
    return scheme.getHeaderGradient(_isLightTheme);
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
        _isLightTheme =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.light;
        break;
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载主题模式
    final themeIndex = prefs.getInt('theme_mode') ?? 2; // 默认跟随系统
    _themeMode = AppThemeMode.values[themeIndex];

    // 加载主题方案
    final schemeIndex = prefs.getInt('theme_scheme') ?? 0; // 默认蓝色主题
    _themeScheme = AppThemeScheme.values[schemeIndex];

    _updateTheme();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
    await prefs.setInt('theme_scheme', _themeScheme.index);
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
