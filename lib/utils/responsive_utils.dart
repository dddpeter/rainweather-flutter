import 'package:flutter/material.dart';

/// 响应式断点工具类
///
/// 提供基于屏幕尺寸的响应式布局支持
/// 遵循 Mobile-first 设计原则
class ResponsiveUtils {
  ResponsiveUtils._();

  // ==================== 断点定义 ====================

  /// 手机最大宽度（portrait）
  static const double mobileMaxWidth = 599;

  /// 平板最小宽度（portrait）
  static const double tabletMinWidth = 600;

  /// 平板最大宽度
  static const double tabletMaxWidth = 1023;

  /// 桌面最小宽度
  static const double desktopMinWidth = 1024;

  /// 大桌面最小宽度
  static const double largeDesktopMinWidth = 1440;

  /// 超大桌面最小宽度（支持 5-6 列布局）
  static const double extraLargeDesktopMinWidth = 1920;

  // ==================== 设备类型判断 ====================

  /// 是否为手机
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletMinWidth;
  }

  /// 是否为平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletMinWidth && width < desktopMinWidth;
  }

  /// 是否为桌面
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }

  /// 是否为大桌面
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopMinWidth;
  }

  /// 是否为超大桌面
  static bool isExtraLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= extraLargeDesktopMinWidth;
  }

  // ==================== 屏幕尺寸分类 ====================

  /// 获取当前屏幕尺寸分类
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMaxWidth) {
      return ScreenSize.mobile;
    } else if (width < desktopMinWidth) {
      return ScreenSize.tablet;
    } else if (width < largeDesktopMinWidth) {
      return ScreenSize.desktop;
    } else if (width < extraLargeDesktopMinWidth) {
      return ScreenSize.largeDesktop;
    } else {
      return ScreenSize.extraLargeDesktop;
    }
  }

  // ==================== 响应式值选择 ====================

  /// 根据屏幕尺寸返回不同的值
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
    T? extraLargeDesktop,
  }) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case ScreenSize.extraLargeDesktop:
        return extraLargeDesktop ?? largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// 响应式间距
  static double responsiveSpacing(
    BuildContext context, {
    double mobile = 12,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// 响应式字体大小
  ///
  /// 根据屏幕尺寸自动调整字体大小，提升大屏可读性
  /// 增量策略：
  /// - Tablet: +2px (600-1023px)
  /// - Desktop: +4px (1024-1439px)
  /// - Large Desktop: +6px (1440-1919px)
  /// - Extra Large Desktop: +8px (>=1920px)
  static double responsiveFontSize(
    BuildContext context, {
    double mobile = 14,
    double? tablet,
    double? desktop,
    double? largeDesktop,
    double? extraLargeDesktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet ?? (mobile + 2),
      desktop: desktop ?? (mobile + 4),
      largeDesktop: largeDesktop ?? (mobile + 6),
      extraLargeDesktop: extraLargeDesktop ?? (mobile + 8),
    );
  }

  /// 响应式列数（用于网格布局）
  static int responsiveColumnCount(
    BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
    int? largeDesktop,
    int? extraLargeDesktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
      extraLargeDesktop: extraLargeDesktop,
    );
  }

  // ==================== 安全区域 ====================

  /// 获取水平安全边距
  static EdgeInsets horizontalPadding(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 16);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 24);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32);
      case ScreenSize.largeDesktop:
        return const EdgeInsets.symmetric(horizontal: 48);
      case ScreenSize.extraLargeDesktop:
        return const EdgeInsets.symmetric(horizontal: 64);
    }
  }

  /// 获取垂直安全边距
  static EdgeInsets verticalPadding(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(vertical: 8);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(vertical: 12);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(vertical: 16);
      case ScreenSize.largeDesktop:
        return const EdgeInsets.symmetric(vertical: 24);
      case ScreenSize.extraLargeDesktop:
        return const EdgeInsets.symmetric(vertical: 32);
    }
  }
}

/// 屏幕尺寸枚举
enum ScreenSize {
  /// 手机 (< 600px)
  mobile,

  /// 平板 (600px - 1023px)
  tablet,

  /// 桌面 (1024px - 1439px)
  desktop,

  /// 大桌面 (1440px - 1919px)
  largeDesktop,

  /// 超大桌面 (>= 1920px)
  extraLargeDesktop,
}

/// 响应式 Widget 扩展
extension ResponsiveWidgetExtension on Widget {
  /// 添加响应式内边距
  Widget withResponsivePadding(BuildContext context) {
    return Padding(padding: ResponsiveUtils.horizontalPadding(context), child: this);
  }

  /// 添加响应式约束（最大宽度）
  Widget withResponsiveConstraints(BuildContext context) {
    final size = ResponsiveUtils.getScreenSize(context);
    double? maxWidth;
    switch (size) {
      case ScreenSize.mobile:
        maxWidth = null; // 手机全屏
        break;
      case ScreenSize.tablet:
        maxWidth = 720;
        break;
      case ScreenSize.desktop:
        maxWidth = 1200;
        break;
      case ScreenSize.largeDesktop:
        maxWidth = 1440;
        break;
      case ScreenSize.extraLargeDesktop:
        maxWidth = 1920;
        break;
    }

    if (maxWidth == null) {
      return this;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: this,
      ),
    );
  }
}
