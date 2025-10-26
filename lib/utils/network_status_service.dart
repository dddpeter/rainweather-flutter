import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 网络连接状态
enum NetworkStatus {
  connected, // 已连接
  disconnected, // 未连接
  unknown, // 未知
}

/// 网络状态监听服务
/// 提供网络状态检测和变化监听功能
class NetworkStatusService extends ChangeNotifier {
  static final NetworkStatusService _instance =
      NetworkStatusService._internal();
  factory NetworkStatusService() => _instance;
  NetworkStatusService._internal();

  NetworkStatus _currentStatus = NetworkStatus.unknown;
  Timer? _statusCheckTimer;

  /// 当前网络状态
  NetworkStatus get currentStatus => _currentStatus;

  /// 是否已连接
  bool get isConnected => _currentStatus == NetworkStatus.connected;

  /// 是否离线
  bool get isOffline => _currentStatus == NetworkStatus.disconnected;

  /// 初始化服务
  Future<void> initialize() async {
    // 立即检查一次网络状态
    await checkNetworkStatus();

    // 启动定期检查（每30秒检查一次）
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await checkNetworkStatus();
    });
  }

  /// 检查网络状态
  Future<NetworkStatus> checkNetworkStatus() async {
    try {
      final result = await InternetAddress.lookup(
        'www.baidu.com',
      ).timeout(const Duration(seconds: 3));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _updateStatus(NetworkStatus.connected);
        return NetworkStatus.connected;
      } else {
        _updateStatus(NetworkStatus.disconnected);
        return NetworkStatus.disconnected;
      }
    } on SocketException catch (_) {
      _updateStatus(NetworkStatus.disconnected);
      return NetworkStatus.disconnected;
    } catch (e) {
      if (kDebugMode) {
        print('网络状态检查失败: $e');
      }
      _updateStatus(NetworkStatus.unknown);
      return NetworkStatus.unknown;
    }
  }

  /// 更新网络状态
  void _updateStatus(NetworkStatus newStatus) {
    if (_currentStatus != newStatus) {
      final oldStatus = _currentStatus;
      _currentStatus = newStatus;

      if (kDebugMode) {
        print('网络状态变化: ${oldStatus.name} -> ${newStatus.name}');
      }

      // 通知监听者
      notifyListeners();
    }
  }

  /// 检查网络是否可用（快速检查）
  Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup(
        'www.baidu.com',
      ).timeout(const Duration(seconds: 2));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 销毁服务
  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  /// 单例销毁（用于测试）
  static void reset() {
    _instance._statusCheckTimer?.cancel();
    _instance._currentStatus = NetworkStatus.unknown;
  }
}
