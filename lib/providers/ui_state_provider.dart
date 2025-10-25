import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// UI状态Provider - 专门管理UI状态（加载、错误等）
class UIStateProvider extends ChangeNotifier {
  // 全局加载状态
  bool _isLoading = false;
  String? _error;

  // 页面状态
  int _currentTabIndex = 0;
  bool _isShowingCityWeather = false;

  // 特定功能加载状态
  bool _isLoadingWeather = false;
  bool _isLoadingLocation = false;
  bool _isLoadingCities = false;
  bool _isRefreshing = false;

  // 错误状态
  String? _weatherError;
  String? _locationError;
  String? _citiesError;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentTabIndex => _currentTabIndex;
  bool get isShowingCityWeather => _isShowingCityWeather;
  bool get isLoadingWeather => _isLoadingWeather;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isLoadingCities => _isLoadingCities;
  bool get isRefreshing => _isRefreshing;
  String? get weatherError => _weatherError;
  String? get locationError => _locationError;
  String? get citiesError => _citiesError;

  /// 设置全局加载状态
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      Logger.d('全局加载状态: $loading', tag: 'UIStateProvider');
    }
  }

  /// 设置全局错误
  void setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
      if (error != null) {
        Logger.e('设置全局错误: $error', tag: 'UIStateProvider');
      }
    }
  }

  /// 清除全局错误
  void clearError() {
    setError(null);
  }

  /// 设置当前标签页索引
  void setCurrentTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
      Logger.d('当前标签页索引: $index', tag: 'UIStateProvider');
    }
  }

  /// 设置是否显示城市天气
  void setShowingCityWeather(bool showing) {
    if (_isShowingCityWeather != showing) {
      _isShowingCityWeather = showing;
      notifyListeners();
      Logger.d('显示城市天气: $showing', tag: 'UIStateProvider');
    }
  }

  /// 设置天气加载状态
  void setLoadingWeather(bool loading) {
    if (_isLoadingWeather != loading) {
      _isLoadingWeather = loading;
      notifyListeners();
      Logger.d('天气加载状态: $loading', tag: 'UIStateProvider');
    }
  }

  /// 设置定位加载状态
  void setLoadingLocation(bool loading) {
    if (_isLoadingLocation != loading) {
      _isLoadingLocation = loading;
      notifyListeners();
      Logger.d('定位加载状态: $loading', tag: 'UIStateProvider');
    }
  }

  /// 设置城市加载状态
  void setLoadingCities(bool loading) {
    if (_isLoadingCities != loading) {
      _isLoadingCities = loading;
      notifyListeners();
      Logger.d('城市加载状态: $loading', tag: 'UIStateProvider');
    }
  }

  /// 设置刷新状态
  void setRefreshing(bool refreshing) {
    if (_isRefreshing != refreshing) {
      _isRefreshing = refreshing;
      notifyListeners();
      Logger.d('刷新状态: $refreshing', tag: 'UIStateProvider');
    }
  }

  /// 设置天气错误
  void setWeatherError(String? error) {
    if (_weatherError != error) {
      _weatherError = error;
      notifyListeners();
      if (error != null) {
        Logger.e('设置天气错误: $error', tag: 'UIStateProvider');
      }
    }
  }

  /// 设置定位错误
  void setLocationError(String? error) {
    if (_locationError != error) {
      _locationError = error;
      notifyListeners();
      if (error != null) {
        Logger.e('设置定位错误: $error', tag: 'UIStateProvider');
      }
    }
  }

  /// 设置城市错误
  void setCitiesError(String? error) {
    if (_citiesError != error) {
      _citiesError = error;
      notifyListeners();
      if (error != null) {
        Logger.e('设置城市错误: $error', tag: 'UIStateProvider');
      }
    }
  }

  /// 清除所有错误
  void clearAllErrors() {
    _error = null;
    _weatherError = null;
    _locationError = null;
    _citiesError = null;
    notifyListeners();
    Logger.d('清除所有错误', tag: 'UIStateProvider');
  }

  /// 清除特定错误
  void clearWeatherError() {
    setWeatherError(null);
  }

  void clearLocationError() {
    setLocationError(null);
  }

  void clearCitiesError() {
    setCitiesError(null);
  }

  /// 重置所有状态
  void resetAllStates() {
    _isLoading = false;
    _error = null;
    _currentTabIndex = 0;
    _isShowingCityWeather = false;
    _isLoadingWeather = false;
    _isLoadingLocation = false;
    _isLoadingCities = false;
    _isRefreshing = false;
    _weatherError = null;
    _locationError = null;
    _citiesError = null;
    notifyListeners();
    Logger.d('重置所有UI状态', tag: 'UIStateProvider');
  }

  /// 检查是否有任何错误
  bool get hasAnyError =>
      _error != null ||
      _weatherError != null ||
      _locationError != null ||
      _citiesError != null;

  /// 检查是否有任何加载状态
  bool get hasAnyLoading =>
      _isLoading ||
      _isLoadingWeather ||
      _isLoadingLocation ||
      _isLoadingCities ||
      _isRefreshing;
}
