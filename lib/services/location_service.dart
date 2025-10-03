import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import 'geocoding_service.dart';

enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  error,
}

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
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        print('Location permission granted: $permission');
        return LocationPermissionResult.granted;
      }
      
      return LocationPermissionResult.denied;
    } catch (e) {
      print('Error requesting location permission: $e');
      return LocationPermissionResult.error;
    }
  }
  
  /// Get current location
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // Check permissions first
      LocationPermissionResult permissionResult = await requestLocationPermission();
      
      switch (permissionResult) {
        case LocationPermissionResult.denied:
          throw LocationException('定位权限被拒绝，请在设置中开启定位权限');
        case LocationPermissionResult.deniedForever:
          throw LocationException('定位权限被永久拒绝，请在设置中手动开启定位权限');
        case LocationPermissionResult.error:
          throw LocationException('定位权限检查失败，请重试');
        case LocationPermissionResult.granted:
          break;
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('定位服务未开启，请在设置中开启定位服务');
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Use reverse geocoding to get address information
      LocationModel? location = await _geocodingService.reverseGeocode(
        position.latitude, 
        position.longitude
      );
      
      // If reverse geocoding fails, use fallback method
      if (location == null) {
        location = await _geocodingService.fallbackReverseGeocode(
          position.latitude, 
          position.longitude
        );
      }
      
      // Cache the location
      _cachedLocation = location;
      
      return location;
    } catch (e) {
      print('Location error: $e');
      
      if (e is LocationException) {
        // Re-throw location exceptions with user-friendly messages
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
  
  /// Set cached location
  void setCachedLocation(LocationModel location) {
    _cachedLocation = location;
  }
  
  /// Cleanup resources
  void cleanup() {
    _cachedLocation = null;
  }
}
