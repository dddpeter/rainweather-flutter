import 'app_state_manager.dart';

/// 应用状态调试工具
class AppStateDebug {
  /// 打印应用状态信息
  static Future<void> printStatus() async {
    final appStateManager = AppStateManager();
    final status = await appStateManager.getStatusInfo();

    print('📱 === 应用状态信息 ===');
    print('🚀 应用完全启动: ${status['isAppFullyStarted']}');
    print('🔄 正在初始化: ${status['isInitializing']}');
    print('⏰ 初始化时间: ${status['initializationTime'] ?? '未设置'}');
    print('📍 最后定位时间: ${status['lastLocationTime'] ?? '未设置'}');
    print('✅ 允许定位: ${status['canPerformLocation']}');
    print('✅ 允许获取数据: ${status['canFetchWeatherData']}');
    print('📱 === 状态信息结束 ===');
  }

  /// 重置应用状态（仅用于调试）
  static void reset() {
    print('🔄 调试：重置应用状态');
    AppStateManager().reset();
  }
}
