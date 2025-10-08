import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_tencent_lbs_plugin/flutter_tencent_lbs_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

enum TencentLocationPermissionResult { granted, denied, deniedForever, error }

class TencentLocationException implements Exception {
  final String message;
  TencentLocationException(this.message);

  @override
  String toString() => 'TencentLocationException: $message';
}

class TencentLocationService {
  static TencentLocationService? _instance;
  final FlutterTencentLBSPlugin _location = FlutterTencentLBSPlugin();
  LocationModel? _cachedLocation;
  bool _isInitialized = false;

  // 腾讯定位API Key配置
  static const String _apiKey = 'ONHBZ-X3WWZ-FADXR-T5BOL-C4RP7-THFFB';

  // 天地图API Key（用于逆地理编码）
  static const String _tiandituKey = '0fd82aec5db7ce742c16ed1baa41b349';

  TencentLocationService._();

  static TencentLocationService getInstance() {
    _instance ??= TencentLocationService._();
    return _instance!;
  }

  /// 全局设置腾讯定位服务（在应用启动时调用）
  Future<void> setGlobalPrivacyAgreement() async {
    try {
      print('🔧 TencentLocationService: 全局设置腾讯定位服务');

      // 设置用户隐私政策同意
      _location.setUserAgreePrivacy();

      // 初始化腾讯定位
      _location.init(key: _apiKey);

      print('✅ TencentLocationService: 腾讯定位服务初始化成功');
    } catch (e) {
      print('❌ TencentLocationService: 腾讯定位服务初始化失败: $e');
      throw TencentLocationException('腾讯定位服务初始化失败: $e');
    }
  }

  /// 初始化腾讯定位服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 TencentLocationService: 开始初始化');

      // iOS平台跳过权限检查，直接初始化
      if (!Platform.isIOS) {
        // Android检查权限
        if (await _getPermissions()) return;
      } else {
        print('📱 TencentLocationService: iOS平台，跳过初始化时的权限检查');
      }

      // 隐私政策同意和初始化已在应用启动时设置
      _isInitialized = true;
      print('✅ 腾讯定位服务初始化成功');
    } catch (e) {
      print('❌ 腾讯定位服务初始化失败: $e');
      throw TencentLocationException('腾讯定位服务初始化失败: $e');
    }
  }

  /// 获取权限
  Future<bool> _getPermissions() async {
    try {
      print('🔍 TencentLocationService: 检查定位权限');

      // iOS上使用locationWhenInUse，Android上使用location
      final permission = Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location;

      final status = await permission.status;
      if (status.isGranted) {
        print('✅ TencentLocationService: 权限已获取');
        return false;
      }

      print('🔍 TencentLocationService: 请求定位权限');
      final requestStatus = await permission.request();

      if (requestStatus.isGranted) {
        print('✅ TencentLocationService: 权限获取成功');
        return false;
      } else if (requestStatus.isDenied) {
        print('❌ TencentLocationService: 权限被拒绝');
        throw TencentLocationException('定位权限被拒绝');
      } else if (requestStatus.isPermanentlyDenied) {
        print('❌ TencentLocationService: 权限被永久拒绝');
        throw TencentLocationException('定位权限被永久拒绝，请在设置中手动开启');
      } else {
        print('❌ TencentLocationService: 权限获取失败');
        throw TencentLocationException('定位权限获取失败');
      }
    } catch (e) {
      print('❌ TencentLocationService: 权限检查失败: $e');
      return true; // 返回true表示有错误，应该停止执行
    }
  }

  /// 获取当前位置（单次定位）
  Future<LocationModel?> getCurrentLocation() async {
    try {
      print('🚀 TencentLocationService: 开始获取当前位置');

      if (!_isInitialized) {
        print('🔧 TencentLocationService: 初始化服务');
        await initialize();
      }

      // iOS暂时跳过权限检查，直接尝试定位
      if (Platform.isIOS) {
        print('📱 TencentLocationService: iOS平台，跳过权限检查，直接定位');
      } else {
        // Android继续检查权限
        if (await _getPermissions()) {
          print('❌ TencentLocationService: 权限未授予');
          throw TencentLocationException('定位权限未授予');
        }
      }

      print('✅ TencentLocationService: 准备开始定位');

      // 获取单次定位
      print('🚀 开始腾讯定位...');
      final location = await _location.getLocationOnce();

      if (location == null) {
        print('❌ 腾讯定位失败：返回结果为空');
        return null;
      }

      print('=' * 60);
      print('📍 腾讯定位原始数据:');
      print('=' * 60);
      try {
        final json = location.toJson();
        json.forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });
      } catch (e) {
        print('  无法转换为JSON: $e');
      }
      print('=' * 60);

      // 解析定位结果
      final locationModel = await _parseTencentLocation(location);
      if (locationModel != null) {
        print('✅ 腾讯定位成功: ${locationModel.district}');
        _cachedLocation = locationModel;
      }

      return locationModel;
    } catch (e) {
      print('❌ 获取当前位置失败: $e');
      return null;
    }
  }

  /// 解析腾讯定位结果
  Future<LocationModel?> _parseTencentLocation(dynamic location) async {
    try {
      print('🔍 TencentLocationService: 解析定位结果');
      print('🔍 TencentLocationService: location类型: ${location.runtimeType}');

      // 将location转换为Map，因为返回的是动态对象
      Map<String, dynamic> locationMap = {};

      // 尝试使用toJson方法
      try {
        if (location.toJson != null) {
          locationMap = location.toJson();
          print('🔍 TencentLocationService: 定位数据: $locationMap');
        }
      } catch (e) {
        print('⚠️ TencentLocationService: 无法使用toJson: $e');
      }

      // 根据平台选择合适的坐标系
      double lat = _getDoubleValue(location, 'latitude') ?? 0.0;
      double lng = _getDoubleValue(location, 'longitude') ?? 0.0;

      // Android使用WGS84坐标，iOS使用GCJ02坐标（根据文档建议）
      if (Platform.isAndroid) {
        print('🤖 Android平台，使用WGS84坐标');
      } else if (Platform.isIOS) {
        print('📱 iOS平台，使用GCJ02坐标');
      }

      // 腾讯定位字段映射（从toJson获取）
      final address = _getStringValue(location, 'address') ?? '';
      final name = _getStringValue(location, 'name') ?? '';
      final city = _getStringValue(location, 'city') ?? '';
      final province = _getStringValue(location, 'province') ?? '';
      final area = _getStringValue(location, 'area') ?? '';

      print(
        '🔍 TencentLocationService: address=$address, name=$name, city=$city, province=$province, area=$area',
      );

      // 检查是否有有效的地址信息
      if (city.isEmpty &&
          province.isEmpty &&
          area.isEmpty &&
          address.isEmpty &&
          name.isEmpty) {
        print('⚠️ TencentLocationService: 腾讯定位没有返回地址信息，只有坐标');

        // 尝试使用天地图逆地理编码
        if (lat != 0.0 && lng != 0.0) {
          print('🔄 TencentLocationService: 尝试使用天地图逆地理编码');
          final reverseGeoResult = await _reverseGeocodeTianditu(lng, lat);
          if (reverseGeoResult != null) {
            print('✅ TencentLocationService: 天地图逆地理编码成功');
            return reverseGeoResult;
          }
        }

        print('⚠️ TencentLocationService: 将尝试下一个定位服务（高德地图）');
        return null; // 返回null，让系统尝试下一个定位服务
      }

      return LocationModel(
        lat: lat,
        lng: lng,
        address: address.isNotEmpty ? address : name,
        country: '中国', // 腾讯定位默认中国
        province: province,
        city: city,
        district: area, // 腾讯定位使用 area 字段表示区县
        street: '',
        adcode: _getStringValue(location, 'cityCode') ?? '',
        town: '',
        isProxyDetected: false, // 腾讯定位通常不是代理
      );
    } catch (e) {
      print('❌ 解析腾讯定位结果失败: $e');
    }
    return null;
  }

  /// 安全获取字符串值
  String? _getStringValue(dynamic obj, String key) {
    try {
      final value = obj.toJson()[key];
      return value?.toString();
    } catch (e) {
      return null;
    }
  }

  /// 安全获取双精度值
  double? _getDoubleValue(dynamic obj, String key) {
    try {
      final value = obj.toJson()[key];
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 天地图逆地理编码（将坐标转换为地址）
  Future<LocationModel?> _reverseGeocodeTianditu(double lon, double lat) async {
    try {
      print('🌐 开始天地图逆地理编码: lon=$lon, lat=$lat');

      // 构建请求参数
      final postStr = jsonEncode({"lon": lon, "lat": lat, "ver": 1});

      // 构建URL
      final url = Uri.parse(
        'https://api.tianditu.gov.cn/geocoder?postStr=$postStr&type=geocode&tk=$_tiandituKey',
      );

      print('🌐 天地图API URL: $url');

      // 发送HTTP请求
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⏰ 天地图逆地理编码超时');
              throw TimeoutException('天地图逆地理编码超时');
            },
          );

      if (response.statusCode != 200) {
        print('❌ 天地图逆地理编码请求失败: ${response.statusCode}');
        return null;
      }

      // 解析响应
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('🌐 天地图响应: $data');

      if (data['status'] != '0') {
        print('❌ 天地图逆地理编码失败: ${data['msg']}');
        return null;
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        print('❌ 天地图返回结果为空');
        return null;
      }

      final addressComponent =
          result['addressComponent'] as Map<String, dynamic>?;
      if (addressComponent == null) {
        print('❌ 天地图地址组件为空');
        return null;
      }

      // 提取地址信息
      final formattedAddress = result['formatted_address'] as String? ?? '';
      final province = addressComponent['province'] as String? ?? '';
      final city = addressComponent['city'] as String? ?? '';
      final county = addressComponent['county'] as String? ?? '';
      final town = addressComponent['town'] as String? ?? '';
      final road = addressComponent['road'] as String? ?? '';

      print(
        '🌐 天地图地址解析: province=$province, city=$city, county=$county, town=$town',
      );

      return LocationModel(
        lat: lat,
        lng: lon,
        address: formattedAddress,
        country: addressComponent['nation'] as String? ?? '中国',
        province: province,
        city: city.isNotEmpty ? city : province, // 直辖市city为空，使用province
        district: county,
        street: road,
        adcode: addressComponent['county_code'] as String? ?? '',
        town: town,
        isProxyDetected: false,
      );
    } catch (e) {
      print('❌ 天地图逆地理编码失败: $e');
      return null;
    }
  }

  /// 开启连续定位监听
  Future<void> startLocationChange({
    required Function(LocationModel) onLocationChanged,
    Function(String)? onError,
  }) async {
    try {
      print('🔧 TencentLocationService: 开启连续定位监听');

      if (!_isInitialized) {
        await initialize();
      }

      if (await _getPermissions()) {
        onError?.call('定位权限未授予');
        return;
      }

      // 添加定位监听
      _location.addLocationListener((location) async {
        final locationModel = await _parseTencentLocation(location);
        if (locationModel != null) {
          _cachedLocation = locationModel;
          onLocationChanged(locationModel);
        }
      });

      // 开启连续定位（15秒间隔）
      _location.getLocation(
        interval: 15 * 1000, // 15秒间隔
        backgroundLocation: false, // 暂不开启后台定位
      );

      print('✅ TencentLocationService: 连续定位监听已开启');
    } catch (e) {
      print('❌ 开启连续定位监听失败: $e');
      onError?.call('开启连续定位监听失败: $e');
    }
  }

  /// 停止连续定位监听
  void stopLocationChange() {
    try {
      print('🔧 TencentLocationService: 停止连续定位监听');
      _location.stop();
      print('✅ TencentLocationService: 连续定位监听已停止');
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
      print('❌ 腾讯定位服务不可用: $e');
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    try {
      print('🔧 TencentLocationService: 释放资源');
      stopLocationChange();
      _isInitialized = false;
      print('✅ TencentLocationService: 资源已释放');
    } catch (e) {
      print('❌ 释放资源失败: $e');
    }
  }
}
