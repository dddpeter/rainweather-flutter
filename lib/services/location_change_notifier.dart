import '../models/location_model.dart';

/// 定位变化通知器
/// 使用观察者模式，当定位成功时通知所有订阅者
class LocationChangeNotifier {
  static final LocationChangeNotifier _instance =
      LocationChangeNotifier._internal();
  factory LocationChangeNotifier() => _instance;
  LocationChangeNotifier._internal();

  // 订阅者列表
  final List<LocationChangeListener> _listeners = [];

  /// 添加监听器
  void addListener(LocationChangeListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      print(
        '📍 LocationChangeNotifier: 添加监听器 ${listener.runtimeType}，当前监听器数量: ${_listeners.length}',
      );
      print(
        '📍 LocationChangeNotifier: 当前所有监听器: ${_listeners.map((l) => l.runtimeType).toList()}',
      );
    } else {
      print('📍 LocationChangeNotifier: 监听器 ${listener.runtimeType} 已存在，跳过添加');
    }
  }

  /// 移除监听器
  void removeListener(LocationChangeListener listener) {
    final removed = _listeners.remove(listener);
    if (removed) {
      print(
        '📍 LocationChangeNotifier: 移除监听器 ${listener.runtimeType}，当前监听器数量: ${_listeners.length}',
      );
      print(
        '📍 LocationChangeNotifier: 剩余监听器: ${_listeners.map((l) => l.runtimeType).toList()}',
      );
    } else {
      print('📍 LocationChangeNotifier: 监听器 ${listener.runtimeType} 不存在，无法移除');
    }
  }

  /// 通知所有监听器定位成功
  void notifyLocationSuccess(LocationModel newLocation) {
    print(
      '📍 LocationChangeNotifier: 通知定位成功 ${newLocation.district}，监听器数量: ${_listeners.length}',
    );
    print(
      '📍 LocationChangeNotifier: 定位详情 - 城市: ${newLocation.city}, 区县: ${newLocation.district}, 省份: ${newLocation.province}',
    );

    if (_listeners.isEmpty) {
      print('⚠️ LocationChangeNotifier: 没有监听器，无法通知');
      return;
    }

    for (int i = 0; i < _listeners.length; i++) {
      final listener = _listeners[i];
      try {
        print(
          '📍 LocationChangeNotifier: 正在通知监听器[${i + 1}/${_listeners.length}] ${listener.runtimeType}',
        );
        listener.onLocationSuccess(newLocation);
        print('✅ LocationChangeNotifier: 监听器 ${listener.runtimeType} 通知成功');
      } catch (e) {
        print('❌ LocationChangeNotifier: 监听器 ${listener.runtimeType} 通知失败: $e');
        print('❌ LocationChangeNotifier: 错误堆栈: ${StackTrace.current}');
      }
    }

    print('📍 LocationChangeNotifier: 定位成功通知完成');
  }

  /// 通知所有监听器定位失败
  void notifyLocationFailed(String error) {
    print(
      '📍 LocationChangeNotifier: 通知定位失败 $error，监听器数量: ${_listeners.length}',
    );

    if (_listeners.isEmpty) {
      print('⚠️ LocationChangeNotifier: 没有监听器，无法通知');
      return;
    }

    for (int i = 0; i < _listeners.length; i++) {
      final listener = _listeners[i];
      try {
        print(
          '📍 LocationChangeNotifier: 正在通知监听器[${i + 1}/${_listeners.length}] ${listener.runtimeType}',
        );
        listener.onLocationFailed(error);
        print('✅ LocationChangeNotifier: 监听器 ${listener.runtimeType} 通知成功');
      } catch (e) {
        print('❌ LocationChangeNotifier: 监听器 ${listener.runtimeType} 通知失败: $e');
        print('❌ LocationChangeNotifier: 错误堆栈: ${StackTrace.current}');
      }
    }

    print('📍 LocationChangeNotifier: 定位失败通知完成');
  }

  /// 清空所有监听器
  void clearListeners() {
    _listeners.clear();
    print('📍 LocationChangeNotifier: 清空所有监听器');
  }

  /// 获取当前监听器状态（调试用）
  void debugPrintStatus() {
    print('📍 LocationChangeNotifier: 当前状态');
    print('📍 LocationChangeNotifier: 监听器数量: ${_listeners.length}');
    print(
      '📍 LocationChangeNotifier: 监听器列表: ${_listeners.map((l) => l.runtimeType).toList()}',
    );
  }

  /// 测试通知功能（调试用）
  void testNotification() {
    print('🧪 LocationChangeNotifier: 开始测试通知功能');

    if (_listeners.isEmpty) {
      print('⚠️ LocationChangeNotifier: 没有监听器，无法测试');
      return;
    }

    // 创建测试位置
    final testLocation = LocationModel(
      address: '测试地址',
      country: '中国',
      province: '测试省份',
      city: '测试城市',
      district: '测试区县',
      street: '测试街道',
      adcode: '110000',
      town: '测试镇',
      lat: 39.9042,
      lng: 116.4074,
    );

    print('🧪 LocationChangeNotifier: 发送测试定位成功通知');
    notifyLocationSuccess(testLocation);

    print('🧪 LocationChangeNotifier: 发送测试定位失败通知');
    notifyLocationFailed('测试定位失败');

    print('🧪 LocationChangeNotifier: 测试完成');
  }
}

/// 定位变化监听器接口
mixin LocationChangeListener {
  /// 定位成功回调
  void onLocationSuccess(LocationModel newLocation);

  /// 定位失败回调
  void onLocationFailed(String error);
}

/// 定位变化事件类型
enum LocationChangeEventType { success, failed }

/// 定位变化事件
class LocationChangeEvent {
  final LocationChangeEventType type;
  final LocationModel? location;
  final String? error;

  LocationChangeEvent.success(LocationModel location)
    : type = LocationChangeEventType.success,
      location = location,
      error = null;

  LocationChangeEvent.failed(String error)
    : type = LocationChangeEventType.failed,
      location = null,
      error = error;
}
