import '../providers/weather_provider.dart';
import '../utils/persistent_app_state.dart';
import '../utils/app_health_check.dart';
import '../utils/smart_refresh_scheduler.dart';
import '../utils/app_state_manager.dart';

/// 恢复策略类型
enum RecoveryStrategy {
  fullRestart, // 完全重启
  heavyRefresh, // 重度刷新
  lightRefresh, // 轻度刷新
  quickCheck, // 快速检查
}

/// 应用恢复管理器
class AppRecoveryManager {
  static final AppRecoveryManager _instance = AppRecoveryManager._internal();
  factory AppRecoveryManager() => _instance;
  AppRecoveryManager._internal();

  // 恢复策略阈值（分钟）
  static const int _fullRestartThreshold = 60; // 1小时
  static const int _heavyRefreshThreshold = 10; // 10分钟
  static const int _lightRefreshThreshold = 5; // 5分钟

  /// 处理应用恢复
  Future<void> handleResume(WeatherProvider weatherProvider) async {
    print('\n🔄 ========== 应用恢复管理器 ==========');

    try {
      // 1. 获取后台时长
      final persistentState = await PersistentAppState.getInstance();
      final backgroundDuration = await persistentState.getBackgroundDuration();

      // 2. 检查是否被系统杀死
      final wasKilled = await persistentState.wasKilledBySystem();

      // 3. 确定恢复策略
      final strategy = _determineStrategy(backgroundDuration, wasKilled);
      print('📋 恢复策略: ${_getStrategyName(strategy)}');

      // 4. 执行恢复策略
      await _executeStrategy(strategy, backgroundDuration, weatherProvider);

      // 5. 保存状态
      await persistentState.saveState();

      print('✅ ========== 应用恢复完成 ==========\n');
    } catch (e) {
      print('❌ 应用恢复失败: $e');
      // 即使失败也尝试快速检查
      await _quickCheck(weatherProvider);
    }
  }

  /// 确定恢复策略
  RecoveryStrategy _determineStrategy(
    Duration? backgroundDuration,
    bool wasKilled,
  ) {
    // 如果被系统杀死，直接完全重启
    if (wasKilled) {
      print('⚠️ 检测到应用被系统杀死，需要完全重启');
      return RecoveryStrategy.fullRestart;
    }

    // 如果没有后台时长记录，快速检查
    if (backgroundDuration == null) {
      print('ℹ️ 无后台时长记录，执行快速检查');
      return RecoveryStrategy.quickCheck;
    }

    final minutes = backgroundDuration.inMinutes;
    print('⏱️ 后台时长: $minutes 分钟');

    // 根据后台时长决定策略
    if (minutes >= _fullRestartThreshold) {
      print('🔴 超过 $_fullRestartThreshold 分钟，需要完全重启');
      return RecoveryStrategy.fullRestart;
    } else if (minutes >= _heavyRefreshThreshold) {
      print('🟡 超过 $_heavyRefreshThreshold 分钟，需要重度刷新');
      return RecoveryStrategy.heavyRefresh;
    } else if (minutes >= _lightRefreshThreshold) {
      print('🟢 超过 $_lightRefreshThreshold 分钟，需要轻度刷新');
      return RecoveryStrategy.lightRefresh;
    } else {
      print('🔵 后台时间较短，快速检查即可');
      return RecoveryStrategy.quickCheck;
    }
  }

  /// 执行恢复策略
  Future<void> _executeStrategy(
    RecoveryStrategy strategy,
    Duration? backgroundDuration,
    WeatherProvider weatherProvider,
  ) async {
    switch (strategy) {
      case RecoveryStrategy.fullRestart:
        await _fullRestart(weatherProvider);
        break;
      case RecoveryStrategy.heavyRefresh:
        await _heavyRefresh(backgroundDuration, weatherProvider);
        break;
      case RecoveryStrategy.lightRefresh:
        await _lightRefresh(weatherProvider);
        break;
      case RecoveryStrategy.quickCheck:
        await _quickCheck(weatherProvider);
        break;
    }
  }

  /// 完全重启
  Future<void> _fullRestart(WeatherProvider weatherProvider) async {
    print('\n🔴 执行完全重启策略');

    try {
      // 1. 健康检查
      print('📋 步骤 1/5: 健康检查');
      final healthCheck = AppHealthCheck();
      final report = await healthCheck.performCheck(verbose: true);

      // 2. 修复问题
      if (!report.isHealthy) {
        print('📋 步骤 2/5: 修复检测到的问题');
        await healthCheck.fixIssues(report);
      } else {
        print('📋 步骤 2/5: 系统健康，无需修复');
      }

      // 3. 重置应用状态
      print('📋 步骤 3/5: 重置应用状态');
      AppStateManager().reset();

      // 4. 重新初始化
      print('📋 步骤 4/5: 重新初始化应用');
      await weatherProvider.initializeWeather();

      // 5. 标记完成
      print('📋 步骤 5/5: 标记应用启动完成');
      AppStateManager().markAppFullyStarted();

      print('✅ 完全重启完成');
    } catch (e) {
      print('❌ 完全重启失败: $e');
      // 降级到重度刷新
      await _heavyRefresh(null, weatherProvider);
    }
  }

  /// 重度刷新
  Future<void> _heavyRefresh(
    Duration? backgroundDuration,
    WeatherProvider weatherProvider,
  ) async {
    print('\n🟡 执行重度刷新策略');

    try {
      // 1. 快速健康检查
      print('📋 步骤 1/4: 快速健康检查');
      final healthCheck = AppHealthCheck();
      final isHealthy = await healthCheck.quickCheck();

      if (!isHealthy) {
        print('⚠️ 快速检查发现问题，执行完整检查');
        final report = await healthCheck.performCheck();
        await healthCheck.fixIssues(report);
      }

      // 2. 检查定位服务
      print('📋 步骤 2/4: 检查定位服务');
      final scheduler = SmartRefreshScheduler();
      if (await scheduler.needsLocationUpdate()) {
        print('📍 需要更新定位');
      }

      // 3. 智能刷新所有数据
      print('📋 步骤 3/4: 智能刷新数据');
      if (backgroundDuration != null) {
        await scheduler.executeSmartRefresh(
          backgroundDuration,
          weatherProvider,
        );
      } else {
        await scheduler.fullRefresh(weatherProvider);
      }

      // 4. 保存更新时间
      print('📋 步骤 4/4: 保存更新时间');
      final persistentState = await PersistentAppState.getInstance();
      await persistentState.saveWeatherUpdateTime();

      print('✅ 重度刷新完成');
    } catch (e) {
      print('❌ 重度刷新失败: $e');
      // 降级到轻度刷新
      await _lightRefresh(weatherProvider);
    }
  }

  /// 轻度刷新
  Future<void> _lightRefresh(WeatherProvider weatherProvider) async {
    print('\n🟢 执行轻度刷新策略');

    try {
      // 1. 快速健康检查
      print('📋 步骤 1/2: 快速健康检查');
      final healthCheck = AppHealthCheck();
      await healthCheck.quickCheck();

      // 2. 刷新关键数据
      print('📋 步骤 2/2: 刷新关键数据');
      final scheduler = SmartRefreshScheduler();
      await scheduler.lightRefresh(weatherProvider);

      print('✅ 轻度刷新完成');
    } catch (e) {
      print('❌ 轻度刷新失败: $e');
    }
  }

  /// 快速检查
  Future<void> _quickCheck(WeatherProvider weatherProvider) async {
    print('\n🔵 执行快速检查策略');

    try {
      // 仅验证连接和基本状态
      final healthCheck = AppHealthCheck();
      final isHealthy = await healthCheck.quickCheck();

      if (!isHealthy) {
        print('⚠️ 快速检查发现问题，升级到轻度刷新');
        await _lightRefresh(weatherProvider);
      } else {
        print('✅ 快速检查完成，系统正常');
      }
    } catch (e) {
      print('❌ 快速检查失败: $e');
    }
  }

  /// 获取策略名称
  String _getStrategyName(RecoveryStrategy strategy) {
    switch (strategy) {
      case RecoveryStrategy.fullRestart:
        return '完全重启';
      case RecoveryStrategy.heavyRefresh:
        return '重度刷新';
      case RecoveryStrategy.lightRefresh:
        return '轻度刷新';
      case RecoveryStrategy.quickCheck:
        return '快速检查';
    }
  }

  /// 处理应用进入后台
  Future<void> handlePause() async {
    print('\n📱 应用进入后台，保存状态');

    try {
      final persistentState = await PersistentAppState.getInstance();

      // 保存当前时间
      await persistentState.saveState(
        lastActive: DateTime.now(),
        wasProperlyShutdown: false, // 标记为未正常关闭
      );

      print('✅ 状态已保存');
    } catch (e) {
      print('❌ 保存状态失败: $e');
    }
  }

  /// 处理应用正常关闭
  Future<void> handleShutdown() async {
    print('\n📱 应用正常关闭，保存状态');

    try {
      final persistentState = await PersistentAppState.getInstance();
      await persistentState.markProperShutdown();
      print('✅ 正常关闭标记已保存');
    } catch (e) {
      print('❌ 保存关闭标记失败: $e');
    }
  }
}
