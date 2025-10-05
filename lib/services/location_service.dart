import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import 'geocoding_service.dart';
import 'ip_location_service.dart';

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
  final GeocodingService _geocodingService = GeocodingService.getInstance();

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
    } catch (e) {
      print('Error checking location permission: $e');
      return LocationPermissionResult.error;
    }
  }

  /// Check and request location permissions
  Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        print('Location permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          print('Location permission denied by user');
          return LocationPermissionResult.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        return LocationPermissionResult.deniedForever;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('Location permission granted: $permission');
        return LocationPermissionResult.granted;
      }

      return LocationPermissionResult.denied;
    } catch (e) {
      print('Error requesting location permission: $e');
      return LocationPermissionResult.error;
    }
  }

  /// Get current location with proxy detection
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // ① 检查权限（参考方案：3行代码搞定）
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
        print('无定位权限，尝试IP定位');
        return await _tryIpLocationWithProxyDetection();
      }

      // ② 检查位置服务
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('位置服务未开启，尝试IP定位');
        return await _tryIpLocationWithProxyDetection();
      }

      print('尝试GPS定位...');

      // ③ 拿位置（参考方案：单次定位）
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, // 精度≈10m
            timeLimit: const Duration(seconds: 15), // 减少超时时间
          ),
        );

        // Use reverse geocoding to get address information
        LocationModel? location = await _geocodingService.reverseGeocode(
          position.latitude,
          position.longitude,
        );

        // If reverse geocoding fails, use fallback method
        if (location == null) {
          location = await _geocodingService.fallbackReverseGeocode(
            position.latitude,
            position.longitude,
          );
        }

        if (location != null) {
          print('GPS定位成功: ${location.district}');
          _cachedLocation = location;
          return location;
        }
      } catch (e) {
        print('GPS定位失败: $e，尝试IP定位');
      }

      // If GPS fails, try IP location but with proxy detection
      print('GPS定位失败，尝试IP定位...');
      return await _tryIpLocationWithProxyDetection();
    } catch (e) {
      print('定位服务错误: $e');

      if (e is LocationException) {
        rethrow;
      } else if (e is TimeoutException) {
        throw LocationException('定位超时，请检查网络连接或重试');
      } else {
        throw LocationException('定位失败：${e.toString()}');
      }
    }
  }

  /// Get cached location
  LocationModel? getCachedLocation() {
    return _cachedLocation;
  }

  /// Try IP location with proxy detection
  Future<LocationModel?> _tryIpLocationWithProxyDetection() async {
    try {
      print('尝试IP定位...');
      final ipLocationService = IpLocationService.getInstance();
      final location = await ipLocationService.getLocationByIp();

      if (location != null) {
        print('IP定位成功: ${location.district}');

        // Check if the location might be from a proxy/VPN
        if (await _isLikelyProxyLocation(location)) {
          print('检测到可能的代理/VPN位置，建议使用GPS定位');
          // Still return the location but with a warning
          location.isProxyDetected = true;
        }

        // Cache the IP location
        _cachedLocation = location;
        return location;
      } else {
        print('IP定位失败');
        return null;
      }
    } catch (e) {
      print('IP定位错误: $e');
      return null;
    }
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
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high, // 精度≈10m
        ),
      );
    } catch (e) {
      print('简化定位失败: $e');
      return null;
    }
  }

  /// 验证GPS定位功能
  Future<Map<String, dynamic>> validateGpsLocation() async {
    Map<String, dynamic> result = {
      'permission_check': false,
      'service_enabled': false,
      'gps_position': null,
      'reverse_geocoding': null,
      'final_location': null,
      'errors': <String>[],
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

      // 2. 检查位置服务（改进检测逻辑）
      print('🔍 验证GPS定位 - 步骤2: 检查位置服务');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      result['service_enabled'] = serviceEnabled;
      print('位置服务状态: $serviceEnabled');

      // 注意：某些Android设备上isLocationServiceEnabled()可能不准确
      // 我们将通过实际尝试获取位置来验证
      if (!serviceEnabled) {
        print('⚠️ 位置服务检测为未开启，但某些设备检测不准确，将尝试实际定位验证');
        // 不直接返回错误，而是继续尝试定位
      }

      // 3. 获取GPS位置（实际验证位置服务是否可用）
      print('🔍 验证GPS定位 - 步骤3: 获取GPS位置');
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium, // 降低精度要求以提高成功率
            timeLimit: const Duration(seconds: 10), // 减少超时时间
          ),
        );
        result['gps_position'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        };
        print('✅ GPS位置获取成功: ${position.latitude}, ${position.longitude}');

        // 如果实际获取到了GPS位置，说明位置服务实际上是可用的
        if (!serviceEnabled) {
          print('✅ 实际验证：位置服务实际上是可用的（检测API可能不准确）');
          result['service_enabled'] = true; // 更新检测结果
        }
      } catch (e) {
        print('❌ GPS位置获取失败: $e');

        // 分析具体的错误原因
        String errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('location service') ||
            errorMessage.contains('location service disabled')) {
          result['errors'].add('位置服务未开启或不可用');
        } else if (errorMessage.contains('timeout') ||
            errorMessage.contains('time limit')) {
          // 提供更详细的超时处理建议
          result['errors'].add('GPS定位超时 - 可能原因：');
          result['errors'].add('• 在室内或信号较弱的环境');
          result['errors'].add('• 位置服务未完全开启');
          result['errors'].add('• GPS信号被阻挡');
          result['errors'].add('建议：尝试到室外开阔地带重试');
        } else if (errorMessage.contains('permission')) {
          result['errors'].add('定位权限问题');
        } else {
          result['errors'].add('GPS定位失败: $e');
        }

        // 如果位置服务检测显示未开启，且实际定位也失败，则确认位置服务问题
        if (!serviceEnabled) {
          result['errors'].add('位置服务未开启');
        }

        return result; // 定位失败，返回结果
      }

      // 4. 反向地理编码（只有在GPS定位成功时才执行）
      print('🔍 验证GPS定位 - 步骤4: 反向地理编码');
      LocationModel? location = await _geocodingService.reverseGeocode(
        result['gps_position']['latitude'],
        result['gps_position']['longitude'],
      );

      if (location == null) {
        print('主要反向地理编码失败，尝试备用方法');
        location = await _geocodingService.fallbackReverseGeocode(
          result['gps_position']['latitude'],
          result['gps_position']['longitude'],
        );
      }

      if (location != null) {
        result['reverse_geocoding'] = {
          'address': location.address,
          'district': location.district,
          'city': location.city,
          'province': location.province,
        };
        result['final_location'] = location;
        print('反向地理编码成功: ${location.district}');
      } else {
        result['errors'].add('反向地理编码失败');
      }
    } catch (e) {
      result['errors'].add('GPS验证过程出错: $e');
      print('GPS验证错误: $e');
    }

    return result;
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

  /// Cleanup resources
  void cleanup() {
    _cachedLocation = null;
  }
}
