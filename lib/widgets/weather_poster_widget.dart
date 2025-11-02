import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/sun_moon_index_model.dart';
import '../providers/theme_provider.dart';
import '../constants/app_constants.dart';

/// 天气海报组件
/// 用于生成分享的天气海报图片
class WeatherPosterWidget extends StatelessWidget {
  final WeatherModel weather;
  final LocationModel location;
  final ThemeProvider themeProvider;
  final SunMoonIndexData? sunMoonIndexData; // 可选的生活指数数据

  const WeatherPosterWidget({
    super.key,
    required this.weather,
    required this.location,
    required this.themeProvider,
    this.sunMoonIndexData, // 可选参数
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current?.current;
    final temperature = current?.temperature ?? '--';
    final weatherType = current?.weather ?? '--';
    final humidity = current?.humidity ?? '--';
    final windPower = current?.windpower ?? '--';
    final feelsLike = current?.feelstemperature ?? '--';
    final aqi = weather.current?.air?.AQI;
    final aqiLevel = weather.current?.air?.levelIndex ?? '--';

    // 获取今日温度范围（从15日预报）
    int tempHigh = 0;
    int tempLow = 0;
    if (weather.forecast15d != null && weather.forecast15d!.isNotEmpty) {
      final today = weather.forecast15d![0];
      final tempHighStr = today.temperature_am ?? '--';
      final tempLowStr = today.temperature_pm ?? '--';
      tempHigh = int.tryParse(tempHighStr) ?? 0;
      tempLow = int.tryParse(tempLowStr) ?? 0;
    }

    // 城市名称
    final cityName = location.district.isNotEmpty
        ? location.district
        : location.city;
    final provinceName = location.province;

    // 获取天气图片（优先使用旧图标，降级到中文PNG图标）
    final weatherImage = AppConstants.dayWeatherImages[weatherType];
    // 使用中文PNG图标作为备用
    final chineseWeatherIcon =
        AppConstants.chineseWeatherImages[weatherType] ??
        AppConstants.chineseWeatherImages['晴'] ??
        '晴.png';

    // 获取紫外线强度
    String uvLevel = _getUVLevel(sunMoonIndexData, weatherType);

    // 当前日期
    final now = DateTime.now();
    final dateStr = '${now.month}月${now.day}日';
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekDay = weekDays[now.weekday - 1];

    return Container(
      width: 375,
      height: 667, // 标准手机屏幕比例 (iPhone 8/SE)
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E88E5), // MD3: 鲜艳蓝色
            Color(0xFF1565C0), // MD3: 深蓝色
          ],
        ),
      ),
      child: Stack(
        children: [
          // MD3风格背景装饰
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 添加顶部装饰条
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFB74D).withOpacity(0.8), // 橙色
                    const ui.Color.fromARGB(
                      255,
                      233,
                      96,
                      204,
                    ).withOpacity(0.8), // 绿色
                    const ui.Color.fromARGB(
                      255,
                      17,
                      231,
                      82,
                    ).withOpacity(0.8), // 蓝色
                  ],
                ),
              ),
            ),
          ),

          // 主要内容
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 城市名称和日期
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 城市名称（彩虹渐变）
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFD700), // 金色
                                Color(0xFFFFFFFF), // 白色
                                Color(0xFF87CEEB), // 天蓝色
                              ],
                            ).createShader(bounds),
                            child: Text(
                              cityName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (provinceName.isNotEmpty &&
                              provinceName != cityName)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                provinceName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          weekDay,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 主要温度、天气图片和天气信息
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 左侧：天气图标和天气类型（横向排列）
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 天气图片（MD3风格）
                        Container(
                          width: 90,
                          height: 90,
                          padding: const EdgeInsets.all(10),
                          child: weatherImage != null
                              ? Image.asset(
                                  'assets/images/$weatherImage',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // 图片加载失败时显示中文PNG图标
                                    return Image.asset(
                                      'assets/images/$chineseWeatherIcon',
                                      fit: BoxFit.contain,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/$chineseWeatherIcon',
                                  fit: BoxFit.contain,
                                ),
                        ),
                        const SizedBox(width: 8),
                        // 天气类型（彩虹渐变）
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF87CEEB), // 天蓝色
                              Color(0xFFFFFFFF), // 白色
                              Color(0xFFFFD700), // 金色
                            ],
                          ).createShader(bounds),
                          child: Text(
                            weatherType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 右侧：温度和温度范围（横向排列）
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 温度（彩虹渐变）
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700), // 金色
                                  Color(0xFFFFFFFF), // 白色
                                  Color(0xFFFFB6C1), // 浅粉色
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                temperature,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  height: 0.9,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '℃',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // 温度范围（竖向排列）
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 最低温（向下箭头 + 白色）
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  weather.forecast15d != null &&
                                          weather.forecast15d!.isNotEmpty
                                      ? '${weather.forecast15d![0].temperature_pm ?? '--'}℃'
                                      : '--℃',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // 最高温（向上箭头 + 明亮橙色）
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: const Color(0xFFFFB74D), // 明亮橙色
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  weather.forecast15d != null &&
                                          weather.forecast15d!.isNotEmpty
                                      ? '${weather.forecast15d![0].temperature_am ?? '--'}℃'
                                      : '--℃',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB74D), // 明亮橙色
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(flex: 1), // 弹性间距，让内容均匀分布
                // AI智能助手卡片（琥珀金渐变毛玻璃）
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ui.Color.fromARGB(
                              255,
                              251,
                              176,
                              1,
                            ).withOpacity(0.85), // 琥珀金
                            ui.Color.fromARGB(
                              255,
                              251,
                              203,
                              120,
                            ).withOpacity(0.85), // 深琥珀金
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFFFD54F).withOpacity(0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6F00).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // AI图标（深色）
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.382),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.psychology,
                              color: ui.Color.fromARGB(255, 11, 2, 84), // 深棕色
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // AI建议文字（深色）
                          Expanded(
                            child: Text(
                              _generateAISummary(
                                weatherType: weatherType,
                                temperature: temperature,
                                humidity: humidity,
                                aqi: aqi,
                                tempHigh: tempHigh,
                                tempLow: tempLow,
                              ),
                              style: const TextStyle(
                                color: ui.Color.fromARGB(255, 42, 25, 0), // 深棕色
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFFFE082),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8), // 详细信息卡片前固定间距
                // 底部详细信息卡片（MD3风格 - 渐变背景）
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.95), // 高透白色
                        const ui.Color.fromARGB(
                          255,
                          237,
                          200,
                          148,
                        ).withOpacity(0.9), // 浅灰白色
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24), // MD3: 大圆角
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 空气质量（第一行）
                      _buildDetailRow(
                        Icons.eco,
                        '空气质量',
                        '$aqiLevel${aqi != null ? ' AQI $aqi' : ''}',
                        _getAQIDescription(aqi),
                        _getAQIColor(aqi),
                      ),

                      _buildDivider(),

                      // 体感温度（橙红色）
                      _buildDetailRow(
                        Icons.thermostat,
                        '体感温度',
                        '${int.tryParse(feelsLike) ?? feelsLike}℃',
                        _getFeelsLikeDescription(feelsLike, temperature),
                        const Color(0xFFFF6F00), // MD3: 鲜艳橙色
                      ),

                      _buildDivider(),

                      // 湿度（青色）
                      _buildDetailRow(
                        Icons.water_drop,
                        '相对湿度',
                        '$humidity%',
                        _getHumidityDescription(humidity),
                        const Color(0xFF00ACC1), // MD3: 鲜艳青色
                      ),

                      _buildDivider(),

                      // 风力（灰绿色）
                      _buildDetailRow(
                        Icons.air,
                        '风力风向',
                        windPower,
                        _getWindDescription(windPower),
                        const Color(0xFF66BB6A), // MD3: 鲜艳绿色
                      ),

                      _buildDivider(),

                      // 紫外线（金黄色）
                      _buildDetailRow(
                        Icons.wb_sunny,
                        '紫外线强度',
                        uvLevel,
                        _getUVDescription(uvLevel),
                        const Color(0xFFFFA000), // MD3: 鲜艳金色
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1), // 弹性间距，让品牌标识均匀分布
                // 底部品牌标识（无背景，更小）
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_queue,
                        color: Colors.white.withOpacity(0.9),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '智雨天气 · 精准预报 贴心提醒',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取紫外线强度等级
  String _getUVLevel(SunMoonIndexData? sunMoonData, String weatherType) {
    // 1. 优先从生活指数中获取紫外线数据
    if (sunMoonData?.index != null) {
      final uvIndex = sunMoonData!.index!.firstWhere(
        (item) => item.indexTypeCh == '紫外线强度指数',
        orElse: () => LifeIndex(),
      );
      if (uvIndex.indexLevel != null && uvIndex.indexLevel!.isNotEmpty) {
        return uvIndex.indexLevel!;
      }
    }

    // 2. 根据天气类型智能估算
    if (weatherType.contains('晴')) {
      return '强';
    } else if (weatherType.contains('多云') || weatherType == '少云') {
      return '中等';
    } else if (weatherType.contains('阴')) {
      return '弱';
    } else if (weatherType.contains('雨') ||
        weatherType.contains('雪') ||
        weatherType.contains('雾') ||
        weatherType.contains('霾')) {
      return '很弱';
    } else {
      return '中等';
    }
  }

  /// 构建详情行（MD3风格 - 优化渐变背景适配）
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    String description,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // MD3: 彩色图标背景（增强对比度）
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: iconColor.withOpacity(0.6), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF212121), // 更深的灰色
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF0D47A1), // 更深的蓝色
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF616161), // 深灰色
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分割线（MD3风格）
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Divider(color: Colors.grey[300], height: 1),
    );
  }

  /// 获取AQI颜色（MD3色彩系统）
  Color _getAQIColor(String? aqi) {
    if (aqi == null) return Colors.grey;
    final aqiValue = int.tryParse(aqi) ?? 0;
    if (aqiValue <= 50) {
      return const Color(0xFF2E7D32); // MD3: 深绿
    } else if (aqiValue <= 100) {
      return const Color(0xFF689F38); // MD3: 亮绿
    } else if (aqiValue <= 150) {
      return const Color(0xFFF57C00); // MD3: 橙色
    } else if (aqiValue <= 200) {
      return const Color(0xFFE53935); // MD3: 红色
    } else if (aqiValue <= 300) {
      return const Color(0xFFC62828); // MD3: 深红
    } else {
      return const Color(0xFF6A1B9A); // MD3: 紫色
    }
  }

  /// 获取空气质量描述
  String _getAQIDescription(String? aqi) {
    if (aqi == null) return '';
    final aqiValue = int.tryParse(aqi) ?? 0;
    if (aqiValue <= 50) {
      return '空气清新，适合户外活动';
    } else if (aqiValue <= 100) {
      return '空气质量良好，可正常活动';
    } else if (aqiValue <= 150) {
      return '敏感人群应减少户外活动';
    } else if (aqiValue <= 200) {
      return '建议减少户外活动';
    } else if (aqiValue <= 300) {
      return '避免户外活动，外出戴口罩';
    } else {
      return '严重污染，避免外出';
    }
  }

  /// 获取体感温度描述
  String _getFeelsLikeDescription(String feelsLike, String actualTemp) {
    final feels = int.tryParse(feelsLike) ?? 0;
    final actual = int.tryParse(actualTemp) ?? 0;
    final diff = feels - actual;

    if (diff > 3) {
      return '比实际温度感觉更热';
    } else if (diff < -3) {
      return '比实际温度感觉更冷';
    } else {
      return '与实际温度相近';
    }
  }

  /// 获取湿度描述
  String _getHumidityDescription(String humidity) {
    final humidityValue = int.tryParse(humidity) ?? 0;
    if (humidityValue >= 80) {
      return '湿度较大，体感闷热';
    } else if (humidityValue >= 60) {
      return '湿度适中，体感舒适';
    } else if (humidityValue >= 40) {
      return '湿度较低，体感干燥';
    } else {
      return '空气干燥，注意补水';
    }
  }

  /// 获取风力描述
  String _getWindDescription(String windPower) {
    if (windPower.contains('微风') ||
        windPower.contains('1级') ||
        windPower.contains('2级')) {
      return '微风轻拂，适合出行';
    } else if (windPower.contains('3级') || windPower.contains('4级')) {
      return '风力适中，注意保暖';
    } else if (windPower.contains('5级') || windPower.contains('6级')) {
      return '风力较大，小心行走';
    } else {
      return '大风天气，减少外出';
    }
  }

  /// 获取紫外线描述
  String _getUVDescription(String uvLevel) {
    if (uvLevel == '强' || uvLevel == '很强' || uvLevel == '极强') {
      return '紫外线强，需做好防晒';
    } else if (uvLevel == '中等') {
      return '适度防晒即可';
    } else {
      return '紫外线较弱，无需防晒';
    }
  }

  /// 生成AI智能摘要（详细版）
  String _generateAISummary({
    required String weatherType,
    required String temperature,
    required String humidity,
    required String? aqi,
    required int tempHigh,
    required int tempLow,
  }) {
    final temp = int.tryParse(temperature) ?? 20;
    final hum = int.tryParse(humidity) ?? 50;
    final aqiValue = int.tryParse(aqi ?? '50') ?? 50;
    final tempDiff = (tempHigh - tempLow).abs();

    List<String> parts = [];

    // 1. 天气状况描述
    if (weatherType.contains('晴')) {
      if (temp >= 30) {
        parts.add('今日晴空万里☀️，气温较高达${temperature}℃，体感炎热');
      } else if (temp >= 25) {
        parts.add('今日阳光明媚☀️，温度${temperature}℃，温暖舒适');
      } else if (temp >= 15) {
        parts.add('今日天气晴朗☀️，气温${temperature}℃，十分宜人');
      } else {
        parts.add('今日晴朗☀️但气温偏低${temperature}℃，需适当保暖');
      }
    } else if (weatherType.contains('雨')) {
      if (weatherType.contains('大雨') || weatherType.contains('暴雨')) {
        parts.add('今日有强降雨🌧️，出行务必带伞，路面积水注意安全');
      } else if (weatherType.contains('中雨')) {
        parts.add('今日有中雨🌧️，建议减少外出，出门记得带伞');
      } else {
        parts.add('今日有小雨🌧️，出行记得带伞，路面湿滑小心慢行');
      }
    } else if (weatherType.contains('雪')) {
      parts.add('今日降雪❄️，气温${temperature}℃，注意防寒保暖和出行安全');
    } else if (weatherType.contains('云') || weatherType.contains('阴')) {
      parts.add('今日多云转阴☁️，气温${temperature}℃，适合外出但建议备伞');
    } else {
      parts.add('今日天气${weatherType}，当前温度${temperature}℃');
    }

    // 2. 温差提醒
    if (tempDiff >= 15) {
      parts.add('昼夜温差高达${tempDiff}℃，早晚需及时增减衣物避免感冒');
    } else if (tempDiff >= 10) {
      parts.add('昼夜温差${tempDiff}℃较大，建议穿便于增减的分层衣物');
    }

    // 3. 空气质量建议
    if (aqiValue > 200) {
      parts.add('空气质量重度污染，强烈建议减少户外活动，外出必须佩戴N95口罩');
    } else if (aqiValue > 150) {
      parts.add('空气质量较差，建议减少户外活动，外出佩戴口罩做好防护');
    } else if (aqiValue > 100) {
      parts.add('空气质量一般，敏感人群如儿童老人应减少户外运动');
    } else if (aqiValue <= 50) {
      parts.add('空气清新质量优良，非常适合户外运动和深呼吸');
    }

    // 4. 湿度建议
    if (hum >= 80) {
      parts.add('空气湿度${hum}%偏高，体感闷热，注意室内通风除湿');
    } else if (hum <= 30) {
      parts.add('空气湿度${hum}%偏低较干燥，注意多喝水补充水分和皮肤保湿');
    }

    // 5. 综合出行建议
    if (weatherType.contains('晴') &&
        temp >= 20 &&
        temp <= 28 &&
        aqiValue <= 100) {
      parts.add('今日天气舒适宜人，是外出游玩、运动健身的好时机');
    } else if (temp >= 35) {
      parts.add('高温天气请避免在午后外出，做好防晒措施多喝水防中暑');
    } else if (temp <= 0) {
      parts.add('气温冰点以下，外出需穿厚实羽绒服，暴露部位注意防冻伤');
    }

    return '${parts.join('。')}。';
  }
}
