import 'package:flutter/material.dart';

/// 自定义主题扩展 - 用于存储应用特定的颜色
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color primaryBlue;
  final Color accentBlue;
  final Color accentGreen;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color cardBackground;
  final Color cardBorder;
  final Color glassBackground;
  final Color currentTagBackground;
  final Color currentTagBorder;
  final Color currentTag;
  final Color dividerColor;
  final Color buttonShadow;
  final Color highTemp;
  final Color lowTemp;
  final Color sunrise;
  final Color sunset;
  final Color moon;
  final Color tagBackground;
  final Color tagTextOnPrimary;
  final Color tagBorder;
  final LinearGradient primaryGradient;

  const AppThemeExtension({
    required this.primaryBlue,
    required this.accentBlue,
    required this.accentGreen,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.cardBackground,
    required this.cardBorder,
    required this.glassBackground,
    required this.currentTagBackground,
    required this.currentTagBorder,
    required this.currentTag,
    required this.dividerColor,
    required this.buttonShadow,
    required this.highTemp,
    required this.lowTemp,
    required this.sunrise,
    required this.sunset,
    required this.moon,
    required this.tagBackground,
    required this.tagTextOnPrimary,
    required this.tagBorder,
    required this.primaryGradient,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? primaryBlue,
    Color? accentBlue,
    Color? accentGreen,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? cardBackground,
    Color? cardBorder,
    Color? glassBackground,
    Color? currentTagBackground,
    Color? currentTagBorder,
    Color? currentTag,
    Color? dividerColor,
    Color? buttonShadow,
    Color? highTemp,
    Color? lowTemp,
    Color? sunrise,
    Color? sunset,
    Color? moon,
    Color? tagBackground,
    Color? tagTextOnPrimary,
    Color? tagBorder,
    LinearGradient? primaryGradient,
  }) {
    return AppThemeExtension(
      primaryBlue: primaryBlue ?? this.primaryBlue,
      accentBlue: accentBlue ?? this.accentBlue,
      accentGreen: accentGreen ?? this.accentGreen,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      glassBackground: glassBackground ?? this.glassBackground,
      currentTagBackground: currentTagBackground ?? this.currentTagBackground,
      currentTagBorder: currentTagBorder ?? this.currentTagBorder,
      currentTag: currentTag ?? this.currentTag,
      dividerColor: dividerColor ?? this.dividerColor,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      highTemp: highTemp ?? this.highTemp,
      lowTemp: lowTemp ?? this.lowTemp,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      moon: moon ?? this.moon,
      tagBackground: tagBackground ?? this.tagBackground,
      tagTextOnPrimary: tagTextOnPrimary ?? this.tagTextOnPrimary,
      tagBorder: tagBorder ?? this.tagBorder,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      currentTagBackground: Color.lerp(
        currentTagBackground,
        other.currentTagBackground,
        t,
      )!,
      currentTagBorder: Color.lerp(
        currentTagBorder,
        other.currentTagBorder,
        t,
      )!,
      currentTag: Color.lerp(currentTag, other.currentTag, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      buttonShadow: Color.lerp(buttonShadow, other.buttonShadow, t)!,
      highTemp: Color.lerp(highTemp, other.highTemp, t)!,
      lowTemp: Color.lerp(lowTemp, other.lowTemp, t)!,
      sunrise: Color.lerp(sunrise, other.sunrise, t)!,
      sunset: Color.lerp(sunset, other.sunset, t)!,
      moon: Color.lerp(moon, other.moon, t)!,
      tagBackground: Color.lerp(tagBackground, other.tagBackground, t)!,
      tagTextOnPrimary: Color.lerp(
        tagTextOnPrimary,
        other.tagTextOnPrimary,
        t,
      )!,
      tagBorder: Color.lerp(tagBorder, other.tagBorder, t)!,
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
    );
  }

  /// 亮色主题扩展
  static AppThemeExtension light() {
    return const AppThemeExtension(
      primaryBlue: Color(0xFF012d78),
      accentBlue: Color(0xFF8edafc),
      accentGreen: Color(0xFF2E7D32),
      textPrimary: Color(0xFF001A4D),
      textSecondary: Color(0xFF003366),
      textTertiary: Color(0xFF6B7280),
      cardBackground: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFE1F5FE),
      glassBackground: Color(0x20FFFFFF),
      currentTagBackground: Color(0xFFE53E3E),
      currentTagBorder: Color(0xFFE53E3E),
      currentTag: Color(0xFFFFFFFF),
      dividerColor: Color(0xFFB8D9F5),
      buttonShadow: Color(0x15000000),
      highTemp: Color(0xFFD32F2F),
      lowTemp: Color(0xFF8edafc),
      sunrise: Color(0xFFFFA726),
      sunset: Color(0xFFC2185B),
      moon: Color(0xFF673AB7),
      tagBackground: Color(0xFFE8F5E8),
      tagTextOnPrimary: Color(0xFF1976D2),
      tagBorder: Color(0xFF1976D2),
      primaryGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8edafc), Color(0xFFE1F5FE)],
      ),
    );
  }

  /// 暗色主题扩展
  static AppThemeExtension dark() {
    return const AppThemeExtension(
      primaryBlue: Color(0xFF4A90E2),
      accentBlue: Color(0xFF8edafc),
      accentGreen: Color(0xFF4CAF50),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFE8F4FD),
      textTertiary: Color(0xFFB8D9F5),
      cardBackground: Color(0x25FFFFFF),
      cardBorder: Color(0x35FFFFFF),
      glassBackground: Color(0x30FFFFFF),
      currentTagBackground: Color(0xFF4A90E2),
      currentTagBorder: Color(0xFF4A90E2),
      currentTag: Color(0xFFFFFFFF),
      dividerColor: Color(0xFF2D4A7D),
      buttonShadow: Color(0x30000000),
      highTemp: Color(0xFFFF5722),
      lowTemp: Color(0xFF8edafc),
      sunrise: Color(0xFFFFA726),
      sunset: Color(0xFFE91E63),
      moon: Color(0xFFB39DDB),
      tagBackground: Color(0xFF4A90E2),
      tagTextOnPrimary: Color(0xFFE8F4FD),
      tagBorder: Color(0xFF4A90E2),
      primaryGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF012d78), Color(0xFF0A1B3D)],
      ),
    );
  }
}

/// 扩展方法，方便在任何地方获取主题扩展
extension ThemeExtras on BuildContext {
  AppThemeExtension get appTheme {
    return Theme.of(this).extension<AppThemeExtension>() ??
        AppThemeExtension.dark();
  }
}
