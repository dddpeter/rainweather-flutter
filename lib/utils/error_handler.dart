import 'package:flutter/material.dart';
import 'logger.dart';

/// 应用错误类型枚举
enum AppErrorType {
  network('网络错误'),
  location('定位错误'),
  dataParsing('数据解析错误'),
  cache('缓存错误'),
  permission('权限错误'),
  unknown('未知错误');

  const AppErrorType(this.message);
  final String message;
}

/// 统一错误处理工具类
class ErrorHandler {
  /// 处理并显示错误
  static void handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    AppErrorType? type,
    VoidCallback? onRetry,
  }) {
    // 记录错误日志
    Logger.e(
      '错误处理: ${error.toString()}',
      tag: context ?? 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    // 确定错误类型
    final errorType = type ?? _determineErrorType(error);

    // 根据错误类型提供不同的处理策略
    switch (errorType) {
      case AppErrorType.network:
        _handleNetworkError(error, onRetry: onRetry);
        break;
      case AppErrorType.location:
        _handleLocationError(error, onRetry: onRetry);
        break;
      case AppErrorType.dataParsing:
        _handleDataParsingError(error);
        break;
      case AppErrorType.cache:
        _handleCacheError(error);
        break;
      case AppErrorType.permission:
        _handlePermissionError(error, onRetry: onRetry);
        break;
      default:
        _handleUnknownError(error);
    }
  }

  /// 确定错误类型
  static AppErrorType _determineErrorType(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return AppErrorType.network;
    }

    if (errorString.contains('location') ||
        errorString.contains('gps') ||
        errorString.contains('permission denied')) {
      return AppErrorType.location;
    }

    if (errorString.contains('json') ||
        errorString.contains('parse') ||
        errorString.contains('format')) {
      return AppErrorType.dataParsing;
    }

    if (errorString.contains('cache') || errorString.contains('storage')) {
      return AppErrorType.cache;
    }

    if (errorString.contains('permission')) {
      return AppErrorType.permission;
    }

    return AppErrorType.unknown;
  }

  /// 处理网络错误
  static void _handleNetworkError(Object error, {VoidCallback? onRetry}) {
    Logger.w('处理网络错误: $error', tag: 'NetworkError');

    // 可以在这里添加网络重试逻辑
    if (onRetry != null) {
      // 延迟重试
      Future.delayed(const Duration(seconds: 2), () {
        onRetry();
      });
    }
  }

  /// 处理定位错误
  static void _handleLocationError(Object error, {VoidCallback? onRetry}) {
    Logger.w('处理定位错误: $error', tag: 'LocationError');

    // 定位错误通常需要用户手动操作
    if (onRetry != null) {
      // 延迟重试，给用户时间检查权限
      Future.delayed(const Duration(seconds: 3), () {
        onRetry();
      });
    }
  }

  /// 处理数据解析错误
  static void _handleDataParsingError(Object error) {
    Logger.e('数据解析错误，使用默认数据', tag: 'DataParsingError', error: error);
    // 数据解析错误通常使用默认值
  }

  /// 处理缓存错误
  static void _handleCacheError(Object error) {
    Logger.w('缓存错误，清除缓存重试', tag: 'CacheError');
    // 缓存错误通常需要清除缓存
  }

  /// 处理权限错误
  static void _handlePermissionError(Object error, {VoidCallback? onRetry}) {
    Logger.w('权限错误，需要用户授权', tag: 'PermissionError');
    // 权限错误需要用户手动授权
  }

  /// 处理未知错误
  static void _handleUnknownError(Object error) {
    Logger.e('未知错误', tag: 'UnknownError', error: error);
  }

  /// 安全执行异步操作
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? operationName,
    T? defaultValue,
    bool showError = true,
  }) async {
    try {
      Logger.d('开始执行操作: ${operationName ?? '未知操作'}', tag: 'SafeExecute');
      final result = await operation();
      Logger.s('操作完成: ${operationName ?? '未知操作'}', tag: 'SafeExecute');
      return result;
    } catch (error, stackTrace) {
      if (showError) {
        handleError(error, stackTrace: stackTrace, context: operationName);
      } else {
        Logger.e(
          '操作失败: ${operationName ?? '未知操作'}',
          tag: 'SafeExecute',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return defaultValue;
    }
  }

  /// 安全执行同步操作
  static T? safeExecuteSync<T>(
    T Function() operation, {
    String? operationName,
    T? defaultValue,
    bool showError = true,
  }) {
    try {
      Logger.d('开始执行同步操作: ${operationName ?? '未知操作'}', tag: 'SafeExecuteSync');
      final result = operation();
      Logger.s('同步操作完成: ${operationName ?? '未知操作'}', tag: 'SafeExecuteSync');
      return result;
    } catch (error, stackTrace) {
      if (showError) {
        handleError(error, stackTrace: stackTrace, context: operationName);
      } else {
        Logger.e(
          '同步操作失败: ${operationName ?? '未知操作'}',
          tag: 'SafeExecuteSync',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return defaultValue;
    }
  }

  /// 显示用户友好的错误消息
  static String getUserFriendlyMessage(AppErrorType type, Object error) {
    switch (type) {
      case AppErrorType.network:
        return '网络连接异常，请检查网络设置后重试';
      case AppErrorType.location:
        return '定位失败，请确保已开启定位权限';
      case AppErrorType.dataParsing:
        return '数据格式异常，正在尝试恢复';
      case AppErrorType.cache:
        return '缓存异常，正在重新加载数据';
      case AppErrorType.permission:
        return '权限不足，请在设置中允许相关权限';
      default:
        return '操作失败，请稍后重试';
    }
  }

  /// 检查是否为可重试的错误
  static bool isRetryableError(Object error) {
    final errorType = _determineErrorType(error);
    return errorType == AppErrorType.network ||
        errorType == AppErrorType.location ||
        errorType == AppErrorType.cache;
  }

  /// 获取重试延迟时间
  static Duration getRetryDelay(int attemptCount) {
    // 指数退避策略：1s, 2s, 4s, 8s, 最大16s
    final delay = Duration(seconds: [1, 2, 4, 8, 16][attemptCount.clamp(0, 4)]);
    Logger.d(
      '重试延迟: ${delay.inSeconds}秒 (第${attemptCount + 1}次重试)',
      tag: 'RetryDelay',
    );
    return delay;
  }
}

/// 错误处理扩展
extension ErrorExtension on Object {
  /// 获取用户友好的错误消息
  String get userFriendlyMessage {
    final type = ErrorHandler._determineErrorType(this);
    return ErrorHandler.getUserFriendlyMessage(type, this);
  }

  /// 检查是否可重试
  bool get isRetryable => ErrorHandler.isRetryableError(this);
}
