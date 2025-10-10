import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_alert_model.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import 'notification_service.dart';
import 'ai_service.dart';

/// 天气提醒服务
class WeatherAlertService {
  static WeatherAlertService? _instance;
  static WeatherAlertService get instance =>
      _instance ??= WeatherAlertService._();

  WeatherAlertService._();

  // 存储键
  static const String _alertsKey = 'weather_alerts';
  static const String _settingsKey = 'weather_alert_settings';

  // 提醒设置
  WeatherAlertSettings _settings = WeatherAlertSettings();

  // 当前提醒列表
  List<WeatherAlertModel> _alerts = [];

  // 通知服务
  final NotificationService _notificationService = NotificationService.instance;

  // AI服务
  final AIService _aiService = AIService();

  /// 获取提醒设置
  WeatherAlertSettings get settings => _settings;

  /// 获取当前提醒列表
  List<WeatherAlertModel> get alerts =>
      _alerts.where((alert) => alert.shouldShow).toList();

  /// 获取指定城市的提醒列表（支持区县和市的灵活匹配）
  List<WeatherAlertModel> getAlertsForCity(
    String cityName, [
    LocationModel? location,
  ]) {
    return _alerts.where((alert) {
      if (!alert.shouldShow) return false;

      // 使用城市匹配逻辑
      return _isCityMatch(alert.cityName, cityName, location);
    }).toList();
  }

  /// 获取必须提醒（一档）
  List<WeatherAlertModel> get requiredAlerts =>
      _alerts.where((alert) => alert.isRequired && alert.shouldShow).toList();

  /// 获取场景提醒（二档）
  List<WeatherAlertModel> get scenarioAlerts => _alerts
      .where((alert) => alert.isScenarioBased && alert.shouldShow)
      .toList();

  /// 初始化服务
  Future<void> initialize() async {
    await _loadSettings();
    await _loadAlerts();
    // 初始化通知服务
    await _notificationService.initialize();
    await _notificationService.createNotificationChannels();
  }

  /// 加载提醒设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = WeatherAlertSettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('加载天气提醒设置失败: $e');
    }
  }

  /// 保存提醒设置
  Future<void> saveSettings(WeatherAlertSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
      _settings = settings;
    } catch (e) {
      print('保存天气提醒设置失败: $e');
    }
  }

  /// 加载提醒列表
  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsKey);
      if (alertsJson != null) {
        final alertsList = jsonDecode(alertsJson) as List<dynamic>;
        _alerts = alertsList
            .map(
              (alertJson) =>
                  WeatherAlertModel.fromJson(alertJson as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      print('加载天气提醒列表失败: $e');
    }
  }

  /// 保存提醒列表
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = jsonEncode(
        _alerts.map((alert) => alert.toJson()).toList(),
      );
      await prefs.setString(_alertsKey, alertsJson);
    } catch (e) {
      print('保存天气提醒列表失败: $e');
    }
  }

  /// 分析天气数据并生成提醒
  Future<List<WeatherAlertModel>> analyzeWeather(
    WeatherModel weather,
    LocationModel location,
  ) async {
    final newAlerts = <WeatherAlertModel>[];
    final current = weather.current?.current;

    if (current == null) return newAlerts;

    final cityName = _getCityName(location);
    final now = DateTime.now();

    print('\n🔍 开始分析天气生成提醒 - 城市: $cityName');

    // 分析当前天气
    final currentWeatherAlerts = await _analyzeCurrentWeather(
      current,
      cityName,
      now,
    );
    newAlerts.addAll(currentWeatherAlerts);
    print('✅ 当前天气提醒: ${currentWeatherAlerts.length}条');

    // 分析24小时预报
    final hourlyAlerts = await _analyzeHourlyForecast(
      weather.forecast24h,
      cityName,
      now,
    );
    newAlerts.addAll(hourlyAlerts);
    print('✅ 24小时预报提醒: ${hourlyAlerts.length}条');

    // 分析15天预报
    final dailyAlerts = await _analyzeDailyForecast(
      weather.forecast15d,
      cityName,
      now,
    );
    newAlerts.addAll(dailyAlerts);
    print('✅ 15天预报提醒: ${dailyAlerts.length}条');

    // 分析空气质量
    final airQualityAlerts = _analyzeAirQuality(
      weather.current?.air ?? weather.air,
      cityName,
      now,
    );
    newAlerts.addAll(airQualityAlerts);

    // 清理同一城市的旧提醒（避免不同城市的提醒混合）
    _cleanupCityAlerts(cityName);

    // 过滤重复提醒
    final filteredAlerts = _filterDuplicateAlerts(newAlerts);

    // 添加到提醒列表
    _alerts.addAll(filteredAlerts);

    // 清理过期提醒
    _cleanupExpiredAlerts();

    // 保存提醒列表
    await _saveAlerts();

    // 发送通知
    if (filteredAlerts.isNotEmpty) {
      await _notificationService.sendWeatherAlertNotifications(filteredAlerts);
    }

    return filteredAlerts;
  }

  /// 分析当前天气
  Future<List<WeatherAlertModel>> _analyzeCurrentWeather(
    CurrentWeather current,
    String cityName,
    DateTime now,
  ) async {
    final alerts = <WeatherAlertModel>[];
    final weather = current.weather ?? '';

    // 获取对应的提醒规则
    final rules = _getWeatherAlertRules(weather);

    for (final rule in rules) {
      // 检查是否应该生成提醒
      if (_shouldGenerateAlert(rule, current, now)) {
        var alert = _createAlertFromRule(rule, current, cityName, now);

        // 使用AI增强提醒内容（仅针对重要提醒）
        if (rule.isRequired || rule.level == WeatherAlertLevel.red) {
          final timeInfo = '当前时间';
          final enhancedContent = await _enhanceAlertWithAI(
            weatherTerm: rule.weatherTerm,
            cityName: cityName,
            timeInfo: timeInfo,
            level: rule.level,
            isRequired: rule.isRequired,
          );

          if (enhancedContent != null) {
            alert = alert.copyWith(content: enhancedContent);
          }
        }

        alerts.add(alert);
      }
    }
    return alerts;
  }

  /// 分析24小时预报
  Future<List<WeatherAlertModel>> _analyzeHourlyForecast(
    List<HourlyWeather>? hourlyForecast,
    String cityName,
    DateTime now,
  ) async {
    final alerts = <WeatherAlertModel>[];

    if (hourlyForecast == null || hourlyForecast.isEmpty) return alerts;

    // 检查未来12小时的天气变化
    final relevantHours = hourlyForecast.take(12).toList();

    for (final hour in relevantHours) {
      final weather = hour.weather ?? '';
      final rules = _getWeatherAlertRules(weather);

      for (final rule in rules) {
        // 场景提醒：检查是否在通勤时间
        if (rule.isScenarioBased && _isCommuteTime(now)) {
          var alert = _createHourlyAlertFromRule(rule, hour, cityName, now);

          // 使用AI增强通勤时段的提醒内容
          final timeInfo = hour.forecasttime ?? '未来时段';
          final enhancedContent = await _enhanceAlertWithAI(
            weatherTerm: rule.weatherTerm,
            cityName: cityName,
            timeInfo: timeInfo,
            level: rule.level,
            isRequired: rule.isRequired,
          );

          if (enhancedContent != null) {
            alert = alert.copyWith(content: enhancedContent);
          }

          alerts.add(alert);
        }
      }
    }

    return alerts;
  }

  /// 分析15天预报
  Future<List<WeatherAlertModel>> _analyzeDailyForecast(
    List<DailyWeather>? dailyForecast,
    String cityName,
    DateTime now,
  ) async {
    final alerts = <WeatherAlertModel>[];

    if (dailyForecast == null || dailyForecast.isEmpty) return alerts;

    // 检查未来3天的天气
    final relevantDays = dailyForecast.take(3).toList();

    for (final day in relevantDays) {
      // 检查上午和下午天气
      final amWeather = day.weather_am ?? '';
      final pmWeather = day.weather_pm ?? '';

      final amRules = _getWeatherAlertRules(amWeather);
      final pmRules = _getWeatherAlertRules(pmWeather);

      for (final rule in amRules) {
        if (rule.isRequired) {
          var alert = _createDailyAlertFromRule(rule, day, cityName, now, true);

          // 对严重天气使用AI增强
          if (rule.level == WeatherAlertLevel.red) {
            final dateStr = day.forecasttime ?? '未来';
            final enhancedContent = await _enhanceAlertWithAI(
              weatherTerm: rule.weatherTerm,
              cityName: cityName,
              timeInfo: '$dateStr 上午',
              level: rule.level,
              isRequired: rule.isRequired,
            );

            if (enhancedContent != null) {
              alert = alert.copyWith(content: enhancedContent);
            }
          }

          alerts.add(alert);
        }
      }

      for (final rule in pmRules) {
        if (rule.isRequired) {
          var alert = _createDailyAlertFromRule(
            rule,
            day,
            cityName,
            now,
            false,
          );

          // 对严重天气使用AI增强
          if (rule.level == WeatherAlertLevel.red) {
            final dateStr = day.forecasttime ?? '未来';
            final enhancedContent = await _enhanceAlertWithAI(
              weatherTerm: rule.weatherTerm,
              cityName: cityName,
              timeInfo: '$dateStr 下午',
              level: rule.level,
              isRequired: rule.isRequired,
            );

            if (enhancedContent != null) {
              alert = alert.copyWith(content: enhancedContent);
            }
          }

          alerts.add(alert);
        }
      }
    }

    return alerts;
  }

  /// 分析空气质量
  List<WeatherAlertModel> _analyzeAirQuality(
    AirQuality? air,
    String cityName,
    DateTime now,
  ) {
    final alerts = <WeatherAlertModel>[];

    if (air == null || !_settings.enableAirQualityAlerts) return alerts;

    final aqi = int.tryParse(air.AQI ?? '');
    if (aqi == null) return alerts;

    // 检查空气质量是否超过阈值
    if (aqi >= _settings.airQualityThreshold) {
      final level = _getAirQualityLevel(aqi);
      // 使用日期作为ID的一部分
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final alert = WeatherAlertModel(
        id: 'air_quality_${cityName}_$dateStr',
        title: '空气质量提醒',
        content: '当前空气质量指数为${aqi}，属于${level}，建议减少户外活动',
        level: aqi >= 200 ? WeatherAlertLevel.red : WeatherAlertLevel.yellow,
        type: WeatherAlertType.airQuality,
        isRequired: aqi >= 200,
        isScenarioBased: aqi < 200,
        threshold: 'AQI ≥ ${_settings.airQualityThreshold}',
        weatherTerm: '空气质量',
        reason: 'PM2.5浓度过高，对健康有影响',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 6)),
        cityName: cityName,
        priority: aqi >= 200 ? 1 : 3,
      );
      alerts.add(alert);
    }

    return alerts;
  }

  /// 获取天气提醒规则
  List<WeatherAlertRule> _getWeatherAlertRules(String weather) {
    final rules = <WeatherAlertRule>[];

    // 一档：必须提醒（红色预警/危险）
    if (weather.contains('暴雨') ||
        weather.contains('大暴雨') ||
        weather.contains('特大暴雨')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.red,
          isRequired: true,
          isScenarioBased: false,
          threshold: '≥橙色预警',
          reason: '城市内涝、地铁停运',
          type: WeatherAlertType.rain,
          priority: 1,
        ),
      );
    }

    if (weather.contains('暴雪')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.red,
          isRequired: true,
          isScenarioBased: false,
          threshold: '≥橙色预警',
          reason: '道路结冰、高速封路',
          type: WeatherAlertType.snow,
          priority: 1,
        ),
      );
    }

    if (weather.contains('沙尘暴') || weather.contains('强沙尘暴')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.red,
          isRequired: true,
          isScenarioBased: false,
          threshold: '≥黄色预警',
          reason: '能见度 <200 m，呼吸系统风险',
          type: WeatherAlertType.dust,
          priority: 1,
        ),
      );
    }

    if (weather.contains('冰雹') || weather.contains('雨凇')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.red,
          isRequired: true,
          isScenarioBased: false,
          threshold: '只要发布',
          reason: '砸车、砸伤人',
          type: WeatherAlertType.hail,
          priority: 1,
        ),
      );
    }

    if (weather.contains('霾') &&
        (weather.contains('中度') ||
            weather.contains('重度') ||
            weather.contains('严重'))) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.red,
          isRequired: true,
          isScenarioBased: false,
          threshold: '≥中度霾',
          reason: 'PM2.5>150，健康风险',
          type: WeatherAlertType.fog,
          priority: 1,
        ),
      );
    }

    if (weather.contains('冻雨')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.red,
          isRequired: true,
          isScenarioBased: false,
          threshold: '只要发布',
          reason: '电线/路面结冰，极易翻车',
          type: WeatherAlertType.rain,
          priority: 1,
        ),
      );
    }

    // 二档：看场景提醒（黄色预警/出行高峰）
    if (weather.contains('大雨') || weather.contains('雷阵雨')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.yellow,
          isRequired: false,
          isScenarioBased: true,
          threshold: '≥黄色预警',
          reason: '影响出行安全',
          scenario: '下班高峰+红色拥堵路段',
          type: WeatherAlertType.rain,
          priority: 3,
        ),
      );
    }

    if (weather.contains('雾') ||
        weather.contains('浓雾') ||
        weather.contains('强浓雾')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.yellow,
          isRequired: false,
          isScenarioBased: true,
          threshold: '能见度 <500 m',
          reason: '能见度低，影响出行',
          scenario: '机场/高速出行前',
          type: WeatherAlertType.fog,
          priority: 3,
        ),
      );
    }

    if (weather.contains('雨夹雪') || weather.contains('雨雪天气')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.yellow,
          isRequired: false,
          isScenarioBased: true,
          threshold: '≥小雨量级',
          reason: '路面湿滑，影响出行',
          scenario: '早晨通勤',
          type: WeatherAlertType.snow,
          priority: 3,
        ),
      );
    }

    if (weather.contains('浮尘') || weather.contains('扬沙')) {
      rules.add(
        WeatherAlertRule(
          weatherTerm: weather,
          level: WeatherAlertLevel.yellow,
          isRequired: false,
          isScenarioBased: true,
          threshold: '≥黄色预警',
          reason: '空气质量差，影响呼吸',
          scenario: '儿童/老人外出',
          type: WeatherAlertType.dust,
          priority: 3,
        ),
      );
    }

    return rules;
  }

  /// 判断是否应该生成提醒
  bool _shouldGenerateAlert(
    WeatherAlertRule rule,
    CurrentWeather current,
    DateTime now,
  ) {
    // 检查设置
    if (rule.isRequired && !_settings.enableRequiredAlerts) return false;
    if (rule.isScenarioBased && !_settings.enableScenarioAlerts) return false;

    // 场景提醒需要检查通勤时间
    if (rule.isScenarioBased) {
      return _isCommuteTime(now);
    }

    return true;
  }

  /// 判断是否在通勤时间
  bool _isCommuteTime(DateTime now) {
    if (!_settings.enableCommuteAlerts) return false;
    return _settings.commuteTime.isCommuteTime(now);
  }

  /// 使用AI优化提醒内容
  Future<String?> _enhanceAlertWithAI({
    required String weatherTerm,
    required String cityName,
    required String timeInfo,
    required WeatherAlertLevel level,
    required bool isRequired,
  }) async {
    try {
      final levelName = level == WeatherAlertLevel.red
          ? '红色预警（危险）'
          : level == WeatherAlertLevel.yellow
          ? '黄色预警（警告）'
          : '蓝色预警（提示）';

      final prompt = _aiService.buildWeatherAlertPrompt(
        weatherTerm: weatherTerm,
        cityName: cityName,
        timeInfo: timeInfo,
        alertLevel: levelName,
        isRequired: isRequired,
      );

      final aiResponse = await _aiService.generateSmartAdvice(prompt);

      if (aiResponse != null && aiResponse.isNotEmpty) {
        final enhancedContent = _aiService.parseAlertText(aiResponse);
        if (enhancedContent != null && enhancedContent.isNotEmpty) {
          print('✅ AI增强提醒内容成功: $enhancedContent');
          return enhancedContent;
        }
      }

      return null;
    } catch (e) {
      print('⚠️ AI增强提醒失败，使用默认内容: $e');
      return null;
    }
  }

  /// 从规则创建提醒
  WeatherAlertModel _createAlertFromRule(
    WeatherAlertRule rule,
    CurrentWeather current,
    String cityName,
    DateTime now,
  ) {
    // 使用日期作为ID的一部分，同一天同一城市的相同提醒只生成一次
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return WeatherAlertModel(
      id: '${rule.type.toString()}_${rule.weatherTerm}_${cityName}_$dateStr',
      title: '${rule.weatherTerm}提醒',
      content: _generateAlertContent(rule, current),
      level: rule.level,
      type: rule.type,
      isRequired: rule.isRequired,
      isScenarioBased: rule.isScenarioBased,
      scenario: rule.scenario,
      threshold: rule.threshold,
      weatherTerm: rule.weatherTerm,
      reason: rule.reason,
      createdAt: now,
      expiresAt: now.add(Duration(hours: rule.isRequired ? 12 : 6)),
      cityName: cityName,
      priority: rule.priority,
    );
  }

  /// 从规则创建小时预报提醒
  WeatherAlertModel _createHourlyAlertFromRule(
    WeatherAlertRule rule,
    HourlyWeather hour,
    String cityName,
    DateTime now,
  ) {
    // 使用日期和小时作为ID的一部分
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final hourStr = hour.forecasttime ?? 'unknown';
    return WeatherAlertModel(
      id: 'hourly_${rule.type.toString()}_${rule.weatherTerm}_${cityName}_${dateStr}_$hourStr',
      title: '未来${hour.forecasttime}${rule.weatherTerm}提醒',
      content: _generateHourlyAlertContent(rule, hour),
      level: rule.level,
      type: rule.type,
      isRequired: rule.isRequired,
      isScenarioBased: rule.isScenarioBased,
      scenario: rule.scenario,
      threshold: rule.threshold,
      weatherTerm: rule.weatherTerm,
      reason: rule.reason,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 6)),
      cityName: cityName,
      priority: rule.priority,
    );
  }

  /// 从规则创建每日预报提醒
  WeatherAlertModel _createDailyAlertFromRule(
    WeatherAlertRule rule,
    DailyWeather day,
    String cityName,
    DateTime now,
    bool isAm,
  ) {
    final timeStr = isAm ? '上午' : '下午';
    // 使用日期和时段作为ID的一部分
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final dayStr = day.forecasttime ?? day.week ?? 'unknown';

    return WeatherAlertModel(
      id: 'daily_${rule.type.toString()}_${rule.weatherTerm}_${cityName}_${dateStr}_${dayStr}_$timeStr',
      title: '未来${timeStr}${rule.weatherTerm}提醒',
      content: _generateDailyAlertContent(rule, day, isAm),
      level: rule.level,
      type: rule.type,
      isRequired: rule.isRequired,
      isScenarioBased: rule.isScenarioBased,
      scenario: rule.scenario,
      threshold: rule.threshold,
      weatherTerm: rule.weatherTerm,
      reason: rule.reason,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      cityName: cityName,
      priority: rule.priority,
    );
  }

  /// 生成提醒内容
  String _generateAlertContent(WeatherAlertRule rule, CurrentWeather current) {
    final temp = current.temperature ?? '--';
    final wind = '${current.winddir ?? '--'} ${current.windpower ?? ''}';

    return '${rule.weatherTerm}天气，当前温度${temp}℃，${wind}。${rule.reason}，请${rule.isRequired ? '务必' : '注意'}${_getAlertAction(rule)}。';
  }

  /// 生成小时预报提醒内容
  String _generateHourlyAlertContent(
    WeatherAlertRule rule,
    HourlyWeather hour,
  ) {
    final time = hour.forecasttime ?? '未来';
    final temp = hour.temperature ?? '--';

    return '预计${time}将有${rule.weatherTerm}，温度${temp}℃。${rule.reason}，${rule.scenario != null ? '特别是${rule.scenario}时' : ''}请注意${_getAlertAction(rule)}。';
  }

  /// 生成每日预报提醒内容
  String _generateDailyAlertContent(
    WeatherAlertRule rule,
    DailyWeather day,
    bool isAm,
  ) {
    final timeStr = isAm ? '上午' : '下午';
    final temp = isAm ? day.temperature_am : day.temperature_pm;

    return '预计未来${timeStr}将有${rule.weatherTerm}，温度${temp ?? '--'}℃。${rule.reason}，请${_getAlertAction(rule)}。';
  }

  /// 获取提醒动作
  String _getAlertAction(WeatherAlertRule rule) {
    switch (rule.type) {
      case WeatherAlertType.rain:
        return '携带雨具，注意交通安全';
      case WeatherAlertType.snow:
        return '注意防滑保暖，谨慎驾驶';
      case WeatherAlertType.fog:
        return '减少户外活动，出行注意安全';
      case WeatherAlertType.dust:
        return '佩戴口罩，减少户外活动';
      case WeatherAlertType.hail:
        return '避免外出，保护车辆';
      case WeatherAlertType.temperature:
        return '适当增减衣物';
      case WeatherAlertType.visibility:
        return '谨慎驾驶，注意安全';
      case WeatherAlertType.airQuality:
        return '减少户外活动';
      default:
        return '做好防护措施';
    }
  }

  /// 获取城市名称
  String _getCityName(LocationModel location) {
    // 优先使用区/县，再用市，最后用省
    if (location.district.isNotEmpty && location.district != '未知') {
      return location.district;
    } else if (location.city.isNotEmpty && location.city != '未知') {
      return location.city;
    } else if (location.province.isNotEmpty && location.province != '未知') {
      return location.province;
    } else {
      return '当前位置';
    }
  }

  /// 判断两个城市名称是否匹配（考虑区县和市的关系）
  bool _isCityMatch(
    String cityName,
    String targetCity,
    LocationModel? location,
  ) {
    // 完全匹配
    if (cityName == targetCity) {
      return true;
    }

    // 如果location提供了，检查区县和市的关系
    if (location != null) {
      // 如果cityName是区县，targetCity是市（或反过来）
      if ((cityName == location.district && targetCity == location.city) ||
          (cityName == location.city && targetCity == location.district)) {
        return true;
      }

      // 同时检查省份
      if ((cityName == location.district && targetCity == location.province) ||
          (cityName == location.province && targetCity == location.district) ||
          (cityName == location.city && targetCity == location.province) ||
          (cityName == location.province && targetCity == location.city)) {
        return true;
      }
    }

    return false;
  }

  /// 获取空气质量等级
  String _getAirQualityLevel(int aqi) {
    if (aqi <= 50) return '优';
    if (aqi <= 100) return '良';
    if (aqi <= 150) return '轻度污染';
    if (aqi <= 200) return '中度污染';
    if (aqi <= 300) return '重度污染';
    return '严重污染';
  }

  /// 过滤重复提醒
  List<WeatherAlertModel> _filterDuplicateAlerts(
    List<WeatherAlertModel> newAlerts,
  ) {
    final filtered = <WeatherAlertModel>[];

    for (final newAlert in newAlerts) {
      // 检查是否已存在相同ID的提醒（基于日期和类型的稳定ID）
      final exists = _alerts.any(
        (existing) =>
            existing.id == newAlert.id ||
            (existing.weatherTerm == newAlert.weatherTerm &&
                existing.cityName == newAlert.cityName &&
                existing.type == newAlert.type &&
                !existing.isExpired),
      );

      if (!exists) {
        filtered.add(newAlert);
        print(
          '✅ WeatherAlertService: 添加新提醒 - ${newAlert.title} (${newAlert.id})',
        );
      } else {
        print(
          '⏭️ WeatherAlertService: 跳过重复提醒 - ${newAlert.title} (${newAlert.id})',
        );
      }
    }

    return filtered;
  }

  /// 清理过期提醒
  void _cleanupExpiredAlerts() {
    _alerts.removeWhere((alert) => alert.isExpired);
  }

  /// 清理指定城市的旧提醒
  void _cleanupCityAlerts(String cityName) {
    // 只清理非重要提醒，保留重要提醒（红色预警）
    _alerts.removeWhere(
      (alert) =>
          alert.cityName == cityName && !alert.isRequired && !alert.isExpired,
    );
  }

  /// 标记提醒为已读
  Future<void> markAsRead(String alertId) async {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      await _saveAlerts();
    }
  }

  /// 标记提醒为已显示
  Future<void> markAsShown(String alertId) async {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isShown: true);
      await _saveAlerts();
    }
  }

  /// 清除所有提醒
  Future<void> clearAllAlerts() async {
    _alerts.clear();
    await _saveAlerts();
  }

  /// 清除已读提醒
  Future<void> clearReadAlerts() async {
    _alerts.removeWhere((alert) => alert.isRead);
    await _saveAlerts();
  }
}
