import 'dart:async';
import 'package:flutter/foundation.dart';

/// 请求去重服务
/// 防止相同请求并发执行，提高性能和稳定性
class RequestDeduplicator {
  static final RequestDeduplicator _instance = RequestDeduplicator._internal();
  factory RequestDeduplicator() => _instance;
  RequestDeduplicator._internal();

  /// 存储正在进行的请求
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  /// 请求超时时间（秒）
  static const int _requestTimeoutSeconds = 30;

  /// 执行去重请求
  /// [key] 请求的唯一标识
  /// [request] 实际的请求函数
  /// [T] 返回类型
  Future<T> execute<T>(String key, Future<T> Function() request) async {
    // 如果相同请求正在进行，等待其完成
    if (_pendingRequests.containsKey(key)) {
      if (kDebugMode) {
        print('🔄 请求去重：等待相同请求完成 - $key');
      }
      return await _pendingRequests[key]!.future as T;
    }

    // 创建新的请求
    final completer = Completer<T>();
    _pendingRequests[key] = completer;

    try {
      if (kDebugMode) {
        print('🚀 开始执行请求 - $key');
      }

      // 执行实际请求，设置超时
      final result = await request().timeout(
        const Duration(seconds: _requestTimeoutSeconds),
        onTimeout: () {
          throw TimeoutException(
            '请求超时',
            const Duration(seconds: _requestTimeoutSeconds),
          );
        },
      );

      // 请求成功，完成并返回结果
      completer.complete(result);
      return result;
    } catch (e) {
      // 请求失败，完成并抛出异常
      completer.completeError(e);
      rethrow;
    } finally {
      // 清理请求记录
      _pendingRequests.remove(key);
      if (kDebugMode) {
        print('✅ 请求完成并清理 - $key');
      }
    }
  }

  /// 取消指定请求
  void cancel(String key) {
    final completer = _pendingRequests.remove(key);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(Exception('请求被取消'));
      if (kDebugMode) {
        print('❌ 请求已取消 - $key');
      }
    }
  }

  /// 取消所有请求
  void cancelAll() {
    for (final key in _pendingRequests.keys.toList()) {
      cancel(key);
    }
    if (kDebugMode) {
      print('🛑 所有请求已取消');
    }
  }

  /// 获取当前正在进行的请求数量
  int get pendingRequestCount => _pendingRequests.length;

  /// 检查是否有指定请求正在进行
  bool isRequestPending(String key) => _pendingRequests.containsKey(key);

  /// 获取所有正在进行的请求键
  List<String> get pendingRequestKeys => _pendingRequests.keys.toList();
}

/// 请求键生成器
class RequestKeyGenerator {
  /// 生成天气请求键
  static String weatherRequest(String cityName, {String? type}) {
    return 'weather_${cityName}_${type ?? 'current'}';
  }

  /// 生成AI请求键
  static String aiRequest(String prompt, {String? type}) {
    final hash = prompt.hashCode;
    return 'ai_${type ?? 'general'}_$hash';
  }

  /// 生成定位请求键
  static String locationRequest({String? provider}) {
    return 'location_${provider ?? 'default'}';
  }

  /// 生成缓存请求键
  static String cacheRequest(String key, {String? type}) {
    return 'cache_${type ?? 'default'}_$key';
  }
}
