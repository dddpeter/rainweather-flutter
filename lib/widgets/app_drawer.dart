import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_version.dart';
import '../screens/weather_animation_test_screen.dart';
import '../screens/weather_layout_test_screen.dart';
import '../screens/weather_alert_settings_screen.dart';
import '../screens/weather_alert_test_screen.dart';
import '../screens/all_location_test_screen.dart';
import '../screens/lunar_calendar_screen.dart';

/// 应用抽屉菜单
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Drawer(
          backgroundColor: AppColors.backgroundPrimary,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 头部
              _buildDrawerHeader(context, themeProvider),

              // 基础功能组
              _buildSectionTitle('基础功能'),
              _buildMenuItem(
                context,
                icon: themeProvider.isLightTheme
                    ? Icons.light_mode
                    : Icons.dark_mode,
                title: '主题设置',
                subtitle: _getThemeSubtitle(themeProvider),
                onTap: () {
                  Navigator.pop(context);
                  _showThemeDialog(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.calendar_view_month_rounded,
                title: '黄历节日',
                subtitle: '查看农历、节气、宜忌',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToLaoHuangLi(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.notifications_active,
                title: '天气提醒设置',
                subtitle: '配置通勤时段和阈值',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToWeatherAlertSettings(context);
                },
              ),

              const Divider(height: 24, indent: 16, endIndent: 16),

              // 测试功能组（二级菜单，可展开/收起）
              _buildTestFunctionsMenu(context),

              const Divider(height: 24, indent: 16, endIndent: 16),

              // 关于应用
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: '关于应用',
                subtitle: 'v${AppVersion.version}',
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog(context);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// 构建抽屉头部
  Widget _buildDrawerHeader(BuildContext context, ThemeProvider themeProvider) {
    // 使用App背景渐变色
    final headerDecoration = BoxDecoration(gradient: AppColors.primaryGradient);

    // 根据主题调整文字颜色
    final textColor = themeProvider.isLightTheme
        ? AppColors
              .primaryBlue // 亮色模式：深蓝色
        : Colors.white; // 暗色模式：白色

    final subtextColor = themeProvider.isLightTheme
        ? AppColors
              .textSecondary // 亮色模式：次要文字色
        : Colors.white.withOpacity(0.9); // 暗色模式：半透明白色

    return DrawerHeader(
      decoration: headerDecoration,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 应用图标（添加背景容器提高可见度）
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 应用名称
          Text(
            AppVersion.appName,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // 应用描述
          Text(
            AppVersion.description,
            style: TextStyle(color: subtextColor, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 构建测试功能二级菜单
  Widget _buildTestFunctionsMenu(BuildContext context) {
    // 统一使用主题色
    final iconColor = AppColors.primaryBlue;

    return ExpansionTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.science, color: iconColor, size: 22),
      ),
      title: Text(
        '测试功能',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '开发调试工具',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      iconColor: AppColors.textPrimary,
      collapsedIconColor: AppColors.textSecondary,
      children: [
        _buildSubMenuItem(
          context,
          icon: Icons.bug_report,
          title: '天气提醒测试',
          onTap: () {
            Navigator.pop(context);
            _navigateToWeatherAlertTest(context);
          },
        ),
        _buildSubMenuItem(
          context,
          icon: Icons.animation,
          title: '天气动画测试',
          onTap: () {
            Navigator.pop(context);
            _navigateToWeatherTest(context);
          },
        ),
        _buildSubMenuItem(
          context,
          icon: Icons.format_align_center,
          title: '天气布局测试',
          onTap: () {
            Navigator.pop(context);
            _navigateToWeatherLayoutTest(context);
          },
        ),
        _buildSubMenuItem(
          context,
          icon: Icons.location_on,
          title: '定位服务测试',
          onTap: () {
            Navigator.pop(context);
            _navigateToAllLocationTest(context);
          },
        ),
      ],
    );
  }

  /// 构建二级菜单项
  Widget _buildSubMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // 统一使用主题色
    final iconColor = AppColors.primaryBlue;

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    // 统一使用主题色
    final iconColor = AppColors.primaryBlue;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  /// 获取主题副标题
  String _getThemeSubtitle(ThemeProvider themeProvider) {
    switch (themeProvider.themeMode) {
      case AppThemeMode.light:
        return '亮色模式';
      case AppThemeMode.dark:
        return '暗色模式';
      case AppThemeMode.system:
        return '跟随系统';
    }
  }

  // ==================== 导航方法 ====================

  void _navigateToLaoHuangLi(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LunarCalendarScreen(isSelectMode: false),
      ),
    );
  }

  void _navigateToWeatherTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeatherAnimationTestScreen(),
      ),
    );
  }

  void _navigateToWeatherLayoutTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherLayoutTestScreen()),
    );
  }

  void _navigateToAllLocationTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllLocationTestScreen()),
    );
  }

  void _navigateToWeatherAlertSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeatherAlertSettingsScreen(),
      ),
    );
  }

  void _navigateToWeatherAlertTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherAlertTestScreen()),
    );
  }

  // ==================== 对话框方法 ====================

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            AppColors.setThemeProvider(themeProvider);

            return AlertDialog(
              backgroundColor: AppColors.backgroundSecondary,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
              title: Text(
                '主题设置',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeOption(
                    context,
                    '亮色主题',
                    AppThemeMode.light,
                    Icons.light_mode,
                    themeProvider.themeMode == AppThemeMode.light,
                  ),
                  const SizedBox(height: 8),
                  _buildThemeOption(
                    context,
                    '暗色主题',
                    AppThemeMode.dark,
                    Icons.dark_mode,
                    themeProvider.themeMode == AppThemeMode.dark,
                  ),
                  const SizedBox(height: 8),
                  _buildThemeOption(
                    context,
                    '跟随系统',
                    AppThemeMode.system,
                    Icons.settings_brightness,
                    themeProvider.themeMode == AppThemeMode.system,
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    AppThemeMode mode,
    IconData icon,
    bool isSelected,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        AppColors.setThemeProvider(themeProvider);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.primaryBlue, width: 2)
                : Border.all(
                    color: AppColors.borderColor.withOpacity(0.3),
                    width: 1,
                  ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
              size: 24,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 16,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: AppColors.primaryBlue,
                    size: 24,
                  )
                : const SizedBox(width: 24),
            onTap: () {
              themeProvider.setThemeMode(mode);
              AppColors.setThemeProvider(themeProvider);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3,
          icon: Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryBlue,
            size: 32,
          ),
          title: Text(
            '关于应用',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppVersion.appName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '版本: ${AppVersion.version} (构建 ${AppVersion.buildNumber})',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppVersion.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 v${AppVersion.version} 更新内容',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 全新Drawer抽屉菜单设计\n'
                      '• Material Design 3 规范完善\n'
                      '• 通勤提醒级别标签反色优化\n'
                      '• AI标签主题自适应配色\n'
                      '• 城市天气AI总结智能缓存\n'
                      '• 空气质量卡片样式优化',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppVersion.copyright,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
