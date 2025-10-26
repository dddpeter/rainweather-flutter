import '../models/location_model.dart';
import 'location_provider_interface.dart';
import 'tencent_location_service.dart';
import 'amap_location_service.dart';
import 'baidu_location_service.dart';

/// 定位服务类型
enum LocationProviderType {
  tencent, // 腾讯定位（默认优先）
  amap, // 高德地图定位
  baidu, // 百度定位
}

/// 定位服务工厂
/// 根据配置和可用性选择最佳的定位服务
class LocationProviderFactory {
  static LocationProviderFactory? _instance;
  LocationProviderFactory._internal();
  factory LocationProviderFactory() {
    _instance ??= LocationProviderFactory._internal();
    return _instance!;
  }

  /// 创建定位服务实例
  /// 根据类型返回对应的定位服务
  LocationProviderInterface createProvider(LocationProviderType type) {
    switch (type) {
      case LocationProviderType.tencent:
        return TencentLocationService.getInstance();
      case LocationProviderType.amap:
        return AMapLocationService.getInstance();
      case LocationProviderType.baidu:
        return BaiduLocationService.getInstance();
      default:
        return TencentLocationService.getInstance();
    }
  }

  /// 获取最佳定位服务
  /// 按优先级尝试不同的定位服务，返回第一个可用的服务
  Future<LocationProviderInterface?> getBestProvider({
    List<LocationProviderType> priority = const [
      LocationProviderType.tencent,
      LocationProviderType.amap,
      LocationProviderType.baidu,
    ],
  }) async {
    for (final type in priority) {
      final provider = createProvider(type);

      // 检查服务是否可用
      if (provider.isAvailable) {
        return provider;
      }

      // 尝试初始化服务
      try {
        await provider.initialize();
        if (provider.isAvailable) {
          return provider;
        }
      } catch (e) {
        // 初始化失败，尝试下一个服务
        continue;
      }
    }

    // 所有服务都不可用，返回第一个作为默认
    return priority.isNotEmpty ? createProvider(priority.first) : null;
  }

  /// 获取所有可用的定位服务
  Future<List<LocationProviderInterface>> getAvailableProviders() async {
    final List<LocationProviderInterface> availableProviders = [];

    final allTypes = LocationProviderType.values;

    for (final type in allTypes) {
      final provider = createProvider(type);

      try {
        if (!provider.isAvailable) {
          await provider.initialize();
        }

        if (provider.isAvailable) {
          availableProviders.add(provider);
        }
      } catch (e) {
        // 初始化失败，跳过
        continue;
      }
    }

    return availableProviders;
  }

  /// 使用最佳服务获取当前位置
  /// 自动选择最佳定位服务并获取位置
  Future<LocationModel?> getCurrentLocationWithBestProvider({
    List<LocationProviderType> priority = const [
      LocationProviderType.tencent,
      LocationProviderType.amap,
      LocationProviderType.baidu,
    ],
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 获取最佳服务
    final provider = await getBestProvider(priority: priority);

    if (provider == null) {
      return null;
    }

    // 尝试获取位置
    try {
      return await provider.getCurrentLocation().timeout(
        timeout,
        onTimeout: () {
          return null;
        },
      );
    } catch (e) {
      return null;
    }
  }
}
