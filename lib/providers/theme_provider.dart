import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_themes.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  AppThemeScheme _themeScheme = AppThemeScheme.blue;
  bool _isLightTheme = false;
  bool _isInitialized = false; // 添加初始化标记

  AppThemeMode get themeMode => _themeMode;
  AppThemeScheme get themeScheme => _themeScheme;
  bool get isLightTheme => _isLightTheme;
  bool get isInitialized => _isInitialized; // 暴露初始化状态

  ThemeProvider() {
    // 初始化默认主题状态
    _themeScheme = AppThemeScheme.blue; // 确保初始化为有效值
    _updateTheme();
    // 监听系统主题变化（添加防抖）
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      if (_themeMode == AppThemeMode.system && _isInitialized) {
        _updateTheme();
        notifyListeners();
      }
    };
    // 异步加载主题配置
    _loadThemeFromPrefs();
  }

  /// 切换主题方案
  void setThemeScheme(AppThemeScheme scheme) {
    _themeScheme = scheme;
    _saveThemeToPrefs();
    notifyListeners();
  }

  /// 获取当前主题的亮色配色
  Map<String, Color> get lightColors {
    try {
      return AppThemes.getScheme(_themeScheme).lightColors;
    } catch (e) {
      // 如果获取失败，返回蓝色主题的亮色配置
      return AppThemes.blue.lightColors;
    }
  }

  /// 获取当前主题的暗色配色
  Map<String, Color> get darkColors {
    try {
      return AppThemes.getScheme(_themeScheme).darkColors;
    } catch (e) {
      // 如果获取失败，返回蓝色主题的暗色配置
      return AppThemes.blue.darkColors;
    }
  }

  /// 获取颜色（从当前主题方案获取）
  Color getColor(String colorName) {
    try {
      final colorMap = _isLightTheme ? lightColors : darkColors;
      final color = colorMap[colorName];
      if (color != null) {
        return color;
      }
      // 如果找不到颜色，返回默认蓝色
      return const Color(0xFF4A90E2);
    } catch (e) {
      // 如果出现任何异常，返回默认蓝色
      return const Color(0xFF4A90E2);
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
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载主题模式
      final themeIndex = prefs.getInt('theme_mode') ?? 2; // 默认跟随系统
      if (themeIndex >= 0 && themeIndex < AppThemeMode.values.length) {
        _themeMode = AppThemeMode.values[themeIndex];
      }

      // 加载主题方案（添加边界检查）
      final schemeIndex = prefs.getInt('theme_scheme') ?? 0; // 默认蓝色主题
      if (schemeIndex >= 0 && schemeIndex < AppThemeScheme.values.length) {
        _themeScheme = AppThemeScheme.values[schemeIndex];
      } else {
        // 如果索引超出范围，重置为默认值
        _themeScheme = AppThemeScheme.blue;
        await prefs.setInt('theme_scheme', 0);
      }

      _updateTheme();
      // 标记初始化完成
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // 加载失败时使用默认值
      _themeMode = AppThemeMode.system;
      _themeScheme = AppThemeScheme.blue;
      _updateTheme();
      _isInitialized = true; // 即使失败也标记为已初始化
      notifyListeners();
    }
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

  /// 根据当前时间推荐主题
  AppThemeScheme _getRecommendedThemeByTime() {
    final hour = DateTime.now().hour;
    // 6:00-20:00 白天，20:00-6:00 夜晚
    if (hour >= 6 && hour < 20) {
      // 白天推荐亮色主题
      return AppThemeScheme.blue;
    } else {
      // 夜晚推荐暗色主题（深空黑）
      return AppThemeScheme.deepSpace;
    }
  }

  /// 根据天气状况推荐主题
  AppThemeScheme _getRecommendedThemeByWeather(String weatherCode) {
    // 天气代码：07小雨 08中雨 09大雨
    // 00晴 01多云 02阴 26雾
    final code = weatherCode;

    if (code == '07' ||
        code == '08' ||
        code == '09' ||
        code == '10' ||
        code == 'd07' ||
        code == 'n07' ||
        code == 'd08' ||
        code == 'n08' ||
        code == 'd09' ||
        code == 'n09' ||
        code == 'd10' ||
        code == 'n10') {
      // 雨天推荐青色系（Teal）
      return AppThemeScheme.teal;
    } else if (code == '00' || code == 'd00' || code == 'n00') {
      // 晴天推荐橙色系（Amber）
      return AppThemeScheme.amber;
    } else if (code == '26' || code == 'd26' || code == 'n26') {
      // 雾天推荐灰色系（深空黑）
      return AppThemeScheme.deepSpace;
    } else {
      // 默认推荐当前主题
      return _themeScheme;
    }
  }

  /// 获取推荐主题和理由
  Map<String, dynamic> getRecommendedTheme({String? weatherCode}) {
    AppThemeScheme recommendedScheme;
    String reason;

    if (weatherCode != null && weatherCode.isNotEmpty) {
      // 优先根据天气推荐
      recommendedScheme = _getRecommendedThemeByWeather(weatherCode);
      final weatherName = _getWeatherName(weatherCode);
      reason =
          '当前${weatherName}，推荐"${AppThemes.getScheme(recommendedScheme).name}"主题';
    } else {
      // 根据时间推荐
      recommendedScheme = _getRecommendedThemeByTime();
      final hour = DateTime.now().hour;
      if (hour >= 6 && hour < 12) {
        reason = '当前早晨时段，推荐"${AppThemes.getScheme(recommendedScheme).name}"主题';
      } else if (hour >= 12 && hour < 18) {
        reason = '当前下午时段，推荐"${AppThemes.getScheme(recommendedScheme).name}"主题';
      } else {
        reason = '当前夜晚时段，推荐"${AppThemes.getScheme(recommendedScheme).name}"主题';
      }
    }

    final isSameAsCurrent = recommendedScheme == _themeScheme;

    return {
      'scheme': recommendedScheme,
      'reason': reason,
      'isCurrent': isSameAsCurrent,
    };
  }

  /// 获取天气名称
  String _getWeatherName(String weatherCode) {
    final code = weatherCode.toUpperCase();
    if (code.contains('07') || code.contains('D07') || code.contains('N07')) {
      return '小雨';
    } else if (code.contains('08') ||
        code.contains('D08') ||
        code.contains('N08')) {
      return '中雨';
    } else if (code.contains('09') ||
        code.contains('D09') ||
        code.contains('N09')) {
      return '大雨';
    } else if (code.contains('10') ||
        code.contains('D10') ||
        code.contains('N10')) {
      return '暴雨';
    } else if (code.contains('00') ||
        code.contains('D00') ||
        code.contains('N00')) {
      return '晴天';
    } else if (code.contains('26') ||
        code.contains('D26') ||
        code.contains('N26')) {
      return '雾';
    } else {
      return '多云';
    }
  }
}
