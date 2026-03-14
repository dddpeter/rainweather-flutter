/// 抽屉菜单导航逻辑
///
/// 集中管理所有菜单项的导航逻辑
library;

import 'package:flutter/material.dart';
import '../screens/lunar_calendar_screen.dart';
import '../screens/weather_animation_test_screen.dart';
import '../screens/weather_layout_test_screen.dart';
import '../screens/all_location_test_screen.dart';
import '../screens/weather_icons_test_screen.dart';
import '../screens/weather_alert_settings_screen.dart';
import '../screens/weather_alert_test_screen.dart';
import '../constants/app_version.dart';

/// 抽屉导航处理器
class DrawerNavigationHandler {
  /// 导航到黄历页面
  static void navigateToLaoHuangLi(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LunarCalendarScreen()),
    );
  }

  /// 导航到天气动画测试
  static void navigateToWeatherAnimationTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherAnimationTestScreen()),
    );
  }

  /// 导航到天气布局测试
  static void navigateToWeatherLayoutTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherLayoutTestScreen()),
    );
  }

  /// 导航到定位测试
  static void navigateToAllLocationTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllLocationTestScreen()),
    );
  }

  /// 导航到天气图标测试
  static void navigateToWeatherIconsTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherIconsTestScreen()),
    );
  }

  /// 导航到天气提醒设置
  static void navigateToWeatherAlertSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherAlertSettingsScreen()),
    );
  }

  /// 导航到天气提醒测试
  static void navigateToWeatherAlertTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherAlertTestScreen()),
    );
  }

  /// 显示主题设置对话框
  static void showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('主题设置'),
        content: const Text('选择您喜欢的主题模式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  static void showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: '智雨天气',
        applicationVersion: 'v${AppVersion.version}',
        applicationIcon: const Icon(Icons.cloud, size: 48),
        children: [
          const Text('一款现代化的天气预报应用'),
          const SizedBox(height: 8),
          const Text('支持智能定位、AI天气摘要等功能'),
        ],
      ),
    );
  }
}
