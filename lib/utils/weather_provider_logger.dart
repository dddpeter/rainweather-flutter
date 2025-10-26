import 'package:flutter/foundation.dart';

/// WeatherProvider专用日志工具
/// 支持日志级别控制，可在生产环境关闭详细日志
class WeatherProviderLogger {
  // 日志级别开关
  static bool _enableDebugLogs = kDebugMode; // Debug模式默认开启
  static bool _enableInfoLogs = true;
  static bool _enableErrorLogs = true;

  /// 启用/禁用Debug日志
  static void setEnableDebugLogs(bool enable) {
    _enableDebugLogs = enable;
  }

  /// Debug日志（详细信息，如变量值、中间状态）
  static void debug(String message, {String? tag}) {
    if (_enableDebugLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('🐛 $prefix$message');
    }
  }

  /// Info日志（一般信息，如流程节点）
  static void info(String message, {String? tag}) {
    if (_enableInfoLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('ℹ️ $prefix$message');
    }
  }

  /// Success日志（成功提示）
  static void success(String message, {String? tag}) {
    if (_enableInfoLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('✅ $prefix$message');
    }
  }

  /// Warning日志（警告信息）
  static void warning(String message, {String? tag}) {
    if (_enableInfoLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('⚠️ $prefix$message');
    }
  }

  /// Error日志（错误信息）
  static void error(String message, {String? tag}) {
    if (_enableErrorLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('❌ $prefix$message');
    }
  }

  /// 分隔线（用于分段）
  static void separator(String title) {
    if (_enableInfoLogs) {
      print('═══ $title ═══');
    }
  }

  /// 标题框（用于重要节点）
  static void box(String title) {
    if (_enableInfoLogs) {
      print('╔════════════════════════════════════════╗');
      print('║  $title  ║');
      print('╚════════════════════════════════════════╝');
    }
  }

  /// 步骤日志（用于多步骤流程）
  static void step(int stepNumber, String message) {
    if (_enableDebugLogs) {
      print('   $stepNumber. $message');
    }
  }
}
