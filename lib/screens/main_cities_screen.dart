import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import '../models/city_model.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/location_change_notifier.dart';
import '../utils/city_name_matcher.dart';
import '../utils/weather_icon_helper.dart';
import '../widgets/city_card_skeleton.dart';
import 'city_weather_swipe_screen.dart';
import 'weather_alerts_screen.dart';

class MainCitiesScreen extends StatefulWidget {
  const MainCitiesScreen({super.key});

  @override
  State<MainCitiesScreen> createState() => _MainCitiesScreenState();
}

class _MainCitiesScreenState extends State<MainCitiesScreen>
    with LocationChangeListener, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 保持页面状态

  @override
  void initState() {
    super.initState();
    // 添加定位变化监听器
    LocationChangeNotifier().addListener(this);
    // 调试：打印当前监听器状态
    LocationChangeNotifier().debugPrintStatus();
  }

  @override
  void dispose() {
    // 移除定位变化监听器
    LocationChangeNotifier().removeListener(this);
    super.dispose();
  }

  /// 定位成功回调（主要城市页面不响应今日天气页面的定位）
  @override
  void onLocationSuccess(LocationModel newLocation) {
    print('📍 MainCitiesScreen: 收到定位成功通知 ${newLocation.district}');
    print('📍 MainCitiesScreen: 主要城市页面只响应自己的定位图标，忽略此通知');
    // 主要城市页面只有点击定位图标才会更新第一个卡片
  }

  /// 定位失败回调（主要城市页面不响应今日天气页面的定位失败）
  @override
  void onLocationFailed(String error) {
    print('❌ MainCitiesScreen: 收到定位失败通知 $error');
    print('❌ MainCitiesScreen: 主要城市页面只响应自己的定位图标，忽略此通知');
    // 主要城市页面只有点击定位图标失败时才提示
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持AutomaticKeepAlive
    // 使用Consumer监听主题变化，确保整个页面在主题切换时重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.screenBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '主要城市',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Consumer<WeatherProvider>(
                              builder: (context, weatherProvider, child) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showAddCityDialog(
                                        context,
                                        weatherProvider,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_location_alt_rounded,
                                            size: 18,
                                            color: AppColors.titleBarIconColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '添加城市',
                                            style: TextStyle(
                                              color:
                                                  AppColors.titleBarIconColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '长按拖拽可调整城市顺序，左滑可删除城市（当前位置城市除外）',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cities List
                  Expanded(
                    child: Consumer<WeatherProvider>(
                      builder: (context, weatherProvider, child) {
                        final cities = weatherProvider.mainCities;
                        final isLoading = weatherProvider.isLoadingCities;

                        // 首次进入主要城市列表时主动刷新天气数据
                        if (cities.isNotEmpty &&
                            !weatherProvider
                                .hasPerformedInitialMainCitiesRefresh) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            weatherProvider.performInitialMainCitiesRefresh();
                          });
                        }

                        // 首次加载（没有数据）：显示加载圈
                        if (isLoading && cities.isEmpty) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentBlue,
                            ),
                          );
                        }

                        // 刷新中（有数据）：显示骨架屏，避免页面抖动
                        if ((isLoading ||
                                weatherProvider.isLoadingCitiesWeather) &&
                            cities.isNotEmpty) {
                          return CityCardSkeletonList(itemCount: cities.length);
                        }

                        // 没有数据且不在加载：显示空状态
                        if (cities.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_city_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '暂无主要城市',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // 正常显示城市列表
                        return RefreshIndicator(
                          onRefresh: () async {
                            await weatherProvider.refreshMainCitiesWeather();
                          },
                          color: AppColors.primaryBlue,
                          backgroundColor: AppColors.backgroundSecondary,
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.screenHorizontalPadding,
                            ),
                            itemCount: cities.length,
                            // 移除固定高度，使用灵活布局
                            onReorder: (oldIndex, newIndex) async {
                              // Handle reordering
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }

                              // Get current location city name
                              final currentLocationName = weatherProvider
                                  .getCurrentLocationCityName();

                              // Don't allow reordering if trying to move current location
                              if (cities[oldIndex].name ==
                                  currentLocationName) {
                                return;
                              }

                              // Create new list with reordered cities
                              final List<CityModel> reorderedCities = List.from(
                                cities,
                              );
                              final city = reorderedCities.removeAt(oldIndex);
                              reorderedCities.insert(newIndex, city);

                              // Update sort order
                              await weatherProvider.updateCitiesSortOrder(
                                reorderedCities,
                              );
                            },
                            itemBuilder: (context, index) {
                              final city = cities[index];
                              final cityWeather = weatherProvider
                                  .getCityWeather(city.name);
                              // 判断是否是当前城市：名称匹配或者是虚拟当前城市
                              final currentLocationName = weatherProvider
                                  .getCurrentLocationCityName();
                              final isCurrentLocation =
                                  CityNameMatcher.isCurrentLocationCity(
                                    city.name,
                                    currentLocationName,
                                    city.id,
                                  );

                              // 使用 RepaintBoundary 隔离重绘区域，提升列表性能
                              return RepaintBoundary(
                                key: ValueKey('city_${city.id}_$index'),
                                child: Dismissible(
                                key: ValueKey(
                                  'dismissible_${city.id}_${city.name}_${index}',
                                ),
                                direction: isCurrentLocation
                                    ? DismissDirection.none
                                    : DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.error.withOpacity(0.8),
                                        AppColors.error,
                                      ],
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        color: AppColors.textPrimary,
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '删除城市',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondaryBackground: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.textSecondary.withOpacity(
                                          0.8,
                                        ),
                                        AppColors.textSecondary,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cancel_outlined,
                                        color: AppColors.textPrimary,
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '取消',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    // 禁止删除当前位置城市（因为它会自动重新出现）
                                    if (isCurrentLocation) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('当前位置城市无法删除'),
                                            backgroundColor:
                                                AppColors.textSecondary,
                                            duration: Duration(
                                              milliseconds: 1500,
                                            ),
                                          ),
                                        );
                                      }
                                      return false;
                                    }
                                    // 禁止删除虚拟当前城市
                                    if (city.id == 'virtual_current_location') {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('当前位置城市无法删除'),
                                            backgroundColor:
                                                AppColors.textSecondary,
                                            duration: Duration(
                                              milliseconds: 1500,
                                            ),
                                          ),
                                        );
                                      }
                                      return false;
                                    }
                                    return await _showDeleteCityDialog(
                                      context,
                                      weatherProvider,
                                      city,
                                    );
                                  }
                                  return false;
                                },
                                child: Padding(
                                  key: ValueKey(
                                    'padding_${city.id}_${city.name}_${index}',
                                  ),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    decoration: themeProvider.isLightTheme
                                        ? BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white,
                                                const Color(0xFFF5F5F5), // 淡灰色
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          )
                                        : null,
                                    child: Card(
                                      elevation: 0, // 去掉阴影效果
                                      shadowColor: Colors.transparent,
                                      // 亮色模式：透明背景（使用外层渐变）
                                      // 暗色模式：使用统一的卡片背景色
                                      color: themeProvider.isLightTheme
                                          ? Colors.transparent
                                          : AppColors.materialCardColor,
                                      shape: AppColors.cardShape,
                                      child: InkWell(
                                        onTap: () {
                                          // Navigate to city weather screen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CityWeatherSwipeScreen(
                                                    cityName: city.name,
                                                  ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Title
                                                    Row(
                                                      children: [
                                                        // 城市名称和定位图标
                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                city.name,
                                                                style: TextStyle(
                                                                  color: AppColors
                                                                      .textPrimary,
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              // 定位图标（如果是当前定位城市）
                                                              if (isCurrentLocation) ...[
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    onTap: () async {
                                                                      // 点击定位图标，更新当前位置数据
                                                                      await _updateCurrentLocation(
                                                                        context,
                                                                        weatherProvider,
                                                                      );
                                                                    },
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    child: Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        // 亮色模式：无背景色，暗色模式：绿色背景
                                                                        color:
                                                                            Provider.of<
                                                                                  ThemeProvider
                                                                                >(
                                                                                  context,
                                                                                  listen: false,
                                                                                )
                                                                                .isLightTheme
                                                                            ? const Color.fromARGB(
                                                                                30,
                                                                                3,
                                                                                113,
                                                                                1,
                                                                              )
                                                                            : const Color(
                                                                                0xFF64DD17,
                                                                              ).withOpacity(
                                                                                0.25,
                                                                              ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                        // 亮色模式：添加边框
                                                                        border:
                                                                            Provider.of<
                                                                                  ThemeProvider
                                                                                >(
                                                                                  context,
                                                                                  listen: false,
                                                                                )
                                                                                .isLightTheme
                                                                            ? Border.all(
                                                                                color: const Color.fromARGB(
                                                                                  255,
                                                                                  3,
                                                                                  113,
                                                                                  1,
                                                                                ),
                                                                                width: 1,
                                                                              )
                                                                            : null,
                                                                        // 参考详细信息卡片的阴影（亮色模式无阴影）
                                                                        boxShadow:
                                                                            Provider.of<
                                                                                  ThemeProvider
                                                                                >(
                                                                                  context,
                                                                                  listen: false,
                                                                                )
                                                                                .isLightTheme
                                                                            ? null
                                                                            : [
                                                                                BoxShadow(
                                                                                  color: Colors.black.withOpacity(
                                                                                    0.15,
                                                                                  ),
                                                                                  blurRadius: 6,
                                                                                  offset: const Offset(
                                                                                    0,
                                                                                    2,
                                                                                  ),
                                                                                  spreadRadius: 0,
                                                                                ),
                                                                              ],
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.my_location,
                                                                            // 参考详细信息卡片：亮色用绿色，暗色用白色
                                                                            color:
                                                                                Provider.of<
                                                                                      ThemeProvider
                                                                                    >(
                                                                                      context,
                                                                                      listen: false,
                                                                                    )
                                                                                    .isLightTheme
                                                                                ? const Color.fromARGB(
                                                                                    255,
                                                                                    3,
                                                                                    113,
                                                                                    1,
                                                                                  )
                                                                                : Colors.white,
                                                                            size:
                                                                                14,
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                6,
                                                                          ),
                                                                          Text(
                                                                            '当前位置',
                                                                            style: TextStyle(
                                                                              // 参考详细信息卡片：亮色用深蓝，暗色用白色
                                                                              color:
                                                                                  Provider.of<
                                                                                        ThemeProvider
                                                                                      >(
                                                                                        context,
                                                                                        listen: false,
                                                                                      )
                                                                                      .isLightTheme
                                                                                  ? const Color.fromARGB(
                                                                                      255,
                                                                                      3,
                                                                                      113,
                                                                                      1,
                                                                                    )
                                                                                  : Colors.white,
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        // 预警图标
                                                        _buildCityAlertIcon(
                                                          context,
                                                          cityWeather,
                                                          city.name,
                                                        ),
                                                      ],
                                                    ),
                                                    // Subtitle
                                                    if (cityWeather != null ||
                                                        weatherProvider
                                                            .isLoadingCitiesWeather)
                                                      const SizedBox(height: 8),
                                                    if (cityWeather != null)
                                                      _buildCityWeatherInfo(
                                                        cityWeather,
                                                        weatherProvider,
                                                      )
                                                    else if (weatherProvider
                                                        .isLoadingCitiesWeather)
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    AppColors
                                                                        .textSecondary,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            '加载中...',
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                            },
                          ),
                        );
                      },
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

  /// 构建城市气象预警图标（原始预警，来自天气API）
  Widget _buildCityAlertIcon(
    BuildContext context,
    dynamic cityWeather,
    String cityName,
  ) {
    if (cityWeather == null) {
      return const SizedBox.shrink();
    }

    // 获取气象预警（原始预警数据，来自天气API）
    final alerts = cityWeather.current?.alerts;

    // 过滤掉过期的预警
    final validAlerts = _filterExpiredAlerts(alerts);
    final hasValidAlerts = validAlerts.isNotEmpty;

    if (!hasValidAlerts) {
      return const SizedBox.shrink();
    }

    // Icon button without badge
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WeatherAlertsScreen(alerts: validAlerts),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8), // Material Design 3 标准
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// 过滤掉过期的气象预警
  List<WeatherAlert> _filterExpiredAlerts(List<WeatherAlert>? alerts) {
    if (alerts == null || alerts.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final validAlerts = <WeatherAlert>[];

    for (final alert in alerts) {
      // 检查预警是否有发布时间
      if (alert.publishTime == null || alert.publishTime!.isEmpty) {
        // 没有发布时间，保留
        validAlerts.add(alert);
        continue;
      }

      try {
        // 解析发布时间（格式如: "2025-10-10 08:00:00"）
        final publishTime = DateTime.parse(alert.publishTime!);

        // 预警有效期：发布后24小时内
        final expiryTime = publishTime.add(const Duration(hours: 24));

        if (now.isBefore(expiryTime)) {
          validAlerts.add(alert);
        } else {
          print('🗑️ 过滤过期预警: ${alert.type} (发布时间: ${alert.publishTime})');
        }
      } catch (e) {
        // 解析失败，保留该预警
        print('⚠️ 无法解析预警时间: ${alert.publishTime}，保留该预警');
        validAlerts.add(alert);
      }
    }

    return validAlerts;
  }

  Widget _buildCityWeatherInfo(
    dynamic cityWeather,
    WeatherProvider weatherProvider,
  ) {
    final current = cityWeather?.current?.current;
    if (current == null) return const SizedBox.shrink();

    final weatherDesc = current.weather ?? '晴';
    final temperature = current.temperature ?? '--';
    final feelsLike = current.feelstemperature;

    // 获取空气质量数据
    final air = cityWeather?.current?.air ?? cityWeather?.air;
    final aqi = air != null ? int.tryParse(air.AQI ?? '') : null;

    // 判断是白天还是夜间
    final isDay = weatherProvider.isDayTime();

    // 获取主题
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // 第一列：天气图标
          SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: WeatherIconHelper.buildWeatherIcon(
                weatherDesc,
                !isDay,
                58,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 第二列：温度信息
          SizedBox(
            width: 80,
            height: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 温度
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      temperature,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '℃',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                // 体感温度
                if (feelsLike != null && feelsLike != temperature)
                  Text(
                    '体感 $feelsLike℃',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 第三列：天气详情
          Expanded(
            child: SizedBox(
              height: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 天气描述
                  Text(
                    weatherDesc,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 风力和湿度
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 风力
                      if (current.windpower != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.air,
                              size: 10,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '${current.winddir ?? ''}${current.windpower}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      // 湿度
                      if (current.humidity != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 10,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${current.humidity}%',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 第四列：AQI
          if (aqi != null)
            SizedBox(
              width: 65,
              height: 64,
              child: Transform.translate(
                offset: const Offset(0, -2), // 向上偏移2px，产生浮动感
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.isLightTheme
                        ? WeatherIconHelper.getAirQualityColor(
                            aqi,
                          ) // 亮色模式：AQI原色背景（dark效果）
                        : WeatherIconHelper.getAirQualityColor(
                            aqi,
                          ).withOpacity(0.3), // 暗色模式：半透明背景
                    borderRadius: BorderRadius.circular(6),
                    // 添加浮动阴影效果
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isLightTheme
                            ? Colors.black.withOpacity(0.15)
                            : Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                      // 添加内阴影增强立体感
                      BoxShadow(
                        color: themeProvider.isLightTheme
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        offset: const Offset(0, -1),
                        blurRadius: 2,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'AQI',
                        style: TextStyle(
                          color: themeProvider.isLightTheme
                              ? Colors.white
                              : WeatherIconHelper.getAirQualityColor(aqi),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          shadows: themeProvider.isLightTheme
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 0.5),
                                    blurRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$aqi',
                        style: TextStyle(
                          color: themeProvider.isLightTheme
                              ? Colors.white
                              : WeatherIconHelper.getAirQualityColor(aqi),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          shadows: themeProvider.isLightTheme
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 0.5),
                                    blurRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        WeatherIconHelper.getAirQualityLevelText(aqi),
                        style: TextStyle(
                          color: themeProvider.isLightTheme
                              ? Colors.white
                              : WeatherIconHelper.getAirQualityColor(aqi),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          shadows: themeProvider.isLightTheme
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 0.5),
                                    blurRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Show add city dialog
  void _showAddCityDialog(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) async {
    showDialog(
      context: context,
      builder: (context) => _AddCityDialog(weatherProvider: weatherProvider),
    );
  }

  /// 更新当前位置数据
  Future<void> _updateCurrentLocation(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) async {
    try {
      print('📍 点击定位图标，开始定位并更新第一个卡片');

      // 只定位并更新第一个卡片（当前定位城市）
      final success = await weatherProvider
          .refreshFirstCityLocationAndWeather();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '定位成功，已更新为 ${weatherProvider.currentLocation?.district ?? "当前位置"}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('定位失败，保持显示之前的数据'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 更新位置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('定位失败，保持显示原有数据'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteCityDialog(
    BuildContext context,
    WeatherProvider weatherProvider,
    CityModel city,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundSecondary,
            shape: AppColors.dialogShape,
            title: Text('删除城市', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              '确定要从主要城市中删除 "${city.name}" 吗？',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                  final success = await weatherProvider.removeMainCity(city.id);
                  if (success && context.mounted) {
                    // 使用Toast显示删除成功信息
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已删除城市: ${city.name}'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(milliseconds: 1500),
                      ),
                    );
                  } else if (context.mounted) {
                    // 删除失败也显示Toast
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('删除城市失败，请重试'),
                        backgroundColor: AppColors.error,
                        duration: Duration(milliseconds: 1500),
                      ),
                    );
                  }
                },
                child: Text('删除', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Add City Dialog Widget
class _AddCityDialog extends StatefulWidget {
  final WeatherProvider weatherProvider;

  const _AddCityDialog({required this.weatherProvider});

  @override
  State<_AddCityDialog> createState() => _AddCityDialogState();
}

class _AddCityDialogState extends State<_AddCityDialog> {
  final TextEditingController searchController = TextEditingController();
  List<CityModel> searchResults = [];
  bool isSearching = false;
  bool isInitialLoading = true;

  // 直辖市和省会城市列表
  final defaultCityNames = [
    '北京', '上海', '天津', '重庆', // 直辖市
    '哈尔滨', '长春', '沈阳', '呼和浩特', '石家庄', '太原', '西安', // 北方省会
    '济南', '郑州', '南京', '武汉', '杭州', '合肥', '福州', '南昌', // 中部省会
    '长沙', '贵阳', '成都', '广州', '昆明', '南宁', '海口', // 南方省会
    '兰州', '西宁', '银川', '乌鲁木齐', '拉萨', // 西部省会
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultCities();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// 预加载默认城市
  Future<void> _loadDefaultCities() async {
    setState(() {
      isInitialLoading = true;
    });

    final allDefaultCities = <CityModel>[];
    for (final cityName in defaultCityNames) {
      final results = await widget.weatherProvider.searchCities(cityName);
      if (results.isNotEmpty) {
        // 找到精确匹配的城市
        final exactMatch = results.firstWhere(
          (city) => city.name == cityName,
          orElse: () => results.first,
        );
        allDefaultCities.add(exactMatch);
      }
    }

    if (mounted) {
      setState(() {
        searchResults = allDefaultCities;
        isInitialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Material Design 3: 弹窗样式
      backgroundColor: AppColors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 3,
      icon: Icon(
        Icons.add_location_alt_rounded,
        color: AppColors.accentGreen,
        size: 32,
      ),
      title: Column(
        children: [
          Text(
            '添加城市',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '直辖市 · 省会',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // 固定高度防止溢出
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: '搜索城市名称（如：北京、上海）',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                filled: true,
                fillColor: AppColors.borderColor.withOpacity(0.05),
                // Material Design 3: 更大的圆角
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  setState(() {
                    isSearching = true;
                  });
                  final results = await widget.weatherProvider.searchCities(
                    value,
                  );
                  if (mounted) {
                    setState(() {
                      searchResults = results;
                      isSearching = false;
                    });
                  }
                } else {
                  // 恢复显示默认城市
                  _loadDefaultCities();
                }
              },
            ),
            const SizedBox(height: 16),
            if (isInitialLoading || isSearching)
              Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              )
            else if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: searchResults.length,
                  itemExtent: 60.0, // 固定搜索项目高度，提高滚动性能
                  itemBuilder: (context, index) {
                    final city = searchResults[index];
                    final isMainCity = widget.weatherProvider.mainCities.any(
                      (c) => c.id == city.id,
                    );

                    // Material Design 3: 列表项样式
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isMainCity
                            ? AppColors.accentGreen.withOpacity(0.15)
                            : AppColors.borderColor.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMainCity
                              ? AppColors.accentGreen
                              : AppColors.borderColor.withOpacity(0.2),
                          width: isMainCity ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Row(
                          children: [
                            Text(
                              city.name,
                              style: TextStyle(
                                color: isMainCity
                                    ? AppColors.accentGreen
                                    : AppColors.textPrimary,
                                fontWeight: isMainCity
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              city.id,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: isMainCity
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accentGreen,
                                size: 22,
                              )
                            : Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                        onTap: isMainCity
                            ? null
                            : () async {
                                final success = await widget.weatherProvider
                                    .addMainCity(city);
                                if (success) {
                                  // 刷新UI显示已添加状态
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  // 显示添加成功提示（在弹窗内使用轻量级提示）
                                } else {
                                  // 显示添加失败提示
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('添加城市失败，请重试'),
                                        backgroundColor: AppColors.error,
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    );
                  },
                ),
              )
            else if (searchController.text.isEmpty && searchResults.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '正在加载城市列表...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )
            else if (searchController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '未找到匹配的城市',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
