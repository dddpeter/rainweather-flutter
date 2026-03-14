import 'package:flutter/material.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import '../widgets/error_dialog.dart';
import '../utils/error_handler.dart';

/// 错误处理 Mixin
///
/// 提供统一的错误处理能力：
/// - 错误对话框显示
/// - 错误日志记录
/// - Result 类型处理
/// - 错误类型识别
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// 显示错误对话框
  void showErrorDialog({
    required String title,
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      errorType: _getErrorType(message),
      onRetry: onRetry,
      retryText: retryText,
    );
  }

  /// 处理 Result 类型错误
  void handleResultError<R>(Result<R> result, {VoidCallback? onRetry}) {
    if (result.isFailure) {
      final error = result.error;
      AppLogger.e(
        error.message,
        tag: runtimeType.toString(),
        error: error.originalError,
      );

      showErrorDialog(
        title: '操作失败',
        message: error.message,
        onRetry: onRetry,
      );
    }
  }

  /// 处理异常错误
  void handleException(Object error, {StackTrace? stackTrace}) {
    final appError = AppErrorFactory.fromException(error);

    AppLogger.e(
      appError.message,
      tag: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );

    showErrorDialog(
      title: '发生错误',
      message: appError.message,
    );
  }

  /// 执行异步操作并处理错误
  Future<D?> executeWithErrorHandling<D>(
    Future<D> Function() operation, {
    VoidCallback? onError,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (showError) {
        handleException(e, stackTrace: stackTrace);
      } else {
        AppLogger.e(
          '操作失败',
          tag: runtimeType.toString(),
          error: e,
          stackTrace: stackTrace,
        );
      }
      onError?.call();
      return null;
    }
  }

  /// 从错误消息识别错误类型
  AppErrorType _getErrorType(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('socket')) {
      return AppErrorType.network;
    }

    if (lowerMessage.contains('location') ||
        lowerMessage.contains('gps') ||
        lowerMessage.contains('定位')) {
      return AppErrorType.location;
    }

    if (lowerMessage.contains('permission') ||
        lowerMessage.contains('权限')) {
      return AppErrorType.permission;
    }

    if (lowerMessage.contains('database') ||
        lowerMessage.contains('sqlite')) {
      return AppErrorType.cache;
    }

    return AppErrorType.unknown;
  }
}
