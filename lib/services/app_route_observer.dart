import 'package:flutter/material.dart';
import 'page_activation_observer.dart';

/// 应用路由观察者
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final PageActivationObserver _pageActivationObserver;

  AppRouteObserver(this._pageActivationObserver);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  void _handleRouteChange(Route<dynamic> route) {
    final routeName = route.settings.name ?? route.runtimeType.toString();
    print('🔄 RouteObserver: 路由变化 - $routeName');

    // 通知页面激活
    _pageActivationObserver.notifyPageActivated(routeName);
  }
}
