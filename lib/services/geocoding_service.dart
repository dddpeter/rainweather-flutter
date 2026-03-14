import 'dart:async';
import 'package:dio/dio.dart';
import '../models/location_model.dart';
import '../utils/logger.dart';
import 'request_deduplicator.dart';

class GeocodingService {
  static GeocodingService? _instance;
  late Dio _dio;
  final RequestDeduplicator _deduplicator = RequestDeduplicator();

  // 百度地图逆地理编码API
  static const String _baiduGeocodingUrl =
      'https://api.map.baidu.com/reverse_geocoding/v3';
  static const String _baiduKey =
      'IU72QI4cmcMnDBV9WAakDLN3m3LCbLWz'; // 百度地图API Key

  // 缓存：城市名称 -> LocationModel
  final Map<String, LocationModel> _cache = {};

  // 缓存过期时间（1小时）
  static const Duration cacheExpiration = Duration(hours: 1);

  // 缓存时间戳
  final Map<String, DateTime> _cacheTimestamps = {};

  GeocodingService._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'RainWeather/1.0.0 (Flutter)',
        },
      ),
    );
  }

  static GeocodingService getInstance() {
    _instance ??= GeocodingService._();
    return _instance!;
  }

  /// Reverse geocoding using Baidu API
  Future<LocationModel?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        _baiduGeocodingUrl,
        queryParameters: {
          'ak': _baiduKey,
          'location': '$lat,$lng', // 百度地图使用纬度,经度格式
          'output': 'json',
          'coordtype': 'wgs84ll', // GPS坐标
          'extensions_poi': '1',
          'extensions_road': '1',
          'extensions_town': '1',
        },
      );

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
  LocationModel _parseBaiduResponse(
    Map<String, dynamic> result,
    double lat,
    double lng,
  ) {
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
    if (district.isNotEmpty &&
        !district.endsWith('区') &&
        !district.endsWith('县') &&
        !district.endsWith('市')) {
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

  /// 正向地理编码 - 将城市名称转换为坐标（使用OpenStreetMap Nominatim）
  /// 支持国外城市查询
  /// 
  /// [cityName] 城市名称
  /// [useCache] 是否使用缓存，默认为true
  /// [forceRefresh] 是否强制刷新，忽略缓存
  /// 
  /// 返回 LocationModel 对象，查询失败返回 null
  Future<LocationModel?> geocode(String cityName, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    if (cityName.isEmpty) {
      Logger.w('城市名称为空', tag: 'GeocodingService');
      return null;
    }

    // 标准化城市名称
    final normalizedName = cityName.trim();

    // 先检查预设的国际城市坐标（避免网络请求）
    final presetLocation = _getPresetInternationalCity(normalizedName);
    if (presetLocation != null) {
      Logger.d('使用预设坐标: $normalizedName', tag: 'GeocodingService');
      return presetLocation;
    }

    // 检查缓存
    if (useCache && !forceRefresh && _cache.containsKey(normalizedName)) {
      final cachedData = _cache[normalizedName];
      final cachedTime = _cacheTimestamps[normalizedName];
      
      if (cachedData != null && cachedTime != null) {
        // 检查缓存是否过期
        if (DateTime.now().difference(cachedTime) < cacheExpiration) {
          Logger.d('使用缓存的地理编码结果: $normalizedName', tag: 'GeocodingService');
          return cachedData;
        } else {
          // 缓存过期，清除
          _cache.remove(normalizedName);
          _cacheTimestamps.remove(normalizedName);
        }
      }
    }

    final requestKey = 'geo:$normalizedName';

    return await _deduplicator.execute<LocationModel?>(requestKey, () async {
      try {
        Logger.d('查询地理编码: $normalizedName', tag: 'GeocodingService');

        // 使用OpenStreetMap Nominatim API
        // 注意：Nominatim要求设置User-Agent，否则可能被拒绝
        final response = await _dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': normalizedName,
            'format': 'json',
            'addressdetails': '1',
            'limit': '1',
          },
          options: Options(
            headers: {
              'User-Agent': 'RainWeather/1.0 (Flutter Weather App)',
              'Accept': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          
          if (data.isNotEmpty) {
            // 取第一个结果（最相关的）
            final result = data.first as Map<String, dynamic>;
            
            // 构建LocationModel
            final locationModel = _parseNominatimResponse(result);
            
            // 保存到缓存
            _cache[normalizedName] = locationModel;
            _cacheTimestamps[normalizedName] = DateTime.now();
            
            Logger.d(
              '地理编码查询成功: $normalizedName -> (${locationModel.lat}, ${locationModel.lng})',
              tag: 'GeocodingService',
            );
            
            return locationModel;
          } else {
            Logger.w('未找到城市坐标: $normalizedName', tag: 'GeocodingService');
            return null;
          }
        }
        return null;
      } catch (e) {
        Logger.e('地理编码查询失败: $normalizedName', tag: 'GeocodingService', error: e);
        return null;
      }
    });
  }

  /// 预设的国际城市坐标（避免网络请求）
  /// 数据来源：OpenStreetMap / Google Maps
  static final Map<String, LocationModel> _presetInternationalCities = {
    // 亚洲
    '东京': LocationModel(
      address: 'Tokyo, Japan',
      country: '日本',
      province: '东京都',
      city: '东京',
      district: '东京',
      street: '',
      adcode: '',
      town: '',
      lat: 35.6762,
      lng: 139.6503,
    ),
    '首尔': LocationModel(
      address: 'Seoul, South Korea',
      country: '韩国',
      province: '首尔特别市',
      city: '首尔',
      district: '首尔',
      street: '',
      adcode: '',
      town: '',
      lat: 37.5665,
      lng: 126.9780,
    ),
    '新加坡': LocationModel(
      address: 'Singapore',
      country: '新加坡',
      province: '新加坡',
      city: '新加坡',
      district: '新加坡',
      street: '',
      adcode: '',
      town: '',
      lat: 1.3521,
      lng: 103.8198,
    ),
    '曼谷': LocationModel(
      address: 'Bangkok, Thailand',
      country: '泰国',
      province: '曼谷',
      city: '曼谷',
      district: '曼谷',
      street: '',
      adcode: '',
      town: '',
      lat: 13.7563,
      lng: 100.5018,
    ),
    // 大洋洲
    '悉尼': LocationModel(
      address: 'Sydney, Australia',
      country: '澳大利亚',
      province: '新南威尔士州',
      city: '悉尼',
      district: '悉尼',
      street: '',
      adcode: '',
      town: '',
      lat: -33.8688,
      lng: 151.2093,
    ),
    '墨尔本': LocationModel(
      address: 'Melbourne, Australia',
      country: '澳大利亚',
      province: '维多利亚州',
      city: '墨尔本',
      district: '墨尔本',
      street: '',
      adcode: '',
      town: '',
      lat: -37.8136,
      lng: 144.9631,
    ),
    // 欧洲
    '伦敦': LocationModel(
      address: 'London, United Kingdom',
      country: '英国',
      province: '英格兰',
      city: '伦敦',
      district: '伦敦',
      street: '',
      adcode: '',
      town: '',
      lat: 51.5074,
      lng: -0.1278,
    ),
    '巴黎': LocationModel(
      address: 'Paris, France',
      country: '法国',
      province: '法兰西岛',
      city: '巴黎',
      district: '巴黎',
      street: '',
      adcode: '',
      town: '',
      lat: 48.8566,
      lng: 2.3522,
    ),
    // 北美
    '纽约': LocationModel(
      address: 'New York, USA',
      country: '美国',
      province: '纽约州',
      city: '纽约',
      district: '纽约',
      street: '',
      adcode: '',
      town: '',
      lat: 40.7128,
      lng: -74.0060,
    ),
    '洛杉矶': LocationModel(
      address: 'Los Angeles, USA',
      country: '美国',
      province: '加利福尼亚州',
      city: '洛杉矶',
      district: '洛杉矶',
      street: '',
      adcode: '',
      town: '',
      lat: 34.0522,
      lng: -118.2437,
    ),
    '旧金山': LocationModel(
      address: 'San Francisco, USA',
      country: '美国',
      province: '加利福尼亚州',
      city: '旧金山',
      district: '旧金山',
      street: '',
      adcode: '',
      town: '',
      lat: 37.7749,
      lng: -122.4194,
    ),
    '温哥华': LocationModel(
      address: 'Vancouver, Canada',
      country: '加拿大',
      province: '不列颠哥伦比亚省',
      city: '温哥华',
      district: '温哥华',
      street: '',
      adcode: '',
      town: '',
      lat: 49.2827,
      lng: -123.1207,
    ),
    '多伦多': LocationModel(
      address: 'Toronto, Canada',
      country: '加拿大',
      province: '安大略省',
      city: '多伦多',
      district: '多伦多',
      street: '',
      adcode: '',
      town: '',
      lat: 43.6532,
      lng: -79.3832,
    ),
    // 中东
    '迪拜': LocationModel(
      address: 'Dubai, UAE',
      country: '阿联酋',
      province: '迪拜',
      city: '迪拜',
      district: '迪拜',
      street: '',
      adcode: '',
      town: '',
      lat: 25.2048,
      lng: 55.2708,
    ),
    // 亚洲 - 更多城市
    '大阪': LocationModel(
      address: 'Osaka, Japan',
      country: '日本',
      province: '大阪府',
      city: '大阪',
      district: '大阪',
      street: '',
      adcode: '',
      town: '',
      lat: 34.6937,
      lng: 135.5023,
    ),
    '京都': LocationModel(
      address: 'Kyoto, Japan',
      country: '日本',
      province: '京都府',
      city: '京都',
      district: '京都',
      street: '',
      adcode: '',
      town: '',
      lat: 35.0116,
      lng: 135.7681,
    ),
    '普吉岛': LocationModel(
      address: 'Phuket, Thailand',
      country: '泰国',
      province: '普吉府',
      city: '普吉岛',
      district: '普吉岛',
      street: '',
      adcode: '',
      town: '',
      lat: 7.8804,
      lng: 98.3923,
    ),
    '巴厘岛': LocationModel(
      address: 'Bali, Indonesia',
      country: '印度尼西亚',
      province: '巴厘省',
      city: '巴厘岛',
      district: '巴厘岛',
      street: '',
      adcode: '',
      town: '',
      lat: -8.3405,
      lng: 115.0920,
    ),
    '马尔代夫': LocationModel(
      address: 'Maldives',
      country: '马尔代夫',
      province: '马累',
      city: '马尔代夫',
      district: '马尔代夫',
      street: '',
      adcode: '',
      town: '',
      lat: 3.2028,
      lng: 73.2207,
    ),
    '香港': LocationModel(
      address: 'Hong Kong',
      country: '中国',
      province: '香港特别行政区',
      city: '香港',
      district: '香港',
      street: '',
      adcode: '',
      town: '',
      lat: 22.3193,
      lng: 114.1694,
    ),
    '澳门': LocationModel(
      address: 'Macau',
      country: '中国',
      province: '澳门特别行政区',
      city: '澳门',
      district: '澳门',
      street: '',
      adcode: '',
      town: '',
      lat: 22.1987,
      lng: 113.5439,
    ),
    '台北': LocationModel(
      address: 'Taipei, Taiwan',
      country: '台湾',
      province: '台北市',
      city: '台北',
      district: '台北',
      street: '',
      adcode: '',
      town: '',
      lat: 25.0330,
      lng: 121.5654,
    ),
    '多哈': LocationModel(
      address: 'Doha, Qatar',
      country: '卡塔尔',
      province: '多哈',
      city: '多哈',
      district: '多哈',
      street: '',
      adcode: '',
      town: '',
      lat: 25.2854,
      lng: 51.5310,
    ),
    // 大洋洲 - 更多
    '奥克兰': LocationModel(
      address: 'Auckland, New Zealand',
      country: '新西兰',
      province: '奥克兰大区',
      city: '奥克兰',
      district: '奥克兰',
      street: '',
      adcode: '',
      town: '',
      lat: -36.8509,
      lng: 174.7645,
    ),
    // 欧洲 - 更多城市
    '罗马': LocationModel(
      address: 'Rome, Italy',
      country: '意大利',
      province: '拉齐奥大区',
      city: '罗马',
      district: '罗马',
      street: '',
      adcode: '',
      town: '',
      lat: 41.9028,
      lng: 12.4964,
    ),
    '米兰': LocationModel(
      address: 'Milan, Italy',
      country: '意大利',
      province: '伦巴第大区',
      city: '米兰',
      district: '米兰',
      street: '',
      adcode: '',
      town: '',
      lat: 45.4642,
      lng: 9.1900,
    ),
    '威尼斯': LocationModel(
      address: 'Venice, Italy',
      country: '意大利',
      province: '威尼托大区',
      city: '威尼斯',
      district: '威尼斯',
      street: '',
      adcode: '',
      town: '',
      lat: 45.4408,
      lng: 12.3155,
    ),
    '佛罗伦萨': LocationModel(
      address: 'Florence, Italy',
      country: '意大利',
      province: '托斯卡纳大区',
      city: '佛罗伦萨',
      district: '佛罗伦萨',
      street: '',
      adcode: '',
      town: '',
      lat: 43.7696,
      lng: 11.2558,
    ),
    '柏林': LocationModel(
      address: 'Berlin, Germany',
      country: '德国',
      province: '柏林州',
      city: '柏林',
      district: '柏林',
      street: '',
      adcode: '',
      town: '',
      lat: 52.5200,
      lng: 13.4050,
    ),
    '慕尼黑': LocationModel(
      address: 'Munich, Germany',
      country: '德国',
      province: '巴伐利亚州',
      city: '慕尼黑',
      district: '慕尼黑',
      street: '',
      adcode: '',
      town: '',
      lat: 48.1351,
      lng: 11.5820,
    ),
    '法兰克福': LocationModel(
      address: 'Frankfurt, Germany',
      country: '德国',
      province: '黑森州',
      city: '法兰克福',
      district: '法兰克福',
      street: '',
      adcode: '',
      town: '',
      lat: 50.1109,
      lng: 8.6821,
    ),
    '马德里': LocationModel(
      address: 'Madrid, Spain',
      country: '西班牙',
      province: '马德里自治区',
      city: '马德里',
      district: '马德里',
      street: '',
      adcode: '',
      town: '',
      lat: 40.4168,
      lng: -3.7038,
    ),
    '巴塞罗那': LocationModel(
      address: 'Barcelona, Spain',
      country: '西班牙',
      province: '加泰罗尼亚',
      city: '巴塞罗那',
      district: '巴塞罗那',
      street: '',
      adcode: '',
      town: '',
      lat: 41.3851,
      lng: 2.1734,
    ),
    '阿姆斯特丹': LocationModel(
      address: 'Amsterdam, Netherlands',
      country: '荷兰',
      province: '北荷兰省',
      city: '阿姆斯特丹',
      district: '阿姆斯特丹',
      street: '',
      adcode: '',
      town: '',
      lat: 52.3676,
      lng: 4.9041,
    ),
    '维也纳': LocationModel(
      address: 'Vienna, Austria',
      country: '奥地利',
      province: '维也纳州',
      city: '维也纳',
      district: '维也纳',
      street: '',
      adcode: '',
      town: '',
      lat: 48.2082,
      lng: 16.3738,
    ),
    '布拉格': LocationModel(
      address: 'Prague, Czech Republic',
      country: '捷克',
      province: '布拉格',
      city: '布拉格',
      district: '布拉格',
      street: '',
      adcode: '',
      town: '',
      lat: 50.0755,
      lng: 14.4378,
    ),
    '布达佩斯': LocationModel(
      address: 'Budapest, Hungary',
      country: '匈牙利',
      province: '佩斯州',
      city: '布达佩斯',
      district: '布达佩斯',
      street: '',
      adcode: '',
      town: '',
      lat: 47.4979,
      lng: 19.0402,
    ),
    '哥本哈根': LocationModel(
      address: 'Copenhagen, Denmark',
      country: '丹麦',
      province: '首都大区',
      city: '哥本哈根',
      district: '哥本哈根',
      street: '',
      adcode: '',
      town: '',
      lat: 55.6761,
      lng: 12.5683,
    ),
    '斯德哥尔摩': LocationModel(
      address: 'Stockholm, Sweden',
      country: '瑞典',
      province: '斯德哥尔摩省',
      city: '斯德哥尔摩',
      district: '斯德哥尔摩',
      street: '',
      adcode: '',
      town: '',
      lat: 59.3293,
      lng: 18.0686,
    ),
    '奥斯陆': LocationModel(
      address: 'Oslo, Norway',
      country: '挪威',
      province: '奥斯陆',
      city: '奥斯陆',
      district: '奥斯陆',
      street: '',
      adcode: '',
      town: '',
      lat: 59.9139,
      lng: 10.7522,
    ),
    '赫尔辛基': LocationModel(
      address: 'Helsinki, Finland',
      country: '芬兰',
      province: '新地区',
      city: '赫尔辛基',
      district: '赫尔辛基',
      street: '',
      adcode: '',
      town: '',
      lat: 60.1699,
      lng: 24.9384,
    ),
    '莫斯科': LocationModel(
      address: 'Moscow, Russia',
      country: '俄罗斯',
      province: '莫斯科州',
      city: '莫斯科',
      district: '莫斯科',
      street: '',
      adcode: '',
      town: '',
      lat: 55.7558,
      lng: 37.6173,
    ),
    '圣彼得堡': LocationModel(
      address: 'Saint Petersburg, Russia',
      country: '俄罗斯',
      province: '圣彼得堡州',
      city: '圣彼得堡',
      district: '圣彼得堡',
      street: '',
      adcode: '',
      town: '',
      lat: 59.9311,
      lng: 30.3609,
    ),
    '伊斯坦布尔': LocationModel(
      address: 'Istanbul, Turkey',
      country: '土耳其',
      province: '伊斯坦布尔省',
      city: '伊斯坦布尔',
      district: '伊斯坦布尔',
      street: '',
      adcode: '',
      town: '',
      lat: 41.0082,
      lng: 28.9784,
    ),
    '雅典': LocationModel(
      address: 'Athens, Greece',
      country: '希腊',
      province: '阿提卡大区',
      city: '雅典',
      district: '雅典',
      street: '',
      adcode: '',
      town: '',
      lat: 37.9838,
      lng: 23.7275,
    ),
    '苏黎世': LocationModel(
      address: 'Zurich, Switzerland',
      country: '瑞士',
      province: '苏黎世州',
      city: '苏黎世',
      district: '苏黎世',
      street: '',
      adcode: '',
      town: '',
      lat: 47.3769,
      lng: 8.5417,
    ),
    '日内瓦': LocationModel(
      address: 'Geneva, Switzerland',
      country: '瑞士',
      province: '日内瓦州',
      city: '日内瓦',
      district: '日内瓦',
      street: '',
      adcode: '',
      town: '',
      lat: 46.2044,
      lng: 6.1432,
    ),
    // 北美 - 更多城市
    '芝加哥': LocationModel(
      address: 'Chicago, USA',
      country: '美国',
      province: '伊利诺伊州',
      city: '芝加哥',
      district: '芝加哥',
      street: '',
      adcode: '',
      town: '',
      lat: 41.8781,
      lng: -87.6298,
    ),
    '西雅图': LocationModel(
      address: 'Seattle, USA',
      country: '美国',
      province: '华盛顿州',
      city: '西雅图',
      district: '西雅图',
      street: '',
      adcode: '',
      town: '',
      lat: 47.6062,
      lng: -122.3321,
    ),
    '华盛顿': LocationModel(
      address: 'Washington D.C., USA',
      country: '美国',
      province: '华盛顿特区',
      city: '华盛顿',
      district: '华盛顿',
      street: '',
      adcode: '',
      town: '',
      lat: 38.9072,
      lng: -77.0369,
    ),
    '波士顿': LocationModel(
      address: 'Boston, USA',
      country: '美国',
      province: '马萨诸塞州',
      city: '波士顿',
      district: '波士顿',
      street: '',
      adcode: '',
      town: '',
      lat: 42.3601,
      lng: -71.0589,
    ),
    '拉斯维加斯': LocationModel(
      address: 'Las Vegas, USA',
      country: '美国',
      province: '内华达州',
      city: '拉斯维加斯',
      district: '拉斯维加斯',
      street: '',
      adcode: '',
      town: '',
      lat: 36.1699,
      lng: -115.1398,
    ),
    '迈阿密': LocationModel(
      address: 'Miami, USA',
      country: '美国',
      province: '佛罗里达州',
      city: '迈阿密',
      district: '迈阿密',
      street: '',
      adcode: '',
      town: '',
      lat: 25.7617,
      lng: -80.1918,
    ),
    '蒙特利尔': LocationModel(
      address: 'Montreal, Canada',
      country: '加拿大',
      province: '魁北克省',
      city: '蒙特利尔',
      district: '蒙特利尔',
      street: '',
      adcode: '',
      town: '',
      lat: 45.5017,
      lng: -73.5673,
    ),
    // 南美
    '里约热内卢': LocationModel(
      address: 'Rio de Janeiro, Brazil',
      country: '巴西',
      province: '里约热内卢州',
      city: '里约热内卢',
      district: '里约热内卢',
      street: '',
      adcode: '',
      town: '',
      lat: -22.9068,
      lng: -43.1729,
    ),
    '圣保罗': LocationModel(
      address: 'Sao Paulo, Brazil',
      country: '巴西',
      province: '圣保罗州',
      city: '圣保罗',
      district: '圣保罗',
      street: '',
      adcode: '',
      town: '',
      lat: -23.5505,
      lng: -46.6333,
    ),
    '布宜诺斯艾利斯': LocationModel(
      address: 'Buenos Aires, Argentina',
      country: '阿根廷',
      province: '布宜诺斯艾利斯自治市',
      city: '布宜诺斯艾利斯',
      district: '布宜诺斯艾利斯',
      street: '',
      adcode: '',
      town: '',
      lat: -34.6037,
      lng: -58.3816,
    ),
    '利马': LocationModel(
      address: 'Lima, Peru',
      country: '秘鲁',
      province: '利马省',
      city: '利马',
      district: '利马',
      street: '',
      adcode: '',
      town: '',
      lat: -12.0464,
      lng: -77.0428,
    ),
    '圣地亚哥': LocationModel(
      address: 'Santiago, Chile',
      country: '智利',
      province: '圣地亚哥首都大区',
      city: '圣地亚哥',
      district: '圣地亚哥',
      street: '',
      adcode: '',
      town: '',
      lat: -33.4489,
      lng: -70.6693,
    ),
    // 非洲
    '开罗': LocationModel(
      address: 'Cairo, Egypt',
      country: '埃及',
      province: '开罗省',
      city: '开罗',
      district: '开罗',
      street: '',
      adcode: '',
      town: '',
      lat: 30.0444,
      lng: 31.2357,
    ),
    '约翰内斯堡': LocationModel(
      address: 'Johannesburg, South Africa',
      country: '南非',
      province: '豪登省',
      city: '约翰内斯堡',
      district: '约翰内斯堡',
      street: '',
      adcode: '',
      town: '',
      lat: -26.2041,
      lng: 28.0473,
    ),
    '开普敦': LocationModel(
      address: 'Cape Town, South Africa',
      country: '南非',
      province: '西开普省',
      city: '开普敦',
      district: '开普敦',
      street: '',
      adcode: '',
      town: '',
      lat: -33.9249,
      lng: 18.4241,
    ),
    '卡萨布兰卡': LocationModel(
      address: 'Casablanca, Morocco',
      country: '摩洛哥',
      province: '卡萨布兰卡-塞塔特大区',
      city: '卡萨布兰卡',
      district: '卡萨布兰卡',
      street: '',
      adcode: '',
      town: '',
      lat: 33.5731,
      lng: -7.5898,
    ),
  };

  /// 获取预设的国际城市坐标
  LocationModel? _getPresetInternationalCity(String cityName) {
    return _presetInternationalCities[cityName];
  }

  /// 解析Nominatim API响应
  LocationModel _parseNominatimResponse(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>? ?? {};
    
    return LocationModel(
      address: result['display_name'] as String? ?? '',
      country: address['country'] as String? ?? '未知',
      province: address['state'] as String? ?? '未知',
      city: address['city'] as String? ??
             address['town'] as String? ??
             address['village'] as String? ??
             '未知',
      district: address['city'] as String? ??
                address['town'] as String? ??
                '未知',
      street: address['road'] as String? ?? '',
      adcode: '',
      town: '',
      lat: (result['lat'] as num).toDouble(),
      lng: (result['lon'] as num).toDouble(),
    );
  }

  /// 清空缓存
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    Logger.d('清空地理编码缓存', tag: 'GeocodingService');
  }

  /// 获取缓存大小
  int get cacheSize => _cache.length;
}
