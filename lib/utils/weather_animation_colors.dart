import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

/// 天气动画颜色工具类
/// 根据当前主题提供合适的动画颜色
class WeatherAnimationColors {
  static ThemeProvider? _themeProvider;

  /// 设置主题提供者
  static void setThemeProvider(ThemeProvider provider) {
    _themeProvider = provider;
  }

  /// 获取当前是否为亮色主题
  static bool get isLightTheme => _themeProvider?.isLightTheme ?? false;

  /// 云朵颜色 - 根据主题调整
  static Color get cloudColor {
    if (isLightTheme) {
      return const Color(0xFFB8D9F5); // 亮色主题：使用暗色主题的浅蓝色云朵
    } else {
      return const Color(0xFFB8D9F5); // 暗色主题：浅蓝色云朵
    }
  }

  /// 云朵阴影颜色
  static Color get cloudShadowColor {
    if (isLightTheme) {
      return const Color(0xFF8BB3D6); // 亮色主题：使用暗色主题的浅蓝色阴影
    } else {
      return const Color(0xFF8BB3D6); // 暗色主题：浅蓝色阴影
    }
  }

  /// 阴天云朵颜色 - 比多云更深的云朵
  static Color get overcastCloudColor {
    if (isLightTheme) {
      return const Color(0xFF8BB3D6); // 亮色主题：使用暗色主题的浅蓝色阴天云朵
    } else {
      return const Color(0xFF8BB3D6); // 暗色主题：浅蓝色阴天云朵（比多云更浅）
    }
  }

  /// 雨滴颜色
  static Color get rainColor {
    if (isLightTheme) {
      return const Color(0xFF64B5F6); // 亮色主题：使用暗色主题的浅蓝色雨滴
    } else {
      return const Color(0xFF64B5F6); // 暗色主题：浅蓝色雨滴
    }
  }

  /// 雪花颜色
  static Color get snowColor {
    if (isLightTheme) {
      return const Color(0xFFE1F5FE); // 亮色主题：使用暗色主题的白色雪花
    } else {
      return const Color(0xFFE1F5FE); // 暗色主题：白色雪花
    }
  }

  /// 太阳颜色
  static Color get sunColor {
    if (isLightTheme) {
      return const Color(0xFFFFA726); // 亮色主题：偏橘红的黄色太阳
    } else {
      return const Color(0xFFFFA726); // 暗色主题：偏橘红的黄色太阳
    }
  }

  /// 太阳光芒颜色
  static Color get sunRayColor {
    if (isLightTheme) {
      return const Color(0xFFFFC107); // 亮色主题：使用暗色主题的橙色光芒
    } else {
      return const Color(0xFFFFC107); // 暗色主题：橙色光芒
    }
  }

  /// 月亮颜色
  static Color get moonColor {
    if (isLightTheme) {
      return const Color(0xFFB39DDB); // 亮色主题：使用暗色主题的紫色月亮
    } else {
      return const Color(0xFFB39DDB); // 暗色主题：紫色月亮
    }
  }

  /// 雾霾颜色
  static Color get fogColor {
    if (isLightTheme) {
      return const Color(0xFFF5F5F5); // 亮色主题：近似白色的灰色雾霾
    } else {
      return const Color(0xFFF5F5F5); // 暗色主题：近似白色的灰色雾霾
    }
  }

  /// 雷暴云颜色
  static Color get thunderCloudColor {
    if (isLightTheme) {
      return const Color(0xFF616161); // 亮色主题：使用暗色主题的灰色雷暴云
    } else {
      return const Color(0xFF616161); // 暗色主题：灰色雷暴云
    }
  }

  /// 闪电颜色
  static Color get lightningColor {
    return const Color(0xFFFFEB3B); // 闪电始终是黄色
  }

  /// 粒子颜色（通用）
  static Color get particleColor {
    if (isLightTheme) {
      return AppColors.textPrimary; // 亮色主题：深色粒子
    } else {
      return AppColors.textSecondary; // 暗色主题：浅色粒子
    }
  }

  /// 灰尘粒子颜色（黑灰色）
  static Color get dustColor {
    if (isLightTheme) {
      return const Color(0xFF616161); // 亮色主题：中灰色灰尘粒子
    } else {
      return const Color(0xFF9E9E9E); // 暗色主题：浅灰色灰尘粒子
    }
  }

  /// 获取带透明度的颜色
  static Color withOpacity(Color baseColor, double opacity) {
    return baseColor.withOpacity(opacity);
  }
}
