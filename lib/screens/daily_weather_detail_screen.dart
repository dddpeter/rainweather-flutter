import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/weather_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/weather_animation_widget.dart';
import '../widgets/lunar_info_widget.dart';
import '../services/lunar_service.dart';

/// 单日天气详情页面
/// 显示15天预报中某一天的详细信息，样式与今日天气页面保持一致
class DailyWeatherDetailScreen extends StatelessWidget {
  final DailyWeather dailyWeather;
  final int dayIndex; // 相对于今天的天数（0=今天，1=明天，...）

  const DailyWeatherDetailScreen({
    super.key,
    required this.dailyWeather,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: RefreshIndicator(
              onRefresh: () async {
                // 预报数据不需要刷新
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 头部天气区域
                  SliverToBoxAdapter(child: _buildTopWeatherSection(context)),

                  // 内容区域
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        AppColors.cardSpacingWidget,

                        // 上午/下午详细信息
                        _buildTimePeriodDetails(context),

                        AppColors.cardSpacingWidget,

                        // 农历信息
                        _buildLunarInfoCard(context),

                        AppColors.cardSpacingWidget,

                        // 宜忌信息
                        _buildYiJiInfo(context),

                        AppColors.cardSpacingWidget,

                        // 即将到来的节气
                        _buildUpcomingSolarTerms(context),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建顶部天气区域（与今日天气页面一致）
  Widget _buildTopWeatherSection(BuildContext context) {
    final date = _parseDate(dailyWeather.forecasttime);
    final dayLabel = _getDayLabel();
    final themeProvider = context.read<ThemeProvider>();

    // 计算平均温度
    final tempPm = int.tryParse(dailyWeather.temperature_pm ?? '0') ?? 0;
    final tempAm = int.tryParse(dailyWeather.temperature_am ?? '0') ?? 0;
    final avgTemp = ((tempPm + tempAm) / 2).round();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: themeProvider.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              // 顶部导航栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: themeProvider.getColor('headerTextPrimary'),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            '$dayLabel  ${date.month}月${date.day}日',
                            style: TextStyle(
                              color: themeProvider.getColor(
                                'headerTextPrimary',
                              ),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dailyWeather.week ?? '',
                            style: TextStyle(
                              color: themeProvider.getColor(
                                'headerTextSecondary',
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 占位保持居中
                ],
              ),
              const SizedBox(height: 16),

              // 天气动画和温度
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 天气动画
                  Flexible(
                    flex: 45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        WeatherAnimationWidget(
                          weatherType: dailyWeather.weather_pm ?? '晴',
                          size: 100,
                          isPlaying: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // 温度和天气信息
                  Flexible(
                    flex: 55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 温度
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$avgTemp',
                              style: TextStyle(
                                color: themeProvider.getColor(
                                  'headerTextPrimary',
                                ),
                                fontSize: 72,
                                fontWeight: FontWeight.w300,
                                height: 0.9,
                                letterSpacing: -2,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '°C',
                                style: TextStyle(
                                  color: themeProvider.getColor(
                                    'headerTextPrimary',
                                  ),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 天气描述
                        Text(
                          dailyWeather.weather_pm ?? '--',
                          style: TextStyle(
                            color: themeProvider.getColor(
                              'headerTextSecondary',
                            ),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 温度范围
                        Row(
                          children: [
                            Text(
                              '${dailyWeather.temperature_am}°',
                              style: TextStyle(
                                color: themeProvider.getColor(
                                  'headerTextSecondary',
                                ),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' ~ ',
                              style: TextStyle(
                                color: themeProvider.getColor(
                                  'headerTextSecondary',
                                ),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${dailyWeather.temperature_pm}°',
                              style: TextStyle(
                                color: themeProvider.getColor(
                                  'headerTextSecondary',
                                ),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 农历和节气信息
              _buildLunarAndSolarTerm(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建农历和节气信息
  Widget _buildLunarAndSolarTerm(BuildContext context) {
    try {
      final date = _parseDate(dailyWeather.forecasttime);
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(date);
      final themeProvider = context.read<ThemeProvider>();

      final tags = <Widget>[];

      // 农历日期
      tags.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              color: themeProvider.getColor('headerTextSecondary'),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              _formatLunarDate(lunarInfo.lunarMonth, lunarInfo.lunarDay),
              style: TextStyle(
                color: themeProvider.getColor('headerTextSecondary'),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );

      // 节气
      if (lunarInfo.solarTerm != null && lunarInfo.solarTerm!.isNotEmpty) {
        tags.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lunarInfo.solarTerm!,
              style: TextStyle(
                color: themeProvider.getColor('headerTextSecondary'),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      // 节日
      if (lunarInfo.festivals.isNotEmpty) {
        tags.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lunarInfo.festivals.first,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      return Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: tags,
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  /// 构建上午/下午详细信息
  Widget _buildTimePeriodDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenHorizontalPadding,
      ),
      child: Row(
        children: [
          // 上午
          Expanded(
            child: _buildPeriodCard(
              context,
              '上午',
              dailyWeather.weather_pm ?? '--',
              dailyWeather.temperature_pm ?? '--',
              dailyWeather.winddir_pm ?? '--',
              dailyWeather.windpower_pm ?? '--',
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          // 下午
          Expanded(
            child: _buildPeriodCard(
              context,
              '下午',
              dailyWeather.weather_am ?? '--',
              dailyWeather.temperature_am ?? '--',
              dailyWeather.winddir_am ?? '--',
              dailyWeather.windpower_am ?? '--',
              AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时段卡片
  Widget _buildPeriodCard(
    BuildContext context,
    String period,
    String weather,
    String temperature,
    String windDir,
    String windPower,
    Color accentColor,
  ) {
    // 判断是白天还是夜间（根据时段）
    // 注意：上午使用pm数据（夜间），下午使用am数据（白天）
    final isNight = period == '上午';

    // 获取中文天气图标路径
    String getChineseWeatherIcon(String weatherType, bool isNight) {
      final iconMap = isNight
          ? AppConstants.chineseNightWeatherImages
          : AppConstants.chineseWeatherImages;
      return iconMap[weatherType] ?? iconMap['晴'] ?? '晴.png';
    }

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // 时段标题（缩小）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8), // 标题和图标的间隙
            // 天气PNG图标（48px）
            Image.asset(
              'assets/images/${getChineseWeatherIcon(weather, isNight)}',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // 加载失败时显示默认图标
                return Image.asset(
                  'assets/images/不清楚.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                );
              },
            ),
            const SizedBox(height: 4), // 图标和天气描述的距离（更近）
            // 天气描述（再缩小）
            Text(
              weather,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2), // 天气和温度的距离（更近）
            // 温度（再缩小）
            Text(
              '$temperature℃',
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 风向风力
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.air, color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$windDir $windPower',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建农历信息卡片
  Widget _buildLunarInfoCard(BuildContext context) {
    try {
      final date = _parseDate(dailyWeather.forecasttime);
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(date);

      // LunarInfoWidget 内部已经有 padding，不需要外层再加
      return LunarInfoWidget(lunarInfo: lunarInfo);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  /// 格式化农历日期
  String _formatLunarDate(String lunarMonth, String lunarDay) {
    if (lunarMonth.contains('月')) {
      return '$lunarMonth$lunarDay';
    }
    return '$lunarMonth月$lunarDay';
  }

  /// 解析日期字符串
  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now().add(Duration(days: dayIndex));
    }
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now().add(Duration(days: dayIndex));
    }
  }

  /// 获取日期标签
  String _getDayLabel() {
    if (dayIndex == 0) return '今天';
    if (dayIndex == 1) return '明天';
    if (dayIndex == 2) return '后天';
    return '${dayIndex}天后';
  }

  /// 构建宜忌信息卡片
  Widget _buildYiJiInfo(BuildContext context) {
    try {
      final date = _parseDate(dailyWeather.forecasttime);
      final lunarService = LunarService.getInstance();
      final lunarInfo = lunarService.getLunarInfo(date);
      return YiJiWidget(lunarInfo: lunarInfo);
    } catch (e) {
      print('❌ 获取宜忌信息失败: $e');
      return const SizedBox.shrink();
    }
  }

  /// 构建即将到来的节气
  Widget _buildUpcomingSolarTerms(BuildContext context) {
    try {
      final lunarService = LunarService.getInstance();

      // 直接获取未来的节气（从当前日期开始）
      final upcomingTerms = lunarService.getUpcomingSolarTerms(days: 60);

      if (upcomingTerms.isEmpty) {
        return const SizedBox.shrink();
      }

      return SolarTermListWidget(solarTerms: upcomingTerms, title: '即将到来的节气');
    } catch (e) {
      print('❌ 获取节气信息失败: $e');
      return const SizedBox.shrink();
    }
  }
}
