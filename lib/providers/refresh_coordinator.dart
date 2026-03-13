import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// RefreshCoordinator - 定时刷新协调器
///
/// 职责：
/// - 管理定时刷新（每小时自动刷新天气数据）
/// - 管理后台刷新（应用进入后台/前台时刷新）
/// - Timer 生命周期管理
/// - 提供刷新回调接口
class RefreshCoordinator extends ChangeNotifier {
  // ===== 定时器 =====
  Timer? _hourlyRefreshTimer;
  Timer? _backgroundRefreshTimer;

  // ===== 配置 =====
  static const Duration _hourlyRefreshInterval = Duration(hours: 1);
  static const Duration _backgroundRefreshTimeout = Duration(minutes: 30);

  // ===== 状态标志 =====
  bool _isActive = false;
  DateTime? _appBackgroundSince;

  // ===== 回调函数 =====
  Future<void> Function()? _onHourlyRefresh;
  Future<void> Function()? _onAppResume;

  // ===== Getters =====
  bool get isActive => _isActive;
  bool get isAppInBackground => _appBackgroundSince != null;

  /// 启动协调器
  void start({
    Future<void> Function()? onHourlyRefresh,
    Future<void> Function()? onAppResume,
  }) {
    if (_isActive) {
      Logger.d('RefreshCoordinator 已在运行', tag: 'RefreshCoordinator');
      return;
    }

    _onHourlyRefresh = onHourlyRefresh;
    _onAppResume = onAppResume;
    _isActive = true;

    // 启动每小时定时刷新
    _startHourlyRefreshTimer();

    Logger.d('RefreshCoordinator 已启动', tag: 'RefreshCoordinator');
    notifyListeners();
  }

  /// 停止协调器
  void stop() {
    if (!_isActive) {
      return;
    }

    _hourlyRefreshTimer?.cancel();
    _backgroundRefreshTimer?.cancel();
    _hourlyRefreshTimer = null;
    _backgroundRefreshTimer = null;

    _isActive = false;
    _appBackgroundSince = null;

    Logger.d('RefreshCoordinator 已停止', tag: 'RefreshCoordinator');
    notifyListeners();
  }

  /// 启动每小时定时刷新
  void _startHourlyRefreshTimer() {
    _hourlyRefreshTimer?.cancel();

    _hourlyRefreshTimer = Timer.periodic(_hourlyRefreshInterval, (_) {
      Logger.d('执行每小时定时刷新', tag: 'RefreshCoordinator');
      _onHourlyRefresh?.call();
    });

    Logger.d('每小时定时刷新已启动', tag: 'RefreshCoordinator');
  }

  /// 应用进入后台
  void onAppPaused() {
    _appBackgroundSince = DateTime.now();
    Logger.d('应用进入后台: $_appBackgroundSince', tag: 'RefreshCoordinator');

    // 启动后台超时检查
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer(_backgroundRefreshTimeout, () {
      if (_appBackgroundSince != null) {
        Logger.d(
          '应用在后台超过 ${_backgroundRefreshTimeout.inMinutes} 分钟，停止刷新',
          tag: 'RefreshCoordinator',
        );
        stop();
      }
    });

    notifyListeners();
  }

  /// 应用恢复到前台
  Future<void> onAppResumed() async {
    if (_appBackgroundSince == null) {
      return;
    }

    final backgroundDuration = DateTime.now().difference(_appBackgroundSince!);
    Logger.d('应用恢复到前台，后台时长: $backgroundDuration', tag: 'RefreshCoordinator');

    // 取消后台超时检查
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;

    // 如果在后台超过超时时间，可能需要重新初始化
    if (backgroundDuration > _backgroundRefreshTimeout) {
      Logger.d(
        '应用在后台超过 ${_backgroundRefreshTimeout.inMinutes} 分钟，建议重新初始化',
        tag: 'RefreshCoordinator',
      );
      // 这里可以触发完全重启的逻辑
    }

    _appBackgroundSince = null;

    // 执行恢复回调
    await _onAppResume?.call();

    notifyListeners();
  }

  /// 手动触发刷新
  Future<void> triggerRefresh() async {
    Logger.d('手动触发刷新', tag: 'RefreshCoordinator');
    await _onHourlyRefresh?.call();
  }

  /// 重置每小时定时器（用于数据更新后重新计时）
  void resetHourlyTimer() {
    if (_isActive && _onHourlyRefresh != null) {
      _startHourlyRefreshTimer();
      Logger.d('每小时定时器已重置', tag: 'RefreshCoordinator');
    }
  }

  /// 释放资源
  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
