import 'package:flutter/material.dart';

/// 页面激活监听器接口
abstract class PageActivationListener {
  /// 页面被激活时调用（类似Vue的activated）
  void onPageActivated();

  /// 页面被停用时调用（类似Vue的deactivated）
  void onPageDeactivated();
}

/// 页面激活观察者
class PageActivationObserver {
  static final PageActivationObserver _instance =
      PageActivationObserver._internal();
  factory PageActivationObserver() => _instance;
  PageActivationObserver._internal();

  // 存储所有监听器
  final Set<PageActivationListener> _listeners = <PageActivationListener>{};

  // 当前激活的页面路径
  String? _currentActiveRoute;

  // 页面激活状态
  final Map<String, bool> _pageActivationState = {};

  /// 添加页面激活监听器
  void addListener(PageActivationListener listener) {
    _listeners.add(listener);
  }

  /// 移除页面激活监听器
  void removeListener(PageActivationListener listener) {
    _listeners.remove(listener);
  }

  /// 通知页面激活
  void notifyPageActivated(String routeName) {
    print('📱 PageActivationObserver: 页面激活 - $routeName');

    // 如果有之前激活的页面，先通知停用
    if (_currentActiveRoute != null && _currentActiveRoute != routeName) {
      _notifyPageDeactivated(_currentActiveRoute!);
    }

    // 更新当前激活页面
    _currentActiveRoute = routeName;
    _pageActivationState[routeName] = true;

    // 通知页面激活
    _notifyPageActivated(routeName);
  }

  /// 通知页面停用
  void notifyPageDeactivated(String routeName) {
    print('📱 PageActivationObserver: 页面停用 - $routeName');
    _notifyPageDeactivated(routeName);
  }

  /// 内部方法：通知页面激活
  void _notifyPageActivated(String routeName) {
    for (final listener in _listeners) {
      try {
        listener.onPageActivated();
      } catch (e) {
        // 忽略监听器错误，避免影响其他监听器
      }
    }
  }

  /// 内部方法：通知页面停用
  void _notifyPageDeactivated(String routeName) {
    _pageActivationState[routeName] = false;

    for (final listener in _listeners) {
      try {
        listener.onPageDeactivated();
      } catch (e) {
        // 忽略监听器错误，避免影响其他监听器
      }
    }
  }

  /// 检查页面是否激活
  bool isPageActivated(String routeName) {
    return _pageActivationState[routeName] ?? false;
  }

  /// 获取当前激活的页面
  String? get currentActiveRoute => _currentActiveRoute;

  /// 清理所有监听器（应用退出时调用）
  void clearAllListeners() {
    _listeners.clear();
    _currentActiveRoute = null;
    _pageActivationState.clear();
    print('📱 PageActivationObserver: 已清理所有监听器');
  }
}

/// 页面激活混入类，用于StatefulWidget
mixin PageActivationMixin<T extends StatefulWidget> on State<T>
    implements PageActivationListener {
  final PageActivationObserver _observer = PageActivationObserver();
  String? _routeName;

  @override
  void initState() {
    super.initState();
    // 延迟获取路由名称，避免在initState中访问context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeName = ModalRoute.of(context)?.settings.name;
    });
    _observer.addListener(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 检查当前路由是否发生变化
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != _routeName) {
      _routeName = currentRoute;
    }
  }

  @override
  void dispose() {
    if (_routeName != null) {
      _observer.notifyPageDeactivated(_routeName!);
    }
    _observer.removeListener(this);
    super.dispose();
  }

  /// 手动触发页面激活（用于特殊场景）
  void triggerPageActivation() {
    if (_routeName != null) {
      _observer.notifyPageActivated(_routeName!);
    }
  }

  /// 获取当前页面路由名称
  String? get currentRouteName => _routeName;
}
