import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_themes.dart';
import '../constants/app_version.dart';
import '../screens/weather_animation_test_screen.dart';
import '../screens/weather_layout_test_screen.dart';
import '../screens/weather_alert_settings_screen.dart';
import '../screens/weather_alert_test_screen.dart';
import '../screens/all_location_test_screen.dart';
import '../screens/lunar_calendar_screen.dart';
import '../screens/weather_icons_test_screen.dart';
// import '../screens/radar_screen.dart'; // 已移除雷达图功能

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

              const SizedBox(height: 4),

              // 主题推荐提示
              _buildThemeRecommendation(context, themeProvider),

              // 主题配色快速切换
              _buildThemeQuickSwitch(context, themeProvider),

              const SizedBox(height: 8),

              // 主题设置
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

              const SizedBox(height: 12),

              // 测试功能组（二级菜单，可展开/收起）
              _buildTestFunctionsMenu(context),

              const SizedBox(height: 12),

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
    // 获取当前主题方案
    final scheme = AppThemes.getScheme(themeProvider.themeScheme);
    final isLight = themeProvider.isLightTheme;
    
    // 使用主题方案中定义的头部渐变
    final headerGradient = scheme.getHeaderGradient(isLight);
    
    // 根据主题方案和亮暗模式计算文字颜色
    // 某些主题（如amber、sunset等）在亮色模式下背景较浅，需要深色文字
    final needsDarkText = _needsDarkHeaderText(themeProvider.themeScheme, isLight);
    final textColor = needsDarkText ? AppColors.drawerHeaderTextDark : Colors.white;
    final textSecondaryColor = needsDarkText
        ? AppColors.drawerHeaderTextSecondary
        : Colors.white.withOpacity(0.9);
    final descriptionBgColor = needsDarkText
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.2);

    final headerDecoration = BoxDecoration(
      gradient: headerGradient,
      boxShadow: [
        BoxShadow(
          color: _getHeaderShadowColor(themeProvider.themeScheme, isLight),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Container(
      decoration: headerDecoration,
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 应用图标（添加发光效果）
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 右侧文字信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 应用名称
                Text(
                  AppVersion.appName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                // 应用描述
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: descriptionBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppVersion.description,
                    style: TextStyle(
                      color: textSecondaryColor, 
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 判断是否需要深色文字（浅色背景）
  bool _needsDarkHeaderText(AppThemeScheme scheme, bool isLight) {
    // 亮色模式下，某些主题的头部背景较浅，需要深色文字
    if (isLight) {
      return scheme == AppThemeScheme.amber || 
             scheme == AppThemeScheme.sunset ||
             scheme == AppThemeScheme.rose;
    }
    // 暗色模式下，所有主题都使用浅色背景，所以用白色文字
    return false;
  }

  /// 获取头部阴影颜色
  Color _getHeaderShadowColor(AppThemeScheme scheme, bool isLight) {
    if (isLight) {
      // 亮色模式下的阴影颜色
      switch (scheme) {
        case AppThemeScheme.amber:
          return const Color(0xFFFF8F00).withOpacity(0.3);
        case AppThemeScheme.sunset:
          return const Color(0xFFFF5722).withOpacity(0.3);
        case AppThemeScheme.rose:
          return const Color(0xFFE91E63).withOpacity(0.3);
        default:
          return AppColors.primaryBlue.withOpacity(0.3);
      }
    } else {
      // 暗色模式下的阴影颜色
      return AppColors.accentBlue.withOpacity(0.3);
    }
  }

  /// 构建主题推荐提示
  Widget _buildThemeRecommendation(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    // 获取天气数据
    final weatherProvider = context.read<WeatherProvider>();
    final currentWeather = weatherProvider.currentWeather;
    String? weatherCode;

    if (currentWeather != null &&
        currentWeather.current?.current?.weatherPic != null) {
      weatherCode = currentWeather.current!.current!.weatherPic;
    }

    // 获取推荐主题
    final recommendation = themeProvider.getRecommendedTheme(
      weatherCode: weatherCode,
    );

    // 如果推荐的是当前主题，不显示提示
    if (recommendation['isCurrent'] == true) {
      return const SizedBox.shrink();
    }

    final recommendedScheme = recommendation['scheme'] as AppThemeScheme;
    final reason = recommendation['reason'] as String;
    final primaryColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.12),
            primaryColor.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              themeProvider.setThemeScheme(recommendedScheme);
              AppColors.setThemeProvider(themeProvider);
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: primaryColor.withOpacity(0.1),
              foregroundColor: primaryColor,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              side: BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '应用',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主题配色快速切换
  Widget _buildThemeQuickSwitch(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final activeColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppThemes.allSchemes.asMap().entries.map((entry) {
          final index = entry.key;
          final scheme = entry.value;
          final isSelected =
              themeProvider.themeScheme == AppThemeScheme.values[index];

          return _ThemeCardWithPulse(
            width: 78,
            scheme: scheme,
            isSelected: isSelected,
            activeColor: activeColor,
            onTap: () {
              themeProvider.setThemeScheme(AppThemeScheme.values[index]);
              AppColors.setThemeProvider(themeProvider);
            },
          );
        }).toList(),
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建测试功能二级菜单
  Widget _buildTestFunctionsMenu(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // 暗色模式下使用更亮的强调色
    final iconColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.15),
                  iconColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.science, color: iconColor, size: 24),
          ),
          title: Text(
            '测试功能',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '开发调试工具',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          iconColor: AppColors.textPrimary,
          collapsedIconColor: AppColors.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
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
                  _buildSubMenuItem(
                    context,
                    icon: Icons.image,
                    title: '天气图标测试',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToWeatherIconsTest(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建二级菜单项
  Widget _buildSubMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // 暗色模式下使用更亮的强调色
    final iconColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // 暗色模式下使用更亮的强调色
    final iconColor = themeProvider.isLightTheme
        ? AppColors.primaryBlue
        : AppColors.accentBlue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 图标容器
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withOpacity(0.15),
                        iconColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                // 标题和副标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary, 
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 箭头图标
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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

  void _navigateToWeatherIconsTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherIconsTestScreen()),
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

  // 雷达图导航方法已移除

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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 主题方案选择
                    Text(
                      '主题配色',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppThemes.allSchemes.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final scheme = entry.value;
                        final isSelected =
                            themeProvider.themeScheme ==
                            AppThemeScheme.values[index];

                        final activeColor = themeProvider.isLightTheme
                            ? AppColors.primaryBlue
                            : AppColors.accentBlue;

                        return GestureDetector(
                          onTap: () {
                            themeProvider.setThemeScheme(
                              AppThemeScheme.values[index],
                            );
                            AppColors.setThemeProvider(themeProvider);
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              // 选中时添加明显的边框和阴影
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
                                    : Colors.transparent,
                                width: isSelected ? 3 : 0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: activeColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: scheme.previewColor,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    scheme.icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scheme.name.replaceAll('主题', ''),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // 亮暗模式选择
                    Text(
                      '显示模式',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: themeProvider.isLightTheme
                        ? AppColors.primaryBlue
                        : AppColors.accentBlue, // 暗色模式使用更亮的强调色
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

        // 暗色模式下使用更亮的强调色
        final activeColor = themeProvider.isLightTheme
            ? AppColors.primaryBlue
            : AppColors.accentBlue;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(
                    themeProvider.isLightTheme ? 0.15 : 0.24,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: activeColor, width: 2)
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
              size: 24,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 16,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: activeColor, size: 24)
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
                      '• 黄历详情页面改为滑动页面设计\n'
                      '• 新增AI解读页面，支持左右滑动切换\n'
                      '• 优化通勤提醒自动清理逻辑\n'
                      '• 修复通勤提醒时段结束后不消失的问题\n'
                      '• 优化日出日落卡片布局，更加紧凑\n'
                      '• 修复页面指示器按钮颜色显示问题',
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

/// 带脉冲动画的主题卡片
class _ThemeCardWithPulse extends StatefulWidget {
  final double width;
  final ThemeColorScheme scheme;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ThemeCardWithPulse({
    required this.width,
    required this.scheme,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_ThemeCardWithPulse> createState() => _ThemeCardWithPulseState();
}

class _ThemeCardWithPulseState extends State<_ThemeCardWithPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 只在选中时播放动画
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_ThemeCardWithPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中状态改变时，控制动画
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isSelected ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? widget.activeColor
                    : widget.activeColor.withOpacity(0.3),
                width: widget.isSelected ? 2.5 : 1.5,
              ),
              boxShadow: widget.isSelected
                  ? [
                      // 选中时的轻微阴影
                      BoxShadow(
                        color: widget.activeColor.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                      // 底部阴影
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      // 未选中时的边框阴影
                      BoxShadow(
                        color: widget.activeColor.withOpacity(0.15),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                      // 未选中时的底部阴影
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.5, -0.5),
                  end: Alignment(1.0, 1.0),
                  colors: [
                    widget.scheme.previewColor,
                    widget.scheme.previewColor.withOpacity(0.82),
                  ],
                  stops: const [0.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 图标
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(widget.isSelected ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.scheme.icon, 
                      color: Colors.white, 
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 主题名称
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      widget.scheme.name.replaceAll('主题', ''),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        height: 1.1,
                        shadows: widget.isSelected
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // 选中指示器
                  if (widget.isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 7),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
