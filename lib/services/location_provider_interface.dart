import '../models/location_model.dart';

/// 定位服务提供者接口
/// 定义统一的定位服务接口，供不同的定位实现使用
abstract class LocationProviderInterface {
  /// 获取当前位置
  /// 返回LocationModel，如果定位失败返回null
  Future<LocationModel?> getCurrentLocation();

  /// 获取定位服务名称
  String get serviceName;

  /// 是否可用
  bool get isAvailable;

  /// 初始化服务
  Future<void> initialize();

  /// 释放资源
  Future<void> dispose();
}
