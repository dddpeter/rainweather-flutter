import 'dart:async';
import 'dart:io';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import 'location_provider_interface.dart';

enum BaiduLocationPermissionResult { granted, denied, deniedForever, error }

class BaiduLocationException implements Exception {
  final String message;
  BaiduLocationException(this.message);

  @override
  String toString() => 'BaiduLocationException: $message';
}

class BaiduLocationService implements LocationProviderInterface {
  static BaiduLocationService? _instance;
  final LocationFlutterPlugin _loc = LocationFlutterPlugin();
  LocationModel? _cachedLocation;
  StreamSubscription<Map<String, Object>>? _locationSubscription;
  bool _isInitialized = false;

  // 百度定位AK配置
  // Android端AK在AndroidManifest.xml中配置
  // iOS端AK通过代码设置
  static const String _iosAK = '3S45oqe6EyUi1KKSXhjEgp4qvnsqbDW9';

  BaiduLocationService._();

  static BaiduLocationService getInstance() {
    _instance ??= BaiduLocationService._();
    return _instance!;
  }

  /// 全局设置隐私政策同意（在应用启动时调用）
  Future<void> setGlobalPrivacyAgreement() async {
    try {
      print('🔧 BaiduLocationService: 全局设置隐私政策同意');

      // 设置定位插件隐私政策同意
      _loc.setAgreePrivacy(true);

      // iOS端需要通过代码设置AK
      if (Platform.isIOS) {
        print('🔧 BaiduLocationService: 设置iOS端AK');
        await _loc.authAK(_iosAK);
        print('✅ BaiduLocationService: iOS端AK设置成功');
      }

      // 请求定位权限（参照demo）
      print('🔧 BaiduLocationService: 请求定位权限');
      await requestLocationPermission();

      print('✅ BaiduLocationService: 全局隐私政策同意设置成功');
    } catch (e) {
      print('❌ BaiduLocationService: 全局隐私政策同意设置失败: $e');
      throw BaiduLocationException('全局隐私政策同意设置失败: $e');
    }
  }

  /// 初始化百度定位服务
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 BaiduLocationService: 开始初始化');

      // 注意：隐私政策同意已在应用启动时全局设置，这里不需要重复设置

      // 配置Android参数（参照demo）
      final androidOpt = BaiduLocationAndroidOption(
        coorType: 'bd09ll',
        locationMode: BMFLocationMode.hightAccuracy,
        isNeedAddress: true,
        isNeedAltitude: true,
        isNeedLocationPoiList: true,
        isNeedNewVersionRgc: true,
        isNeedLocationDescribe: true,
        openGps: true,
        locationPurpose: BMFLocationPurpose.sport,
        coordType: BMFLocationCoordType.bd09ll,
        scanspan: 0, // 单次定位
      );

      // 配置iOS参数（参照demo）
      final iosOpt = BaiduLocationIOSOption(
        coordType: BMFLocationCoordType.bd09ll,
        BMKLocationCoordinateType: 'BMKLocationCoordinateTypeBMK09LL',
        desiredAccuracy: BMFDesiredAccuracy.best,
      );

      // 准备定位
      Map iosMap = iosOpt.getMap();
      Map androidMap = androidOpt.getMap();
      bool success = await _loc.prepareLoc(
        androidMap,
        iosMap,
        <String, dynamic>{},
      );

      if (success) {
        _isInitialized = true;
        print('✅ 百度定位服务初始化成功');
      } else {
        throw BaiduLocationException('百度定位服务初始化失败');
      }
    } catch (e) {
      print('❌ 百度定位服务初始化失败: $e');
      throw BaiduLocationException('百度定位服务初始化失败: $e');
    }
  }

  /// 检查定位权限
  Future<BaiduLocationPermissionResult> checkLocationPermission() async {
    try {
      // iOS上使用locationWhenInUse，Android上使用location
      final permission = Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location;

      PermissionStatus status = await permission.status;

      if (status == PermissionStatus.granted) {
        return BaiduLocationPermissionResult.granted;
      } else if (status == PermissionStatus.denied) {
        return BaiduLocationPermissionResult.denied;
      } else if (status == PermissionStatus.permanentlyDenied) {
        return BaiduLocationPermissionResult.deniedForever;
      } else {
        return BaiduLocationPermissionResult.error;
      }
    } catch (e) {
      print('检查定位权限失败: $e');
      return BaiduLocationPermissionResult.error;
    }
  }

  /// 申请定位权限
  Future<bool> requestLocationPerm() async {
    // iOS上使用locationWhenInUse，Android上使用location
    final permission = Platform.isIOS
        ? Permission.locationWhenInUse
        : Permission.location;

    final status = await permission.request();
    return status.isGranted;
  }

  /// 请求定位权限
  Future<BaiduLocationPermissionResult> requestLocationPermission() async {
    try {
      // 使用permission_handler请求权限
      bool granted = await requestLocationPerm();

      if (granted) {
        return BaiduLocationPermissionResult.granted;
      } else {
        // 检查是否被永久拒绝
        final permission = Platform.isIOS
            ? Permission.locationWhenInUse
            : Permission.location;

        PermissionStatus status = await permission.status;
        if (status == PermissionStatus.permanentlyDenied) {
          return BaiduLocationPermissionResult.deniedForever;
        } else {
          return BaiduLocationPermissionResult.denied;
        }
      }
    } catch (e) {
      print('请求定位权限失败: $e');
      return BaiduLocationPermissionResult.error;
    }
  }

  /// 开始定位
  Future<void> startLocation() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // 检查权限
      BaiduLocationPermissionResult permissionResult =
          await checkLocationPermission();
      if (permissionResult == BaiduLocationPermissionResult.denied) {
        permissionResult = await requestLocationPermission();
      }

      if (permissionResult != BaiduLocationPermissionResult.granted) {
        throw BaiduLocationException('定位权限未授予');
      }

      // 开始定位
      await _loc.startLocation();
      print('✅ 百度定位已开始');
    } catch (e) {
      print('❌ 开始定位失败: $e');
      throw BaiduLocationException('开始定位失败: $e');
    }
  }

  /// 停止定位
  Future<void> stopLocation() async {
    try {
      await _loc.stopLocation();
      print('✅ 百度定位已停止');
    } catch (e) {
      print('❌ 停止定位失败: $e');
    } finally {
      // 确保无论成功或失败都清理订阅
      _locationSubscription?.cancel();
      _locationSubscription = null;
    }
  }

  /// 简化的定位测试方法
  Future<void> testSimpleLocation() async {
    try {
      print('🧪 BaiduLocationService: 开始简化定位测试');

      // 只测试初始化
      print('🧪 测试初始化...');
      await initialize();
      print('✅ 初始化成功');

      // 测试权限检查
      print('🧪 测试权限检查...');
      final permissionResult = await checkLocationPermission();
      print('🧪 权限状态: $permissionResult');

      if (permissionResult == BaiduLocationPermissionResult.granted) {
        print('🧪 权限已授予，开始定位测试...');

        // 设置回调
        if (Platform.isIOS) {
          _loc.singleLocationCallback(
            callback: (BaiduLocation result) {
              print(
                '🧪 iOS定位回调: errorCode=${result.errorCode}, lat=${result.latitude}, lng=${result.longitude}',
              );
            },
          );
        } else if (Platform.isAndroid) {
          _loc.seriesLocationCallback(
            callback: (BaiduLocation result) {
              print(
                '🧪 Android定位回调: errorCode=${result.errorCode}, lat=${result.latitude}, lng=${result.longitude}',
              );
            },
          );
        }

        // 开始定位
        bool success = false;
        if (Platform.isIOS) {
          success = await _loc.singleLocation({
            'isReGeocode': true,
            'isNetworkState': true,
          });
        } else if (Platform.isAndroid) {
          success = await _loc.startLocation();
        }

        print('🧪 定位启动结果: $success');

        // 等待3秒后停止
        await Future.delayed(const Duration(seconds: 3));
        await stopLocation();
      } else {
        print('🧪 权限未授予，无法测试定位');
      }
    } catch (e) {
      print('❌ 简化定位测试失败: $e');
    }
  }

  /// 处理定位结果
  void _handleLocationResult(
    BaiduLocation result,
    Completer<LocationModel?> completer,
  ) {
    try {
      print('📍 收到百度定位回调结果');
      print('📍 百度定位结果: ${result.toString()}');

      // 检查错误码（只有出错时才有errorCode，成功时为null）
      final code = result.errorCode;
      if (code != null) {
        print('⚠️ 百度定位返回码 code=$code, info=${result.errorInfo}');
      }

      // 定位成功，解析结果
      final lat = result.latitude;
      final lng = result.longitude;
      final address = result.address;
      final country = result.country;
      final province = result.province;
      final city = result.city;
      final district = result.district;
      final street = result.street;
      final adCode = result.adCode;
      final streetNumber = result.streetNumber;

      if (lat != null && lng != null) {
        print('✅ 百度定位成功: $lat,$lng');

        // 创建LocationModel
        LocationModel location = LocationModel(
          lat: lat,
          lng: lng,
          address: address ?? '',
          country: country ?? '',
          province: province ?? '',
          city: city ?? '',
          district: district ?? '',
          street: street ?? '',
          adcode: adCode ?? '',
          town: streetNumber ?? '',
          isProxyDetected: false, // 百度定位通常不是代理
        );

        print('✅ 位置信息: ${location.district}');
        _cachedLocation = location;

        if (!completer.isCompleted) {
          completer.complete(location);
        }
      } else {
        print('❌ 百度定位成功但坐标为空');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    } catch (e) {
      print('❌ 解析百度定位结果失败: $e');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
  }

  /// 获取当前位置（单次定位）
  @override
  Future<LocationModel?> getCurrentLocation() async {
    try {
      print('🚀 BaiduLocationService: 开始获取当前位置');

      if (!_isInitialized) {
        print('🔧 BaiduLocationService: 初始化服务');
        await initialize();
      }

      // iOS暂时跳过权限检查，直接尝试定位
      if (Platform.isIOS) {
        print('📱 BaiduLocationService: iOS平台，跳过权限检查，直接定位');
      } else {
        // Android继续检查权限
        print('🔍 BaiduLocationService: 检查权限');
        BaiduLocationPermissionResult permissionResult =
            await checkLocationPermission();
        if (permissionResult == BaiduLocationPermissionResult.denied) {
          print('🔍 BaiduLocationService: 请求权限');
          permissionResult = await requestLocationPermission();
        }

        if (permissionResult != BaiduLocationPermissionResult.granted) {
          print('❌ BaiduLocationService: 权限未授予');
          throw BaiduLocationException('定位权限未授予');
        }
      }

      print('✅ BaiduLocationService: 准备开始定位');

      // 创建Completer来处理异步结果
      final Completer<LocationModel?> completer = Completer<LocationModel?>();

      // 根据平台设置不同的回调
      if (Platform.isIOS) {
        // iOS端单次定位回调
        _loc.singleLocationCallback(
          callback: (BaiduLocation result) {
            _handleLocationResult(result, completer);
          },
        );
      } else if (Platform.isAndroid) {
        // Android端连续定位回调（但只接收一次结果后立即停止）
        _loc.seriesLocationCallback(
          callback: (BaiduLocation result) {
            print('🤖 Android定位回调: errorCode=${result.errorCode}');
            _handleLocationResult(result, completer);
            // 接收到结果后立即停止定位（参照demo）
            _loc.stopLocation();
          },
        );
      }

      // 开始定位
      print('🚀 开始启动百度定位...');
      bool success = false;
      if (Platform.isIOS) {
        print('📱 iOS平台，使用singleLocation');
        success = await _loc.singleLocation({
          'isReGeocode': true,
          'isNetworkState': true,
        });
        print('📱 iOS定位启动结果: $success');
      } else if (Platform.isAndroid) {
        print('🤖 Android平台，使用startLocation');
        success = await _loc.startLocation();
        print('🤖 Android定位启动结果: $success');
      }

      if (!success) {
        print('❌ 启动定位失败');
        return null;
      }

      print('⏳ 等待定位结果...');

      // 等待定位结果，设置超时
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ 百度定位超时');
          // 停止定位
          _loc.stopLocation();
          return null;
        },
      );
    } catch (e) {
      print('❌ 获取当前位置失败: $e');
      return null;
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
      print('❌ 定位服务不可用: $e');
      return false;
    }
  }

  /// 获取定位能力信息
  Future<Map<String, dynamic>> getLocationCapabilities() async {
    try {
      bool serviceAvailable = await isLocationServiceAvailable();
      BaiduLocationPermissionResult permission =
          await checkLocationPermission();

      String statusDescription = '';
      String recommendation = '';

      if (!serviceAvailable) {
        statusDescription = '百度定位服务不可用';
        recommendation = '请检查网络连接或重试';
      } else if (permission == BaiduLocationPermissionResult.denied) {
        statusDescription = '定位权限被拒绝';
        recommendation = '请在应用设置中授予定位权限';
      } else if (permission == BaiduLocationPermissionResult.deniedForever) {
        statusDescription = '定位权限被永久拒绝';
        recommendation = '请在应用设置中手动开启定位权限';
      } else if (permission == BaiduLocationPermissionResult.granted) {
        statusDescription = '百度定位服务可用';
        recommendation = '支持高精度定位，包括GPS、网络定位等';
      }

      return {
        'serviceAvailable': serviceAvailable,
        'permission': permission.toString(),
        'statusDescription': statusDescription,
        'recommendation': recommendation,
        'supportsBaiduLocation': true,
        'coordinateType': 'bd09ll', // 百度坐标系
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'serviceAvailable': false,
        'statusDescription': '无法检测百度定位能力',
        'recommendation': '请检查网络连接和权限设置',
        'supportsBaiduLocation': false,
      };
    }
  }

  /// 清理资源
  void cleanup() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _cachedLocation = null;
    _isInitialized = false;
  }

  /// 销毁实例
  @override
  Future<void> dispose() async {
    cleanup();
    _instance = null;
  }

  /// 服务名称
  @override
  String get serviceName => '百度定位';

  /// 是否可用
  @override
  bool get isAvailable => _isInitialized;
}
