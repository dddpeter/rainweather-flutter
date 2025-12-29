import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../providers/theme_provider.dart';
import 'theme_extensions.dart';

/// 颜色对比度工具
class ColorContrast {
  /// 计算相对亮度
  static double _luminance(Color color) {
    final r = _linearize(color.red / 255);
    final g = _linearize(color.green / 255);
    final b = _linearize(color.blue / 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double colorChannel) {
    if (colorChannel <= 0.03928) {
      return colorChannel / 12.92;
    } else {
      return math.pow((colorChannel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// 计算对比度 (WCAG标准)
  static double contrast(Color foreground, Color background) {
    final fgLum = _luminance(foreground);
    final bgLum = _luminance(background);
    final lighter = math.max(fgLum, bgLum);
    final darker = math.min(fgLum, bgLum);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 检查是否满足WCAG AA标准 (4.5:1)
  static bool meetsAA(Color foreground, Color background) {
    return contrast(foreground, background) >= 4.5;
  }

  /// 检查是否满足WCAG AAA标准 (7:1)
  static bool meetsAAA(Color foreground, Color background) {
    return contrast(foreground, background) >= 7.0;
  }

  /// 自动选择合适的文字颜色（黑或白）
  static Color autoTextColor(Color background) {
    const white = Colors.white;
    const black = Color(0xFF1A1A1A);
    return contrast(white, background) > contrast(black, background) ? white : black;
  }
}

/// AI配色方案 - 统一所有AI功能的配色
class AIColorScheme {
  // 琥珀金系 - 主要AI功能
  static const Color aiGoldDark = Color(0xFFFF8F00);
  static const Color aiGoldMedium = Color(0xFFFFA726);
  static const Color aiGoldLight = Color(0xFFFFCC80);
  static const Color aiGoldLighter = Color(0xFFFFE082);

  // 深琥珀金系 - 用于文字和图标
  static const Color aiGoldTextDark = Color(0xFF4E342E);
  static const Color aiGoldTextMedium = Color(0xFF5D4037);
  static const Color aiGoldTextLight = Color(0xFF6D4C41);

  // AI标签颜色
  static const Color aiLabelLight = Color(0xFFFF8F00);
  static const Color aiLabelDark = Color(0xFFFFB300);

  /// 获取AI渐变（已优化对比度）
  static LinearGradient getAIGradient(bool isLight) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLight
          ? [aiGoldLighter, aiGoldLight, aiGoldMedium]
          : [aiGoldDark, aiGoldMedium, aiGoldLight],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// 获取AI文字颜色（优化对比度）
  static Color getAITextColor(bool isLight) {
    return isLight ? aiGoldTextDark : aiGoldTextMedium;
  }

  /// 获取AI图标颜色
  static Color getAIIconColor(bool isLight) {
    return getAITextColor(isLight);
  }

  /// 获取AI标签颜色
  static Color getAILabelColor(bool isLight) {
    return isLight ? aiLabelLight : aiLabelDark;
  }

  /// AI渐变透明度
  static const double gradientOpacity = 0.8;

  /// AI标签背景透明度
  static const double labelBgOpacity = 0.15;

  /// 标签边框透明度
  static const double labelBorderOpacity = 0.3;
}

/// 语义化颜色层级
class AppColorShades {
  // 主色层级 - 蓝色系
  static const Color primary50 = Color(0xFFE3F2FD);
  static const Color primary100 = Color(0xFFBBDEFB);
  static const Color primary200 = Color(0xFF90CAF9);
  static const Color primary300 = Color(0xFF64B5F6);
  static const Color primary400 = Color(0xFF42A5F5);
  static const Color primary500 = Color(0xFF2196F3);
  static const Color primary600 = Color(0xFF1E88E5);
  static const Color primary700 = Color(0xFF1976D2);
  static const Color primary800 = Color(0xFF1565C0);
  static const Color primary900 = Color(0xFF0D47A1);

  // 绿色层级
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);

  // 橙色层级
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange200 = Color(0xFFFFCC80);
  static const Color orange300 = Color(0xFFFFB74D);
  static const Color orange400 = Color(0xFFFFA726);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color orange600 = Color(0xFFFF8F00);
  static const Color orange700 = Color(0xFFFF6F00);

  // 金色层级
  static const Color gold100 = Color(0xFFFFF8E1);
  static const Color gold200 = Color(0xFFFFECB3);
  static const Color gold300 = Color(0xFFFFD54F);
  static const Color gold400 = Color(0xFFFFCA28);
  static const Color gold500 = Color(0xFFFFC107);
  static const Color gold600 = Color(0xFFFFB300);
  static const Color gold700 = Color(0xFFFFA000);
  static const Color gold800 = Color(0xFFFF8F00);
  static const Color gold900 = Color(0xFFFF6F00);

  // 红色层级
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red300 = Color(0xFFE57373);
  static const Color red400 = Color(0xFFEF5350);
  static const Color red500 = Color(0xFFF44336);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);

  /// 根据背景自动选择合适的主色层级
  static Color getPrimaryForBackground(bool isLight, bool isCard) {
    if (isLight) {
      return isCard ? primary700 : primary900;
    } else {
      return isCard ? primary300 : primary200;
    }
  }

  /// 根据背景选择绿色
  static Color getGreenForBackground(bool isLight) {
    return isLight ? green600 : green400;
  }

  /// 根据背景选择橙色
  static Color getOrangeForBackground(bool isLight) {
    return isLight ? orange600 : orange400;
  }
}

/// 应用颜色配置 - 支持亮色和暗色主题
///
/// ⚠️ 重要：颜色定义已迁移到 ThemeProvider
/// - ThemeProvider 是唯一颜色来源，定义了所有主题颜色
/// - AppColors 只提供便捷的 getter 方法
/// - 推荐新代码使用: context.appTheme.textPrimary
/// - 兼容旧代码: AppColors.textPrimary (需要 setThemeProvider)
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
      // Fallback: 返回默认蓝色主题的暗色配色
      const fallbackColors = {
        'primary': Color(0xFF4A90E2),
        'accent': Color(0xFF8edafc),
        'textPrimary': Color(0xFFFFFFFF),
        'textSecondary': Color(0xFFE8F4FD),
        'textTertiary': Color(0xFFB8D9F5),
        'cardBackground': Color(0x25FFFFFF),
        'cardBorder': Color(0x35FFFFFF),
      };
      return fallbackColors[colorName] ?? const Color(0xFF4A90E2);
    } catch (e) {
      // 如果出现任何异常，返回默认颜色
      return const Color(0xFF4A90E2);
    }
  }

  // ==================== ⚠️ 固定颜色（不建议删除）====================
  // 以下颜色为固定颜色，不受主题系统影响，保留原设计语义
  // 标记：NEVER_DELETE - 固定颜色，不应该主题化
  //
  // 1. 卡片背景色 - 与主题背景配合使用的固定颜色
  // 2. 温度色 - 语义化颜色（高温红色、低温蓝色）
  // 3. 天气色 - 天气现象的固定表示
  // 4. 空气质量色 - 国家标准的固定色阶
  // 5. 小卡片专用色 - UI层次结构固定色

  /// 亮色模式卡片背景 - 暖白色（淡粉米白，不透明）
  // NEVER_DELETE - 卡片背景固定色
  static const Color lightCardBackground = Color(0xFFFDF7F7); // #FDF7F7

  /// 暗色模式卡片背景 - 半透明白色
  // NEVER_DELETE - 卡片背景固定色
  static const Color darkCardBackground = Color(0x30FFFFFF); // 白色 透明度

  /// 今日天气和城市天气页面头部大卡片背景 - 固定深蓝色（不区分亮暗模式）
  // NEVER_DELETE - 页面头部固定背景色
  static const Color weatherHeaderCardBackground = Color(
    0xFF0A1B3D,
  ); // 深蓝色，固定不变

  // 所有颜色现在从 ThemeProvider 读取，不再维护重复定义
  // ThemeProvider 是唯一颜色来源
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

  /// 高温色 - 深色模式使用橙红色，浅色模式使用红色
  static Color get highTemp => _themeProvider?.isLightTheme == true
      ? const Color(0xFFD32F2F) // 浅色模式：红色
      : const Color(0xFFFF5722); // 深色模式：橙红色

  /// 低温色 - 深色模式使用亮蓝色，浅色模式使用主题蓝色
  static Color get lowTemp => _themeProvider?.isLightTheme == true
      ? const Color(0xFF012d78) // 浅色模式：主题蓝色
      : const Color(0xFF8edafc); // 深色模式：亮蓝色

  /// 温度图表色 - 深色模式使用亮蓝色，浅色模式使用主题蓝色
  static Color get temperatureChart => _themeProvider?.isLightTheme == true
      ? const Color(0xFF012d78) // 浅色模式：主题蓝色
      : const Color(0xFF8edafc); // 深色模式：亮蓝色

  /// 背景色
  static Color get backgroundPrimary => _getColor('background');

  /// 次背景色
  static Color get backgroundSecondary => _getColor('surface');

  /// AppBar 和底部导航背景色 - 与 Drawer 头部背景色一致
  /// 使用 backgroundSecondary，确保文字图标清晰可见
  static Color get appBarBackground => backgroundSecondary;

  /// 强调绿色
  static Color get accentGreen => _getColor('success');

  /// 详细信息卡片专用绿色 - 根据主题模式调整亮度
  static Color get detailCardGreen => _themeProvider?.isLightTheme == true
      ? const Color(0xFF4CAF50) // 亮色模式：一般绿色
      : const Color(0xFF66BB6A); // 暗色模式：亮一些的绿色

  /// 卡片内部图标颜色 - 深色模式使用亮色，浅色模式使用深色
  static Color get cardIconColor => _themeProvider?.isLightTheme == true
      ? const Color(0xFF2E7D32) // 亮色模式：深绿色，在浅色背景上清晰可见
      : const Color(0xFF81C784); // 暗色模式：亮绿色，在深色背景上清晰可见

  /// 卡片内部图标背景颜色 - 根据主题模式调整透明度
  static Color get cardIconBackgroundColor =>
      _themeProvider?.isLightTheme == true
      ? const Color(0xFF2E7D32).withOpacity(0.15) // 亮色模式：深绿色背景
      : const Color(0xFF81C784).withOpacity(0.25); // 暗色模式：亮绿色背景

  /// 卡片主题蓝色 - 深色模式使用亮些的蓝色，浅色模式使用主题蓝色
  static Color get cardThemeBlue => _themeProvider?.isLightTheme == true
      ? const Color(0xFF012d78) // 亮色模式：主题蓝色
      : const Color(0xFF4A90E2); // 暗色模式：亮蓝色

  /// 卡片主题蓝色背景 - 根据主题模式调整透明度
  static Color get cardThemeBlueBackground =>
      _themeProvider?.isLightTheme == true
      ? const Color(0xFF012d78).withOpacity(0.15) // 亮色模式：主题蓝色背景
      : const Color(0xFF4A90E2).withOpacity(0.25); // 暗色模式：亮蓝色背景

  /// 卡片主题蓝色图标颜色 - 深色模式使用亮些的蓝色，浅色模式使用深蓝色
  static Color get cardThemeBlueIconColor =>
      _themeProvider?.isLightTheme == true
      ? const Color(0xFF001A4D) // 亮色模式：深蓝色图标
      : const Color.fromARGB(255, 159, 206, 244); // 暗色模式：更亮的蓝色图标

  /// 卡片主题蓝色图标背景颜色 - 根据主题模式调整透明度
  static Color get cardThemeBlueIconBackgroundColor =>
      _themeProvider?.isLightTheme == true
      ? const Color(0xFF001A4D).withOpacity(0.15) // 亮色模式：深蓝色图标背景
      : const Color(0xFF90CAF9).withOpacity(0.25); // 暗色模式：更亮的蓝色图标背景

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
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 紧凑卡片装饰（用于小卡片）
  static BoxDecoration get compactCardDecoration => BoxDecoration(
    color: _getColor('cardBackground'),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 小型卡片装饰（用于标签等）
  static BoxDecoration get smallCardDecoration => BoxDecoration(
    color: _getColor('cardBackground'),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 24小时小卡片装饰（使用主题色渐变边框）
  static BoxDecoration get hourlySmallCardDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [_getColor('cardBackground'), _getColor('cardBackground')],
      stops: const [0.0, 1.0],
    ),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: _getColor('primary'), width: 1.5),
  );

  /// 玻璃效果卡片装饰（用于24小时页面的风格）
  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: _getColor('glassBackground'),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _getColor('cardBorder'), width: 1),
  );

  /// 带阴影的卡片装饰
  static BoxDecoration get shadowCardDecoration => BoxDecoration(
    color: _getColor('cardBackground'),
    borderRadius: BorderRadius.circular(8),
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

  /// 卡片外层左右 margin - 与 AppConstants.screenHorizontalPadding 保持一致（12.0）
  static const double cardHorizontalMargin =
      12.0; // 已在 AppConstants.screenHorizontalPadding 定义

  /// 卡片之间的上下间距 - Material Design 3 推荐的最小间距
  static const double cardSpacing = 12.0;

  /// 卡片间距Widget - 用于大卡片之间的标准间距
  static Widget get cardSpacingWidget => const SizedBox(height: cardSpacing);

  /// 大卡片内部 padding - 标准内边距（详细信息、空气质量、图表等）
  static const double cardInnerPadding = 16.0;

  /// 图表卡片内部 padding - 为图表留更多空间（温度趋势、15日图表等）
  static const double chartCardInnerPadding = 12.0;

  /// Material 卡片的 elevation（根据主题调整）
  static double get cardElevation =>
      _themeProvider?.isLightTheme == true ? 2 : 2; // 亮色模式也使用 2，增强边缘可见性

  /// Material 卡片的形状
  static RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

  /// 小卡片的形状
  static RoundedRectangleBorder get smallCardShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));

  /// Material 卡片的颜色（根据主题返回对应的卡片背景色）
  static Color get materialCardColor => _themeProvider?.isLightTheme == true
      ? const Color(0xFFF8FAFF) // 亮色模式：带轻微蓝色调的白色背景
      : darkCardBackground; // 暗色模式：半透明白色

  /// Material 卡片的阴影颜色（亮色主题用淡色，暗色主题用深色）
  static Color get cardShadowColor => _themeProvider?.isLightTheme == true
      ? Colors.black.withOpacity(0.15) // 亮色模式：增强阴影，提高边缘可见性
      : Colors.black.withOpacity(0.3);

  // 公共弹窗样式
  /// 标准弹窗装饰
  static BoxDecoration get dialogDecoration => BoxDecoration(
    color: _getColor('surface'),
    borderRadius: BorderRadius.circular(8),
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
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: _getColor('border'), width: 1),
  );

  // 主题化渐变色
  /// 主背景渐变（AppBar 和抽屉头部使用，随主题方案切换）
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

  /// Screen背景渐变（固定蓝色，只随亮暗模式切换，不随主题方案变化）
  static LinearGradient get screenBackgroundGradient {
    try {
      if (_themeProvider != null) {
        final isLight = _themeProvider!.isLightTheme;
        // 固定蓝色渐变，只随亮暗模式切换
        return isLight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F5F5), // 浅灰色
                  Color(0xFFEEEEEE), // 稍深的浅灰色
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF012d78), // 指定的深蓝色
                  Color(0xFF0A1B3D), // 基于深蓝色的渐变
                ],
              );
      }
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF012d78), Color(0xFF0A1B3D)],
      );
    } catch (e) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF012d78), Color(0xFF0A1B3D)],
      );
    }
  }

  // ==================== 天气相关颜色（NEVER_DELETE）====================
  // 天气现象的语义化颜色，固定不变
  /// 晴天颜色 - NEVER_DELETE
  static const Color sunnyColor = Color(0xFFFFD54F);

  /// 多云颜色 - NEVER_DELETE
  static const Color cloudyColor = Color(0xFFBDBDBD);

  /// 雨天颜色 - NEVER_DELETE
  static const Color rainyColor = Color(0xFF64B5F6);

  /// 雪天颜色 - NEVER_DELETE
  static const Color snowyColor = Color(0xFFE1F5FE);

  /// 雾天颜色 - NEVER_DELETE
  static const Color foggyColor = Color(0xFF9E9E9E);

  // ==================== 空气质量颜色（NEVER_DELETE）====================
  // 国家标准的空气质量等级颜色，固定不变
  /// 优 - NEVER_DELETE
  static const Color airExcellent = Color(0xFF4CAF50);

  /// 良 - NEVER_DELETE
  static const Color airGood = Color(0xFF8BC34A);

  /// 轻度污染 - NEVER_DELETE
  static const Color airLight = Color(0xFFFFC107);

  /// 中度污染 - NEVER_DELETE
  static const Color airModerate = Color(0xFFFF9800);

  /// 重度污染 - NEVER_DELETE
  static const Color airHeavy = Color(0xFFF44336);

  /// 严重污染 - NEVER_DELETE
  static const Color airSevere = Color(0xFF9C27B0);

  // ==================== 小卡片专用冷基调色（NEVER_DELETE）====================
  // UI层次结构固定色，与主题配合使用
  // 与 App 背景 #4A90E2 同属蓝绿邻近色环，冷感专业
  // 末尾两位 4D = 30% 不透明度，对比度 ≥ 4.5:1

  /// 清爽冷蓝 - 用于第一列（同色系，亮一级） - NEVER_DELETE
  static const Color lightCardCoolBlue = Color(0x4DA6FF4D);
  static const Color lightCardCoolBlueText = Color(0xFFFFFFFF); // 白字

  /// 薄荷青 - 用于第二列（蓝绿过渡，冷感） - NEVER_DELETE
  static const Color lightCardMintCyan = Color(0x2AC4B34D);
  static const Color lightCardMintCyanText = Color(0xFFFFFFFF); // 白字

  /// 科技泳池蓝 - 用于信息类（邻近色，偏青） - NEVER_DELETE
  static const Color lightCardTechBlue = Color(0x00C2FF4D);
  static const Color lightCardTechBlueText = Color(0xFFFFFFFF); // 白字

  /// 雾青蓝 - 用于节气（同色系，更淡） - NEVER_DELETE
  static const Color lightCardMistyBlue = Color(0x5AC8FA4D);
  static const Color lightCardMistyBlueText = Color(0xFFFFFFFF); // 白字

  /// 湖水蓝 - 备用（邻近色，微绿） - NEVER_DELETE
  static const Color lightCardLakeBlue = Color(0x3AA9C94D);
  static const Color lightCardLakeBlueText = Color(0xFFFFFFFF); // 白字

  /// 淡雾蓝 - 备用（同色系，柔化） - NEVER_DELETE
  static const Color lightCardSoftBlue = Color(0x6BB6FF4D);
  static const Color lightCardSoftBlueText = Color(0xFFFFFFFF); // 白字

  // ==================== 通勤提醒专用活泼色（超越冷基调） ====================
  // 通勤提醒保持活泼色，更醒目

  /// 蜜橘 - 通勤警告类
  static const Color lightCardOrange = Color(0xFF8A004D);
  static const Color lightCardOrangeText = Color(0xFFFFFFFF); // 白字

  /// 薄荷绿 - 通勤建议
  static const Color lightCardMint = Color(0x7BFF7F4D);
  static const Color lightCardMintText = Color(0xFF2B3D4F); // 藏青灰字

  /// 草莓 - 通勤严重
  static const Color lightCardPink = Color(0xFF3C7A4D);
  static const Color lightCardPinkText = Color(0xFFFFFFFF); // 白字

  /// 青柠 - 通勤提示
  static const Color lightCardLime = Color(0x9DFF004D);
  static const Color lightCardLimeText = Color(0xFF2A3B32); // 墨绿灰字

  /// 柠檬黄 - 天气黄色预警
  static const Color lightCardYellow = Color(0xFFD5004D);
  static const Color lightCardYellowText = Color(0xFF2B3D4F); // 藏青灰字

  // ==================== AI卡片颜色常量 ====================
  
  /// AI标签颜色
  /// 亮色模式：琥珀金
  static const Color aiLabelColorLight = Color(0xFFFF8F00);
  /// 暗色模式：金琥珀色
  static const Color aiLabelColorDark = Color(0xFFFFB300);

  /// AI渐变背景色 - 亮色模式（琥珀金变种色系）
  static const Color aiGradientLightDark = Color(0xFFFF8F00); // 深琥珀金
  static const Color aiGradientLightMid = Color(0xFFFFA726); // 中琥珀金
  static const Color aiGradientLightLight = Color(0xFFFFCC80); // 浅琥珀金
  
  /// AI渐变背景色 - 暗色模式（琥珀金变种色系）
  static const Color aiGradientDarkDark = Color(0xFFFFB300); // 深金琥珀色
  static const Color aiGradientDarkMid = Color(0xFFFFC947); // 中金琥珀色
  static const Color aiGradientDarkLight = Color(0xFFFFE082); // 浅金琥珀色
  
  /// AI渐变背景透明度
  static const double aiGradientOpacity = 0.8;
  
  /// AI卡片文字颜色
  /// 亮色模式：深色文字（在琥珀金渐变背景上）
  static const Color aiTextColorLight = Color(0xFF3E2723); // 深棕色，在琥珀金渐变背景上对比度高
  /// 暗色模式：深色文字（在金琥珀色渐变背景上）
  static const Color aiTextColorDark = Color(0xFF3E2723); // 深棕色，在金琥珀色渐变背景上对比度高
  
  /// 通勤提醒小卡片背景色
  /// 亮色模式：柔和青色
  static const Color commuteCardBgLight = Color(0xFF4DD0E1);
  /// 暗色模式：柔和绿色（非黄色系）
  static const Color commuteCardBgDark = Color(0xFF66BB6A);
  /// 通勤提醒小卡片背景透明度
  static const double commuteCardBgOpacity = 0.85;
  
  /// AI标签背景透明度
  static const double aiLabelBgOpacity = 0.15;
  
  /// 标签边框透明度
  static const double labelBorderOpacity = 0.3;
  
  /// 标签白色背景透明度
  static const double labelWhiteBgOpacityLight = 0.9;
  static const double labelWhiteBgOpacityDark = 0.2;

  // ==================== 特殊强调色 ====================

  /// 吉祥色 - 农历吉字（根据主题自动选择）
  static Color get auspiciousGold => _themeProvider?.isLightTheme == true
      ? auspiciousGoldLight
      : auspiciousGoldDark;

  /// 农历凶字红色（根据主题自动选择）
  static Color get ominousRed => _themeProvider?.isLightTheme == true
      ? ominousRedLight
      : ominousRedDark;

  /// 生活指数橙色（根据主题自动选择）
  static Color get lifeIndexOrangeAuto => _themeProvider?.isLightTheme == true
      ? lifeIndexOrangeDark
      : lifeIndexOrange;

  /// 生活指数绿色（根据主题自动选择）
  static Color get lifeIndexGreenAuto => _themeProvider?.isLightTheme == true
      ? lifeIndexGreen
      : lifeIndexGreenLight;

  /// 生活指数第一列橙色 - 优化对比度
  static const Color lifeIndexOrange = Color(0xFFFFB74D);
  static const Color lifeIndexOrangeDark = Color(0xFFFF9800);

  /// 生活指数第二列绿色 - 优化对比度
  static const Color lifeIndexGreen = Color(0xFF64DD17);
  static const Color lifeIndexGreenLight = Color(0xFF66BB6A);

  /// 农历吉字金色 - 优化对比度
  static const Color auspiciousGoldLight = Color(0xFFF9A825); // 亮色模式使用
  static const Color auspiciousGoldDark = Color(0xFFFFD700); // 暗色模式使用

  /// 农历凶字红色 - 优化对比度（避免纯红色）
  static const Color ominousRedLight = Color(0xFFD32F2F); // 亮色模式
  static const Color ominousRedDark = Color(0xFFE53935); // 暗色模式

  /// 抽屉头部深色文字（浅色背景时使用）
  static const Color drawerHeaderTextDark = Color(0xFF1A1A1A);

  /// 抽屉头部次要文字颜色
  static const Color drawerHeaderTextSecondary = Color(0xFF4A4A4A);

  /// 空气质量严重污染亮色版本（通过透明度使用）
  static const Color airSevereLight = Color(0xFFBA68C8);

  // ==================== 通勤提醒专用渐变色 ====================

  /// 通勤提醒深紫色
  static const Color commuteDeepPurple = Color(0xFF4A148C);

  /// 通勤提醒深蓝色
  static const Color commuteDeepBlue = Color(0xFF1A237E);

  /// 通勤提醒更深蓝色
  static const Color commuteDarkerBlue = Color(0xFF0D47A1);

  /// 通勤提醒金色光晕
  static const Color commuteGoldGlow = Color(0xFFFFB300);
}
