import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// LocationProvider - GPS 定位管理 Provider
///
/// 职责：
/// - 管理 GPS 定位（当前定位、原始定位）
/// - 定位防抖（5分钟内不重复定位）
/// - 定位权限管理
/// - 跟踪当前显示的是定位数据还是城市数据
/// - 提供定位刷新接口
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService.getInstance();
  final DatabaseService _databaseService = DatabaseService.getInstance();

  // ===== 定位数据 =====
  LocationModel? _currentLocation; // 当前使用的位置（可能是定位或城市）
  LocationModel? _originalLocation; // GPS 定位的位置
  bool _isShowingCityWeather = false; // 是否显示城市天气

  // ===== 状态标志 =====
  bool _isLoadingLocation = false;
  bool _isLocationRefreshing = false; // 全局定位刷新锁
  bool _hasPerformedInitialLocation = false; // 是否已首次定位
  String? _locationError;

  // ===== 定位防抖 =====
  DateTime? _lastLocationTime;
  static const Duration _locationDebounce = Duration(minutes: 5);

  // ===== Getters =====
  LocationModel? get currentLocation => _currentLocation;
  LocationModel? get originalLocation => _originalLocation;
  bool get isShowingCityWeather => _isShowingCityWeather;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isLocationRefreshing => _isLocationRefreshing;
  bool get hasPerformedInitialLocation => _hasPerformedInitialLocation;
  String? get locationError => _locationError;

  /// 是否需要刷新定位（基于防抖时间）
  bool _shouldRefreshLocation() {
    if (_lastLocationTime == null) return true;
    final timeSinceLastLocation = DateTime.now().difference(_lastLocationTime!);
    return timeSinceLastLocation > _locationDebounce;
  }

  /// 初始化定位
  Future<bool> initializeLocation() async {
    if (_hasPerformedInitialLocation) {
      Logger.d('定位已初始化，跳过', tag: 'LocationProvider');
      return true;
    }

    setLoadingLocation(true);

    try {
      // 1. 尝试从数据库加载缓存的位置
      final cachedLocation = await _databaseService.getLocationData('current_location');
      if (cachedLocation != null) {
        _currentLocation = cachedLocation;
        _originalLocation = cachedLocation;
        Logger.d('从缓存加载位置: ${cachedLocation.district}', tag: 'LocationProvider');
      }

      // 2. 获取新定位
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _updateLocation(location);
        _lastLocationTime = DateTime.now();
        _hasPerformedInitialLocation = true;
        Logger.d('定位成功: ${location.district}', tag: 'LocationProvider');
        return true;
      } else {
        // 3. 使用默认位置
        final defaultLocation = _getDefaultLocation();
        _updateLocation(defaultLocation);
        _hasPerformedInitialLocation = true;
        Logger.d('使用默认位置: ${defaultLocation.city}', tag: 'LocationProvider');
        return true;
      }
    } catch (e) {
      _locationError = e.toString();
      Logger.e('定位初始化失败', tag: 'LocationProvider', error: e);

      // 使用默认位置
      final defaultLocation = _getDefaultLocation();
      _updateLocation(defaultLocation);
      _hasPerformedInitialLocation = true;
      return false;
    } finally {
      setLoadingLocation(false);
    }
  }

  /// 刷新定位
  Future<bool> refreshLocation({
    bool forceRefresh = false, // 是否强制定位（忽略防抖）
    bool notifyUI = true,
  }) async {
    // 检查防抖
    if (!forceRefresh && !_shouldRefreshLocation()) {
      Logger.d('定位防抖：距离上次定位不足5分钟', tag: 'LocationProvider');
      return true;
    }

    // 检查是否已在刷新
    if (_isLocationRefreshing) {
      Logger.d('定位正在刷新中，跳过', tag: 'LocationProvider');
      return false;
    }

    _isLocationRefreshing = true;
    if (notifyUI) notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _updateLocation(location);
        _lastLocationTime = DateTime.now();
        Logger.d('定位刷新成功: ${location.district}', tag: 'LocationProvider');
        return true;
      } else {
        _locationError = '无法获取位置';
        Logger.e('定位刷新失败：无法获取位置', tag: 'LocationProvider');
        return false;
      }
    } catch (e) {
      _locationError = e.toString();
      Logger.e('定位刷新失败', tag: 'LocationProvider', error: e);
      return false;
    } finally {
      _isLocationRefreshing = false;
      if (notifyUI) notifyListeners();
    }
  }

  /// 切换到城市天气
  void switchToCityWeather(LocationModel city) {
    _currentLocation = city;
    _isShowingCityWeather = true;
    Logger.d('切换到城市天气: ${city.district}', tag: 'LocationProvider');
    notifyListeners();
  }

  /// 恢复到定位天气
  void restoreLocationWeather() {
    if (_originalLocation != null) {
      _currentLocation = _originalLocation;
      _isShowingCityWeather = false;
      Logger.d('恢复到定位天气', tag: 'LocationProvider');
      notifyListeners();
    }
  }

  /// 更新位置（内部方法）
  void _updateLocation(LocationModel location) {
    bool changed = false;

    if (_currentLocation == null || _currentLocation != location) {
      _currentLocation = location;
      changed = true;
    }

    // 如果是定位结果，更新原始定位
    if (_originalLocation == null || _originalLocation != location) {
      _originalLocation = location;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// 设置加载状态
  void setLoadingLocation(bool loading) {
    if (_isLoadingLocation != loading) {
      _isLoadingLocation = loading;
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    if (_locationError != null) {
      _locationError = null;
      notifyListeners();
    }
  }

  /// 获取默认位置
  LocationModel _getDefaultLocation() {
    return LocationModel(
      address: '北京市',
      country: '中国',
      province: '北京',
      city: '北京',
      district: '北京',
      street: '',
      adcode: '110000',
      town: '',
      lat: 39.9042,
      lng: 116.4074,
    );
  }

  /// 释放资源
  @override
  void dispose() {
    _currentLocation = null;
    _originalLocation = null;
    super.dispose();
  }
}
