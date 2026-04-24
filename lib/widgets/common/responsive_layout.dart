import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../utils/responsive_utils.dart';

/// 响应式网格布局 Widget
///
/// 根据屏幕尺寸自动调整列数
class ResponsiveGrid extends StatelessWidget {
  /// 子项列表
  final List<Widget> children;

  /// 子项之间的间距
  final double spacing;

  /// 垂直间距（默认为 spacing）
  final double? runSpacing;

  /// 最小列宽（用于计算自动列数）
  final double? minChildWidth;

  /// 固定列数（如果设置，将覆盖自动计算）
  final int? fixedColumnCount;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing,
    this.minChildWidth,
    this.fixedColumnCount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 确定列数
    final columnCount =
        fixedColumnCount ??
        (minChildWidth != null
            ? _calculateColumnCount(screenWidth, minChildWidth!, spacing)
            : AppConstants.columnCountForScreen(screenWidth));

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = _calculateItemWidth(constraints.maxWidth, columnCount, spacing);

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing ?? spacing,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }

  int _calculateColumnCount(double screenWidth, double minWidth, double spacing) {
    final maxCols = ((screenWidth + spacing) / (minWidth + spacing)).floor();
    return maxCols.clamp(1, 6); // 最大支持 6 列布局
  }

  double _calculateItemWidth(double containerWidth, int columns, double spacing) {
    final totalSpacing = spacing * (columns - 1);
    return (containerWidth - totalSpacing) / columns;
  }
}

/// 响应式卡片容器
///
/// 根据屏幕尺寸调整内边距和最大宽度
class ResponsiveCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveCardContainer({super.key, required this.child, this.padding, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectivePadding =
        padding ?? EdgeInsets.all(AppConstants.cardSpacingForScreen(screenWidth));

    Widget container = Padding(padding: effectivePadding, child: child);

    // 在大屏幕上限制最大宽度并居中
    if (maxWidth != null || screenWidth >= AppConstants.desktopMinWidth) {
      final effectiveMaxWidth =
          maxWidth ??
          (screenWidth >= AppConstants.largeDesktopMinWidth
              ? 1440
              : screenWidth >= AppConstants.desktopMinWidth
              ? 1200
              : null);

      if (effectiveMaxWidth != null) {
        container = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            child: container,
          ),
        );
      }
    }

    return container;
  }
}

/// 响应式文本 Widget
///
/// 根据屏幕尺寸自动调整字体大小
class ResponsiveText extends StatelessWidget {
  final String data;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText({
    super.key,
    required this.data,
    this.baseFontSize = 14,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // 使用增强的响应式字体增量，提升大屏可读性
    final fontSize = ResponsiveUtils.responsiveFontSize(
      context,
      mobile: baseFontSize,
      tablet: baseFontSize + 2,
      desktop: baseFontSize + 4,
      largeDesktop: baseFontSize + 6,
      extraLargeDesktop: baseFontSize + 8,
    );

    return Text(
      data,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 响应式可见性 Widget
///
/// 根据屏幕尺寸显示或隐藏内容
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool showOnMobile;
  final bool showOnTablet;
  final bool showOnDesktop;
  final bool showOnLargeDesktop;
  final bool showOnExtraLargeDesktop;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.showOnMobile = true,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    this.showOnLargeDesktop = true,
    this.showOnExtraLargeDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveUtils.getScreenSize(context);
    bool shouldShow;

    switch (size) {
      case ScreenSize.mobile:
        shouldShow = showOnMobile;
        break;
      case ScreenSize.tablet:
        shouldShow = showOnTablet;
        break;
      case ScreenSize.desktop:
        shouldShow = showOnDesktop;
        break;
      case ScreenSize.largeDesktop:
        shouldShow = showOnLargeDesktop;
        break;
      case ScreenSize.extraLargeDesktop:
        shouldShow = showOnExtraLargeDesktop;
        break;
    }

    return shouldShow ? child : const SizedBox.shrink();
  }
}
