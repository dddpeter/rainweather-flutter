import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'theme_extensions.dart';

/// 应用颜色配置 - 支持亮色和暗色主题
///
/// 使用指南：
/// 1. 新代码推荐使用: context.appTheme.textPrimary
/// 2. 旧代码兼容使用: AppColors.textPrimary (需要 setThemeProvider)
/// 3. 静态方法: AppColors.of(context).textPrimary
class AppColors {
  static ThemeProvider? _themeProvider;
  static bool _listenerAdded = false;

  /// 从 BuildContext 获取主题扩展（推荐的新方式）
  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>() ??
        AppThemeExtension.dark();
  }

  static void setThemeProvider(ThemeProvider provider) {
    if (_themeProvider != provider) {
      // 移除旧的监听器
      if (_themeProvider != null && _listenerAdded) {
        _themeProvider!.removeListener(_onThemeChanged);
        _listenerAdded = false;
      }
      _themeProvider = provider;
      // 添加新的监听器
      if (!_listenerAdded) {
        provider.addListener(_onThemeChanged);
        _listenerAdded = true;
      }
    }
  }

  static void _onThemeChanged() {
    // 当主题变化时，强制重建所有使用AppColors的Widget
    // 这通过notifyListeners()在ThemeProvider中已经处理了
  }

  static Color _getColor(String colorName) {
    try {
      if (_themeProvider != null) {
        return _themeProvider!.getColor(colorName);
      }
      // Fallback to dark theme colors when theme provider is not initialized
      return darkColors[colorName] ?? const Color(0xFF4A90E2);
    } catch (e) {
      // 如果出现任何异常，返回默认颜色
      return darkColors[colorName] ?? const Color(0xFF4A90E2);
    }
  }

  // 暗色主题配色（默认）- 基于#012d78深蓝色
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
    'currentTag': Color(0xFFFFFFFF), // 当前tag颜色（白色文字）
    'currentTagBackground': Color(0xFF4A90E2), // 当前tag背景色（亮蓝色不透明）
    'currentTagBorder': Color(0xFF4A90E2), // 当前tag边框色（亮蓝色不透明）
    'error': Color(0xFFFF6B6B), // 错误色
    'success': Color(0xFF4CAF50), // 成功色
    'warning': Color(0xFFFFB74D), // 警告色
    'highTemp': Color(0xFFFF5722),
    'lowTemp': Color(0xFF8edafc), // 使用指定的亮蓝色
    // 日出日落颜色 - 暗色主题
    'sunrise': Color(0xFFFFB74D), // 明亮的日出黄色
    'sunset': Color(0xFF1976D2), // 深蓝色日落
    'sunIcon': Color(0xFFFFFFFF), // 白色太阳图标（深色模式）
    'moon': Color(0xFFB39DDB), // 柔和的月光紫色
  };

  // 亮色主题配色 - 基于#8edafc亮蓝色
  static const Map<String, Color> lightColors = {
    'primary': Color(0xFF012d78), // 深蓝色主色
    'primaryDark': Color(0xFF001A4D), // 更深的蓝色
    'accent': Color(0xFF8edafc), // 指定的亮蓝色
    'background': Color(0xFFF0F8FF), // 基于#8edafc的浅蓝背景
    'surface': Color(0xFFFFFFFF), // 纯白表面
    'textPrimary': Color(0xFF001A4D), // 深蓝色文字，高对比度
    'textSecondary': Color(0xFF003366), // 深蓝色次要文字
    'textTertiary': Color(0xFF6B7280), // 较浅的文字，用于未激活状态
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
    'currentTag': Color(0xFFFFFFFF), // 当前tag颜色（白色文字）
    'currentTagBackground': Color(0xFFE53E3E), // 当前tag背景色（红色不透明）
    'currentTagBorder': Color(0xFFE53E3E), // 当前tag边框色（红色不透明）
    'error': Color(0xFFD32F2F), // 错误色
    'success': Color(0xFF2E7D32), // 成功色
    'warning': Color(0xFFE65100), // 警告色
    'highTemp': Color(0xFFD32F2F), // 高温色
    'lowTemp': Color(0xFF8edafc), // 使用指定的亮蓝色
    // 日出日落颜色 - 亮色主题
    'sunrise': Color(0xFFFF9800), // 鲜艳的日出橙色
    'sunset': Color(0xFF1565C0), // 深蓝色日落（亮色模式稍深）
    'sunIcon': Color(0xFFE53935), // 红色太阳图标（浅色模式）
    'moon': Color(0xFF673AB7), // 深紫色月亮
  };
  // 主题化颜色 - 动态获取
  /// 主色调
  static Color get primaryBlue => _getColor('primary');

  /// 文字颜色
  static Color get textPrimary => _getColor('textPrimary');

  /// 次要文字颜色
  static Color get textSecondary => _getColor('textSecondary');

  /// 辅助文字颜色
  static Color get textTertiary => _getColor('textTertiary');

  /// 强调色
  static Color get accentBlue => _getColor('accent');

  /// 成功色
  static Color get success => _getColor('success');

  /// 警告色
  static Color get warning => _getColor('warning');

  /// 错误色
  static Color get error => _getColor('error');

  /// 边框颜色
  static Color get borderColor => _getColor('border');

  /// 玻璃效果背景色
  static Color get glassBackground => _getColor('glassBackground');

  /// 卡片背景色
  static Color get cardBackground => _getColor('cardBackground');

  /// 当前tag卡片背景色
  static Color get currentTagCardBackground =>
      _getColor('currentTagCardBackground');

  /// 卡片边框色
  static Color get cardBorder => _getColor('cardBorder');

  /// 按钮阴影
  static Color get buttonShadow => _getColor('buttonShadow');

  /// 高温色
  static Color get highTemp => _getColor('highTemp');

  /// 低温色
  static Color get lowTemp => _getColor('lowTemp');

  /// 背景色
  static Color get backgroundPrimary => _getColor('background');

  /// 次背景色
  static Color get backgroundSecondary => _getColor('surface');

  /// 强调绿色
  static Color get accentGreen => _getColor('success');

  /// 分割线颜色
  static Color get dividerColor => _getColor('border');

  /// 信息色
  static Color get info => _getColor('primary');

  /// 日出颜色
  static Color get sunrise => _getColor('sunrise');

  /// 日落颜色
  static Color get sunset => _getColor('sunset');

  /// 太阳图标颜色（深色模式白色，浅色模式红色）
  static Color get sunIcon => _getColor('sunIcon');

  /// 月亮颜色
  static Color get moon => _getColor('moon');

  /// 标签背景颜色
  static Color get tagBackground => _getColor('tagBackground');

  /// 主色背景上的标签文字颜色
  static Color get tagTextOnPrimary => _getColor('tagTextOnPrimary');

  /// 标签边框颜色
  static Color get tagBorder => _getColor('tagBorder');

  /// 当前tag颜色
  static Color get currentTag => _getColor('currentTag');

  /// 当前tag背景颜色
  static Color get currentTagBackground => _getColor('currentTagBackground');

  /// 当前tag边框颜色
  static Color get currentTagBorder => _getColor('currentTagBorder');

  // 公共图标样式
  /// 标题栏图标样式
  static const double titleBarIconSize = 24.0;
  static Color get titleBarIconColor => _getColor('textSecondary');

  /// 标题栏图标样式（用于装饰图标）
  static const double titleBarDecorIconSize = 20.0;
  static Color get titleBarDecorIconColor => _getColor('textSecondary');

  // 底部导航栏样式
  /// 底部导航栏激活状态颜色
  static Color get bottomNavSelectedColor => _getColor('bottomNavSelectedText');

  /// 底部导航栏未激活状态颜色
  static Color get bottomNavUnselectedColor => _getColor('textTertiary');

  /// 底部导航栏选中项目背景颜色
  static Color get bottomNavSelectedBackground =>
      _getColor('bottomNavSelectedBg');

  /// 底部导航栏未选中项目背景颜色
  static Color get bottomNavUnselectedBackground => Colors.transparent;

  // 公共卡片样式
  /// 标准卡片装饰
  static BoxDecoration get standardCardDecoration => BoxDecoration(
    color: _getColor('cardBackground'),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 紧凑卡片装饰（用于小卡片）
  static BoxDecoration get compactCardDecoration => BoxDecoration(
    color: _getColor('cardBackground'),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 小型卡片装饰（用于标签等）
  static BoxDecoration get smallCardDecoration => BoxDecoration(
    color: _getColor('cardBackground'),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 24小时小卡片装饰（使用主题色渐变边框）
  static BoxDecoration get hourlySmallCardDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [_getColor('cardBackground'), _getColor('cardBackground')],
      stops: const [0.0, 1.0],
    ),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _getColor('primary'), width: 1.5),
  );

  /// 玻璃效果卡片装饰（用于24小时页面的风格）
  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: _getColor('glassBackground'),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 带阴影的卡片装饰
  static BoxDecoration get shadowCardDecoration => BoxDecoration(
    color: _getColor('cardBackground'),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
    boxShadow: [
      BoxShadow(
        color: _getColor('buttonShadow'),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ==================== Material Design 卡片样式 ====================

  /// Material 卡片的 elevation（根据主题调整）
  static double get cardElevation =>
      _themeProvider?.isLightTheme == true ? 1 : 2;

  /// Material 卡片的形状
  static RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  /// 小卡片的形状
  static RoundedRectangleBorder get smallCardShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  /// Material 卡片的颜色（使用 cardBackground）
  static Color get materialCardColor => _getColor('cardBackground');

  /// Material 卡片的阴影颜色（亮色主题用淡色，暗色主题用深色）
  static Color get cardShadowColor => _themeProvider?.isLightTheme == true
      ? Colors.black.withOpacity(0.1)
      : Colors.black.withOpacity(0.3);

  // 公共弹窗样式
  /// 标准弹窗装饰
  static BoxDecoration get dialogDecoration => BoxDecoration(
    color: _getColor('surface'),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _getColor('border'), width: 1),
    boxShadow: [
      BoxShadow(
        color: _getColor('buttonShadow').withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: _getColor('buttonShadow').withOpacity(0.1),
        blurRadius: 40,
        offset: const Offset(0, 16),
      ),
    ],
  );

  /// 弹窗形状
  static ShapeBorder get dialogShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: _getColor('border'), width: 1),
  );

  // 主题化渐变色
  /// 主背景渐变
  static LinearGradient get primaryGradient {
    try {
      if (_themeProvider != null) {
        return _themeProvider!.primaryGradient;
      }
      // Fallback to dark theme gradient when theme provider is not initialized
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF012d78), Color(0xFF0A1B3D)],
      );
    } catch (e) {
      // 如果出现任何异常，返回默认渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF012d78), Color(0xFF0A1B3D)],
      );
    }
  }

  // 天气相关颜色（固定颜色，不随主题变化）
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

  // 空气质量颜色（固定颜色，不随主题变化）
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
}
