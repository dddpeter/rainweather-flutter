import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';

/// 增强版地理编码服务
/// 使用 geocoding 插件提供更可靠的反向地理编码功能
/// 参考文档：https://pub.dev/packages/geocoding
class EnhancedGeocodingService {
  static EnhancedGeocodingService? _instance;

  EnhancedGeocodingService._();

  static EnhancedGeocodingService getInstance() {
    _instance ??= EnhancedGeocodingService._();
    return _instance!;
  }

  /// 使用 geocoding 插件进行反向地理编码
  /// 根据文档：https://pub.dev/packages/geocoding
  Future<LocationModel?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      print('🌍 准备使用 geocoding 插件进行反向地理编码...');

      // 使用 geocoding 插件的 placemarkFromCoordinates 方法
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        print('✅ geocoding 插件解析成功: ${placemark.locality}');

        return _convertPlacemarkToLocationModel(placemark, latitude, longitude);
      } else {
        print('❌ geocoding 插件未返回任何结果');
        return null;
      }
    } catch (e) {
      print('❌ 增强地理编码错误: $e');
      return null;
    }
  }

  /// 将 Placemark 转换为 LocationModel
  LocationModel _convertPlacemarkToLocationModel(
    Placemark placemark,
    double lat,
    double lng,
  ) {
    // 构建地址信息
    String address = _buildAddress(placemark);

    // 获取省份信息（优先使用 administrativeArea，然后是 subAdministrativeArea）
    String province =
        placemark.administrativeArea ?? placemark.subAdministrativeArea ?? '未知';

    // 获取城市信息（优先使用 locality，然后是 subLocality）
    String city = placemark.locality ?? placemark.subLocality ?? '未知';

    // 获取区县信息（优先使用 subLocality，然后是 thoroughfare）
    String district = placemark.subLocality ?? placemark.thoroughfare ?? city;

    return LocationModel(
      address: address,
      country: placemark.country ?? '中国',
      province: province,
      city: city,
      district: district,
      street: placemark.thoroughfare ?? '未知',
      adcode: '000000', // geocoding 插件不提供行政区划代码
      town: placemark.subLocality ?? '未知',
      lat: lat,
      lng: lng,
    );
  }

  /// 构建完整的地址字符串
  String _buildAddress(Placemark placemark) {
    List<String> addressParts = [];

    // 添加省份
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }

    // 添加城市
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }

    // 添加区县
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }

    // 添加街道
    if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
      addressParts.add(placemark.thoroughfare!);
    }

    return addressParts.join('');
  }

  /// 备用反向地理编码方法（保持与原服务的兼容性）
  Future<LocationModel?> fallbackReverseGeocode(
    double latitude,
    double longitude,
  ) async {
    print('🔄 使用备用反向地理编码...');

    return LocationModel(
      address: '未知位置',
      country: '中国',
      province: '未知',
      city: '未知',
      district: '未知',
      street: '未知',
      adcode: '000000',
      town: '未知',
      lat: latitude,
      lng: longitude,
    );
  }
}
