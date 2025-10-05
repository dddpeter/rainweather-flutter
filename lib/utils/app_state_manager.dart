/// 应用状态管理器
/// 用于防止重复定位和数据获取
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
  DateTime? _initializationTime;
  
  // 最后一次定位时间
  DateTime? _lastLocationTime;
  
  // 定位冷却时间（秒）
  static const int _locationCooldownSeconds = 30;
  
  /// 检查应用是否完全启动
  bool get isAppFullyStarted => _isAppFullyStarted;
  
  /// 检查是否正在初始化
  bool get isInitializing => _isInitializing;
  
  /// 标记应用完全启动
  void markAppFullyStarted() {
    print('🚀 AppStateManager: 应用已完全启动');
    _isAppFullyStarted = true;
    _initializationTime = DateTime.now();
  }
  
  /// 标记开始初始化
  void markInitializationStarted() {
    if (_isInitializing) {
      print('⚠️ AppStateManager: 初始化已在进行中，跳过重复初始化');
      return;
    }
    print('🔄 AppStateManager: 开始初始化');
    _isInitializing = true;
  }
  
  /// 标记初始化完成
  void markInitializationCompleted() {
    print('✅ AppStateManager: 初始化完成');
    _isInitializing = false;
    _lastLocationTime = DateTime.now();
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
      final timeSinceLastLocation = DateTime.now().difference(_lastLocationTime!);
      if (timeSinceLastLocation.inSeconds < _locationCooldownSeconds) {
        print('🚫 AppStateManager: 距离上次定位时间过短 (${timeSinceLastLocation.inSeconds}s < ${_locationCooldownSeconds}s)，跳过定位');
        return false;
      }
    }
    
    print('✅ AppStateManager: 允许执行定位');
    return true;
  }
  
  /// 标记定位完成
  void markLocationCompleted() {
    _lastLocationTime = DateTime.now();
    print('📍 AppStateManager: 定位完成，更新时间戳');
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
  void reset() {
    print('🔄 AppStateManager: 重置应用状态');
    _isAppFullyStarted = false;
    _isInitializing = false;
    _initializationTime = null;
    _lastLocationTime = null;
  }
  
  /// 获取状态信息（用于调试）
  Map<String, dynamic> getStatusInfo() {
    return {
      'isAppFullyStarted': _isAppFullyStarted,
      'isInitializing': _isInitializing,
      'initializationTime': _initializationTime?.toIso8601String(),
      'lastLocationTime': _lastLocationTime?.toIso8601String(),
      'canPerformLocation': canPerformLocation(),
      'canFetchWeatherData': canFetchWeatherData(),
    };
  }
}
