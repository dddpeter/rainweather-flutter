import 'persistent_app_state.dart';

/// 应用状态管理器
/// 用于防止重复定位和数据获取
/// 现在与持久化状态集成
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();

  AppStateManager._internal();

  factory AppStateManager() {
    return _instance;
  }

  // 应用是否完全启动
  bool _isAppFullyStarted = false;

  // 是否正在初始化
  bool _isInitializing = false;

  // 初始化完成时间戳
  // DateTime? _initializationTime;

  // 最后一次定位时间
  DateTime? _lastLocationTime;

  // 定位冷却时间（秒）
  static const int _locationCooldownSeconds = 30;

  // 持久化状态管理器
  PersistentAppState? _persistentState;

  /// 检查应用是否完全启动
  bool get isAppFullyStarted => _isAppFullyStarted;

  /// 检查是否正在初始化
  bool get isInitializing => _isInitializing;

  /// 初始化（从持久化状态恢复）
  Future<void> initialize() async {
    if (_persistentState == null) {
      _persistentState = await PersistentAppState.getInstance();
      print('✅ AppStateManager: 持久化状态管理器已初始化');
    }
  }

  /// 标记应用完全启动
  Future<void> markAppFullyStarted() async {
    print('🚀 AppStateManager: 应用已完全启动');
    _isAppFullyStarted = true;
    // _initializationTime = DateTime.now();

    // 保存到持久化状态
    await _ensureInitialized();
    await _persistentState?.markAppStarted();
  }

  /// 标记开始初始化
  Future<void> markInitializationStarted() async {
    if (_isInitializing) {
      print('⚠️ AppStateManager: 初始化已在进行中，跳过重复初始化');
      return;
    }
    print('🔄 AppStateManager: 开始初始化');
    _isInitializing = true;
  }

  /// 标记初始化完成
  Future<void> markInitializationCompleted() async {
    print('✅ AppStateManager: 初始化完成');
    _isInitializing = false;
    _lastLocationTime = DateTime.now();

    // 保存定位时间到持久化状态
    await _ensureInitialized();
    await _persistentState?.saveLocationUpdateTime();
  }

  /// 检查是否可以执行定位
  bool canPerformLocation() {
    // 如果应用未完全启动，不允许定位
    if (!_isAppFullyStarted) {
      print('🚫 AppStateManager: 应用未完全启动，不允许定位');
      return false;
    }

    // 如果正在初始化，不允许重复定位
    if (_isInitializing) {
      print('🚫 AppStateManager: 正在初始化中，不允许重复定位');
      return false;
    }

    // 检查定位冷却时间
    if (_lastLocationTime != null) {
      final timeSinceLastLocation = DateTime.now().difference(
        _lastLocationTime!,
      );
      if (timeSinceLastLocation.inSeconds < _locationCooldownSeconds) {
        print(
          '🚫 AppStateManager: 距离上次定位时间过短 (${timeSinceLastLocation.inSeconds}s < ${_locationCooldownSeconds}s)，跳过定位',
        );
        return false;
      }
    }

    print('✅ AppStateManager: 允许执行定位');
    return true;
  }

  /// 标记定位完成
  Future<void> markLocationCompleted() async {
    _lastLocationTime = DateTime.now();
    print('📍 AppStateManager: 定位完成，更新时间戳');

    // 保存到持久化状态
    await _ensureInitialized();
    await _persistentState?.saveLocationUpdateTime();
  }

  /// 检查是否可以获取天气数据
  bool canFetchWeatherData() {
    // 如果应用未完全启动，不允许获取数据
    if (!_isAppFullyStarted) {
      print('🚫 AppStateManager: 应用未完全启动，不允许获取天气数据');
      return false;
    }

    print('✅ AppStateManager: 允许获取天气数据');
    return true;
  }

  /// 重置应用状态（用于测试或重新启动）
  Future<void> reset() async {
    print('🔄 AppStateManager: 重置应用状态');
    _isAppFullyStarted = false;
    _isInitializing = false;
    // _initializationTime = null;
    _lastLocationTime = null;

    // 清除持久化状态
    await _ensureInitialized();
    await _persistentState?.clearState();
  }

  /// 检查应用是否被系统杀死
  Future<bool> wasKilledBySystem() async {
    await _ensureInitialized();
    return await _persistentState?.wasKilledBySystem() ?? false;
  }

  /// 确保持久化状态已初始化
  Future<void> _ensureInitialized() async {
    if (_persistentState == null) {
      await initialize();
    }
  }

  // /// 获取状态信息（用于调试）
  // Future<Map<String, dynamic>> getStatusInfo() async {
  //   await _ensureInitialized();
  //   final canPerform = await canPerformLocation();

  //   return {
  //     'isAppFullyStarted': _isAppFullyStarted,
  //     'isInitializing': _isInitializing,
  //     'initializationTime': _initializationTime?.toIso8601String(),
  //     'lastLocationTime': _lastLocationTime?.toIso8601String(),
  //     'canPerformLocation': canPerform,
  //     'canFetchWeatherData': canFetchWeatherData(),
  //     'wasKilledBySystem': await wasKilledBySystem(),
  //   };
  // }
}
