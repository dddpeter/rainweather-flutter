import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/city_model.dart';
import '../../utils/city_name_matcher.dart';
import 'database_core.dart';

/// CityService - 城市管理服务
///
/// 职责：
/// - 城市CRUD操作
/// - 主城市管理
/// - 城市排序
/// - 城市搜索
/// - 城市去重
class CityService {
  final DatabaseCore _core;

  CityService(this._core);

  /// Ensure cities table exists
  Future<void> _ensureCitiesTableExists() async {
    final db = await _core.database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cities (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          isMainCity INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL
        )
      ''');
    } catch (e) {
      print('Failed to ensure cities table exists: $e');
    }
  }

  /// Save a city to database
  Future<void> saveCity(CityModel city) async {
    final db = await _core.database;
    try {
      await _ensureCitiesTableExists();
      await db.insert(
        'cities',
        city.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('City saved: ${city.name}');
    } catch (e) {
      print('Failed to save city: $e');
    }
  }

  /// Get all cities from database
  Future<List<CityModel>> getAllCities() async {
    final db = await _core.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'cities',
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => CityModel.fromMap(map)).toList();
    } catch (e) {
      print('Failed to get cities: $e');
      return [];
    }
  }

  /// Get main cities from database
  Future<List<CityModel>> getMainCities() async {
    final db = await _core.database;
    try {
      await _ensureCitiesTableExists();
      final List<Map<String, dynamic>> maps = await db.query(
        'cities',
        where: 'isMainCity = ?',
        whereArgs: [1],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => CityModel.fromMap(map)).toList();
    } catch (e) {
      print('Failed to get main cities: $e');
      return [];
    }
  }

  /// Get main cities with current location first
  Future<List<CityModel>> getMainCitiesWithCurrentLocationFirst(
    String? currentLocationName,
  ) async {
    final db = await _core.database;
    try {
      await _ensureCitiesTableExists();

      final List<Map<String, dynamic>> maps = await db.query(
        'cities',
        where: 'isMainCity = ?',
        whereArgs: [1],
        orderBy: 'sortOrder ASC, createdAt ASC',
      );

      List<CityModel> cities = maps
          .map((map) => CityModel.fromMap(map))
          .toList();

      print('🔍 Database: Processing current location: $currentLocationName');
      print('🔍 Database: Cities before processing: ${cities.length}');

      bool hasNameConflict = false;
      if (currentLocationName != null && currentLocationName.isNotEmpty) {
        hasNameConflict = cities.any(
          (city) =>
              CityNameMatcher.isCityNameMatch(city.name, currentLocationName) &&
              city.id != 'virtual_current_location',
        );

        if (hasNameConflict) {
          print('🔍 Database: 发现名称冲突，跳过虚拟城市创建: $currentLocationName');
        }
      }

      cities.removeWhere((city) => city.id == 'virtual_current_location');

      if (currentLocationName != null && !hasNameConflict) {
        final currentLocationIndex = cities.indexWhere(
          (city) =>
              CityNameMatcher.isCityNameMatch(city.name, currentLocationName),
        );

        if (currentLocationIndex >= 0) {
          final currentLocation = cities.removeAt(currentLocationIndex);
          cities.insert(0, currentLocation);
          print(
            'Current location "$currentLocationName" moved to front (was manually added)',
          );
        } else {
          CityModel? currentLocationCity = await getCityByName(
            currentLocationName,
          );

          if (currentLocationCity == null) {
            print(
              'Exact match not found for "$currentLocationName", trying fuzzy search...',
            );

            List<Map<String, dynamic>> maps = await db.query(
              'cities',
              where: 'name = ?',
              whereArgs: [currentLocationName],
              limit: 5,
            );

            if (maps.isEmpty) {
              final normalizedName = CityNameMatcher.normalizeCityName(
                currentLocationName,
              );

              maps = await db.query(
                'cities',
                where: 'name LIKE ? OR name LIKE ?',
                whereArgs: ['%$currentLocationName%', '%$normalizedName%'],
                limit: 5,
              );
            }

            if (maps.isNotEmpty) {
              currentLocationCity = CityModel.fromMap(maps.first);
              print('Found fuzzy match: ${currentLocationCity.name}');
            }
          }

          if (currentLocationCity != null) {
            final dynamicCurrentLocation = currentLocationCity.copyWith(
              isMainCity: false,
              sortOrder: -1,
            );
            cities.insert(0, dynamicCurrentLocation);
            print(
              'Current location "${currentLocationCity.name}" added dynamically',
            );
          } else {
            print(
              'Creating virtual current location city for "$currentLocationName"',
            );
            final virtualCurrentLocation = CityModel(
              id: 'virtual_current_location',
              name: currentLocationName,
              isMainCity: false,
              sortOrder: -1,
              createdAt: DateTime.now(),
            );
            cities.insert(0, virtualCurrentLocation);
            print(
              'Virtual current location "$currentLocationName" added to list',
            );
          }
        }
      }

      final uniqueCities = <String, CityModel>{};
      bool hasVirtualCity = false;
      final Set<String> existingNames = <String>{};

      for (final city in cities) {
        if (city.id != 'virtual_current_location') {
          existingNames.add(city.name);
        }
      }

      for (final city in cities) {
        final key = '${city.id}_${city.name}';

        if (city.id == 'virtual_current_location') {
          if (!hasVirtualCity && !existingNames.contains(city.name)) {
            uniqueCities[key] = city;
            hasVirtualCity = true;
            print('🔍 Database: 保留虚拟城市: ${city.name}');
          } else if (existingNames.contains(city.name)) {
            print('🔍 Database: 移除虚拟城市（名称冲突）: ${city.name}');
          } else {
            print('🔍 Database: 移除重复的虚拟城市: ${city.name}');
          }
        } else {
          if (!uniqueCities.containsKey(key)) {
            uniqueCities[key] = city;
          } else {
            print('🔍 Database: 发现重复城市，已移除: ${city.name} (${city.id})');
          }
        }
      }

      final finalCities = uniqueCities.values.toList();

      if (hasVirtualCity) {
        finalCities.sort((a, b) {
          if (a.id == 'virtual_current_location') return -1;
          if (b.id == 'virtual_current_location') return 1;
          return 0;
        });
      }

      print('🔍 Database: Cities after deduplication: ${finalCities.length}');
      return finalCities;
    } catch (e) {
      print('Failed to get main cities with current location first: $e');
      return [];
    }
  }

  /// Check if current location city is already in main cities list
  Future<bool> isCurrentLocationInMainCities(
    String? currentLocationName,
  ) async {
    if (currentLocationName == null || currentLocationName.isEmpty) {
      return false;
    }

    try {
      final cities = await getAllCities();
      return cities.any(
        (city) =>
            CityNameMatcher.isCityNameMatch(city.name, currentLocationName) &&
            city.id != 'virtual_current_location',
      );
    } catch (e) {
      print('Error checking if current location is in main cities: $e');
      return false;
    }
  }

  /// Get city by name
  Future<CityModel?> getCityByName(String name) async {
    final db = await _core.database;
    try {
      List<Map<String, dynamic>> maps = await db.query(
        'cities',
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return CityModel.fromMap(maps.first);
      }

      final normalizedName = CityNameMatcher.normalizeCityName(name);
      maps = await db.query(
        'cities',
        where: 'name = ?',
        whereArgs: [normalizedName],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return CityModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('Failed to get city by name: $e');
      return null;
    }
  }

  /// Get city by ID
  Future<CityModel?> getCityById(String id) async {
    final db = await _core.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'cities',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return CityModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Failed to get city by ID: $e');
      return null;
    }
  }

  /// Delete a city from database
  Future<void> deleteCity(String cityId) async {
    final db = await _core.database;
    try {
      await db.delete('cities', where: 'id = ?', whereArgs: [cityId]);
      print('City deleted: $cityId');
    } catch (e) {
      print('Failed to delete city: $e');
    }
  }

  /// Delete city by name
  Future<void> deleteCityByName(String name) async {
    final db = await _core.database;
    try {
      await db.delete('cities', where: 'name = ?', whereArgs: [name]);
      print('City deleted: $name');
    } catch (e) {
      print('Failed to delete city: $e');
    }
  }

  /// Update city main status
  Future<void> updateCityMainStatus(String cityId, bool isMainCity) async {
    final db = await _core.database;
    try {
      await db.update(
        'cities',
        {'isMainCity': isMainCity ? 1 : 0},
        where: 'id = ?',
        whereArgs: [cityId],
      );
      print('City main status updated: $cityId -> $isMainCity');
    } catch (e) {
      print('Failed to update city main status: $e');
    }
  }

  /// Update city sort order
  Future<void> updateCitySortOrder(String cityId, int sortOrder) async {
    final db = await _core.database;
    try {
      await db.update(
        'cities',
        {'sortOrder': sortOrder},
        where: 'id = ?',
        whereArgs: [cityId],
      );
      print('City sort order updated: $cityId -> $sortOrder');
    } catch (e) {
      print('Failed to update city sort order: $e');
    }
  }

  /// Update multiple cities sort order
  Future<void> updateCitiesSortOrder(
    List<Map<String, dynamic>> citySortOrders,
  ) async {
    final db = await _core.database;
    try {
      await db.transaction((txn) async {
        for (final citySort in citySortOrders) {
          await txn.update(
            'cities',
            {'sortOrder': citySort['sortOrder']},
            where: 'id = ?',
            whereArgs: [citySort['cityId']],
          );
        }
      });
      print('Cities sort order updated: ${citySortOrders.length} cities');
    } catch (e) {
      print('Failed to update cities sort order: $e');
    }
  }

  /// Check if cities table is initialized
  Future<bool> isCitiesTableInitialized() async {
    final db = await _core.database;
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'cities',
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Failed to check cities table: $e');
      return false;
    }
  }

  /// Save city to search table
  Future<void> saveCityToSearch(String id, String name) async {
    final db = await _core.database;
    try {
      await db.insert('city_search', {
        'id': id,
        'name': name,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Failed to save city to search: $e');
    }
  }

  /// Search cities by name from search table
  Future<List<Map<String, dynamic>>> searchCitiesFromDatabase(
    String query,
  ) async {
    final db = await _core.database;
    try {
      await _ensureCitiesTableExists();
      final List<Map<String, dynamic>> maps = await db.query(
        'city_search',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
        limit: 50,
      );
      return maps;
    } catch (e) {
      print('Failed to search cities from database: $e');
      return [];
    }
  }

  /// Initialize city search data from JSON
  Future<void> initializeCitySearchData() async {
    final db = await _core.database;
    try {
      final existingCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM city_search',
      );
      if (existingCount.first['count'] as int > 0) {
        print('City search data already initialized');
        return;
      }

      final String jsonString = await rootBundle.loadString(
        'assets/data/city.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      int savedCount = 0;
      for (final json in jsonList) {
        final Map<String, dynamic> cityJson = json as Map<String, dynamic>;
        await saveCityToSearch(
          cityJson['id'] as String,
          cityJson['name'] as String,
        );
        savedCount++;
      }

      print('Initialized $savedCount cities to search table');
    } catch (e) {
      print('Failed to initialize city search data: $e');
    }
  }

  /// Clear city search data
  Future<void> clearCitySearchData() async {
    final db = await _core.database;
    try {
      await db.delete('city_search');
      print('City search data cleared');
    } catch (e) {
      print('Failed to clear city search data: $e');
    }
  }

  /// Remove duplicate cities with the same name
  Future<void> removeDuplicateCities() async {
    final db = await _core.database;
    try {
      final duplicates = await db.rawQuery('''
        SELECT name, COUNT(*) as count
        FROM cities
        WHERE isMainCity = 1
        GROUP BY name
        HAVING COUNT(*) > 1
      ''');

      for (final duplicate in duplicates) {
        final cityName = duplicate['name'] as String;
        final count = duplicate['count'] as int;

        if (count > 1) {
          final cities = await db.query(
            'cities',
            where: 'name = ? AND isMainCity = ?',
            whereArgs: [cityName, 1],
            orderBy: 'createdAt ASC',
          );

          for (int i = 1; i < cities.length; i++) {
            await db.delete(
              'cities',
              where: 'id = ?',
              whereArgs: [cities[i]['id']],
            );
            print('Removed duplicate city: ${cityName} (${cities[i]['id']})');
          }
        }
      }
    } catch (e) {
      print('Failed to remove duplicate cities: $e');
    }
  }

  /// Clear all cities from database
  Future<void> clearAllCities() async {
    try {
      final db = await _core.database;
      await db.delete('cities');
      print('All cities cleared from database');
    } catch (e) {
      print('Error clearing cities: $e');
    }
  }
}
