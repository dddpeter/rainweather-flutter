/// 抽屉菜单配置数据
///
/// 将菜单项的配置数据集中管理,便于维护和扩展
library;

import 'package:flutter/material.dart';

/// 菜单项配置类
class DrawerMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isTestFunction;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isTestFunction = false,
  });
}

/// 基础功能菜单配置
final List<DrawerMenuItem> basicMenuItems = [
  // 主题设置
  DrawerMenuItem(
    icon: Icons.settings,
    title: '主题设置',
    subtitle: '切换亮色/暗色/跟随系统',
  ),

  // 黄历节日
  DrawerMenuItem(
    icon: Icons.calendar_view_month_rounded,
    title: '黄历节日',
    subtitle: '查看农历、节气、宜忌',
  ),

  // 天气提醒设置
  DrawerMenuItem(
    icon: Icons.notifications_active,
    title: '天气提醒设置',
    subtitle: '配置通勤时段和阈值',
  ),
];

/// 测试功能菜单配置
final List<DrawerMenuItem> testMenuItems = [
  DrawerMenuItem(
    icon: Icons.animation_outlined,
    title: '天气动画测试',
    subtitle: '测试各种天气动画效果',
    isTestFunction: true,
  ),

  DrawerMenuItem(
    icon: Icons.view_compact_alt_outlined,
    title: '天气布局测试',
    subtitle: '测试不同的天气信息布局',
    isTestFunction: true,
  ),

  DrawerMenuItem(
    icon: Icons.cloud_done,
    title: '定位测试',
    subtitle: '测试多种定位方式',
    isTestFunction: true,
  ),

  DrawerMenuItem(
    icon: Icons.emoji_objects_outlined,
    title: '天气图标测试',
    subtitle: '查看所有天气图标',
    isTestFunction: true,
  ),

  DrawerMenuItem(
    icon: Icons.warning_amber_rounded,
    title: '天气提醒测试',
    subtitle: '测试天气提醒功能',
    isTestFunction: true,
  ),
];

/// 关于应用菜单配置
final DrawerMenuItem aboutMenuItem = DrawerMenuItem(
  icon: Icons.info_outline,
  title: '关于应用',
  subtitle: '版本信息和开发者',
);
