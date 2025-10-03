import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../constants/app_colors.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopupMenuButton<String>(
          icon: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.menu,
              color: AppColors.titleBarDecorIconColor,
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
                    themeProvider.isLightTheme ? Icons.light_mode : Icons.dark_mode,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '主题设置',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // 清理缓存
            PopupMenuItem<String>(
              value: 'clear_cache',
              child: Row(
                children: [
                  Icon(
                    Icons.clear_all,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '清理缓存',
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
                  Text(
                    '关于应用',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
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
      case 'clear_cache':
        _showClearCacheDialog(context);
        break;
      case 'about':
        _showAboutDialog(context);
        break;
    }
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
              backgroundColor: AppColors.backgroundSecondary,
              shape: AppColors.dialogShape,
              title: Text(
                '主题设置',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  _buildThemeOption(
                    context,
                    '暗色主题',
                    AppThemeMode.dark,
                    Icons.dark_mode,
                    themeProvider.themeMode == AppThemeMode.dark,
                  ),
                  _buildThemeOption(
                    context,
                    '跟随系统',
                    AppThemeMode.system,
                    Icons.settings_brightness,
                    themeProvider.themeMode == AppThemeMode.system,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '确定',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
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
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
                ? Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1)
                : null,
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
              size: 22,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: AppColors.primaryBlue,
                    size: 20,
                  )
                : null,
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

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: AppColors.dialogShape,
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '清理缓存',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '确定要清理天气缓存数据吗？这将删除所有已保存的天气数据，但保留城市列表和设置。',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                await context.read<WeatherProvider>().clearWeatherCache();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '缓存已清理',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(
                '确定',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
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
          shape: AppColors.dialogShape,
          title: Text(
            '关于应用',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '知雨天气',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '版本: 1.0.0',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '一款简洁美观的天气应用',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '© 2024 知雨天气. All rights reserved.',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '确定',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        );
      },
    );
  }
}
