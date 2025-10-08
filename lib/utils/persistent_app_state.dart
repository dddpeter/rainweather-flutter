import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';

/// 应用状态快照
class AppStateSnapshot {
  final DateTime lastActive;
  final LocationModel? lastLocation;
  final DateTime? lastWeatherUpdate;
  final DateTime? lastLocationUpdate;
  final bool wasProperlyShutdown;

  AppStateSnapshot({
    required this.lastActive,
    this.lastLocation,
    this.lastWeatherUpdate,
    this.lastLocationUpdate,
    this.wasProperlyShutdown = true,
  });

  Map<String, dynamic> toJson() => {
    'lastActive': lastActive.toIso8601String(),
    'lastLocation': lastLocation?.toJson(),
    'lastWeatherUpdate': lastWeatherUpdate?.toIso8601String(),
    'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
    'wasProperlyShutdown': wasProperlyShutdown,
  };

  factory AppStateSnapshot.fromJson(Map<String, dynamic> json) {
    return AppStateSnapshot(
      lastActive: DateTime.parse(json['lastActive']),
      lastLocation: json['lastLocation'] != null
          ? LocationModel.fromJson(json['lastLocation'])
          : null,
      lastWeatherUpdate: json['lastWeatherUpdate'] != null
          ? DateTime.parse(json['lastWeatherUpdate'])
          : null,
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.parse(json['lastLocationUpdate'])
          : null,
      wasProperlyShutdown: json['wasProperlyShutdown'] ?? true,
    );
  }
}

/// 持久化应用状态管理器
class PersistentAppState {
  static const String _keyAppState = 'app_state_snapshot';
  static const String _keyLastActive = 'last_active_time';
  static const String _keyLastLocation = 'last_location';
  static const String _keyLastWeatherUpdate = 'last_weather_update';
  static const String _keyLastLocationUpdate = 'last_location_update';
  static const String _keyProperShutdown = 'was_properly_shutdown';

  static PersistentAppState? _instance;
  SharedPreferences? _prefs;

  PersistentAppState._();

  static Future<PersistentAppState> getInstance() async {
    if (_instance == null) {
      _instance = PersistentAppState._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存应用状态
  Future<void> saveState({
    DateTime? lastActive,
    LocationModel? location,
    DateTime? lastWeatherUpdate,
    DateTime? lastLocationUpdate,
    bool wasProperlyShutdown = true,
  }) async {
    try {
      final snapshot = AppStateSnapshot(
        lastActive: lastActive ?? DateTime.now(),
        lastLocation: location,
        lastWeatherUpdate: lastWeatherUpdate,
        lastLocationUpdate: lastLocationUpdate,
        wasProperlyShutdown: wasProperlyShutdown,
      );

      await _prefs?.setString(_keyAppState, jsonEncode(snapshot.toJson()));
      await _prefs?.setString(
        _keyLastActive,
        (lastActive ?? DateTime.now()).toIso8601String(),
      );
      await _prefs?.setBool(_keyProperShutdown, wasProperlyShutdown);

      print('💾 持久化应用状态已保存');
    } catch (e) {
      print('❌ 保存应用状态失败: $e');
    }
  }

  /// 加载应用状态
  Future<AppStateSnapshot?> loadState() async {
    try {
      final stateJson = _prefs?.getString(_keyAppState);
      if (stateJson == null) {
        print('📦 没有找到保存的应用状态');
        return null;
      }

      final snapshot = AppStateSnapshot.fromJson(
        jsonDecode(stateJson) as Map<String, dynamic>,
      );
      print('📦 应用状态已加载: ${snapshot.lastActive}');
      return snapshot;
    } catch (e) {
      print('❌ 加载应用状态失败: $e');
      return null;
    }
  }

  /// 标记应用正常关闭
  Future<void> markProperShutdown() async {
    await _prefs?.setBool(_keyProperShutdown, true);
    await saveState(wasProperlyShutdown: true);
    print('✅ 应用已标记为正常关闭');
  }

  /// 标记应用启动（清除正常关闭标记）
  Future<void> markAppStarted() async {
    await _prefs?.setBool(_keyProperShutdown, false);
    await saveState(wasProperlyShutdown: false);
    print('🚀 应用已标记为启动');
  }

  /// 检查应用是否被系统杀死
  Future<bool> wasKilledBySystem() async {
    final wasProperlyShutdown = _prefs?.getBool(_keyProperShutdown) ?? true;
    final result = !wasProperlyShutdown;

    if (result) {
      print('⚠️ 检测到应用被系统杀死（未正常关闭）');
    } else {
      print('✅ 应用正常关闭');
    }

    return result;
  }

  /// 获取后台时长
  Future<Duration?> getBackgroundDuration() async {
    try {
      final lastActiveStr = _prefs?.getString(_keyLastActive);
      if (lastActiveStr == null) return null;

      final lastActive = DateTime.parse(lastActiveStr);
      final duration = DateTime.now().difference(lastActive);
      print('⏱️ 后台时长: ${duration.inMinutes} 分钟');
      return duration;
    } catch (e) {
      print('❌ 计算后台时长失败: $e');
      return null;
    }
  }

  /// 获取上次天气更新时间
  Future<DateTime?> getLastWeatherUpdate() async {
    try {
      final updateStr = _prefs?.getString(_keyLastWeatherUpdate);
      if (updateStr == null) return null;
      return DateTime.parse(updateStr);
    } catch (e) {
      print('❌ 获取上次天气更新时间失败: $e');
      return null;
    }
  }

  /// 保存天气更新时间
  Future<void> saveWeatherUpdateTime([DateTime? time]) async {
    final updateTime = time ?? DateTime.now();
    await _prefs?.setString(
      _keyLastWeatherUpdate,
      updateTime.toIso8601String(),
    );
    print('💾 天气更新时间已保存: $updateTime');
  }

  /// 获取上次定位更新时间
  Future<DateTime?> getLastLocationUpdate() async {
    try {
      final updateStr = _prefs?.getString(_keyLastLocationUpdate);
      if (updateStr == null) return null;
      return DateTime.parse(updateStr);
    } catch (e) {
      print('❌ 获取上次定位更新时间失败: $e');
      return null;
    }
  }

  /// 保存定位更新时间
  Future<void> saveLocationUpdateTime([DateTime? time]) async {
    final updateTime = time ?? DateTime.now();
    await _prefs?.setString(
      _keyLastLocationUpdate,
      updateTime.toIso8601String(),
    );
    print('💾 定位更新时间已保存: $updateTime');
  }

  /// 保存最后位置
  Future<void> saveLastLocation(LocationModel location) async {
    try {
      await _prefs?.setString(_keyLastLocation, jsonEncode(location.toJson()));
      print('💾 最后位置已保存: ${location.district}');
    } catch (e) {
      print('❌ 保存最后位置失败: $e');
    }
  }

  /// 获取最后位置
  Future<LocationModel?> getLastLocation() async {
    try {
      final locationJson = _prefs?.getString(_keyLastLocation);
      if (locationJson == null) return null;

      final location = LocationModel.fromJson(
        jsonDecode(locationJson) as Map<String, dynamic>,
      );
      print('📦 最后位置已加载: ${location.district}');
      return location;
    } catch (e) {
      print('❌ 加载最后位置失败: $e');
      return null;
    }
  }

  /// 清除所有状态
  Future<void> clearState() async {
    await _prefs?.remove(_keyAppState);
    await _prefs?.remove(_keyLastActive);
    await _prefs?.remove(_keyLastLocation);
    await _prefs?.remove(_keyLastWeatherUpdate);
    await _prefs?.remove(_keyLastLocationUpdate);
    await _prefs?.remove(_keyProperShutdown);
    print('🗑️ 应用状态已清除');
  }
}
