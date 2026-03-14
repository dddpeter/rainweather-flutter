import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

/// 刷新处理 Mixin
///
/// 提供统一的刷新处理能力：
/// - 下拉刷新
/// - 触觉反馈
/// - 刷新控制
mixin RefreshHandlerMixin<T extends StatefulWidget> on State<T> {
  /// 是否正在刷新
  bool _isRefreshing = false;

  /// 获取刷新状态
  bool get isRefreshing => _isRefreshing;

  /// 执行刷新操作（带触觉反馈）
  Future<void> handleRefresh(Future<void> Function() refreshAction) async {
    if (_isRefreshing) return;

    try {
      _isRefreshing = true;
      if (mounted) {
        setState(() {});
      }

      // iOS触觉反馈
      if (Platform.isIOS) {
        HapticFeedback.mediumImpact();
      }

      AppLogger.d('开始刷新', tag: runtimeType.toString());

      await refreshAction();

      // iOS完成触觉反馈
      if (Platform.isIOS && mounted) {
        HapticFeedback.lightImpact();
      }

      AppLogger.i('刷新完成', tag: runtimeType.toString());
    } catch (e) {
      AppLogger.e(
        '刷新失败',
        tag: runtimeType.toString(),
        error: e,
      );
    } finally {
      _isRefreshing = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// 构建下拉刷新组件
  Widget buildRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color? color,
    Color? backgroundColor,
  }) {
    return RefreshIndicator(
      onRefresh: () => handleRefresh(onRefresh),
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor,
      child: child,
    );
  }

  /// 触发触觉反馈
  void triggerHapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.light,
  }) {
    if (!Platform.isIOS) return;

    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }
}

/// 触觉反馈类型
enum HapticFeedbackType {
  /// 轻度反馈
  light,

  /// 中度反馈
  medium,

  /// 重度反馈
  heavy,
}
