import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/city_model.dart';
import '../models/sun_moon_index_model.dart';
import '../models/commute_advice_model.dart';
import '../constants/app_constants.dart';
import '../utils/city_name_matcher.dart';

class DatabaseService {
  static DatabaseService? _instance;
  Database? _database;

  DatabaseService._();

  static DatabaseService getInstance() {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Initialize database
  Future<void> initDatabase() async {
    if (_database != null) return;

    try {
      String path = join(await getDatabasesPath(), 'weather.db');
      _database = await openDatabase(
        path,
        version: 6,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE weather_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              key TEXT UNIQUE NOT NULL,
              data TEXT NOT NULL,
              type TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              expires_at INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE location_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              key TEXT UNIQUE NOT NULL,
              data TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE cities (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              isMainCity INTEGER NOT NULL DEFAULT 0,
              createdAt INTEGER NOT NULL,
              sortOrder INTEGER NOT NULL DEFAULT 9999
            )
          ''');

          await db.execute('''
            CREATE TABLE city_search (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              createdAt INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE commute_advices (
              id TEXT PRIMARY KEY,
              timestamp TEXT NOT NULL,
              adviceType TEXT NOT NULL,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              icon TEXT NOT NULL,
              isRead INTEGER NOT NULL DEFAULT 0,
              timeSlot TEXT NOT NULL,
              level TEXT NOT NULL DEFAULT 'normal',
              createdAt INTEGER NOT NULL
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // 添加cities表
            await db.execute('''
              CREATE TABLE cities (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                isMainCity INTEGER NOT NULL DEFAULT 0,
                createdAt INTEGER NOT NULL
              )
            ''');
            print('Database upgraded to version 2: Added cities table');
          }
          if (oldVersion < 3) {
            // 添加city_search表
            await db.execute('''
              CREATE TABLE city_search (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                createdAt INTEGER NOT NULL
              )
            ''');
            print('Database upgraded to version 3: Added city_search table');
          }
          if (oldVersion < 4) {
            // 添加sortOrder字段到cities表
            await db.execute('''
              ALTER TABLE cities ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 9999
            ''');
            print(
              'Database upgraded to version 4: Added sortOrder column to cities table',
            );
          }
          if (oldVersion < 5) {
            // 添加commute_advices表
            await db.execute('''
              CREATE TABLE commute_advices (
                id TEXT PRIMARY KEY,
                timestamp TEXT NOT NULL,
                adviceType TEXT NOT NULL,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                icon TEXT NOT NULL,
                isRead INTEGER NOT NULL DEFAULT 0,
                timeSlot TEXT NOT NULL,
                createdAt INTEGER NOT NULL
              )
            ''');
            print(
              'Database upgraded to version 5: Added commute_advices table',
            );
          }
          if (oldVersion < 6) {
            // 添加level字段到commute_advices表
            await db.execute('''
              ALTER TABLE commute_advices ADD COLUMN level TEXT NOT NULL DEFAULT 'normal'
            ''');
            print(
              'Database upgraded to version 6: Added level column to commute_advices table',
            );
          }
        },
      );
    } catch (e) {
      print('Database initialization failed: $e');
      // Continue without database for web platform
    }
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database == null) {
      await initDatabase();
    }
    return _database!;
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete('weather_cache');
      print('All cached data cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear all cities from database
  Future<void> clearAllCities() async {
    try {
      final db = await database;
      await db.delete('cities');
      print('All cities cleared from database');
    } catch (e) {
      print('Error clearing cities: $e');
    }
  }

  /// Clear only weather data, preserve cities and location
  Future<void> clearWeatherData() async {
    try {
      final db = await database;

      // 只删除天气相关的数据，保留城市和位置数据
      await db.delete(
        'weather_cache',
        where:
            'key LIKE ? OR key LIKE ? OR key LIKE ? OR key LIKE ? OR key LIKE ?',
        whereArgs: [
          '%:${AppConstants.weatherAllKey}', // 天气数据
          '%:${AppConstants.hourlyForecastKey}', // 小时预报
          '%:${AppConstants.dailyForecastKey}', // 日预报
          '%:${AppConstants.sunMoonIndexKey}', // 日出日落和生活指数
          '${AppConstants.currentLocationKey}:${AppConstants.weatherAllKey}', // 当前位置天气
        ],
      );

      print('Weather data cleared successfully, cities preserved');
    } catch (e) {
      print('Error clearing weather data: $e');
    }
  }

  /// Store string data
  Future<void> putString(String key, String value) async {
    final db = await database;
    await db.insert('weather_cache', {
      'key': key,
      'data': value,
      'type': 'String',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(AppConstants.cacheExpiration)
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get string data
  Future<String?> getString(String key) async {
    final db = await database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      return result.first['data'] as String?;
    }
    return null;
  }

  /// Store boolean data
  Future<void> putBoolean(String key, bool value) async {
    await putString(key, value.toString());
  }

  /// Get boolean data
  Future<bool> getBoolean(String key, bool defaultValue) async {
    final value = await getString(key);
    if (value != null) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  /// Store integer data
  Future<void> putInt(String key, int value) async {
    await putString(key, value.toString());
  }

  /// Get integer data
  Future<int> getInt(String key, int defaultValue) async {
    final value = await getString(key);
    if (value != null) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Store weather data
  Future<void> putWeatherData(String key, WeatherModel weatherData) async {
    final db = await database;
    await db.insert('weather_cache', {
      'key': key,
      'data': jsonEncode(weatherData.toJson()),
      'type': 'WeatherModel',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(AppConstants.cacheExpiration)
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get weather data
  Future<WeatherModel?> getWeatherData(String key) async {
    final db = await database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      final data = result.first['data'] as String;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return WeatherModel.fromJson(json);
      } catch (e) {
        print('Error parsing weather data: $e');
      }
    }
    return null;
  }

  /// Store sun/moon index data
  Future<void> putSunMoonIndexData(
    String key,
    SunMoonIndexData sunMoonIndexData,
  ) async {
    final db = await database;
    await db.insert('weather_cache', {
      'key': key,
      'data': jsonEncode(sunMoonIndexData.toJson()),
      'type': 'SunMoonIndexData',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(AppConstants.sunMoonIndexCacheExpiration)
          .millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get sun/moon index data
  Future<SunMoonIndexData?> getSunMoonIndexData(String key) async {
    final db = await database;
    final result = await db.query(
      'weather_cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, DateTime.now().millisecondsSinceEpoch],
    );

    if (result.isNotEmpty) {
      final data = result.first['data'] as String;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return SunMoonIndexData.fromJson(json);
      } catch (e) {
        print('Error parsing sun/moon index data: $e');
      }
    }
    return null;
  }

  /// Store location data
  Future<void> putLocationData(String key, LocationModel locationData) async {
    final db = await database;
    await db.insert('location_cache', {
      'key': key,
      'data': jsonEncode(locationData.toJson()),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get location data
  Future<LocationModel?> getLocationData(String key) async {
    final db = await database;
    final result = await db.query(
      'location_cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      final data = result.first['data'] as String;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return LocationModel.fromJson(json);
      } catch (e) {
        print('Error parsing location data: $e');
      }
    }
    return null;
  }

  /// Delete expired data
  Future<int> cleanExpiredData() async {
    final db = await database;
    return await db.delete(
      'weather_cache',
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('weather_cache');
    await db.delete('location_cache');
    await db.delete('cities');
  }

  // ========== City Management Methods ==========

  /// Ensure cities table exists
  Future<void> _ensureCitiesTableExists() async {
    final db = await database;
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
    final db = await database;
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
    final db = await database;
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
    final db = await database;
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
    final db = await database;
    try {
      await _ensureCitiesTableExists();

      // Get all manually added main cities from database
      final List<Map<String, dynamic>> maps = await db.query(
        'cities',
        where: 'isMainCity = ?',
        whereArgs: [1],
        orderBy: 'sortOrder ASC, createdAt ASC',
      );

      List<CityModel> cities = maps
          .map((map) => CityModel.fromMap(map))
          .toList();

      // If we have a current location, handle it dynamically
      print('🔍 Database: Processing current location: $currentLocationName');
      print('🔍 Database: Cities before processing: ${cities.length}');

      // 检查是否存在与非虚拟城市同名的虚拟城市
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

      // 先移除可能存在的虚拟城市，确保只有一个
      cities.removeWhere((city) => city.id == 'virtual_current_location');

      if (currentLocationName != null && !hasNameConflict) {
        // Check if current location is already in the main cities list
        final currentLocationIndex = cities.indexWhere(
          (city) =>
              CityNameMatcher.isCityNameMatch(city.name, currentLocationName),
        );

        if (currentLocationIndex >= 0) {
          // Current location was manually added by user, move it to the front
          final currentLocation = cities.removeAt(currentLocationIndex);
          cities.insert(0, currentLocation);
          print(
            'Current location "$currentLocationName" moved to front (was manually added)',
          );
        } else {
          // Current location is NOT in main cities list, find it from all cities and add dynamically
          CityModel? currentLocationCity = await getCityByName(
            currentLocationName,
          );

          // 如果找不到精确匹配，尝试查找相关城市
          if (currentLocationCity == null) {
            print(
              'Exact match not found for "$currentLocationName", trying fuzzy search...',
            );

            // 尝试查找包含该名称的城市
            final db = await database;

            // 先尝试完全匹配
            List<Map<String, dynamic>> maps = await db.query(
              'cities',
              where: 'name = ?',
              whereArgs: [currentLocationName],
              limit: 5,
            );

            // 如果完全匹配失败，再尝试标准化匹配
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
              // 选择第一个匹配的城市
              currentLocationCity = CityModel.fromMap(maps.first);
              print('Found fuzzy match: ${currentLocationCity.name}');
            }
          }

          if (currentLocationCity != null) {
            // Create a dynamic city object (not marked as main city in database)
            final dynamicCurrentLocation = currentLocationCity.copyWith(
              isMainCity: false, // Mark as NOT a main city in database
              sortOrder: -1, // Special sort order to indicate dynamic position
            );
            cities.insert(0, dynamicCurrentLocation);
            print(
              'Current location "${currentLocationCity.name}" added dynamically (not saved to database)',
            );
          } else {
            // 如果找不到匹配的城市，创建一个虚拟的当前城市
            print(
              'Creating virtual current location city for "$currentLocationName"',
            );
            final virtualCurrentLocation = CityModel(
              id: 'virtual_current_location', // 使用固定ID确保唯一性
              name: currentLocationName,
              isMainCity: false,
              sortOrder: -1,
              createdAt: DateTime.now(),
            );
            cities.insert(0, virtualCurrentLocation);
            print(
              'Virtual current location "$currentLocationName" added to list',
            );
            print(
              '🔍 Database: Cities after adding virtual city: ${cities.length}',
            );
            print(
              '🔍 Database: First city: ${cities.isNotEmpty ? cities.first.name : "None"}',
            );
          }
        }
      }

      // 去重：确保没有重复的城市，特别是虚拟城市
      final uniqueCities = <String, CityModel>{};
      bool hasVirtualCity = false;
      final Set<String> existingNames = <String>{};

      // 第一遍：收集所有非虚拟城市的名称
      for (final city in cities) {
        if (city.id != 'virtual_current_location') {
          existingNames.add(city.name);
        }
      }

      // 第二遍：处理城市去重
      for (final city in cities) {
        final key = '${city.id}_${city.name}';

        // 特殊处理虚拟城市：只允许一个，且不与现有城市名称冲突
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
          // 普通城市去重
          if (!uniqueCities.containsKey(key)) {
            uniqueCities[key] = city;
          } else {
            print('🔍 Database: 发现重复城市，已移除: ${city.name} (${city.id})');
          }
        }
      }

      final finalCities = uniqueCities.values.toList();

      // 确保虚拟城市在列表开头
      if (hasVirtualCity) {
        finalCities.sort((a, b) {
          if (a.id == 'virtual_current_location') return -1;
          if (b.id == 'virtual_current_location') return 1;
          return 0;
        });
      }

      print('🔍 Database: Cities after deduplication: ${finalCities.length}');
      print(
        '🔍 Database: Virtual city count: ${finalCities.where((c) => c.id == 'virtual_current_location').length}',
      );
      return finalCities;
    } catch (e) {
      print('Failed to get main cities with current location first: $e');
      return [];
    }
  }

  /// Check if current location city is already in main cities list
  /// 检查当前定位城市是否已在主城市列表中
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
  /// 先尝试完全匹配，再尝试标准化匹配
  Future<CityModel?> getCityByName(String name) async {
    final db = await database;
    try {
      // 先尝试完全匹配
      List<Map<String, dynamic>> maps = await db.query(
        'cities',
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return CityModel.fromMap(maps.first);
      }

      // 完全匹配失败，尝试标准化匹配
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
    final db = await database;
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
    final db = await database;
    try {
      await db.delete('cities', where: 'id = ?', whereArgs: [cityId]);
      print('City deleted: $cityId');
    } catch (e) {
      print('Failed to delete city: $e');
    }
  }

  /// Delete city by name
  Future<void> deleteCityByName(String name) async {
    final db = await database;
    try {
      await db.delete('cities', where: 'name = ?', whereArgs: [name]);
      print('City deleted: $name');
    } catch (e) {
      print('Failed to delete city: $e');
    }
  }

  /// Delete weather data by key
  Future<void> deleteWeatherData(String key) async {
    final db = await database;
    try {
      await db.delete('weather_cache', where: 'key = ?', whereArgs: [key]);
      print('Weather data deleted: $key');
    } catch (e) {
      print('Failed to delete weather data: $e');
    }
  }

  /// Delete location data by key
  Future<void> deleteLocationData(String key) async {
    final db = await database;
    try {
      await db.delete('location_cache', where: 'key = ?', whereArgs: [key]);
      print('Location data deleted: $key');
    } catch (e) {
      print('Failed to delete location data: $e');
    }
  }

  /// Update city main status
  Future<void> updateCityMainStatus(String cityId, bool isMainCity) async {
    final db = await database;
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
    final db = await database;
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
    final db = await database;
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
    final db = await database;
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
    final db = await database;
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
    final db = await database;
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
    final db = await database;
    try {
      // Check if search data already exists
      final existingCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM city_search',
      );
      if (existingCount.first['count'] as int > 0) {
        print('City search data already initialized');
        return;
      }

      // Load cities from city.json file
      final String jsonString = await rootBundle.loadString(
        'assets/data/city.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      // Save all cities to search table
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
    final db = await database;
    try {
      await db.delete('city_search');
      print('City search data cleared');
    } catch (e) {
      print('Failed to clear city search data: $e');
    }
  }

  /// Remove duplicate cities with the same name
  Future<void> removeDuplicateCities() async {
    final db = await database;
    try {
      // Find duplicate cities by name
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
          // Get all cities with this name, ordered by creation time
          final cities = await db.query(
            'cities',
            where: 'name = ? AND isMainCity = ?',
            whereArgs: [cityName, 1],
            orderBy: 'createdAt ASC',
          );

          // Keep the first one, delete the rest
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

  // ==================== 通勤建议相关方法 ====================

  /// 保存通勤建议
  Future<void> saveCommuteAdvice(CommuteAdviceModel advice) async {
    final db = await database;
    try {
      await db.insert(
        'commute_advices',
        advice.toMap()..['createdAt'] = DateTime.now().millisecondsSinceEpoch,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ 通勤建议已保存: ${advice.title}');
    } catch (e) {
      print('❌ 保存通勤建议失败: $e');
    }
  }

  /// 批量保存通勤建议
  Future<void> saveCommuteAdvices(List<CommuteAdviceModel> advices) async {
    final db = await database;
    final batch = db.batch();

    try {
      for (var advice in advices) {
        batch.insert(
          'commute_advices',
          advice.toMap()..['createdAt'] = DateTime.now().millisecondsSinceEpoch,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      print('✅ 批量保存通勤建议成功: ${advices.length}条');
    } catch (e) {
      print('❌ 批量保存通勤建议失败: $e');
    }
  }

  /// 获取所有通勤建议
  Future<List<CommuteAdviceModel>> getAllCommuteAdvices() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'commute_advices',
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => CommuteAdviceModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ 获取通勤建议失败: $e');
      return [];
    }
  }

  /// 获取未读的通勤建议
  Future<List<CommuteAdviceModel>> getUnreadCommuteAdvices() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'commute_advices',
        where: 'isRead = ?',
        whereArgs: [0],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => CommuteAdviceModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ 获取未读通勤建议失败: $e');
      return [];
    }
  }

  /// 获取今日的通勤建议
  Future<List<CommuteAdviceModel>> getTodayCommuteAdvices() async {
    final db = await database;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startTimestamp = startOfDay.millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'commute_advices',
        where: 'createdAt >= ?',
        whereArgs: [startTimestamp],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => CommuteAdviceModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ 获取今日通勤建议失败: $e');
      return [];
    }
  }

  /// 标记建议为已读
  Future<void> markCommuteAdviceAsRead(String adviceId) async {
    final db = await database;
    try {
      await db.update(
        'commute_advices',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [adviceId],
      );
      print('✅ 通勤建议已标记为已读: $adviceId');
    } catch (e) {
      print('❌ 标记通勤建议失败: $e');
    }
  }

  /// 批量标记建议为已读
  Future<void> markAllCommuteAdvicesAsRead() async {
    final db = await database;
    try {
      await db.update(
        'commute_advices',
        {'isRead': 1},
        where: 'isRead = ?',
        whereArgs: [0],
      );
      print('✅ 所有通勤建议已标记为已读');
    } catch (e) {
      print('❌ 批量标记通勤建议失败: $e');
    }
  }

  /// 删除指定的通勤建议
  Future<void> deleteCommuteAdvice(String adviceId) async {
    final db = await database;
    try {
      await db.delete(
        'commute_advices',
        where: 'id = ?',
        whereArgs: [adviceId],
      );
      print('✅ 通勤建议已删除: $adviceId');
    } catch (e) {
      print('❌ 删除通勤建议失败: $e');
    }
  }

  /// 清理过期的通勤建议（保留15天内的）
  Future<int> cleanExpiredCommuteAdvices() async {
    final db = await database;
    try {
      final now = DateTime.now();
      final fifteenDaysAgo = now.subtract(const Duration(days: 15));
      final timestamp = fifteenDaysAgo.millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        'commute_advices',
        where: 'createdAt < ?',
        whereArgs: [timestamp],
      );

      if (deletedCount > 0) {
        print('✅ 清理过期通勤建议: $deletedCount条');
      }
      return deletedCount;
    } catch (e) {
      print('❌ 清理过期通勤建议失败: $e');
      return 0;
    }
  }

  /// 清理当前时段结束的通勤建议
  Future<int> cleanEndedTimeSlotAdvices(String timeSlot) async {
    final db = await database;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startTimestamp = today.millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        'commute_advices',
        where: 'timeSlot = ? AND createdAt >= ?',
        whereArgs: [timeSlot, startTimestamp],
      );

      if (deletedCount > 0) {
        print('✅ 清理$timeSlot时段的通勤建议: $deletedCount条');
      }
      return deletedCount;
    } catch (e) {
      print('❌ 清理时段通勤建议失败: $e');
      return 0;
    }
  }

  /// 清理重复的通勤建议（保留每种类型+时段的最新一条）
  Future<int> cleanDuplicateCommuteAdvices() async {
    final db = await database;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startTimestamp = today.millisecondsSinceEpoch;

      // 获取今日所有建议
      final List<Map<String, dynamic>> allAdvices = await db.query(
        'commute_advices',
        where: 'createdAt >= ?',
        whereArgs: [startTimestamp],
        orderBy: 'createdAt DESC',
      );

      if (allAdvices.isEmpty) return 0;

      // 按 adviceType + timeSlot 分组
      final Map<String, List<String>> typeGroups = {};
      for (var advice in allAdvices) {
        final key = '${advice['adviceType']}_${advice['timeSlot']}';
        typeGroups.putIfAbsent(key, () => []);
        typeGroups[key]!.add(advice['id'] as String);
      }

      // 删除每组中除了第一条（最新）之外的所有记录
      int deletedCount = 0;
      for (var group in typeGroups.values) {
        if (group.length > 1) {
          // 保留第一条，删除其余
          for (int i = 1; i < group.length; i++) {
            await db.delete(
              'commute_advices',
              where: 'id = ?',
              whereArgs: [group[i]],
            );
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        print('✅ 清理重复通勤建议: $deletedCount条');
      }
      return deletedCount;
    } catch (e) {
      print('❌ 清理重复通勤建议失败: $e');
      return 0;
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
