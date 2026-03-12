import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import 'geocoding_service.dart';
import 'enhanced_geocoding_service.dart';
import 'ip_location_service.dart';
// import 'baidu_location_service.dart'; // 百度定位已禁用
import 'amap_location_service.dart';
import 'tencent_location_service.dart';

enum LocationPermissionResult { granted, denied, deniedForever, error }

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

class LocationService {
  static LocationService? _instance;
  LocationModel? _cachedLocation;
  bool _isLocating = false; // 防止并发定位
  final GeocodingService _geocodingService = GeocodingService.getInstance();
  final EnhancedGeocodingService _enhancedGeocodingService =
      EnhancedGeocodingService.getInstance();
  // final BaiduLocationService _baiduLocationService =
  //     BaiduLocationService.getInstance(); // 百度定位已禁用
  final AMapLocationService _amapLocationService =
      AMapLocationService.getInstance();
  final TencentLocationService _tencentLocationService =
      TencentLocationService.getInstance();

  LocationService._();

  static LocationService getInstance() {
    _instance ??= LocationService._();
    return _instance!;
  }

  /// Check location permission status without requesting
  Future<LocationPermissionResult> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        return LocationPermissionResult.denied;
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionResult.deniedForever;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return LocationPermissionResult.granted;
      }

      return LocationPermissionResult.denied;
    } catch (e, stackTrace) {
      Logger.e(
        '检查定位权限错误',
        tag: 'LocationService',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'LocationService.CheckPermission',
        type: AppErrorType.permission,
      );
      return LocationPermissionResult.error;
    }
  }

  /// Get current position with China-optimized settings (without GMS)
  /// 使用国内优化设置获取当前位置（无 GMS 场景）
  Future<Position> getCurrentPositionChinaOptimized({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration? timeLimit,
  }) async {
    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        forceLocationManager: true, // 强制走系统 Manager（国内无 GMS 场景）
        accuracy: accuracy,
        intervalDuration: const Duration(seconds: 2),
        distanceFilter: 0,
        timeLimit: timeLimit,
      ),
    );
  }

  /// Example of new AndroidSettings API usage
  /// 新 AndroidSettings API 使用示例
  Future<Position> exampleNewAndroidSettings() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        // ← 新的 settings 体系
        forceLocationManager: true, // 等效旧的 forceAndroidLocationManager
        accuracy: LocationAccuracy.high,
        intervalDuration: const Duration(seconds: 2),
        distanceFilter: 0,
      ),
    );
  }

  /// Check and request location permissions
  Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        Logger.d('定位权限被拒绝，请求权限...', tag: 'LocationService');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          Logger.w('用户拒绝了定位权限', tag: 'LocationService');
          return LocationPermissionResult.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.w('定位权限被永久拒绝', tag: 'LocationService');
        return LocationPermissionResult.deniedForever;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Logger.d('定位权限已授予: $permission', tag: 'LocationService');
        return LocationPermissionResult.granted;
      }

      return LocationPermissionResult.denied;
    } catch (e, stackTrace) {
      Logger.e(
        '请求定位权限错误',
        tag: 'LocationService',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'LocationService.RequestPermission',
        type: AppErrorType.permission,
      );
      return LocationPermissionResult.error;
    }
  }

  /// Get current location with proxy detection
  Future<LocationModel?> getCurrentLocation() async {
    // 标记当前是否正在定位，防止并发
    if (_isLocating) {
      Logger.w('正在定位中，请勿重复调用', tag: 'LocationService');
      return _cachedLocation;
    }

    _isLocating = true;

    try {
      // ① 优先尝试腾讯定位（添加超时）
      Logger.d('尝试腾讯定位...', tag: 'LocationService');
      LocationModel? tencentLocation;
      try {
        tencentLocation = await _tencentLocationService
            .getCurrentLocation()
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                Logger.w('腾讯定位超时，切换到高德地图定位', tag: 'LocationService');
                return null;
              },
            );
      } catch (e, stackTrace) {
        Logger.e(
          '腾讯定位失败',
          tag: 'LocationService',
          error: e,
          stackTrace: stackTrace,
        );
        ErrorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'LocationService.TencentLocation',
          type: AppErrorType.location,
        );
      }

      if (tencentLocation != null) {
        Logger.s(
          '腾讯定位成功: ${tencentLocation.district}',
          tag: 'LocationService',
        );
        _cachedLocation = tencentLocation;
        return tencentLocation;
      }

      // ② 腾讯定位失败，尝试高德地图定位
      Logger.d('尝试高德地图定位...', tag: 'LocationService');
      LocationModel? amapLocation;
      try {
        amapLocation = await _amapLocationService
            .getCurrentLocation()
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                Logger.w('高德地图定位超时，切换到百度定位', tag: 'LocationService');
                return null;
              },
            );
      } catch (e, stackTrace) {
        Logger.e(
          '高德地图定位失败',
          tag: 'LocationService',
          error: e,
          stackTrace: stackTrace,
        );
        ErrorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'LocationService.AmapLocation',
          type: AppErrorType.location,
        );
      }

      if (amapLocation != null) {
        Logger.s(
          '高德地图定位成功: ${amapLocation.district}',
          tag: 'LocationService',
        );
        _cachedLocation = amapLocation;
        return amapLocation;
      }

      // ③ 高德地图定位失败，直接尝试GPS定位（百度定位已禁用）
      Logger.d('尝试GPS定位...', tag: 'LocationService');

      // 检查权限（参考方案：3行代码搞定）
      LocationPermission permission = await Geolocator.checkPermission();
      bool ok =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!ok) {
        permission = await Geolocator.requestPermission();
        ok =
            permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
      }
      if (!ok) {
        Logger.w('无定位权限，尝试IP定位', tag: 'LocationService');
        return await _tryIpLocationWithProxyDetection();
      }

      // 检查位置服务
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.w('位置服务未开启，尝试IP定位', tag: 'LocationService');
        return await _tryIpLocationWithProxyDetection();
      }

      // 获取位置（参考方案：单次定位）
      try {
        Position position = await getCurrentPositionChinaOptimized(
          accuracy: LocationAccuracy.best, // 使用最佳精度，确保定位准确性
          timeLimit: const Duration(seconds: 20), // 增加超时时间以适应高精度定位
        );

        // Use enhanced geocoding service (geocoding plugin) first
        LocationModel? location = await _enhancedGeocodingService
            .reverseGeocode(position.latitude, position.longitude);

        // If enhanced geocoding fails, use fallback method
        if (location == null) {
          Logger.w('增强地理编码失败，尝试备用方法', tag: 'LocationService');
          location = await _geocodingService.reverseGeocode(
            position.latitude,
            position.longitude,
          );
        }

        // If still fails, use final fallback
        location ??= await _geocodingService.fallbackReverseGeocode(
          position.latitude,
          position.longitude,
        );

        if (location != null) {
          // 检查GPS定位的位置信息是否为"未知"
          if (_isLocationUnknown(location)) {
            Logger.w('GPS定位成功但位置信息为"未知"，尝试IP定位作为备用', tag: 'LocationService');
            // 继续执行IP定位逻辑
          } else {
            Logger.s('GPS定位成功: ${location.district}', tag: 'LocationService');
            _cachedLocation = location;
            return location;
          }
        }
      } catch (e, stackTrace) {
        Logger.e(
          'GPS定位失败',
          tag: 'LocationService',
          error: e,
          stackTrace: stackTrace,
        );
        ErrorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'LocationService.GPSLocation',
          type: AppErrorType.location,
        );
      }

      // ⑤ 如果GPS也失败，尝试IP定位
      Logger.d('尝试IP定位...', tag: 'LocationService');
      return await _tryIpLocationWithProxyDetection();
    } catch (e, stackTrace) {
      Logger.e(
        '定位服务错误',
        tag: 'LocationService',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'LocationService.GetCurrentLocation',
        type: AppErrorType.location,
      );

      if (e is LocationException) {
        rethrow;
      } else if (e is TimeoutException) {
        throw LocationException('定位超时，请检查网络连接或重试');
      } else {
        throw LocationException('定位失败: ${e.toString()}');
      }
    } finally {
      // 无论成功或失败，都重置定位标志
      _isLocating = false;
    }
  }

  /// Get cached location
  LocationModel? getCachedLocation() {
    return _cachedLocation;
  }

  /// Try IP location with proxy detection
  Future<LocationModel?> _tryIpLocationWithProxyDetection() async {
    try {
      Logger.d('尝试IP定位...', tag: 'LocationService');
      final ipLocationService = IpLocationService.getInstance();
      final location = await ipLocationService.getLocationByIp();

      if (location != null) {
        Logger.s('IP定位成功: ${location.district}', tag: 'LocationService');

        // Check if the location might be from a proxy/VPN
        if (await _isLikelyProxyLocation(location)) {
          Logger.w('检测到可能的代理/VPN位置，建议使用GPS定位', tag: 'LocationService');
          // Still return the location but with a warning
          location.isProxyDetected = true;
        }

        // Cache the IP location
        _cachedLocation = location;
        return location;
      } else {
        Logger.w('IP定位失败', tag: 'LocationService');
        return null;
      }
    } catch (e, stackTrace) {
      Logger.e(
        'IP定位错误',
        tag: 'LocationService',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'LocationService.IPLocation',
        type: AppErrorType.location,
      );
      return null;
    }
  }

  /// 检查位置信息是否为"未知"
  bool _isLocationUnknown(LocationModel location) {
    // 检查关键字段是否为"未知"或空值
    final unknownValues = ['未知', 'unknown', '', 'null', 'None', 'N/A'];

    // 检查城市、区县、省份是否包含未知值
    bool cityUnknown =
        unknownValues.contains(location.city.toLowerCase()) ||
        location.city.isEmpty;
    bool districtUnknown =
        unknownValues.contains(location.district.toLowerCase()) ||
        location.district.isEmpty;
    bool provinceUnknown =
        unknownValues.contains(location.province.toLowerCase()) ||
        location.province.isEmpty;

    // 如果城市、区县、省份都是未知，则认为位置未知
    if (cityUnknown && districtUnknown && provinceUnknown) {
      return true;
    }

    // 如果地址字段包含大量"未知"信息，也认为位置未知
    if (location.address.contains('未知') && location.address.length < 10) {
      return true;
    }

    return false;
  }

  /// Detect if location might be from a proxy/VPN
  Future<bool> _isLikelyProxyLocation(LocationModel location) async {
    try {
      // Common proxy/VPN server locations
      final suspiciousLocations = [
        '新加坡',
        '香港',
        '日本',
        '美国',
        '英国',
        '德国',
        '荷兰',
        '法国',
        'Singapore',
        'Hong Kong',
        'Japan',
        'United States',
        'United Kingdom',
        'Germany',
        'Netherlands',
        'France',
        'Switzerland',
        'Luxembourg',
      ];

      // Check if city or country matches suspicious locations
      final city = location.city.toLowerCase();
      final country = location.country.toLowerCase();
      final province = location.province.toLowerCase();

      for (final suspicious in suspiciousLocations) {
        if (city.contains(suspicious.toLowerCase()) ||
            country.contains(suspicious.toLowerCase()) ||
            province.contains(suspicious.toLowerCase())) {
          return true;
        }
      }

      // Check if coordinates are in common data center locations
      final lat = location.lat;
      final lng = location.lng;

      // Singapore data centers
      if ((lat >= 1.2 && lat <= 1.5) && (lng >= 103.7 && lng <= 104.0)) {
        return true;
      }

      // Hong Kong data centers
      if ((lat >= 22.2 && lat <= 22.4) && (lng >= 114.1 && lng <= 114.3)) {
        return true;
      }

      // Japan Tokyo data centers
      if ((lat >= 35.6 && lat <= 35.8) && (lng >= 139.6 && lng <= 139.8)) {
        return true;
      }

      return false;
    } catch (e) {
      print('代理检测错误: $e');
      return false;
    }
  }

  /// Set cached location
  void setCachedLocation(LocationModel location) {
    _cachedLocation = location;
  }

  /// Check device location capabilities
  Future<Map<String, dynamic>> checkLocationCapabilities() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      // Check if device supports high accuracy location
      bool canGetLocation = await Geolocator.isLocationServiceEnabled();

      // Get detailed status information
      String statusDescription = '';
      String recommendation = '';

      if (!serviceEnabled) {
        statusDescription = '位置服务未开启';
        recommendation = '请在设备设置中开启位置服务';
      } else if (permission == LocationPermission.denied) {
        statusDescription = '定位权限被拒绝';
        recommendation = '请在应用设置中授予定位权限';
      } else if (permission == LocationPermission.deniedForever) {
        statusDescription = '定位权限被永久拒绝';
        recommendation = '请在应用设置中手动开启定位权限';
      } else if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        statusDescription = '定位权限已授予';
        recommendation = '设备支持北斗、GPS等多种卫星定位';
      }

      return {
        'serviceEnabled': serviceEnabled,
        'permission': permission.toString(),
        'canGetLocation': canGetLocation,
        'supportsBDS': true, // Modern devices automatically support BDS
        'statusDescription': statusDescription,
        'recommendation': recommendation,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'supportsBDS': false,
        'statusDescription': '无法检测设备定位能力',
        'recommendation': '请检查设备定位设置',
      };
    }
  }

  /// Check and request location service to be enabled
  Future<bool> requestLocationService() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Request to enable location service
        serviceEnabled = await Geolocator.openLocationSettings();
        print('位置服务开启请求结果: $serviceEnabled');
      }
      return serviceEnabled;
    } catch (e) {
      print('请求开启位置服务失败: $e');
      return false;
    }
  }

  /// Check and request app location settings to be enabled
  Future<bool> requestAppLocationSettings() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Open app settings for user to manually enable permission
        bool opened = await Geolocator.openAppSettings();
        print('打开应用设置结果: $opened');
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('请求应用定位设置失败: $e');
      return false;
    }
  }

  /// Get location with enhanced error handling and user guidance
  Future<LocationModel?> getLocationWithGuidance() async {
    try {
      // First check capabilities
      Map<String, dynamic> capabilities = await checkLocationCapabilities();
      print('设备定位能力: $capabilities');

      // Check location service
      if (!capabilities['serviceEnabled']) {
        print('位置服务未开启，尝试请求开启');
        bool serviceEnabled = await requestLocationService();
        if (!serviceEnabled) {
          throw LocationException('位置服务未开启，请在设备设置中开启位置服务');
        }
      }

      // Check app permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('定位权限未授予，尝试请求权限');
        bool permissionGranted = await requestAppLocationSettings();
        if (!permissionGranted) {
          throw LocationException('定位权限未授予，请在应用设置中授予定位权限');
        }
      }

      // Try to get location
      LocationModel? location = await getCurrentLocation();

      if (location == null) {
        print('所有定位方式都失败，建议用户检查网络和权限设置');
        throw LocationException('定位失败，请检查网络连接和位置权限');
      }

      return location;
    } catch (e) {
      print('定位服务错误: $e');
      rethrow;
    }
  }

  /// 简化版定位方法（参考方案：3行代码搞定）
  Future<Position?> getSimpleLocation() async {
    try {
      // ① 检查权限
      LocationPermission permission = await Geolocator.checkPermission();
      bool ok =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!ok) {
        permission = await Geolocator.requestPermission();
        ok =
            permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
      }
      if (!ok) throw '无定位权限';

      // ② 拿位置（单次）
      return await getCurrentPositionChinaOptimized(
        accuracy: LocationAccuracy.high, // 精度≈10m
      );
    } catch (e) {
      print('简化定位失败: $e');
      return null;
    }
  }

  /// 验证GPS定位功能（改进版本，更可靠）
  Future<Map<String, dynamic>> validateGpsLocation() async {
    Map<String, dynamic> result = {
      'permission_check': false,
      'service_enabled': false,
      'gps_position': null,
      'reverse_geocoding': null,
      'final_location': null,
      'errors': <String>[],
      'location_method': 'unknown', // 记录实际使用的定位方式
    };

    try {
      // 1. 检查权限
      print('🔍 验证GPS定位 - 步骤1: 检查权限');
      LocationPermission permission = await Geolocator.checkPermission();
      bool hasPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      result['permission_check'] = hasPermission;
      print('权限状态: $permission, 有效权限: $hasPermission');

      if (!hasPermission) {
        result['errors'].add('无GPS定位权限');
        return result;
      }

      // 2. 跳过不可靠的位置服务检测，直接尝试定位
      print('🔍 验证GPS定位 - 步骤2: 跳过位置服务检测，直接尝试定位');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      result['service_enabled'] = serviceEnabled;
      print('位置服务检测结果: $serviceEnabled (可能不准确，将通过实际定位验证)');

      // 3. 多层级定位策略
      print('🔍 验证GPS定位 - 步骤3: 开始多层级定位尝试');
      LocationModel? finalLocation = await _tryMultipleLocationMethods();

      if (finalLocation != null) {
        result['final_location'] = finalLocation;
        result['location_method'] = finalLocation.isProxyDetected
            ? 'IP定位'
            : 'GPS定位';

        // 如果成功定位，更新位置服务状态
        result['service_enabled'] = true;
        print('✅ 定位成功，使用方式: ${result['location_method']}');

        // 尝试获取GPS坐标（如果可用）
        if (finalLocation.lat != 0 && finalLocation.lng != 0) {
          result['gps_position'] = {
            'latitude': finalLocation.lat,
            'longitude': finalLocation.lng,
            'accuracy': '通过${result['location_method']}获取',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }

        // 添加反向地理编码信息
        result['reverse_geocoding'] = {
          'address': finalLocation.address,
          'district': finalLocation.district,
          'city': finalLocation.city,
          'province': finalLocation.province,
        };

        return result; // 定位成功
      }

      // 如果所有定位方式都失败
      result['errors'].add('所有定位方式都失败');
      if (!serviceEnabled) {
        result['errors'].add('位置服务未开启');
      }
      return result;
    } catch (e) {
      result['errors'].add('定位验证过程出错: $e');
      print('GPS验证错误: $e');
      return result;
    }
  }

  /// 尝试多种定位方法
  Future<LocationModel?> _tryMultipleLocationMethods() async {
    // 方法1: 尝试高精度GPS定位
    print('📍 尝试方法1: 高精度GPS定位');
    try {
      // 先请求权限
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ GPS定位权限被拒绝');
        throw Exception('GPS定位权限被拒绝');
      }

      Position position = await getCurrentPositionChinaOptimized(
        accuracy: LocationAccuracy.high, // 高精度，约10米
        timeLimit: const Duration(seconds: 10), // 10秒超时
      );

      print('✅ GPS定位成功: ${position.latitude}, ${position.longitude}');

      // 使用增强地理编码服务（geocoding 插件）优先
      LocationModel? location = await _enhancedGeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (location == null) {
        print('🔄 增强地理编码失败，尝试备用方法...');
        location = await _geocodingService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
      }

      if (location == null) {
        print('🔄 备用地理编码失败，尝试最终备用方法...');
        location = await _geocodingService.fallbackReverseGeocode(
          position.latitude,
          position.longitude,
        );
      }

      if (location != null) {
        // 检查GPS定位的位置信息是否为"未知"
        if (_isLocationUnknown(location)) {
          print('⚠️ GPS定位成功但位置信息为"未知"，尝试IP定位作为备用');
          // 继续执行IP定位逻辑
        } else {
          print('✅ GPS定位完整流程成功');
          return location;
        }
      } else {
        print('❌ GPS定位成功但地理编码失败');
      }
    } catch (e) {
      print('❌ 高精度GPS定位失败: $e');
    }

    // 方法1.5: 尝试中等精度GPS定位（备用）
    print('📍 尝试方法1.5: 中等精度GPS定位');
    try {
      Position position = await getCurrentPositionChinaOptimized(
        accuracy: LocationAccuracy.medium, // 中等精度，约100米
        timeLimit: const Duration(seconds: 8), // 8秒超时
      );

      print('✅ 中等精度GPS定位成功: ${position.latitude}, ${position.longitude}');

      // 使用增强地理编码服务（geocoding 插件）优先
      LocationModel? location = await _enhancedGeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (location == null) {
        print('🔄 增强地理编码失败，尝试备用方法...');
        location = await _geocodingService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
      }

      if (location == null) {
        print('🔄 备用地理编码失败，尝试最终备用方法...');
        location = await _geocodingService.fallbackReverseGeocode(
          position.latitude,
          position.longitude,
        );
      }

      if (location != null) {
        // 检查GPS定位的位置信息是否为"未知"
        if (_isLocationUnknown(location)) {
          print('⚠️ 中等精度GPS定位成功但位置信息为"未知"，尝试IP定位作为备用');
          // 继续执行IP定位逻辑
        } else {
          print('✅ 中等精度GPS定位完整流程成功');
          return location;
        }
      } else {
        print('❌ 中等精度GPS定位成功但地理编码失败');
      }
    } catch (e) {
      print('❌ 中等精度GPS定位失败: $e');
      print('🔄 开始尝试IP定位...');
    }

    // 方法2: 尝试IP定位
    print('📍 尝试方法2: IP定位');
    print('📡 正在初始化IP定位服务...');
    try {
      final ipLocationService = IpLocationService.getInstance();
      print('📡 开始调用IP定位接口...');
      final location = await ipLocationService.getLocationByIp();
      print('📡 IP定位接口调用完成，结果: ${location != null ? '成功' : '失败'}');

      if (location != null) {
        print('✅ IP定位成功: ${location.district}');
        location.isProxyDetected = await _isLikelyProxyLocation(location);
        return location;
      } else {
        print('❌ IP定位失败');
      }
    } catch (e) {
      print('❌ IP定位错误: $e');
    }

    // 所有方法都失败
    print('❌ 所有定位方法都失败');
    return null;
  }

  /// Open location settings page
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      print('无法打开位置设置页面: $e');
    }
  }

  /// Open app settings page
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      print('无法打开应用设置页面: $e');
    }
  }

  /// 使用百度定位获取当前位置
  // 百度定位已禁用
  // Future<LocationModel?> getCurrentLocationWithBaidu() async {
  //   try {
  //     print('📍 使用百度定位获取当前位置...');
  //     LocationModel? location = await _baiduLocationService
  //         .getCurrentLocation();
  //     if (location != null) {
  //       print('✅ 百度定位成功: ${location.district}');
  //       _cachedLocation = location;
  //       return location;
  //     } else {
  //       print('❌ 百度定位失败');
  //       return null;
  //     }
  //   } catch (e) {
  //     print('❌ 百度定位错误: $e');
  //     return null;
  //   }
  // }

  /// 检查百度定位服务状态
  // 百度定位已禁用
  // Future<Map<String, dynamic>> checkBaiduLocationStatus() async {
  //   try {
  //     return await _baiduLocationService.getLocationCapabilities();
  //   } catch (e) {
  //     return {
  //       'error': e.toString(),
  //       'serviceAvailable': false,
  //       'statusDescription': '无法检查百度定位状态',
  //       'recommendation': '请检查网络连接和权限设置',
  //     };
  //   }
  // }

  /// Cleanup resources
  void cleanup() {
    _cachedLocation = null;
    // _baiduLocationService.cleanup(); // 百度定位已禁用
  }
}
