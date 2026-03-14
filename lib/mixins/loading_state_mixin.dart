import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// 加载状态 Mixin
///
/// 提供统一的加载状态管理能力：
/// - 加载状态控制
/// - 加载指示器显示
/// - 刷新控制
/// - 状态通知
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在刷新
  bool _isRefreshing = false;

  /// 获取加载状态
  bool get isLoading => _isLoading;

  /// 获取刷新状态
  bool get isRefreshing => _isRefreshing;

  /// 设置加载状态
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  /// 设置刷新状态
  void setRefreshing(bool refreshing) {
    if (mounted) {
      setState(() {
        _isRefreshing = refreshing;
      });
    }
  }

  /// 显示加载指示器
  void showLoading() {
    setLoading(true);
  }

  /// 隐藏加载指示器
  void hideLoading() {
    setLoading(false);
  }

  /// 执行加载操作
  Future<D?> withLoading<D>(
    Future<D> Function() operation, {
    bool showError = true,
    VoidCallback? onComplete,
    VoidCallback? onError,
  }) async {
    if (_isLoading) return null;

    try {
      showLoading();
      AppLogger.d('开始加载', tag: runtimeType.toString());

      final result = await operation();

      AppLogger.i('加载完成', tag: runtimeType.toString());
      return result;
    } catch (e, stackTrace) {
      AppLogger.e(
        '加载失败',
        tag: runtimeType.toString(),
        error: e,
        stackTrace: stackTrace,
      );

      if (showError && mounted) {
        _showLoadError(e);
      }

      onError?.call();
      return null;
    } finally {
      hideLoading();
      onComplete?.call();
    }
  }

  /// 执行刷新操作
  Future<D?> withRefreshing<D>(
    Future<D> Function() operation, {
    bool showError = true,
    VoidCallback? onComplete,
    VoidCallback? onError,
  }) async {
    if (_isRefreshing) return null;

    try {
      setRefreshing(true);
      AppLogger.d('开始刷新', tag: runtimeType.toString());

      final result = await operation();

      AppLogger.i('刷新完成', tag: runtimeType.toString());
      return result;
    } catch (e, stackTrace) {
      AppLogger.e(
        '刷新失败',
        tag: runtimeType.toString(),
        error: e,
        stackTrace: stackTrace,
      );

      if (showError && mounted) {
        _showLoadError(e);
      }

      onError?.call();
      return null;
    } finally {
      setRefreshing(false);
      onComplete?.call();
    }
  }

  /// 显示加载错误
  void _showLoadError(Object error) {
    final message = error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('加载失败: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: () {
            // 子类可以重写此方法来实现重试逻辑
          },
        ),
      ),
    );
  }

  /// 构建加载指示器
  Widget buildLoadingIndicator({Color? color}) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color)
            : null,
      ),
    );
  }

  /// 构建错误视图
  Widget buildErrorView({
    required String message,
    VoidCallback? onRetry,
    String retryText = '重试',
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(retryText),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建空视图
  Widget buildEmptyView({
    String message = '暂无数据',
    IconData icon = Icons.inbox,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
