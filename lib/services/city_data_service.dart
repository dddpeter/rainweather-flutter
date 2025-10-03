import 'dart:convert';
import 'package:flutter/services.dart';

class CityDataService {
  static CityDataService? _instance;
  List<CityInfo> _cities = [];
  
  CityDataService._();
  
  static CityDataService getInstance() {
    _instance ??= CityDataService._();
    return _instance!;
  }
  
  /// Load city data from assets
  Future<void> loadCityData() async {
    if (_cities.isNotEmpty) return; // Already loaded
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/city.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _cities = jsonList.map((json) => CityInfo.fromJson(json)).toList();
      print('Loaded ${_cities.length} cities');
    } catch (e) {
      print('Error loading city data: $e');
      _cities = [];
    }
  }
  
  /// Find city ID by name (supports partial matching)
  String? findCityIdByName(String cityName) {
    if (cityName.isEmpty) return null;
    
    // Direct match
    for (var city in _cities) {
      if (city.name == cityName) {
        return city.id;
      }
    }
    
    // Remove common suffixes and try again
    String cleanName = cityName
        .replaceAll('区', '')
        .replaceAll('县', '')
        .replaceAll('市', '')
        .replaceAll('省', '');
    
    for (var city in _cities) {
      if (city.name == cleanName) {
        return city.id;
      }
    }
    
    // Partial match (contains)
    for (var city in _cities) {
      if (city.name.contains(cityName) || cityName.contains(city.name)) {
        return city.id;
      }
    }
    
    // Partial match with clean name
    for (var city in _cities) {
      if (city.name.contains(cleanName) || cleanName.contains(city.name)) {
        return city.id;
      }
    }
    
    return null;
  }
  
  /// Find city name by ID
  String? findCityNameById(String cityId) {
    for (var city in _cities) {
      if (city.id == cityId) {
        return city.name;
      }
    }
    return null;
  }
  
  /// Get all cities
  List<CityInfo> getAllCities() {
    return List.from(_cities);
  }
  
  /// Search cities by keyword
  List<CityInfo> searchCities(String keyword) {
    if (keyword.isEmpty) return [];
    
    return _cities.where((city) => 
      city.name.toLowerCase().contains(keyword.toLowerCase())
    ).toList();
  }
}

class CityInfo {
  final String id;
  final String name;
  
  CityInfo({
    required this.id,
    required this.name,
  });
  
  factory CityInfo.fromJson(Map<String, dynamic> json) {
    return CityInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
  
  @override
  String toString() {
    return 'CityInfo(id: $id, name: $name)';
  }
}
