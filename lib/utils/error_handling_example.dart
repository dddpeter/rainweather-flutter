import 'package:flutter/material.dart';
import 'error_handler.dart';
import 'logger.dart';
import '../widgets/error_dialog.dart';

/// 错误处理和日志系统使用示例
class ErrorHandlingExample {
  /// 示例1: 使用ErrorHandler处理网络请求错误
  static Future<void> handleNetworkRequest() async {
    try {
      // 模拟网络请求
      Logger.d('开始网络请求', tag: 'Example');

      // 这里可能会抛出网络异常
      throw Exception('网络连接超时');
    } catch (e, stackTrace) {
      // 使用ErrorHandler处理错误
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'Example.NetworkRequest',
        type: AppErrorType.network,
        onRetry: () {
          Logger.d('重试网络请求', tag: 'Example');
          handleNetworkRequest(); // 递归重试
        },
      );
    }
  }

  /// 示例2: 使用ErrorHandler.safeExecute安全执行操作
  static Future<void> safeExecuteExample() async {
    final result = await ErrorHandler.safeExecute(
      () async {
        Logger.d('执行可能失败的操作', tag: 'Example');

        // 模拟可能失败的操作
        if (DateTime.now().millisecond % 2 == 0) {
          throw Exception('随机失败');
        }

        return '操作成功';
      },
      operationName: 'Example.SafeExecute',
      defaultValue: '默认值',
      showError: true,
    );

    Logger.d('操作结果: $result', tag: 'Example');
  }

  /// 示例3: 在UI中显示错误对话框
  static void showErrorDialog(BuildContext context) {
    ErrorDialog.showNetworkError(
      context: context,
      message: '无法连接到服务器，请检查网络设置',
      onRetry: () {
        Logger.d('用户点击重试', tag: 'Example');
        // 重试逻辑
      },
    );
  }

  /// 示例4: 在UI中显示错误Toast
  static void showErrorToast(BuildContext context) {
    ErrorToast.show(
      context: context,
      message: '定位失败，请检查定位权限',
      errorType: AppErrorType.location,
    );
  }

  /// 示例5: 使用Logger记录不同级别的日志
  static void loggingExample() {
    Logger.separator(title: '日志记录示例');

    // 调试日志
    Logger.d('这是调试信息', tag: 'Example');

    // 信息日志
    Logger.i('这是信息日志', tag: 'Example');

    // 警告日志
    Logger.w('这是警告日志', tag: 'Example');

    // 错误日志
    Logger.e('这是错误日志', tag: 'Example');

    // 成功日志
    Logger.s('这是成功日志', tag: 'Example');

    // 网络日志
    Logger.net('这是网络日志', tag: 'Example');

    // 定位日志
    Logger.loc('这是定位日志', tag: 'Example');

    // AI日志
    Logger.ai('这是AI日志', tag: 'Example');

    // 缓存日志
    Logger.cache('这是缓存日志', tag: 'Example');

    // 性能日志
    Logger.perf('这是性能日志', tag: 'Example');

    // 用户操作日志
    Logger.user('这是用户操作日志', tag: 'Example');

    Logger.separator();
  }

  /// 示例6: 性能计时
  static void performanceExample() {
    Logger.startPerf('示例操作');

    // 模拟耗时操作
    for (int i = 0; i < 1000000; i++) {
      // 空循环
    }

    Logger.endPerf('示例操作');
  }
}
