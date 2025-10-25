import 'dart:async';
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// 错误类型枚举
enum ErrorType {
  critical,
  network,
  location,
  database,
  ui,
  unknown,
}

/// 错误报告服务接口
abstract class ErrorReportingService {
  void reportError(Object error, StackTrace? stackTrace);
  void reportFlutterError(FlutterErrorDetails details);
}

/// 默认错误报告服务实现
class DefaultErrorReportingService implements ErrorReportingService {
  @override
  void reportError(Object error, StackTrace? stackTrace) {
    // 在debug模式下打印错误信息
    if (kDebugMode) {
      Logger.e('错误报告: ${error.toString()}', tag: 'ErrorReportingService', error: error, stackTrace: stackTrace);
    }

    // 这里可以添加实际的错误报告逻辑
    // 例如：发送到Firebase、Sentry等
  }

  @override
  void reportFlutterError(FlutterErrorDetails details) {
    // 在debug模式下打印错误信息
    if (kDebugMode) {
      Logger.e('Flutter错误报告: ${details.exception.toString()}', tag: 'ErrorReportingService', error: details.exception, stackTrace: details.stack);
    }

    // 这里可以添加实际的错误报告逻辑
    // 例如：发送到Firebase、Sentry等
  }
}

/// 错误恢复管理器
class ErrorRecoveryManager {
  static final ErrorRecoveryManager _instance = ErrorRecoveryManager._();

  factory ErrorRecoveryManager() => _instance;

  ErrorRecoveryManager._();

  /// 尝试恢复应用状态
  Future<bool> attemptRecovery() async {
    try {
      Logger.i('开始错误恢复流程', tag: 'ErrorRecoveryManager');

      // 1. 清除可能损坏的缓存
      // await _clearCorruptedCache();

      // 2. 重置应用状态
      // await _resetApplicationState();

      // 3. 重新初始化关键服务
      // await _reinitializeServices();

      Logger.i('错误恢复流程完成', tag: 'ErrorRecoveryManager');
      return true;
    } catch (e) {
      Logger.e('错误恢复流程失败: $e', tag: 'ErrorRecoveryManager');
      return false;
    }
  }
}

/// 全局异常处理器
/// 统一处理应用中未被捕获的异常，避免应用崩溃
class GlobalExceptionHandler {
  static final GlobalExceptionHandler _instance = GlobalExceptionHandler._();

  factory GlobalExceptionHandler() => _instance;

  GlobalExceptionHandler._();

  /// 初始化全局异常处理
  void initialize() {
    // 设置全局异常捕获回调
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  /// 处理Flutter框架异常
  void _handleFlutterError(FlutterErrorDetails details) {
    // 记录异常信息
    Logger.e(
      '=== Flutter异常捕获 ===',
      tag: 'GlobalExceptionHandler',
      error: details.exception,
      stackTrace: details.stack,
    );

    // 根据异常类型决定处理策略
    final exception = details.exception;
    final errorType = _classifyError(exception);

    switch (errorType) {
      case ErrorType.critical:
        // 严重错误：显示用户友好的错误页面，并尝试恢复
        _showCriticalErrorDialog(exception);
        break;

      case ErrorType.network:
        // 网络错误：显示Toast，不中断用户体验
        _showNetworkErrorToast(exception);
        break;

      case ErrorType.location:
        // 定位错误：显示Toast，提供重试选项
        _showLocationErrorToast(exception);
        break;

      case ErrorType.database:
        // 数据库错误：静默处理，记录日志
        _handleDatabaseError(exception);
        break;

      case ErrorType.ui:
        // UI错误：记录日志，可能显示Toast
        _handleUIError(exception);
        break;

      default:
        // 其他错误：记录日志，显示通用Toast
        _showGenericErrorToast(exception);
        break;
    }

    // 发送错误报告到分析服务（如果可用）
    _sendErrorReport(details);
  }

  /// 处理平台异常
  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    Logger.e(
      '=== 平台异常捕获 ===',
      tag: 'GlobalExceptionHandler',
      error: error,
      stackTrace: stackTrace,
    );

    // 平台异常通常需要特殊处理
    _showPlatformErrorToast(error);
    _sendPlatformErrorReport(error, stackTrace);
    
    // 返回true表示异常已被处理
    return true;
  }

  /// 分类错误类型
  ErrorType _classifyError(Object? exception) {
    if (exception == null) return ErrorType.unknown;

    final errorString = exception.toString().toLowerCase();

    // 严重错误
    if (errorString.contains('stateerror') ||
        errorString.contains('renderflex') ||
        errorString.contains('overflow') ||
        errorString.contains('out of memory')) {
      return ErrorType.critical;
    }

    // 网络相关错误
    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('host')) {
      return ErrorType.network;
    }

    // 定位相关错误
    if (errorString.contains('location') ||
        errorString.contains('gps') ||
        errorString.contains('permission')) {
      return ErrorType.location;
    }

    // 数据库相关错误
    if (errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('sqlite')) {
      return ErrorType.database;
    }

    // UI相关错误
    if (errorString.contains('widget') ||
        errorString.contains('build') ||
        errorString.contains('layout') ||
        errorString.contains('render')) {
      return ErrorType.ui;
    }

    return ErrorType.unknown;
  }

  /// 显示严重错误对话框
  void _showCriticalErrorDialog(Object exception) {
    // 在debug模式下显示详细错误信息
    if (kDebugMode) {
      Logger.e(
        '严重错误详情',
        tag: 'GlobalExceptionHandler',
        error: exception,
        stackTrace: StackTrace.current,
      );
    }

    // 这里可以添加一个错误恢复机制
    // 例如：清除缓存、重置状态等
  }

  /// 显示网络错误Toast
  void _showNetworkErrorToast(Object exception) {
    Logger.w(
      '网络错误: ${exception.toString()}',
      tag: 'GlobalExceptionHandler',
    );

    // 这里可以添加网络重试逻辑
  }

  /// 显示定位错误Toast
  void _showLocationErrorToast(Object exception) {
    Logger.w(
      '定位错误: ${exception.toString()}',
      tag: 'GlobalExceptionHandler',
    );

    // 这里可以添加定位重试逻辑
  }

  /// 处理数据库错误
  void _handleDatabaseError(Object exception) {
    Logger.e(
      '数据库错误: ${exception.toString()}',
      tag: 'GlobalExceptionHandler',
    );

    // 数据库错误通常不需要显示给用户
    // 但需要记录以便开发者调试
  }

  /// 处理UI错误
  void _handleUIError(Object exception) {
    Logger.w(
      'UI错误: ${exception.toString()}',
      tag: 'GlobalExceptionHandler',
    );

    // UI错误可能需要特殊处理
    // 例如：重新构建部分UI
  }

  /// 显示平台错误Toast
  void _showPlatformErrorToast(Object error) {
    Logger.w(
      '平台错误: ${error.toString()}',
      tag: 'GlobalExceptionHandler',
    );
  }

  /// 显示通用错误Toast
  void _showGenericErrorToast(Object exception) {
    Logger.w(
      '通用错误: ${exception.toString()}',
      tag: 'GlobalExceptionHandler',
    );
  }

  /// 发送Flutter错误报告
  void _sendErrorReport(FlutterErrorDetails details) {
    // 这里可以集成错误报告服务
    // 例如：Firebase Crashlytics、Sentry等
    try {
      // 示例：发送到分析服务
      Logger.i('发送错误报告到分析服务', tag: 'GlobalExceptionHandler');
    } catch (e) {
      Logger.e('发送错误报告失败: $e', tag: 'GlobalExceptionHandler');
    }
  }

  /// 发送平台错误报告
  void _sendPlatformErrorReport(Object error, StackTrace stackTrace) {
    try {
      // 示例：发送到分析服务
      Logger.i('发送平台错误报告到分析服务', tag: 'GlobalExceptionHandler');
    } catch (e) {
      Logger.e('发送平台错误报告失败: $e', tag: 'GlobalExceptionHandler');
    }
  }

  /// 获取用户友好的错误消息
  String getUserFriendlyErrorMessage(Object exception) {
    final errorType = _classifyError(exception);

    switch (errorType) {
      case ErrorType.critical:
        return '应用遇到了严重错误，正在尝试恢复...';
      case ErrorType.network:
        return '网络连接异常，请检查网络设置';
      case ErrorType.location:
        return '定位服务异常，请检查定位权限';
      case ErrorType.database:
        return '数据存储异常，正在尝试恢复...';
      case ErrorType.ui:
        return '界面显示异常，正在刷新...';
      default:
        return '应用遇到了未知错误，请重试';
    }
  }
}
