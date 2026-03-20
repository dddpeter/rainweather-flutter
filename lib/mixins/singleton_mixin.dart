/// 单例模式混入类
///
/// 简化版混入，提供单例模式的标准实现模板
/// 使用时需要配合类自身的静态实例和工厂构造函数
///
/// 使用示例：
/// ```dart
/// class MyService with Singleton {
///   static final MyService _instance = MyService._internal();
///   factory MyService() => _instance;
///   MyService._internal();
///
///   // 重置方法（主要用于测试）
///   static void reset() => _instance = MyService._internal();
/// }
/// ```
mixin Singleton {
  /// 检查是否为单例实例
  bool get isSingleton => true;

  /// 获取单例实例的提示信息
  String get singletonHint => 'This class should be accessed via getInstance() or factory constructor';
}

/// 简化版单例混入标记
///
/// 使用示例：
/// ```dart
/// class MyService with SimpleSingleton {
///   static final MyService _instance = MyService._internal();
///   factory MyService() => _instance;
///   MyService._internal();
/// }
/// ```
mixin SimpleSingleton {
  /// 检查是否为单例实例
  bool get isSingleton => true;
}
