import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city_model.dart';
import '../services/database_service.dart';
import '../constants/app_constants.dart';

class CityService {
  static CityService? _instance;
  final DatabaseService _databaseService;

  CityService._(this._databaseService);

  static CityService getInstance() {
    _instance ??= CityService._(DatabaseService.getInstance());
    return _instance!;
  }

  /// Initialize cities from JSON file
  /// [forceReload] - if true, will clear existing cities and reload from JSON
  Future<void> initializeCitiesFromJson({bool forceReload = false}) async {
    try {
      print('Starting cities initialization from JSON...');

      // Check if this is the first time the app is launched
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('cities_initialized') != true;

      // Check if cities are already initialized
      final existingCities = await _databaseService.getAllCities();
      print('Existing cities count: ${existingCities.length}');
      print('Is first launch: $isFirstLaunch');

      // Determine if we should reload cities
      final shouldReload =
          forceReload || isFirstLaunch || existingCities.isEmpty;

      if (existingCities.isNotEmpty && !shouldReload) {
        print('Cities already initialized, skipping...');
        return;
      }

      // If reload is needed, clear existing cities first
      if (shouldReload && existingCities.isNotEmpty) {
        print('Reload requested, clearing existing cities...');
        await _databaseService.clearAllCities();
        print('Existing cities cleared');
      }

      // Load cities from city.json file
      final String jsonString = await rootBundle.loadString(
        'assets/data/city.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      // Convert to CityModel list
      final List<CityModel> cities = jsonList.map((json) {
        final Map<String, dynamic> cityJson = json as Map<String, dynamic>;
        return CityModel(
          id: cityJson['id'] as String,
          name: cityJson['name'] as String,
          isMainCity: AppConstants.mainCities.contains(cityJson['name']),
          createdAt: DateTime.now(),
        );
      }).toList();

      // Save all cities to database
      int savedCount = 0;
      for (final city in cities) {
        try {
          await _databaseService.saveCity(city);
          savedCount++;
        } catch (e) {
          print('Failed to save city ${city.name}: $e');
        }
      }

      print(
        'Initialized $savedCount cities from JSON (total: ${cities.length})',
      );

      // 从SharedPreferences恢复主要城市列表
      // SharedPreferences会通过Android Auto Backup自动云备份（如果用户开启了）
      await restoreMainCitiesFromPrefs();

      // Mark cities as initialized
      await prefs.setBool('cities_initialized', true);
      print('Cities initialization marked as completed');
    } catch (e) {
      print('Failed to initialize cities from JSON: $e');
    }
  }

  /// Force reload cities from JSON file
  /// This will clear existing cities and reload from city.json
  Future<void> forceReloadCitiesFromJson() async {
    print('Force reloading cities from JSON...');
    await initializeCitiesFromJson(forceReload: true);
  }

  /// Get all cities
  Future<List<CityModel>> getAllCities() async {
    return await _databaseService.getAllCities();
  }

  /// Get main cities
  Future<List<CityModel>> getMainCities() async {
    return await _databaseService.getMainCities();
  }

  /// Get main cities with current location first
  Future<List<CityModel>> getMainCitiesWithCurrentLocationFirst(
    String? currentLocationName,
  ) async {
    return await _databaseService.getMainCitiesWithCurrentLocationFirst(
      currentLocationName,
    );
  }

  /// Get city by name
  Future<CityModel?> getCityByName(String name) async {
    return await _databaseService.getCityByName(name);
  }

  /// Get city by ID
  Future<CityModel?> getCityById(String id) async {
    return await _databaseService.getCityById(id);
  }

  /// Add a city to main cities
  Future<bool> addMainCity(CityModel city) async {
    try {
      // Check if city exists in database
      CityModel? existingCity = await _databaseService.getCityById(city.id);

      if (existingCity != null) {
        // Update existing city to main city
        await _databaseService.updateCityMainStatus(city.id, true);
        print('Updated existing city to main city: ${city.name}');
      } else {
        // Add new city as main city
        final newCity = city.copyWith(isMainCity: true);
        await _databaseService.saveCity(newCity);
        print('Added new main city: ${city.name}');
      }

      // 备份主要城市列表到SharedPreferences
      // SharedPreferences会通过Android Auto Backup自动云备份
      await _backupMainCitiesToPrefs();

      return true;
    } catch (e) {
      print('Failed to add main city: $e');
      return false;
    }
  }

  /// Remove a city from main cities
  Future<bool> removeMainCity(String cityId) async {
    try {
      // Get city info
      final city = await _databaseService.getCityById(cityId);
      if (city == null) {
        print('City not found: $cityId');
        return false;
      }

      // Allow removing any city from main cities (including default ones)
      // Update city status to not main city
      await _databaseService.updateCityMainStatus(cityId, false);
      print('Removed city from main cities: ${city.name}');

      // 备份主要城市列表到SharedPreferences
      await _backupMainCitiesToPrefs();

      return true;
    } catch (e) {
      print('Failed to remove main city: $e');
      return false;
    }
  }

  /// Search cities by name
  Future<List<CityModel>> searchCities(String query) async {
    try {
      if (query.isEmpty) return [];

      // Initialize city search data if needed
      await _databaseService.initializeCitySearchData();

      // Search from database
      final searchResults = await _databaseService.searchCitiesFromDatabase(
        query,
      );

      // Convert to CityModel list
      final results = searchResults
          .map(
            (map) => CityModel(
              id: map['id'] as String,
              name: map['name'] as String,
              isMainCity:
                  false, // Search results are not main cities by default
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                map['createdAt'] as int,
              ),
            ),
          )
          .toList();

      // Sort results: exact matches first, then partial matches
      results.sort((a, b) {
        final aExact = a.name.toLowerCase() == query.toLowerCase();
        final bExact = b.name.toLowerCase() == query.toLowerCase();

        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        // If both are exact or both are partial, sort by name
        return a.name.compareTo(b.name);
      });

      return results;
    } catch (e) {
      print('Failed to search cities: $e');
      return [];
    }
  }

  /// Check if city is a main city
  Future<bool> isMainCity(String cityId) async {
    try {
      final city = await _databaseService.getCityById(cityId);
      return city?.isMainCity ?? false;
    } catch (e) {
      print('Failed to check main city status: $e');
      return false;
    }
  }

  /// Get main city names (for compatibility)
  Future<List<String>> getMainCityNames() async {
    try {
      final mainCities = await _databaseService.getMainCities();
      return mainCities.map((city) => city.name).toList();
    } catch (e) {
      print('Failed to get main city names: $e');
      return AppConstants.mainCities; // Fallback to constants
    }
  }

  /// Reset main cities to default
  Future<void> resetMainCitiesToDefault() async {
    try {
      // Clear all main city status
      final allCities = await _databaseService.getAllCities();
      for (final city in allCities) {
        await _databaseService.updateCityMainStatus(city.id, false);
      }

      // Set default main cities
      for (final cityName in AppConstants.mainCities) {
        final city = await _databaseService.getCityByName(cityName);
        if (city != null) {
          await _databaseService.updateCityMainStatus(city.id, true);
        }
      }

      print('Reset main cities to default');
    } catch (e) {
      print('Failed to reset main cities: $e');
    }
  }

  /// Clear all cities
  Future<void> clearAllCities() async {
    try {
      await _databaseService.clearAllCities();
      print('All cities cleared');
    } catch (e) {
      print('Failed to clear all cities: $e');
    }
  }

  /// Get cities count
  Future<int> getCitiesCount() async {
    try {
      final cities = await _databaseService.getAllCities();
      return cities.length;
    } catch (e) {
      print('Failed to get cities count: $e');
      return 0;
    }
  }

  /// Get main cities count
  Future<int> getMainCitiesCount() async {
    try {
      final mainCities = await _databaseService.getMainCities();
      return mainCities.length;
    } catch (e) {
      print('Failed to get main cities count: $e');
      return AppConstants.mainCities.length; // Fallback
    }
  }

  /// Check if cities are initialized
  Future<bool> isInitialized() async {
    try {
      return await _databaseService.isCitiesTableInitialized();
    } catch (e) {
      print('Failed to check initialization status: $e');
      return false;
    }
  }

  /// 备份主要城市列表到SharedPreferences
  /// SharedPreferences会通过Android Auto Backup功能自动云备份（需要用户开启）
  Future<void> _backupMainCitiesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mainCities = await _databaseService.getMainCities();

      // 只保存用户自定义的城市（排除当前定位城市）
      final userCities = mainCities
          .where(
            (city) =>
                !city.id.contains('virtual') &&
                city.id != 'virtual_current_location',
          )
          .toList();

      final mainCityIds = userCities.map((city) => city.id).toList();
      final mainCityNames = userCities.map((city) => city.name).toList();

      // 备份城市ID和名称（双重保险）
      await prefs.setStringList('main_city_ids', mainCityIds);
      await prefs.setStringList('main_city_names', mainCityNames);

      print('✅ 备份 ${mainCityIds.length} 个用户城市到SharedPreferences');
      print('   城市列表: ${mainCityNames.join(", ")}');
    } catch (e) {
      print('❌ 备份主要城市失败: $e');
    }
  }

  /// 从SharedPreferences恢复主要城市列表
  /// 支持Android Auto Backup云备份恢复
  Future<void> restoreMainCitiesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mainCityIds = prefs.getStringList('main_city_ids');
      final mainCityNames = prefs.getStringList('main_city_names');

      if ((mainCityIds == null || mainCityIds.isEmpty) &&
          (mainCityNames == null || mainCityNames.isEmpty)) {
        print('📦 没有找到城市备份数据');
        return;
      }

      print(
        '📦 找到城市备份: ${mainCityIds?.length ?? 0} 个ID, ${mainCityNames?.length ?? 0} 个名称',
      );

      // 恢复主要城市状态
      int restoredCount = 0;
      int notFoundCount = 0;

      // 优先使用城市ID恢复
      if (mainCityIds != null && mainCityIds.isNotEmpty) {
        for (int i = 0; i < mainCityIds.length; i++) {
          final cityId = mainCityIds[i];
          final cityName = (mainCityNames != null && i < mainCityNames.length)
              ? mainCityNames[i]
              : null;

          // 先尝试通过ID查找
          CityModel? city = await _databaseService.getCityById(cityId);

          // 如果ID查找失败，尝试通过名称查找
          if (city == null && cityName != null) {
            print('⚠️ 城市ID $cityId 未找到，尝试通过名称查找: $cityName');
            city = await _databaseService.getCityByName(cityName);
          }

          if (city != null) {
            await _databaseService.updateCityMainStatus(city.id, true);
            restoredCount++;
            print('✅ 恢复城市: ${city.name} (ID: ${city.id})');
          } else {
            notFoundCount++;
            print('❌ 无法恢复城市: ${cityName ?? cityId}');
          }
        }
      }

      print('📦 城市恢复完成: 成功 $restoredCount 个，失败 $notFoundCount 个');
    } catch (e) {
      print('❌ 恢复主要城市失败: $e');
    }
  }
}
