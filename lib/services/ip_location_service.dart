import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class IpLocationService {
  static IpLocationService? _instance;

  IpLocationService._();

  static IpLocationService getInstance() {
    _instance ??= IpLocationService._();
    return _instance!;
  }

  /// Convert GBK bytes to UTF-8 string (简化版本)
  String _gbkToUtf8(Uint8List gbkBytes) {
    try {
      // 由于GBK转UTF-8比较复杂，这里使用一个简化的方法
      // 先尝试直接UTF-8解码
      String directDecode = utf8.decode(gbkBytes, allowMalformed: true);

      // 如果包含乱码字符，说明是GBK编码
      if (directDecode.contains('') || directDecode.contains('')) {
        // 由于GBK解码比较复杂，这里返回一个默认值
        // 在实际应用中，建议使用专门的GBK解码库
        print('检测到GBK编码，但当前无法正确解码，建议使用其他IP定位接口');
        return '{}'; // 返回空的JSON，让上层处理
      }

      return directDecode;
    } catch (e) {
      // 如果转换失败，返回原始字符串
      return utf8.decode(gbkBytes, allowMalformed: true);
    }
  }

  /// Get location by IP address (optimized priority order)
  Future<LocationModel?> getLocationByIp() async {
    try {
      print('Attempting to get location by IP...');

      // 优先级1: 国内免费IP定位接口（中文地址）
      LocationModel? location = await _tryChineseIpLocationService();
      if (location != null) {
        print(
          '✅ Got location from Chinese IP location service: ${location.district}',
        );
        return location;
      }

      // 优先级2: ip-api.com (备用，支持中文)
      location = await _tryIpApiService();
      if (location != null) {
        print('✅ Got location from IP-API: ${location.district}');
        return location;
      }

      // 优先级2: 太平洋网络IP服务（备用）
      location = await _tryChineseIpService();
      if (location != null) {
        print('✅ Got location from Pconline IP service: ${location.district}');
        return location;
      }

      // 优先级3: ipinfo.io (备用，可能被限制)
      location = await _tryIpInfoService();
      if (location != null) {
        print('✅ Got location from IP Info: ${location.district}');
        return location;
      }

      // 优先级4: ipify (最后备用，需要两次请求)
      location = await _tryIpifyService();
      if (location != null) {
        print('✅ Got location from IPify: ${location.district}');
        return location;
      }

      print('❌ All IP location services failed');
      return null;
    } catch (e) {
      print('IP location error: $e');
      return null;
    }
  }

  /// Try Chinese IP location service (国内免费，中文地址)
  Future<LocationModel?> _tryChineseIpLocationService() async {
    try {
      // 使用ip-api.com的中文接口，更稳定可靠
      final response = await http
          .get(
            Uri.parse('http://ip-api.com/json?lang=zh-CN'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return LocationModel(
            address: data['city'] ?? '未知',
            country: data['country'] ?? '中国',
            province: data['regionName'] ?? '未知',
            city: data['city'] ?? '未知',
            district: data['city'] ?? '未知',
            street: '未知',
            adcode: '000000',
            town: '未知',
            lat: data['lat']?.toDouble() ?? 0.0,
            lng: data['lon']?.toDouble() ?? 0.0,
          );
        }
      }
    } catch (e) {
      print('Chinese IP location service error: $e');
    }
    return null;
  }

  /// Try Chinese IP location service (备用)
  Future<LocationModel?> _tryChineseIpService() async {
    try {
      // 太平洋网络免费IP定位接口
      // 先获取当前IP地址
      final ipResponse = await http
          .get(
            Uri.parse('https://api.ipify.org?format=json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (ipResponse.statusCode == 200) {
        final ipData = json.decode(ipResponse.body);
        final ip = ipData['ip'];

        if (ip != null) {
          // 使用太平洋网络接口获取位置信息
          final locationResponse = await http
              .get(
                Uri.parse(
                  'https://whois.pconline.com.cn/ipJson.jsp?ip=$ip&json=true',
                ),
                headers: {
                  'Accept':
                      'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                  'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
                  'User-Agent':
                      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
                  'Cache-Control': 'no-cache',
                },
              )
              .timeout(const Duration(seconds: 5));

          if (locationResponse.statusCode == 200) {
            // 处理GBK编码的响应
            String responseBody = _gbkToUtf8(locationResponse.bodyBytes);

            try {
              final data = json.decode(responseBody);

              // 太平洋网络返回格式：{"pro":"北京市","city":"北京市","region":"朝阳区","isp":"联通"}
              if (data['city'] != null && data['pro'] != null) {
                return LocationModel(
                  address:
                      '${data['pro']}${data['city']}${data['region'] ?? ''}',
                  country: '中国',
                  province: data['pro'] ?? '未知',
                  city: data['city'] ?? '未知',
                  district: data['region'] ?? data['city'] ?? '未知',
                  street: '未知',
                  adcode: '000000',
                  town: '未知',
                  lat: 0.0, // 太平洋网络接口不返回经纬度
                  lng: 0.0,
                );
              }
            } catch (jsonError) {
              print('JSON parse error after GBK decode: $jsonError');
              print('Response body: $responseBody');
            }
          }
        }
      }
    } catch (e) {
      print('Pconline IP service error: $e');
    }

    // 如果太平洋网络接口失败，尝试直接查询（不传IP参数）
    try {
      final response = await http
          .get(
            Uri.parse('https://whois.pconline.com.cn/ipJson.jsp?json=true'),
            headers: {
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // 处理GBK编码的响应
        String responseBody = _gbkToUtf8(response.bodyBytes);

        try {
          final data = json.decode(responseBody);

          if (data['city'] != null && data['pro'] != null) {
            return LocationModel(
              address: '${data['pro']}${data['city']}${data['region'] ?? ''}',
              country: '中国',
              province: data['pro'] ?? '未知',
              city: data['city'] ?? '未知',
              district: data['region'] ?? data['city'] ?? '未知',
              street: '未知',
              adcode: '000000',
              town: '未知',
              lat: 0.0,
              lng: 0.0,
            );
          }
        } catch (jsonError) {
          print('JSON parse error after GBK decode (direct): $jsonError');
          print('Response body: $responseBody');
        }
      }
    } catch (e) {
      print('Pconline IP service (direct) error: $e');
    }

    return null;
  }

  /// Try IP-API service with Chinese localization
  Future<LocationModel?> _tryIpApiService() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://ip-api.com/json?lang=zh-CN'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Translate English city names to Chinese
          final chineseCity = _translateCityName(data['city'] ?? '');
          final chineseProvince = _translateProvinceName(
            data['regionName'] ?? '',
          );

          return LocationModel(
            address: chineseCity,
            country: data['country'] ?? '中国',
            province: chineseProvince,
            city: chineseCity,
            district: chineseCity,
            street: '未知',
            adcode: '000000',
            town: '未知',
            lat: data['lat']?.toDouble() ?? 0.0,
            lng: data['lon']?.toDouble() ?? 0.0,
          );
        }
      }
    } catch (e) {
      print('IP-API service error: $e');
    }
    return null;
  }

  /// Try ipinfo.io service (free tier available)
  Future<LocationModel?> _tryIpInfoService() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://ipinfo.io/json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['city'] != null) {
          // Parse coordinates from loc field (format: "lat,lon")
          double lat = 0.0;
          double lon = 0.0;
          if (data['loc'] != null) {
            final coords = data['loc'].toString().split(',');
            if (coords.length == 2) {
              lat = double.tryParse(coords[0]) ?? 0.0;
              lon = double.tryParse(coords[1]) ?? 0.0;
            }
          }

          // Translate English names to Chinese
          final chineseCity = _translateCityName(data['city'] ?? '');
          final chineseProvince = _translateProvinceName(data['region'] ?? '');

          return LocationModel(
            address: chineseCity,
            country: data['country'] ?? '中国',
            province: chineseProvince,
            city: chineseCity,
            district: chineseCity,
            street: '未知',
            adcode: '000000',
            town: '未知',
            lat: lat,
            lng: lon,
          );
        }
      }
    } catch (e) {
      print('IP Info service error: $e');
    }
    return null;
  }

  /// Try ipify service (free tier available)
  Future<LocationModel?> _tryIpifyService() async {
    try {
      // First get IP address
      final ipResponse = await http
          .get(
            Uri.parse('https://api.ipify.org?format=json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (ipResponse.statusCode == 200) {
        final ipData = json.decode(ipResponse.body);
        final ip = ipData['ip'];

        if (ip != null) {
          // Then get location by IP (using a free geolocation service)
          final locationResponse = await http
              .get(
                Uri.parse('http://ip-api.com/json/$ip'),
                headers: {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 5));

          if (locationResponse.statusCode == 200) {
            final data = json.decode(locationResponse.body);
            if (data['status'] == 'success') {
              // Translate English names to Chinese
              final chineseCity = _translateCityName(data['city'] ?? '');
              final chineseProvince = _translateProvinceName(
                data['regionName'] ?? '',
              );

              return LocationModel(
                address: chineseCity,
                country: data['country'] ?? '中国',
                province: chineseProvince,
                city: chineseCity,
                district: chineseCity,
                street: '未知',
                adcode: '000000',
                town: '未知',
                lat: data['lat']?.toDouble() ?? 0.0,
                lng: data['lon']?.toDouble() ?? 0.0,
              );
            }
          }
        }
      }
    } catch (e) {
      print('IPify service error: $e');
    }
    return null;
  }

  /// Translate English city names to Chinese
  String _translateCityName(String englishName) {
    final cityTranslations = {
      'Beijing': '北京',
      'Shanghai': '上海',
      'Guangzhou': '广州',
      'Shenzhen': '深圳',
      'Hangzhou': '杭州',
      'Nanjing': '南京',
      'Wuhan': '武汉',
      'Chengdu': '成都',
      'Xi\'an': '西安',
      'Chongqing': '重庆',
      'Tianjin': '天津',
      'Qingdao': '青岛',
      'Dalian': '大连',
      'Xiamen': '厦门',
      'Ningbo': '宁波',
      'Suzhou': '苏州',
      'Wuxi': '无锡',
      'Changsha': '长沙',
      'Zhengzhou': '郑州',
      'Jinan': '济南',
      'Harbin': '哈尔滨',
      'Changchun': '长春',
      'Shenyang': '沈阳',
      'Shijiazhuang': '石家庄',
      'Taiyuan': '太原',
      'Hefei': '合肥',
      'Fuzhou': '福州',
      'Nanchang': '南昌',
      'Kunming': '昆明',
      'Nanning': '南宁',
      'Haikou': '海口',
      'Lanzhou': '兰州',
      'Xining': '西宁',
      'Yinchuan': '银川',
      'Urumqi': '乌鲁木齐',
      'Lhasa': '拉萨',
      'Guiyang': '贵阳',
      'Hong Kong': '香港',
      'Macau': '澳门',
      'Taipei': '台北',
      'Kaohsiung': '高雄',
      'Taichung': '台中',
    };

    return cityTranslations[englishName] ?? englishName;
  }

  /// Translate English province names to Chinese
  String _translateProvinceName(String englishName) {
    final provinceTranslations = {
      'Beijing': '北京市',
      'Shanghai': '上海市',
      'Tianjin': '天津市',
      'Chongqing': '重庆市',
      'Guangdong': '广东省',
      'Jiangsu': '江苏省',
      'Zhejiang': '浙江省',
      'Shandong': '山东省',
      'Henan': '河南省',
      'Sichuan': '四川省',
      'Hubei': '湖北省',
      'Fujian': '福建省',
      'Hunan': '湖南省',
      'Anhui': '安徽省',
      'Hebei': '河北省',
      'Shanxi': '山西省',
      'Liaoning': '辽宁省',
      'Jilin': '吉林省',
      'Heilongjiang': '黑龙江省',
      'Jiangxi': '江西省',
      'Yunnan': '云南省',
      'Guizhou': '贵州省',
      'Gansu': '甘肃省',
      'Qinghai': '青海省',
      'Shaanxi': '陕西省',
      'Hainan': '海南省',
      'Taiwan': '台湾省',
      'Hong Kong': '香港特别行政区',
      'Macau': '澳门特别行政区',
      'Xinjiang': '新疆维吾尔自治区',
      'Tibet': '西藏自治区',
      'Inner Mongolia': '内蒙古自治区',
      'Ningxia': '宁夏回族自治区',
      'Guangxi': '广西壮族自治区',
    };

    return provinceTranslations[englishName] ?? englishName;
  }
}
