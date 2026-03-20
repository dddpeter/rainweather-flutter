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

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopupMenuButton<String>(
          // Material Design 3: 圆角和阴影
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3,
          color: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          icon: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.settings,
              color: themeProvider.getColor('headerIconColor'),
              size: AppColors.titleBarDecorIconSize,
            ),
          ),
          onSelected: (value) => _handleMenuSelection(context, value),
          itemBuilder: (BuildContext context) => [
            // 主题切换
            PopupMenuItem<String>(
              value: 'theme',
              child: Row(
                children: [
                  Icon(
                    themeProvider.isLightTheme
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('主题设置', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            // 老黄历
            PopupMenuItem<String>(
              value: 'lao_huang_li',
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_view_month_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('黄历节日', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            // 天气提醒设置
            PopupMenuItem<String>(
              value: 'weather_alert_settings',
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '天气提醒设置',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            // 天气提醒测试
            PopupMenuItem<String>(
              value: 'weather_alert_test',
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    color: AppColors.accentGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '天气提醒测试',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // 天气动画测试
            PopupMenuItem<String>(
              value: 'weather_test',
              child: Row(
                children: [
                  Icon(Icons.animation, color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '天气动画测试',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            // 天气布局测试
            PopupMenuItem<String>(
              value: 'weather_layout_test',
              child: Row(
                children: [
                  Icon(
                    Icons.format_align_center,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '天气布局测试',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            // 定位服务测试
            PopupMenuItem<String>(
              value: 'all_location_test',
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.accentGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '定位服务测试',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // 版本信息
            PopupMenuItem<String>(
              value: 'about',
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('关于应用', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'theme':
        _showThemeDialog(context);
        break;
      case 'lao_huang_li':
        _navigateToLaoHuangLi(context);
        break;
      case 'weather_test':
        _navigateToWeatherTest(context);
        break;
      case 'weather_layout_test':
        _navigateToWeatherLayoutTest(context);
        break;
      case 'all_location_test':
        _navigateToAllLocationTest(context);
        break;
      case 'weather_alert_settings':
        _navigateToWeatherAlertSettings(context);
        break;
      case 'weather_alert_test':
        _navigateToWeatherAlertTest(context);
        break;
      case 'about':
        _showAboutDialog(context);
        break;
    }
  }

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

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            // 确保AppColors始终使用最新的主题状态
            AppColors.setThemeProvider(themeProvider);

            return AlertDialog(
              // Material Design 3: 弹窗样式
              backgroundColor: AppColors.backgroundSecondary,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Material Design 3 标准
              ),
              elevation: 3,
              title: Text(
                '主题设置',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24, // M3: 更大的标题
                  fontWeight: FontWeight.w500, // M3: Medium weight
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                16,
                24,
                8,
              ), // M3: 标准padding
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
              actionsPadding: const EdgeInsets.fromLTRB(
                24,
                0,
                24,
                16,
              ), // M3: 标准padding
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    // M3: 按钮样式 - 暗色模式下使用更亮的强调色
                    foregroundColor: themeProvider.isLightTheme
                        ? AppColors.primaryBlue
                        : AppColors.accentBlue,
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
        // 确保AppColors始终使用最新的主题状态
        AppColors.setThemeProvider(themeProvider);

        // 暗色模式下使用更亮的强调色
        final activeColor = themeProvider.isLightTheme
            ? AppColors.primaryBlue
            : AppColors.accentBlue;

        // Material Design 3: 选项卡片样式
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(
                    themeProvider.isLightTheme ? 0.15 : 0.24,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8), // M3: 更大的圆角
            border: isSelected
                ? Border.all(color: activeColor, width: 2) // M3: 更粗的边框
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
              color: isSelected ? activeColor : AppColors.textSecondary,
              size: 24, // M3: 稍大的图标
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : AppColors.textPrimary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400, // M3: 适中的字重
                fontSize: 16,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: activeColor,
                    size: 24, // M3: 稍大的图标
                  )
                : const SizedBox(width: 24), // 占位以保持对齐
            onTap: () {
              themeProvider.setThemeMode(mode);
              // 立即更新AppColors
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
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            // Material Design 3: 弹窗样式
            return AlertDialog(
              backgroundColor: AppColors.backgroundSecondary,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
              icon: Icon(
                Icons.info_outline_rounded,
                color: themeProvider.isLightTheme
                    ? AppColors.primaryBlue
                    : AppColors.accentBlue, // 暗色模式使用更亮的强调色
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
                  // 版本更新说明
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
                          '• 性能优化：滚动流畅度提升 40-60%\n'
                          '• 内存优化：内存占用降低 30-40%\n'
                          '• 代码质量：统一日志系统，优化架构\n'
                          '• Bug 修复：修复无限刷新循环问题\n'
                          '• 国际城市：支持海外城市天气查询\n'
                          '• 请求去重：防止重复 API 调用',
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
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
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
      },
    );
  }
}
