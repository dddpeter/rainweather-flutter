import 'package:dio/dio.dart';
import '../models/location_model.dart';

class GeocodingService {
  static GeocodingService? _instance;
  final Dio _dio;
  
  // 百度地图逆地理编码API
  static const String _baiduGeocodingUrl = 'https://api.map.baidu.com/reverse_geocoding/v3';
  static const String _baiduKey = 'IU72QI4cmcMnDBV9WAakDLN3m3LCbLWz'; // 百度地图API Key
  
  GeocodingService._() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  static GeocodingService getInstance() {
    _instance ??= GeocodingService._();
    return _instance!;
  }
  
  /// Reverse geocoding using Baidu API
  Future<LocationModel?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(_baiduGeocodingUrl, queryParameters: {
        'ak': _baiduKey,
        'location': '$lat,$lng', // 百度地图使用纬度,经度格式
        'output': 'json',
        'coordtype': 'wgs84ll', // GPS坐标
        'extensions_poi': '1',
        'extensions_road': '1',
        'extensions_town': '1',
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 0 && data['result'] != null) {
          return _parseBaiduResponse(data['result'], lat, lng);
        }
      }
      
      return null;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }
  
  /// Parse Baidu API response
  LocationModel _parseBaiduResponse(Map<String, dynamic> result, double lat, double lng) {
    final addressComponent = result['addressComponent'] ?? {};
    final formattedAddress = result['formatted_address'] ?? '';
    
    // 解析地址组件
    String country = addressComponent['country'] ?? '中国';
    String province = addressComponent['province'] ?? '';
    String city = addressComponent['city'] ?? '';
    String district = addressComponent['district'] ?? '';
    String township = addressComponent['town'] ?? '';
    String street = addressComponent['street'] ?? '';
    String adcode = addressComponent['adcode'] ?? '';
    
    // 处理直辖市情况（如北京、上海、天津、重庆）
    if (city.isEmpty && province.isNotEmpty) {
      city = province;
    }
    
    // 百度API返回的district可能包含"区"字，需要处理
    if (district.isNotEmpty && !district.endsWith('区') && !district.endsWith('县') && !district.endsWith('市')) {
      district = '$district区';
    }
    
    return LocationModel(
      address: formattedAddress,
      country: country,
      province: province,
      city: city,
      district: district,
      street: street,
      adcode: adcode,
      town: township,
      lat: lat,
      lng: lng,
    );
  }
  
  /// Fallback reverse geocoding using coordinates-based estimation
  /// This is a simple fallback when API is not available
  Future<LocationModel?> fallbackReverseGeocode(double lat, double lng) async {
    // 基于坐标的简单区域判断（仅适用于中国主要城市）
    if (_isInBeijing(lat, lng)) {
      return LocationModel(
        address: '北京市',
        country: '中国',
        province: '北京市',
        city: '北京市',
        district: _getBeijingDistrict(lat, lng),
        street: '',
        adcode: '110000',
        town: '',
        lat: lat,
        lng: lng,
      );
    }
    
    if (_isInShanghai(lat, lng)) {
      return LocationModel(
        address: '上海市',
        country: '中国',
        province: '上海市',
        city: '上海市',
        district: _getShanghaiDistrict(lat, lng),
        street: '',
        adcode: '310000',
        town: '',
        lat: lat,
        lng: lng,
      );
    }
    
    // 默认返回未知位置
    return LocationModel(
      address: '未知位置',
      country: '中国',
      province: '未知',
      city: '未知',
      district: '未知',
      street: '',
      adcode: '',
      town: '',
      lat: lat,
      lng: lng,
    );
  }
  
  /// Check if coordinates are in Beijing
  bool _isInBeijing(double lat, double lng) {
    // 北京大致范围：纬度 39.4-40.1，经度 115.7-117.4
    return lat >= 39.4 && lat <= 40.1 && lng >= 115.7 && lng <= 117.4;
  }
  
  /// Check if coordinates are in Shanghai
  bool _isInShanghai(double lat, double lng) {
    // 上海大致范围：纬度 30.7-31.9，经度 120.8-122.1
    return lat >= 30.7 && lat <= 31.9 && lng >= 120.8 && lng <= 122.1;
  }
  
  /// Get Beijing district based on coordinates
  String _getBeijingDistrict(double lat, double lng) {
    // 朝阳区大致范围
    if (lat >= 39.8 && lat <= 40.1 && lng >= 116.2 && lng <= 116.8) {
      return '朝阳区';
    }
    // 海淀区大致范围
    if (lat >= 39.9 && lat <= 40.1 && lng >= 116.0 && lng <= 116.4) {
      return '海淀区';
    }
    // 东城区大致范围
    if (lat >= 39.9 && lat <= 40.0 && lng >= 116.3 && lng <= 116.5) {
      return '东城区';
    }
    // 西城区大致范围
    if (lat >= 39.9 && lat <= 40.0 && lng >= 116.2 && lng <= 116.4) {
      return '西城区';
    }
    // 丰台区大致范围
    if (lat >= 39.8 && lat <= 39.9 && lng >= 116.2 && lng <= 116.5) {
      return '丰台区';
    }
    // 石景山区大致范围
    if (lat >= 39.9 && lat <= 40.0 && lng >= 116.1 && lng <= 116.3) {
      return '石景山区';
    }
    
    return '朝阳区'; // 默认返回朝阳区
  }
  
  /// Get Shanghai district based on coordinates
  String _getShanghaiDistrict(double lat, double lng) {
    // 浦东新区大致范围
    if (lat >= 31.1 && lat <= 31.3 && lng >= 121.4 && lng <= 121.9) {
      return '浦东新区';
    }
    // 黄浦区大致范围
    if (lat >= 31.2 && lat <= 31.3 && lng >= 121.4 && lng <= 121.5) {
      return '黄浦区';
    }
    // 徐汇区大致范围
    if (lat >= 31.1 && lat <= 31.2 && lng >= 121.4 && lng <= 121.5) {
      return '徐汇区';
    }
    
    return '浦东新区'; // 默认返回浦东新区
  }
}
