import 'dart:async';
import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../services/location_change_notifier.dart';
import '../utils/logger.dart';

/// 定位Provider - 专门管理定位相关状态
class LocationProvider extends ChangeNotifier with LocationChangeListener {
  final LocationService _locationService = LocationService.getInstance();

  // 定位状态
  LocationModel? _currentLocation;
  LocationModel? _originalLocation;
  bool _isLocationRefreshing = false;
  bool _hasPerformedInitialLocation = false;
  DateTime? _lastLocationTime;

  // 定位防抖
  static const Duration _locationDebounceInterval = Duration(minutes: 5);

  // 定位状态
  bool _isLocationEnabled = false;
  String? _locationError;

  // Getters
  LocationModel? get currentLocation => _currentLocation;
  LocationModel? get originalLocation => _originalLocation;
  bool get isLocationRefreshing => _isLocationRefreshing;
  bool get hasPerformedInitialLocation => _hasPerformedInitialLocation;
  bool get isLocationEnabled => _isLocationEnabled;
  String? get locationError => _locationError;

  void initState() {
    // 添加定位变化监听器
    LocationChangeNotifier().addListener(this);
    Logger.d('LocationProvider 初始化完成', tag: 'LocationProvider');
  }

  @override
  void dispose() {
    // 移除定位变化监听器
    LocationChangeNotifier().removeListener(this);
    super.dispose();
  }

  /// 执行定位
  Future<LocationModel?> performLocation() async {
    if (_isLocationRefreshing) {
      Logger.d('定位正在进行中，跳过重复请求', tag: 'LocationProvider');
      return _currentLocation;
    }

    // 检查定位防抖
    if (_lastLocationTime != null) {
      final timeSinceLastLocation = DateTime.now().difference(
        _lastLocationTime!,
      );
      if (timeSinceLastLocation < _locationDebounceInterval) {
        Logger.d('定位防抖中，跳过请求', tag: 'LocationProvider');
        return _currentLocation;
      }
    }

    try {
      _isLocationRefreshing = true;
      _locationError = null;
      notifyListeners();

      Logger.d('开始执行定位', tag: 'LocationProvider');
      final location = await _locationService.getCurrentLocation();

      if (location != null) {
        _currentLocation = location;
        _originalLocation = location; // 保存原始定位
        _lastLocationTime = DateTime.now();
        _hasPerformedInitialLocation = true;
        _isLocationEnabled = true;

        Logger.s('定位成功: ${location.district}', tag: 'LocationProvider');
        notifyListeners();
        return location;
      } else {
        _locationError = '定位失败：无法获取位置信息';
        Logger.e('定位失败：无法获取位置信息', tag: 'LocationProvider');
      }
    } catch (e) {
      _locationError = '定位失败：${e.toString()}';
      Logger.e('定位失败', tag: 'LocationProvider', error: e);
    } finally {
      _isLocationRefreshing = false;
      notifyListeners();
    }

    return null;
  }

  /// 强制定位（忽略防抖）
  Future<LocationModel?> forceLocation() async {
    _lastLocationTime = null; // 清除防抖时间
    return await performLocation();
  }

  /// 设置当前定位（用于城市切换）
  void setCurrentLocation(LocationModel location) {
    _currentLocation = location;
    notifyListeners();
    Logger.d('设置当前定位: ${location.district}', tag: 'LocationProvider');
  }

  /// 恢复原始定位
  void restoreOriginalLocation() {
    if (_originalLocation != null) {
      _currentLocation = _originalLocation;
      notifyListeners();
      Logger.d(
        '恢复原始定位: ${_originalLocation!.district}',
        tag: 'LocationProvider',
      );
    }
  }

  /// 检查定位权限
  Future<bool> checkLocationPermission() async {
    try {
      final result = await _locationService.checkLocationPermission();
      _isLocationEnabled = result == LocationPermissionResult.granted;
      notifyListeners();
      return _isLocationEnabled;
    } catch (e) {
      Logger.e('检查定位权限失败', tag: 'LocationProvider', error: e);
      _isLocationEnabled = false;
      notifyListeners();
      return false;
    }
  }

  /// 请求定位权限
  Future<bool> requestLocationPermission() async {
    try {
      final result = await _locationService.requestLocationPermission();
      _isLocationEnabled = result == LocationPermissionResult.granted;
      notifyListeners();
      return _isLocationEnabled;
    } catch (e) {
      Logger.e('请求定位权限失败', tag: 'LocationProvider', error: e);
      _isLocationEnabled = false;
      notifyListeners();
      return false;
    }
  }

  /// 定位成功回调
  @override
  void onLocationSuccess(LocationModel newLocation) {
    Logger.d('收到定位成功通知: ${newLocation.district}', tag: 'LocationProvider');
    _currentLocation = newLocation;
    _originalLocation = newLocation;
    _lastLocationTime = DateTime.now();
    _hasPerformedInitialLocation = true;
    _isLocationEnabled = true;
    _locationError = null;
    notifyListeners();
  }

  /// 定位失败回调
  @override
  void onLocationFailed(String error) {
    Logger.e('收到定位失败通知: $error', tag: 'LocationProvider');
    _locationError = error;
    _isLocationEnabled = false;
    notifyListeners();
  }

  /// 清除定位数据
  void clearLocationData() {
    _currentLocation = null;
    _originalLocation = null;
    _lastLocationTime = null;
    _hasPerformedInitialLocation = false;
    _isLocationEnabled = false;
    _locationError = null;
    notifyListeners();
  }
}
