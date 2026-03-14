/// 测试功能菜单组件
///
/// 专门用于组织和显示测试功能的菜单
library;

import 'package:flutter/material.dart';
import 'drawer_navigation.dart';
import 'drawer_menu_config.dart';

/// 测试功能菜单组件
class DrawerTestMenu extends StatefulWidget {
  const DrawerTestMenu({super.key});

  @override
  State<DrawerTestMenu> createState() => _DrawerTestMenuState();
}

class _DrawerTestMenuState extends State<DrawerTestMenu> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 测试功能标题（可展开/收起）
        ListTile(
          title: Text(
            '测试功能',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(
            _isExpanded
                ? Icons.expand_less
                : Icons.expand_more,
            size: 20,
          ),
          onTap: _toggleExpanded,
        ),

        // 测试功能菜单项
        if (_isExpanded) ...[
          ...testMenuItems.map((item) => _buildTestMenuItem(context, item)),
        ],
      ],
    );
  }

  /// 构建测试菜单项
  Widget _buildTestMenuItem(BuildContext context, DrawerMenuItem item) {
    return ListTile(
      leading: Icon(item.icon, size: 22),
      title: Text(item.title, style: const TextStyle(fontSize: 15)),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!, style: const TextStyle(fontSize: 13))
          : null,
      onTap: () {
        // 关闭抽屉
        Navigator.pop(context);

        // 执行导航
        _executeNavigation(context, item);
      },
    );
  }

  /// 执行导航
  void _executeNavigation(BuildContext context, DrawerMenuItem item) {
    switch (item.title) {
      case '天气动画测试':
        DrawerNavigationHandler.navigateToWeatherAnimationTest(context);
        break;
      case '天气布局测试':
        DrawerNavigationHandler.navigateToWeatherLayoutTest(context);
        break;
      case '定位测试':
        DrawerNavigationHandler.navigateToAllLocationTest(context);
        break;
      case '天气图标测试':
        DrawerNavigationHandler.navigateToWeatherIconsTest(context);
        break;
      case '天气提醒测试':
        DrawerNavigationHandler.navigateToWeatherAlertTest(context);
        break;
      default:
        break;
    }
  }
}
