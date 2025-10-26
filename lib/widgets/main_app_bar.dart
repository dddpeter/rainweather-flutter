import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import '../services/weather_alert_service.dart';
import '../services/weather_share_service.dart';
import '../screens/outfit_advisor_screen.dart';
import '../screens/health_advisor_screen.dart';
import '../screens/extreme_weather_alert_screen.dart';

/// 主应用的顶部导航栏
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const MainAppBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: themeProvider.isLightTheme
              ? const Color(0xFFE0E0E0)
              : const Color(0xFF424242),
        ),
      ),
      toolbarHeight: 56,
      titleSpacing: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: themeProvider.isLightTheme
                ? const Color(0xFF012d78)
                : const Color(0xFF8edafc),
            size: 28,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          tooltip: '菜单',
        ),
      ),
      actions: [
        // 刷新按钮
        _buildRefreshButton(context, themeProvider),
        // 主题切换按钮
        _buildThemeToggleButton(context, themeProvider),
        // 今日天气页面专属功能菜单
        if (currentIndex == 0) _buildTodayFeaturesMenu(context, themeProvider),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 构建刷新按钮
  Widget _buildRefreshButton(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) => IconButton(
        icon: Icon(
          Icons.refresh_rounded,
          color: themeProvider.isLightTheme
              ? const Color(0xFF012d78)
              : const Color(0xFF8edafc),
          size: 24,
        ),
        onPressed: () async {
          await weatherProvider.forceRefreshWithLocation();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('刷新成功'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.primaryBlue,
              ),
            );
          }
        },
        tooltip: '刷新',
      ),
    );
  }

  /// 构建主题切换按钮
  Widget _buildThemeToggleButton(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return IconButton(
      icon: Icon(
        themeProvider.isLightTheme ? Icons.dark_mode : Icons.light_mode,
        color: themeProvider.isLightTheme
            ? const Color(0xFF012d78)
            : const Color(0xFF8edafc),
        size: 24,
      ),
      onPressed: () {
        themeProvider.setThemeMode(
          themeProvider.isLightTheme ? AppThemeMode.dark : AppThemeMode.light,
        );
      },
      tooltip: themeProvider.isLightTheme ? '切换到暗色' : '切换到亮色',
    );
  }

  /// 构建今日天气页面专属功能菜单
  Widget _buildTodayFeaturesMenu(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.apps_rounded,
        color: themeProvider.isLightTheme
            ? const Color(0xFF012d78)
            : const Color(0xFF8edafc),
        size: 24,
      ),
      tooltip: '更多功能',
      onSelected: (value) => _handleMenuItemSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'ai_assistant',
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 24),
              SizedBox(width: 12),
              Text('AI助手'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'alerts',
          child: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text('综合提醒'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, color: Color(0xFF2E7D32), size: 24),
              SizedBox(width: 12),
              Text('分享天气'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'outfit',
          child: Row(
            children: [
              Icon(Icons.checkroom_rounded, color: Color(0xFF9C27B0), size: 24),
              SizedBox(width: 12),
              Text('穿搭顾问'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'health',
          child: Row(
            children: [
              Icon(Icons.favorite_rounded, color: Color(0xFFE91E63), size: 24),
              SizedBox(width: 12),
              Text('健康管家'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'extreme',
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFFF5722), size: 24),
              SizedBox(width: 12),
              Text('异常预警'),
            ],
          ),
        ),
      ],
    );
  }

  /// 处理菜单项选择
  void _handleMenuItemSelection(BuildContext context, String value) async {
    final weatherProvider = context.read<WeatherProvider>();

    switch (value) {
      case 'ai_assistant':
        weatherProvider.generateWeatherSummary(forceRefresh: true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('正在重新生成AI摘要...'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.primaryBlue,
            ),
          );
        }
        break;

      case 'alerts':
        final alertService = WeatherAlertService.instance;
        final currentLocation = weatherProvider.currentLocation;
        final district =
            currentLocation?.district ?? currentLocation?.city ?? '未知';
        final smartAlerts = alertService.getAlertsForCity(
          district,
          currentLocation,
        );
        // 显示未读提醒数量
        if (context.mounted) {
          final unreadCount = smartAlerts.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('您有 $unreadCount 条天气提醒'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.primaryBlue,
            ),
          );
        }
        break;

      case 'share':
        final weather = weatherProvider.currentWeather;
        final location = weatherProvider.currentLocation;
        final sunMoonIndexData = weatherProvider.sunMoonIndexData;
        if (weather == null || location == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('天气数据加载中，请稍后再试'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        await WeatherShareService.instance.generateAndSavePoster(
          context: context,
          weather: weather,
          location: location,
          themeProvider: context.read<ThemeProvider>(),
          sunMoonIndexData: sunMoonIndexData,
        );
        break;

      case 'outfit':
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OutfitAdvisorScreen(),
            ),
          );
        }
        break;

      case 'health':
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HealthAdvisorScreen(),
            ),
          );
        }
        break;

      case 'extreme':
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExtremeWeatherAlertScreen(),
            ),
          );
        }
        break;
    }
  }
}
