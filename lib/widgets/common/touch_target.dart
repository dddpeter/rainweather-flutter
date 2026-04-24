import 'package:flutter/material.dart';

/// 统一的触摸目标组件
///
/// 确保所有交互元素的最小触摸区域符合 WCAG 2.5.5 标准（48x48px）
///
/// 使用场景：
/// - 图标按钮
/// - 小型点击区域
/// - 需要扩大点击范围的元素
class TouchTarget extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 点击回调
  final VoidCallback? onTap;

  /// 最小宽度（默认 48px，符合 WCAG 标准）
  final double minWidth;

  /// 最小高度（默认 48px，符合 WCAG 标准）
  final double minHeight;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 对齐方式
  final AlignmentGeometry alignment;

  /// 是否显示点击反馈
  final bool showFeedback;

  /// 自定义边框半径（用于 InkWell）
  final BorderRadius? borderRadius;

  const TouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minWidth = 48.0,
    this.minHeight = 48.0,
    this.padding,
    this.alignment = Alignment.center,
    this.showFeedback = true,
    this.borderRadius,
  });

  /// 紧凑型触摸目标（用于空间受限的场景，但仍保持可接受的最小尺寸）
  const TouchTarget.compact({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.alignment = Alignment.center,
    this.showFeedback = true,
    this.borderRadius,
  }) : minWidth = 44.0,
       minHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    Widget target = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Align(alignment: alignment, child: child),
      ),
    );

    if (onTap != null) {
      if (showFeedback) {
        target = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            child: target,
          ),
        );
      } else {
        target = GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: target);
      }
    }

    return target;
  }
}

/// 触摸目标扩展方法
extension TouchTargetExtension on Widget {
  /// 将任何 widget 包装为符合 WCAG 标准的触摸目标
  Widget asTouchTarget({
    VoidCallback? onTap,
    double minWidth = 48.0,
    double minHeight = 48.0,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry alignment = Alignment.center,
    bool showFeedback = true,
    BorderRadius? borderRadius,
  }) {
    return TouchTarget(
      onTap: onTap,
      minWidth: minWidth,
      minHeight: minHeight,
      padding: padding,
      alignment: alignment,
      showFeedback: showFeedback,
      borderRadius: borderRadius,
      child: this,
    );
  }

  /// 紧凑型触摸目标
  Widget asCompactTouchTarget({
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry alignment = Alignment.center,
    bool showFeedback = true,
    BorderRadius? borderRadius,
  }) {
    return TouchTarget.compact(
      onTap: onTap,
      padding: padding,
      alignment: alignment,
      showFeedback: showFeedback,
      borderRadius: borderRadius,
      child: this,
    );
  }
}
