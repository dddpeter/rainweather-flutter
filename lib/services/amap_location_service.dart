import 'dart:async';
import 'dart:io';
import 'package:fl_amap/fl_amap.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import 'location_provider_interface.dart';

enum AMapLocationPermissionResult { granted, denied, deniedForever, error }

class AMapLocationException implements Exception {
  final String message;
  AMapLocationException(this.message);

  @override
  String toString() => 'AMapLocationException: $message';
}

class AMapLocationService implements LocationProviderInterface {
  static AMapLocationService? _instance;
  final FlAMapLocation _location = FlAMapLocation();
  LocationModel? _cachedLocation;
  bool _isInitialized = false;

  // 高德地图API Key配置
  static const String _iosKey = '542565641b09a13192d52ca9c00cf7bb';
  static const String _androidKey = 'caed2a6a1f4ea218793a1cdba8419320';

  AMapLocationService._();

  static AMapLocationService getInstance() {
    _instance ??= AMapLocationService._();
    return _instance!;
  }

  /// 全局设置高德地图API Key（在应用启动时调用）
  Future<void> setGlobalAPIKey() async {
    try {
      print('🔧 AMapLocationService: 全局设置高德地图API Key');

      // 设置高德地图API Key
      final bool keySet = await FlAMap().setAMapKey(
        iosKey: _iosKey,
        androidKey: _androidKey,
      );

      if (keySet) {
        print('✅ AMapLocationService: 高德地图API Key设置成功');
      } else {
        throw AMapLocationException('高德地图API Key设置失败');
      }
    } catch (e) {
      print('❌ AMapLocationService: 高德地图API Key设置失败: $e');
      throw AMapLocationException('高德地图API Key设置失败: $e');
    }
  }

  /// 初始化高德地图定位服务
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 AMapLocationService: 开始初始化');

      // iOS平台跳过权限检查，直接初始化
      if (!Platform.isIOS) {
        // Android检查权限
        if (await _getPermissions()) return;
      } else {
        print('📱 AMapLocationService: iOS平台，跳过初始化时的权限检查');
      }

      // 初始化AMap定位
      final bool data = await _location.initialize();
      if (data) {
        _isInitialized = true;
        print('✅ 高德地图定位服务初始化成功');
      } else {
        throw AMapLocationException('高德地图定位服务初始化失败');
      }
    } catch (e) {
      print('❌ 高德地图定位服务初始化失败: $e');
      throw AMapLocationException('高德地图定位服务初始化失败: $e');
    }
  }

  /// 获取权限
  Future<bool> _getPermissions() async {
    try {
      print('🔍 AMapLocationService: 检查定位权限');

      // iOS上使用locationWhenInUse，Android上使用location
      final permission = Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location;

      final status = await permission.status;
      if (status.isGranted) {
        print('✅ AMapLocationService: 权限已获取');
        return false;
      }

      print('🔍 AMapLocationService: 请求定位权限');
      final requestStatus = await permission.request();

      if (requestStatus.isGranted) {
        print('✅ AMapLocationService: 权限获取成功');
        return false;
      } else if (requestStatus.isDenied) {
        print('❌ AMapLocationService: 权限被拒绝');
        throw AMapLocationException('定位权限被拒绝');
      } else if (requestStatus.isPermanentlyDenied) {
        print('❌ AMapLocationService: 权限被永久拒绝');
        throw AMapLocationException('定位权限被永久拒绝，请在设置中手动开启');
      } else {
        print('❌ AMapLocationService: 权限获取失败');
        throw AMapLocationException('定位权限获取失败');
      }
    } catch (e) {
      print('❌ AMapLocationService: 权限检查失败: $e');
      return true; // 返回true表示有错误，应该停止执行
    }
  }

  /// 获取当前位置（单次定位）
  @override
  Future<LocationModel?> getCurrentLocation() async {
    try {
      print('🚀 AMapLocationService: 开始获取当前位置');

      if (!_isInitialized) {
        print('🔧 AMapLocationService: 初始化服务');
        await initialize();
      }

      // iOS暂时跳过权限检查，直接尝试定位
      if (Platform.isIOS) {
        print('📱 AMapLocationService: iOS平台，跳过权限检查，直接定位');
      } else {
        // Android继续检查权限
        if (await _getPermissions()) {
          print('❌ AMapLocationService: 权限未授予');
          throw AMapLocationException('定位权限未授予');
        }
      }

      print('✅ AMapLocationService: 准备开始定位');

      // 获取单次定位
      print('🚀 开始高德地图定位...');
      final AMapLocation? location = await _location.getLocation();

      if (location == null) {
        print('❌ 高德地图定位失败：返回结果为空');
        return null;
      }

      // 解析定位结果
      final locationModel = _parseAMapLocation(location);
      if (locationModel != null) {
        print('✅ 高德地图定位成功: ${locationModel.district}');
        _cachedLocation = locationModel;
      }

      return locationModel;
    } catch (e) {
      print('❌ 获取当前位置失败: $e');
      return null;
    }
  }

  /// 解析高德地图定位结果
  LocationModel? _parseAMapLocation(AMapLocation location) {
    try {
      // 根据平台解析不同的定位结果
      if (Platform.isAndroid) {
        final androidLocation = location as AMapLocationForAndroid;
        return _parseAndroidLocation(androidLocation);
      } else if (Platform.isIOS) {
        final iosLocation = location as AMapLocationForIOS;
        return _parseIOSLocation(iosLocation);
      }
    } catch (e) {
      print('❌ 解析高德地图定位结果失败: $e');
    }
    return null;
  }

  /// 解析Android定位结果
  LocationModel _parseAndroidLocation(AMapLocationForAndroid location) {
    return LocationModel(
      lat: location.latitude ?? 0.0,
      lng: location.longitude ?? 0.0,
      address: location.address ?? '',
      country: location.country ?? '中国',
      province: location.province ?? '',
      city: location.city ?? '',
      district: location.district ?? '',
      street: location.street ?? '',
      adcode: location.adCode ?? '',
      town: '', // Android版本可能没有township字段
      isProxyDetected: false, // 高德地图定位通常不是代理
    );
  }

  /// 解析iOS定位结果
  LocationModel _parseIOSLocation(AMapLocationForIOS location) {
    return LocationModel(
      lat: location.latitude ?? 0.0,
      lng: location.longitude ?? 0.0,
      address: location.address ?? '',
      country: location.country ?? '中国',
      province: location.province ?? '',
      city: location.city ?? '',
      district: location.district ?? '',
      street: location.street ?? '',
      adcode: location.adCode ?? '',
      town: '', // iOS版本可能没有township字段
      isProxyDetected: false, // 高德地图定位通常不是代理
    );
  }

  /// 开启连续定位监听
  Future<void> startLocationChange({
    required Function(LocationModel) onLocationChanged,
    Function(String)? onError,
  }) async {
    try {
      print('🔧 AMapLocationService: 开启连续定位监听');

      if (!_isInitialized) {
        await initialize();
      }

      if (await _getPermissions()) {
        onError?.call('定位权限未授予');
        return;
      }

      // 添加定位监听
      _location.addListener(
        onLocationChanged: (AMapLocation? location) {
          if (location != null) {
            final locationModel = _parseAMapLocation(location);
            if (locationModel != null) {
              _cachedLocation = locationModel;
              onLocationChanged(locationModel);
            }
          }
        },
        onLocationFailed: (AMapLocationError? error) {
          final errorMsg = '高德地图定位错误: ${error?.toMap()}';
          print('❌ $errorMsg');
          onError?.call(errorMsg);
        },
      );

      print('✅ AMapLocationService: 连续定位监听已开启');
    } catch (e) {
      print('❌ 开启连续定位监听失败: $e');
      onError?.call('开启连续定位监听失败: $e');
    }
  }

  /// 停止连续定位监听
  void stopLocationChange() {
    try {
      print('🔧 AMapLocationService: 停止连续定位监听');
      _location.stopLocation();
      print('✅ AMapLocationService: 连续定位监听已停止');
    } catch (e) {
      print('❌ 停止连续定位监听失败: $e');
    }
  }

  /// 获取缓存的位置
  LocationModel? getCachedLocation() {
    return _cachedLocation;
  }

  /// 设置缓存的位置
  void setCachedLocation(LocationModel location) {
    _cachedLocation = location;
  }

  /// 检查定位服务是否可用
  Future<bool> isLocationServiceAvailable() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return true;
    } catch (e) {
      print('❌ 高德地图定位服务不可用: $e');
      return false;
    }
  }

  /// 释放资源
  @override
  Future<void> dispose() async {
    try {
      print('🔧 AMapLocationService: 释放资源');
      _location.dispose();
      _isInitialized = false;
      print('✅ AMapLocationService: 资源已释放');
    } catch (e) {
      print('❌ 释放资源失败: $e');
    }
  }

  /// 服务名称
  @override
  String get serviceName => '高德地图定位';

  /// 是否可用
  @override
  bool get isAvailable => _isInitialized;
}
