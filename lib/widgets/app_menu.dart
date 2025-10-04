import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';

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
              // Material Design 3: 弹窗样式
              backgroundColor: AppColors.backgroundSecondary,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Material Design 3 标准
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
                    // M3: 按钮样式
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
        // 确保AppColors始终使用最新的主题状态
        AppColors.setThemeProvider(themeProvider);

        // Material Design 3: 选项卡片样式
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8), // M3: 更大的圆角
            border: isSelected
                ? Border.all(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ) // M3: 更粗的边框
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
              size: 24, // M3: 稍大的图标
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textPrimary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400, // M3: 适中的字重
                fontSize: 16,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: AppColors.primaryBlue,
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
        // Material Design 3: 弹窗样式
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                '知雨天气',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '版本: 1.0.0',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '一款简洁美观的天气应用',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2024 知雨天气. All rights reserved.',
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
