import 'dart:io';
import 'package:flutter/foundation.dart';

/// 请求类型枚举
enum RequestType {
  weather, // 天气数据请求
  ai, // AI请求
  location, // 定位请求
  city, // 城市数据请求
  config, // 配置请求
  image, // 图片请求
}

/// 网络质量枚举
enum NetworkQuality {
  excellent, // 优秀 (< 100ms)
  good, // 良好 (100-300ms)
  fair, // 一般 (300-1000ms)
  poor, // 较差 (> 1000ms)
}

/// 网络配置服务
/// 管理不同类型的网络请求配置
class NetworkConfigService {
  static final NetworkConfigService _instance =
      NetworkConfigService._internal();
  factory NetworkConfigService() => _instance;
  NetworkConfigService._internal();

  /// 获取请求配置
  NetworkConfig getConfig(RequestType type) {
    switch (type) {
      case RequestType.weather:
        return NetworkConfig(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
          retryCount: 2,
          retryDelay: const Duration(seconds: 1),
        );

      case RequestType.ai:
        return NetworkConfig(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
          retryCount: 1,
          retryDelay: const Duration(seconds: 2),
        );

      case RequestType.location:
        return NetworkConfig(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 8),
          retryCount: 3,
          retryDelay: const Duration(seconds: 1),
        );

      case RequestType.city:
        return NetworkConfig(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 5),
          retryCount: 2,
          retryDelay: const Duration(seconds: 1),
        );

      case RequestType.config:
        return NetworkConfig(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 8),
          retryCount: 1,
          retryDelay: const Duration(seconds: 1),
        );

      case RequestType.image:
        return NetworkConfig(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
          retryCount: 1,
          retryDelay: const Duration(seconds: 2),
        );
    }
  }

  /// 获取HTTP客户端配置
  HttpClient getHttpClient(RequestType type) {
    final config = getConfig(type);
    final client = HttpClient();

    client.connectionTimeout = config.connectTimeout;
    client.idleTimeout = config.receiveTimeout;

    // 设置用户代理
    client.userAgent = 'RainWeather/1.0.0 (Flutter)';

    return client;
  }

  /// 为请求添加通用请求头
  void addCommonHeaders(HttpClientRequest request) {
    request.headers.set('Accept', 'application/json');
    request.headers.set('Accept-Encoding', 'gzip, deflate');
    request.headers.set('Connection', 'keep-alive');
  }

  /// 检查网络连接状态
  Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('baidu.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 网络连接检查失败: $e');
      }
      return false;
    }
  }

  /// 获取网络质量
  Future<NetworkQuality> getNetworkQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('baidu.com');
      stopwatch.stop();

      // 检查结果是否有效
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        return NetworkQuality.poor;
      }

      final latency = stopwatch.elapsedMilliseconds;

      if (latency < 100) {
        return NetworkQuality.excellent;
      } else if (latency < 300) {
        return NetworkQuality.good;
      } else if (latency < 1000) {
        return NetworkQuality.fair;
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 网络质量检测失败: $e');
      }
      return NetworkQuality.poor;
    }
  }

  /// 根据网络质量调整配置
  NetworkConfig adjustConfigForNetworkQuality(
    NetworkConfig baseConfig,
    NetworkQuality quality,
  ) {
    switch (quality) {
      case NetworkQuality.excellent:
        return baseConfig;

      case NetworkQuality.good:
        return baseConfig.copyWith(
          connectTimeout:
              baseConfig.connectTimeout + const Duration(seconds: 2),
          receiveTimeout:
              baseConfig.receiveTimeout + const Duration(seconds: 3),
        );

      case NetworkQuality.fair:
        return baseConfig.copyWith(
          connectTimeout:
              baseConfig.connectTimeout + const Duration(seconds: 5),
          receiveTimeout:
              baseConfig.receiveTimeout + const Duration(seconds: 8),
          retryCount: baseConfig.retryCount + 1,
        );

      case NetworkQuality.poor:
        return baseConfig.copyWith(
          connectTimeout:
              baseConfig.connectTimeout + const Duration(seconds: 10),
          receiveTimeout:
              baseConfig.receiveTimeout + const Duration(seconds: 15),
          retryCount: baseConfig.retryCount + 2,
          retryDelay: baseConfig.retryDelay + const Duration(seconds: 1),
        );
    }
  }
}

/// 网络配置类
class NetworkConfig {
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final int retryCount;
  final Duration retryDelay;

  const NetworkConfig({
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.retryCount,
    required this.retryDelay,
  });

  NetworkConfig copyWith({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int? retryCount,
    Duration? retryDelay,
  }) {
    return NetworkConfig(
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }

  @override
  String toString() {
    return 'NetworkConfig(connect: ${connectTimeout.inSeconds}s, '
        'receive: ${receiveTimeout.inSeconds}s, '
        'send: ${sendTimeout.inSeconds}s, '
        'retry: $retryCount, '
        'delay: ${retryDelay.inSeconds}s)';
  }
}
