import '../models/location_model.dart';
import '../utils/logger.dart';

class LocationChangeNotifier {
  static final LocationChangeNotifier _instance =
      LocationChangeNotifier._internal();
  factory LocationChangeNotifier() => _instance;
  LocationChangeNotifier._internal();

  final List<LocationChangeListener> _listeners = [];

  void addListener(LocationChangeListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      Logger.d(
        '添加监听器 ${listener.runtimeType}，当前监听器数量: ${_listeners.length}',
        tag: 'LocationChangeNotifier',
      );
      Logger.d(
        '当前所有监听器: ${_listeners.map((l) => l.runtimeType).toList()}',
        tag: 'LocationChangeNotifier',
      );
    } else {
      Logger.d(
        '监听器 ${listener.runtimeType} 已存在，跳过添加',
        tag: 'LocationChangeNotifier',
      );
    }
  }

  void removeListener(LocationChangeListener listener) {
    final removed = _listeners.remove(listener);
    if (removed) {
      Logger.d(
        '移除监听器 ${listener.runtimeType}，当前监听器数量: ${_listeners.length}',
        tag: 'LocationChangeNotifier',
      );
      Logger.d(
        '剩余监听器: ${_listeners.map((l) => l.runtimeType).toList()}',
        tag: 'LocationChangeNotifier',
      );
    } else {
      Logger.w(
        '监听器 ${listener.runtimeType} 不存在，无法移除',
        tag: 'LocationChangeNotifier',
      );
    }
  }

  void notifyLocationSuccess(LocationModel newLocation) {
    Logger.d(
      '通知定位成功 ${newLocation.district}，监听器数量: ${_listeners.length}',
      tag: 'LocationChangeNotifier',
    );
    Logger.d(
      '定位详情 - 城市: ${newLocation.city}, 区县: ${newLocation.district}, 省份: ${newLocation.province}',
      tag: 'LocationChangeNotifier',
    );

    if (_listeners.isEmpty) {
      Logger.w('没有监听器，无法通知', tag: 'LocationChangeNotifier');
      return;
    }

    for (int i = 0; i < _listeners.length; i++) {
      final listener = _listeners[i];
      try {
        Logger.d(
          '正在通知监听器[${i + 1}/${_listeners.length}] ${listener.runtimeType}',
          tag: 'LocationChangeNotifier',
        );
        listener.onLocationSuccess(newLocation);
        Logger.d('监听器 ${listener.runtimeType} 通知成功', tag: 'LocationChangeNotifier');
      } catch (e) {
        Logger.e(
          '监听器 ${listener.runtimeType} 通知失败',
          tag: 'LocationChangeNotifier',
          error: e,
        );
      }
    }

    Logger.d('定位成功通知完成', tag: 'LocationChangeNotifier');
  }

  void notifyLocationFailed(String error) {
    Logger.d(
      '通知定位失败 $error，监听器数量: ${_listeners.length}',
      tag: 'LocationChangeNotifier',
    );

    if (_listeners.isEmpty) {
      Logger.w('没有监听器，无法通知', tag: 'LocationChangeNotifier');
      return;
    }

    for (int i = 0; i < _listeners.length; i++) {
      final listener = _listeners[i];
      try {
        Logger.d(
          '正在通知监听器[${i + 1}/${_listeners.length}] ${listener.runtimeType}',
          tag: 'LocationChangeNotifier',
        );
        listener.onLocationFailed(error);
        Logger.d('监听器 ${listener.runtimeType} 通知成功', tag: 'LocationChangeNotifier');
      } catch (e) {
        Logger.e(
          '监听器 ${listener.runtimeType} 通知失败',
          tag: 'LocationChangeNotifier',
          error: e,
        );
      }
    }

    Logger.d('定位失败通知完成', tag: 'LocationChangeNotifier');
  }

  void clearListeners() {
    _listeners.clear();
    Logger.d('清空所有监听器', tag: 'LocationChangeNotifier');
  }

  void debugPrintStatus() {
    Logger.d('当前状态', tag: 'LocationChangeNotifier');
    Logger.d('监听器数量: ${_listeners.length}', tag: 'LocationChangeNotifier');
    Logger.d(
      '监听器列表: ${_listeners.map((l) => l.runtimeType).toList()}',
      tag: 'LocationChangeNotifier',
    );
  }

  void testNotification() {
    Logger.d('开始测试通知功能', tag: 'LocationChangeNotifier');

    if (_listeners.isEmpty) {
      Logger.w('没有监听器，无法测试', tag: 'LocationChangeNotifier');
      return;
    }

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

    Logger.d('发送测试定位成功通知', tag: 'LocationChangeNotifier');
    notifyLocationSuccess(testLocation);

    Logger.d('发送测试定位失败通知', tag: 'LocationChangeNotifier');
    notifyLocationFailed('测试定位失败');

    Logger.d('测试完成', tag: 'LocationChangeNotifier');
  }
}

mixin LocationChangeListener {
  void onLocationSuccess(LocationModel newLocation);
  void onLocationFailed(String error);
}

enum LocationChangeEventType { success, failed }

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
