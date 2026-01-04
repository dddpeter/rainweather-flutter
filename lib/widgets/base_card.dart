import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 统一的基础卡片组件
///
/// 提供一致的卡片样式，支持多种卡片类型和自定义选项
class BaseCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;

  /// 卡片类型
  final CardType cardType;

  /// 自定义内边距
  final EdgeInsets? padding;

  /// 自定义外边距
  final EdgeInsets? margin;

  /// 自定义背景颜色
  final Color? backgroundColor;

  /// 自定义圆角半径
  final double? borderRadius;

  /// 自定义宽度
  final double? width;

  /// 自定义高度
  final double? height;

  /// 是否使用Card组件
  final bool useMaterialCard;

  /// 点击事件
  final VoidCallback? onTap;

  /// 卡片阴影类型
  final CardShadowType shadowType;

  const BaseCard({
    super.key,
    required this.child,
    this.cardType = CardType.standard,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.width,
    this.height,
    this.useMaterialCard = false,
    this.onTap,
    this.shadowType = CardShadowType.none,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppColors.getCardPadding(cardType);
    // 默认只设置水平 margin，垂直间距由页面布局统一控制
    final effectiveMargin = margin ??
        const EdgeInsets.symmetric(
          horizontal: AppConstants.screenHorizontalPadding,
        );

    final cardContent = Padding(
      padding: effectivePadding,
      child: child,
    );

    if (useMaterialCard) {
      return _buildMaterialCard(context, effectiveMargin, cardContent);
    } else {
      return _buildContainerCard(context, effectiveMargin, cardContent);
    }
  }

  Widget _buildMaterialCard(
      BuildContext context, EdgeInsets margin, Widget child) {
    final borderSide = BorderSide(
      color: AppColors.cardBorder,
      width: 1,
    );

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: Card(
        elevation: shadowType == CardShadowType.none ? 0 : 4,
        shadowColor: AppColors.cardShadowColor,
        color: backgroundColor ?? AppColors.materialCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          side: borderSide,
        ),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius ?? 8),
                child: child,
              )
            : child,
      ),
    );
  }

  Widget _buildContainerCard(
      BuildContext context, EdgeInsets margin, Widget child) {
    final decoration = AppColors.getCardDecoration(
      cardType,
      customColor: backgroundColor,
      customRadius: BorderRadius.circular(borderRadius ?? 8),
    );

    final container = Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: decoration.color,
        gradient: decoration.gradient,
        borderRadius: decoration.borderRadius as BorderRadius,
        border: decoration.border,
        boxShadow: shadowType == CardShadowType.none
            ? decoration.boxShadow
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: decoration.borderRadius as BorderRadius,
          child: container,
        ),
      );
    }

    return container;
  }
}

/// 紧凑卡片组件 - 用于空间受限的场景
class CompactCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const CompactCard({
    super.key,
    required this.child,
    this.margin,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      cardType: CardType.compact,
      margin: margin,
      backgroundColor: backgroundColor,
      onTap: onTap,
      child: child,
    );
  }
}

/// 小型卡片组件 - 用于标签、按钮等小元素
class SmallCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const SmallCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      cardType: CardType.small,
      padding: padding,
      backgroundColor: backgroundColor,
      onTap: onTap,
      child: child,
    );
  }
}

/// AI渐变卡片组件 - 用于AI功能相关卡片
class AICard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? width;

  const AICard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      cardType: CardType.aiGradient,
      margin: margin,
      padding: padding,
      width: width,
      onTap: onTap,
      shadowType: CardShadowType.light,
      child: child,
    );
  }
}

/// 带阴影卡片组件 - 用于需要强调的卡片
class ShadowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ShadowCard({
    super.key,
    required this.child,
    this.margin,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      cardType: CardType.shadow,
      margin: margin,
      backgroundColor: backgroundColor,
      onTap: onTap,
      child: child,
    );
  }
}
