import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../utils/gbk_decoder.dart';

class IpLocationService {
  static IpLocationService? _instance;

  IpLocationService._();

  static IpLocationService getInstance() {
    _instance ??= IpLocationService._();
    return _instance!;
  }

  /// Get location by IP address (只使用太平洋网络接口)
  Future<LocationModel?> getLocationByIp() async {
    try {
      print('Attempting to get location by IP...');

      // 只使用太平洋网络接口
      LocationModel? location = await _tryPconlineService();
      if (location != null) {
        print('✅ Got location from Pconline IP service: ${location.district}');
        return location;
      }

      print('❌ Pconline IP location service failed');
      return null;
    } catch (e) {
      print('IP location error: $e');
      return null;
    }
  }

  /// Try Pconline IP location service (太平洋网络)
  Future<LocationModel?> _tryPconlineService() async {
    try {
      print('📡 正在调用太平洋网络IP定位接口...');
      // 太平洋网络免费IP定位接口 - 直接调用，不需要先获取IP
      final locationResponse = await http
          .get(
            Uri.parse('https://whois.pconline.com.cn/ipJson.jsp?json=true'),
            headers: {
              'Accept': 'application/json, text/html, */*',
              'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('📡 太平洋网络接口响应状态: ${locationResponse.statusCode}');
      if (locationResponse.statusCode == 200) {
        // 使用集成的GBK解码器处理太平洋网络接口的GBK编码响应
        String responseBody = GbkDecoder().decodeWithFallback(
          locationResponse.bodyBytes,
        );
        print('📡 响应内容: $responseBody');

        try {
          final data = json.decode(responseBody);

          // 太平洋网络返回格式：{"pro":"北京市","city":"北京市","region":"朝阳区","isp":"联通"}
          if (data['city'] != null && data['pro'] != null) {
            print(
              '📡 解析成功，位置: ${data['pro']} ${data['city']} ${data['region']}',
            );
            return LocationModel(
              address: '${data['pro']}${data['city']}${data['region'] ?? ''}',
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
          } else {
            print('📡 数据格式不正确: $data');
          }
        } catch (jsonError) {
          print('📡 JSON解析错误: $jsonError');
          print('📡 响应内容: $responseBody');
        }
      } else {
        print('📡 接口请求失败，状态码: ${locationResponse.statusCode}');
      }
    } catch (e) {
      print('📡 太平洋网络IP服务错误: $e');
    }
    return null;
  }
}
