import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class IpLocationService {
  static IpLocationService? _instance;
  
  IpLocationService._();
  
  static IpLocationService getInstance() {
    _instance ??= IpLocationService._();
    return _instance!;
  }
  
  /// Get location by IP address
  Future<LocationModel?> getLocationByIp() async {
    try {
      print('Attempting to get location by IP...');
      
      // Try multiple IP location services for better reliability
      LocationModel? location = await _tryIpApiService();
      if (location != null) {
        print('Got location from IP API: ${location.district}');
        return location;
      }
      
      location = await _tryIpInfoService();
      if (location != null) {
        print('Got location from IP Info: ${location.district}');
        return location;
      }
      
      location = await _tryIpifyService();
      if (location != null) {
        print('Got location from IPify: ${location.district}');
        return location;
      }
      
      print('All IP location services failed');
      return null;
    } catch (e) {
      print('IP location error: $e');
      return null;
    }
  }
  
  /// Try IP-API service (free, no API key required)
  Future<LocationModel?> _tryIpApiService() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
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
      print('IP-API service error: $e');
    }
    return null;
  }
  
  /// Try ipinfo.io service (free tier available)
  Future<LocationModel?> _tryIpInfoService() async {
    try {
      final response = await http.get(
        Uri.parse('https://ipinfo.io/json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
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
          
          return LocationModel(
            address: data['city'] ?? '未知',
            country: data['country'] ?? '中国',
            province: data['region'] ?? '未知',
            city: data['city'] ?? '未知',
            district: data['city'] ?? '未知',
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
      final ipResponse = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (ipResponse.statusCode == 200) {
        final ipData = json.decode(ipResponse.body);
        final ip = ipData['ip'];
        
        if (ip != null) {
          // Then get location by IP (using a free geolocation service)
          final locationResponse = await http.get(
            Uri.parse('http://ip-api.com/json/$ip'),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          
          if (locationResponse.statusCode == 200) {
            final data = json.decode(locationResponse.body);
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
        }
      }
    } catch (e) {
      print('IPify service error: $e');
    }
    return null;
  }
}
