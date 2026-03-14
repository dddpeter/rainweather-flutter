import 'package:flutter/foundation.dart';

/// 应用日志工具类
///
/// 提供统一的日志输出接口，支持：
/// - 日志级别分类 (debug, info, warning, error)
/// - 标签分类
/// - Release 模式自动禁用
/// - 结构化数据输出
///
/// 使用示例：
/// ```dart
/// AppLogger.d('定位成功', tag: 'Location', data: {'lat': 39.9, 'lng': 116.4});
/// AppLogger.e('网络请求失败', tag: 'Network', error: e);
/// ```
class AppLogger {
  // 私有构造函数，防止实例化
  AppLogger._();

  /// 是否启用调试日志
  /// 仅在 Debug 模式下输出日志
  static bool get _enableDebug => kDebugMode;

  /// 日志标签颜色映射（终端输出用）
  static const String _reset = '\x1B[0m';
  static const String _blue = '\x1B[34m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _cyan = '\x1B[36m';

  /// 调试日志
  ///
  /// 用于输出调试信息，仅在 Debug 模式下显示
  static void d(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    if (!_enableDebug) return;
    _log('DEBUG', message, tag: tag, data: data, color: _cyan);
  }

  /// 信息日志
  ///
  /// 用于输出一般信息
  static void i(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    if (!_enableDebug) return;
    _log('INFO', message, tag: tag, data: data, color: _green);
  }

  /// 警告日志
  ///
  /// 用于输出警告信息
  static void w(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    if (!_enableDebug) return;
    _log('WARN', message, tag: tag, data: data, color: _yellow);
  }

  /// 错误日志
  ///
  /// 用于输出错误信息，包含错误堆栈
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (!_enableDebug) return;
    _log(
      'ERROR',
      message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
      color: _red,
    );
  }

  /// 网络请求日志
  ///
  /// 专门用于网络请求的日志输出
  static void network(
    String method,
    String url, {
    int? statusCode,
    Duration? duration,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    Object? error,
  }) {
    if (!_enableDebug) return;

    final buffer = StringBuffer();
    buffer.write('$method $url');

    if (statusCode != null) {
      buffer.write(' [$statusCode]');
    }

    if (duration != null) {
      buffer.write(' (${duration.inMilliseconds}ms)');
    }

    if (requestData != null && requestData.isNotEmpty) {
      buffer.write('\n  Request: $requestData');
    }

    if (responseData != null && responseData.isNotEmpty) {
      buffer.write('\n  Response: $responseData');
    }

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    _log('NETWORK', buffer.toString(), tag: 'HTTP', color: _blue);
  }

  /// 性能日志
  ///
  /// 用于记录性能相关信息
  static void performance(
    String operation,
    Duration duration, {
    String? tag,
    Map<String, dynamic>? metrics,
  }) {
    if (!_enableDebug) return;

    final buffer = StringBuffer();
    buffer.write('$operation: ${duration.inMilliseconds}ms');

    if (metrics != null && metrics.isNotEmpty) {
      buffer.write(' | $metrics');
    }

    _log('PERF', buffer.toString(), tag: tag ?? 'Performance', color: _green);
  }

  /// 核心日志输出方法
  static void _log(
    String level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
    String color = _reset,
  }) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    final tagStr = tag != null ? '[$tag] ' : '';
    final levelStr = '$color[$level]$_reset';

    // 构建日志消息
    final buffer = StringBuffer();
    buffer.write('$timestamp $levelStr$tagStr$message');

    // 添加数据
    if (data != null && data.isNotEmpty) {
      buffer.write('\n  Data: $data');
    }

    // 添加错误信息
    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    // 添加堆栈跟踪
    if (stackTrace != null) {
      buffer.write('\n  StackTrace:\n${_formatStackTrace(stackTrace)}');
    }

    // 使用 debugPrint 输出
    debugPrint(buffer.toString());
  }

  /// 格式化堆栈跟踪
  ///
  /// 只保留关键信息，减少输出长度
  static String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    // 只保留前5行关键信息
    final relevantLines = lines.take(5).map((line) {
      // 提取文件名和行号
      final match = RegExp(r'(\w+\.dart):(\d+)').firstMatch(line);
      if (match != null) {
        return '    ${match.group(1)}:${match.group(2)}';
      }
      return '    ${line.trim()}';
    }).join('\n');
    return relevantLines;
  }
}

/// 日志扩展方法
///
/// 为常用类提供便捷的日志输出方法
extension LoggerExtension on Object {
  /// 打印对象信息
  void logDebug({String? tag}) {
    AppLogger.d(toString(), tag: tag);
  }

  /// 打印对象错误信息
  void logError({String? tag, StackTrace? stackTrace}) {
    AppLogger.e(toString(), tag: tag, stackTrace: stackTrace);
  }
}
