import 'package:flutter/foundation.dart';

/// 统一日志管理工具
/// 支持不同级别的日志输出，在Release模式下自动过滤调试信息
class Logger {
  static const String _tag = 'RainWeather';

  /// 是否启用调试日志（Release模式下自动禁用）
  static bool get _isDebugMode => !kReleaseMode;

  /// 调试级别日志
  static void d(String message, {String? tag}) {
    if (_isDebugMode) {
      _print('🔍', message, tag: tag);
    }
  }

  /// 信息级别日志
  static void i(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('ℹ️', message, tag: tag, error: error);
    }
  }

  /// 警告级别日志
  static void w(String message, {String? tag, Object? error}) {
    _print('⚠️', message, tag: tag, error: error);
  }

  /// 错误级别日志（始终显示）
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _print('❌', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 成功级别日志
  static void s(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('✅', message, tag: tag, error: error);
    }
  }

  /// 网络请求日志
  static void net(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('🌐', message, tag: tag, error: error);
    }
  }

  /// 定位相关日志
  static void loc(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('📍', message, tag: tag, error: error);
    }
  }

  /// AI相关日志
  static void ai(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('🤖', message, tag: tag, error: error);
    }
  }

  /// 缓存相关日志
  static void cache(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('💾', message, tag: tag, error: error);
    }
  }

  /// 性能相关日志
  static void perf(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('⚡', message, tag: tag, error: error);
    }
  }

  /// 用户操作日志
  static void user(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      _print('👤', message, tag: tag, error: error);
    }
  }

  /// 通用日志方法（用于替换 print()）
  /// 在 Debug 模式下显示，Release 模式下过滤
  static void log(dynamic message, {String? tag}) {
    if (_isDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      final finalTag = tag ?? _tag;
      print('[$timestamp] 📝 $finalTag: $message');
    }
  }

  /// 内部打印方法
  static void _print(
    String prefix,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final finalTag = tag ?? _tag;
    String errorMessage = '';
    if (error != null) {
      errorMessage = ' Error: $error';
    }
    String stackTraceMessage = '';
    if (stackTrace != null) {
      stackTraceMessage = ' StackTrace: $stackTrace';
    }
    print(
      '[$timestamp] $prefix $finalTag: $message$errorMessage$stackTraceMessage',
    );
  }

  /// 分隔线
  static void separator({String? title}) {
    if (_isDebugMode) {
      if (title != null) {
        print('\n═════════════════════════════════════════');
        print('║  $title');
        print('═════════════════════════════════════════\n');
      } else {
        print('─────────────────────────────────────────');
      }
    }
  }

  /// 性能计时开始
  static String? _perfStartTime;

  static void startPerf(String operation) {
    if (_isDebugMode) {
      _perfStartTime = DateTime.now().toString();
      perf('⏱️ 开始: $operation');
    }
  }

  /// 性能计时结束
  static void endPerf(String operation) {
    if (_isDebugMode && _perfStartTime != null) {
      final startTime = DateTime.parse(_perfStartTime!);
      final duration = DateTime.now().difference(startTime);
      perf('⏱️ 结束: $operation (${duration.inMilliseconds}ms)');
      _perfStartTime = null;
    }
  }
}
