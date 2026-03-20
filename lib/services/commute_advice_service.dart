import '../models/commute_advice_model.dart';
import '../models/weather_model.dart';
import 'weather_alert_service.dart';
import 'ai_service.dart';
import '../utils/logger.dart';

/// 通勤建议服务
class CommuteAdviceService {
  static final CommuteAdviceService _instance =
      CommuteAdviceService._internal();
  factory CommuteAdviceService() => _instance;
  CommuteAdviceService._internal();

  final AIService _aiService = AIService();

  /// 生成唯一ID（使用时间戳+随机数确保唯一性）
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond; // 微秒作为随机数
    return 'advice_${timestamp}_$random';
  }

  /// 判断当前是否在通勤时段（从用户设置读取）
  static bool isInCommuteTime() {
    final now = DateTime.now();

    // 从天气提醒设置中读取通勤时间配置
    final settings = WeatherAlertService.instance.settings;

    Logger.log('\n🔍 检查通勤时段:');
    Logger.log(
      '   当前时间: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    Logger.log('   星期: ${_getWeekdayName(now.weekday)}');

    // 检查是否启用通勤提醒
    if (!settings.enableCommuteAlerts) {
      Logger.log('   ❌ 通勤提醒未启用（请在"天气提醒设置"中启用）');
      return false;
    }
    Logger.log('   ✅ 通勤提醒已启用');

    // 使用用户配置的通勤时间判断
    final isInTime = settings.commuteTime.isCommuteTime(now);

    if (isInTime) {
      Logger.log('   ✅ 在通勤时段内');
    } else {
      final morningStart = settings.commuteTime.morningStart;
      final morningEnd = settings.commuteTime.morningEnd;
      final eveningStart = settings.commuteTime.eveningStart;
      final eveningEnd = settings.commuteTime.eveningEnd;

      Logger.log('   ❌ 不在通勤时段');
      Logger.log(
        '   早高峰: ${morningStart.hour.toString().padLeft(2, '0')}:${morningStart.minute.toString().padLeft(2, '0')} - ${morningEnd.hour.toString().padLeft(2, '0')}:${morningEnd.minute.toString().padLeft(2, '0')}',
      );
      Logger.log(
        '   晚高峰: ${eveningStart.hour.toString().padLeft(2, '0')}:${eveningStart.minute.toString().padLeft(2, '0')} - ${eveningEnd.hour.toString().padLeft(2, '0')}:${eveningEnd.minute.toString().padLeft(2, '0')}',
      );

      // 检查是否为工作日
      if (!settings.commuteTime.workDays.contains(now.weekday)) {
        Logger.log('   ℹ️ 当前不是工作日');
      }
    }

    return isInTime;
  }

  static String _getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekdays[weekday - 1]}';
  }

  /// 获取当前通勤时段（从用户设置读取）
  static CommuteTimeSlot? getCurrentCommuteTimeSlot() {
    final now = DateTime.now();

    // 从天气提醒设置中读取通勤时间配置
    final settings = WeatherAlertService.instance.settings;

    // 检查是否启用通勤提醒
    if (!settings.enableCommuteAlerts) {
      Logger.log('   ⚠️ getCurrentCommuteTimeSlot: 通勤提醒未启用');
      return null;
    }

    final commuteTime = settings.commuteTime;
    final weekday = now.weekday;

    // 检查是否为工作日
    if (!commuteTime.workDays.contains(weekday)) {
      Logger.log('   ⚠️ getCurrentCommuteTimeSlot: 当前不是工作日');
      return null;
    }

    final currentMinutes = now.hour * 60 + now.minute;

    // 检查早晨通勤时间
    final morningStartMinutes =
        commuteTime.morningStart.hour * 60 + commuteTime.morningStart.minute;
    final morningEndMinutes =
        commuteTime.morningEnd.hour * 60 + commuteTime.morningEnd.minute;

    if (currentMinutes >= morningStartMinutes &&
        currentMinutes < morningEndMinutes) {
      return CommuteTimeSlot.morning;
    }

    // 检查晚上通勤时间
    final eveningStartMinutes =
        commuteTime.eveningStart.hour * 60 + commuteTime.eveningStart.minute;
    final eveningEndMinutes =
        commuteTime.eveningEnd.hour * 60 + commuteTime.eveningEnd.minute;

    if (currentMinutes >= eveningStartMinutes &&
        currentMinutes < eveningEndMinutes) {
      return CommuteTimeSlot.evening;
    }

    return null;
  }

  /// 根据天气数据生成通勤建议（基于当前天气+24小时预报+AI智能生成）
  Future<List<CommuteAdviceModel>> generateAdvices(WeatherModel weather) async {
    final timeSlot = getCurrentCommuteTimeSlot();
    if (timeSlot == null) {
      return []; // 不在通勤时段，不生成建议
    }

    final advices = <CommuteAdviceModel>[];
    final current = weather.current?.current;
    final air = weather.current?.air ?? weather.air;
    final hourlyForecast = weather.forecast24h;

    // 获取用户设置的阈值
    final settings = WeatherAlertService.instance.settings;

    if (current == null) {
      return [];
    }

    // 分析通勤时段的天气趋势
    final commuteWeatherInfo = _analyzeCommuteWeather(
      current: current,
      hourlyForecast: hourlyForecast,
      timeSlot: timeSlot,
      settings: settings,
    );

    // 1. 根据天气类型生成建议
    final futureWeatherTypes =
        commuteWeatherInfo['futureWeatherTypes'] as Set<String>;

    Logger.log('\n🔄 CommuteAdviceService: 开始生成通勤建议');
    Logger.log('⏰ 时段: ${timeSlot == CommuteTimeSlot.morning ? '早高峰' : '晚高峰'}');
    Logger.log('🌦️ 当前天气: ${current.weather}');
    Logger.log('🌡️ 当前温度: ${current.temperature}℃');
    Logger.log('💨 风力: ${current.windpower}');
    Logger.log('😷 空气质量: ${air?.levelIndex ?? '未知'}');
    Logger.log('📊 未来天气类型: ${futureWeatherTypes.length}种\n');

    // 尝试使用AI生成智能建议
    Logger.log('🎯 策略: 优先使用AI智能生成，失败则降级到规则引擎\n');

    final aiAdvice = await _tryGenerateAIAdvice(
      weather: weather,
      timeSlot: timeSlot,
      settings: settings,
      futureWeatherTypes: futureWeatherTypes,
    );

    // 如果AI生成成功，优先使用AI建议
    if (aiAdvice != null) {
      Logger.log('🎉 使用AI生成的建议');
      advices.add(aiAdvice);
      return advices;
    }

    // AI失败或不可用，使用规则引擎生成建议
    Logger.log('\n╔════════════════════════════════════════╗');
    Logger.log('║   ⚠️ AI建议失败，降级到规则引擎  ║');
    Logger.log('╚════════════════════════════════════════╝\n');

    final ruleAdvices = _generateRuleBasedAdvices(
      weather: weather,
      timeSlot: timeSlot,
      settings: settings,
      futureWeatherTypes: futureWeatherTypes,
    );

    Logger.log('📋 规则引擎生成 ${ruleAdvices.length} 条建议');
    for (var advice in ruleAdvices) {
      Logger.log(
        '   - ${advice.title} (级别: ${advice.level.toString().split('.').last})',
      );
    }
    Logger.log('');

    return ruleAdvices;
  }

  /// 尝试使用AI生成智能建议
  Future<CommuteAdviceModel?> _tryGenerateAIAdvice({
    required WeatherModel weather,
    required CommuteTimeSlot timeSlot,
    required settings,
    required Set<String> futureWeatherTypes,
  }) async {
    Logger.log('\n╔════════════════════════════════════════╗');
    Logger.log('║   🤖 AI通勤建议生成流程           ║');
    Logger.log('╚════════════════════════════════════════╝');

    try {
      final current = weather.current?.current;
      final air = weather.current?.air ?? weather.air;

      if (current == null) {
        Logger.log('❌ 步骤1: 天气数据为空');
        return null;
      }

      Logger.log('✅ 步骤1: 获取天气数据');
      Logger.log('   - 天气: ${current.weather}');
      Logger.log('   - 温度: ${current.temperature}℃');
      Logger.log('   - 风力: ${current.windpower}');
      Logger.log('   - 空气: ${air?.levelIndex ?? '未知'}');
      Logger.log('   - 时段: ${timeSlot == CommuteTimeSlot.morning ? '早高峰' : '晚高峰'}');
      Logger.log('   - 未来天气数: ${futureWeatherTypes.length}条');

      // 构建Prompt
      Logger.log('\n✅ 步骤2: 构建AI Prompt');
      final prompt = _aiService.buildCommutePrompt(
        weatherType: current.weather ?? '未知',
        temperature: current.temperature ?? '--',
        windPower: current.windpower ?? '--',
        airQuality: air?.levelIndex ?? '良好',
        timeSlot: timeSlot.toString().split('.').last,
        futureWeather: futureWeatherTypes.toList(),
      );

      // 调用AI
      Logger.log('\n✅ 步骤3: 调用智谱AI API');
      final aiResponse = await _aiService.generateSmartAdvice(prompt);

      if (aiResponse == null || aiResponse.isEmpty) {
        Logger.log('❌ 步骤4: AI响应为空');
        return null;
      }

      Logger.log('✅ 步骤4: AI响应接收成功');
      Logger.log('   响应长度: ${aiResponse.length}字符');

      // 解析AI建议
      Logger.log('\n✅ 步骤5: 解析AI建议');
      final adviceList = _aiService.parseAdviceText(aiResponse);
      Logger.log('   解析出建议条数: ${adviceList.length}');
      for (int i = 0; i < adviceList.length; i++) {
        Logger.log('   建议${i + 1}: ${adviceList[i]}');
      }

      if (adviceList.isEmpty) {
        Logger.log('❌ 解析结果为空');
        return null;
      }

      // 合并多条建议为一条（新版通勤提醒已经是完整文本，只有一条）
      final combinedContent = adviceList.length == 1
          ? adviceList[0]
          : adviceList.join('\n\n');

      // 根据天气情况确定级别
      Logger.log('\n✅ 步骤6: 确定建议级别');
      final level = _determineLevel(
        weatherType: current.weather ?? '',
        temperature: current.temperature ?? '0',
        airQuality: air?.AQI ?? '0',
        futureWeatherTypes: futureWeatherTypes,
      );
      Logger.log('   级别: ${level.toString().split('.').last}');

      // 生成标题和图标
      final titleAndIcon = _generateTitleAndIcon(
        weatherType: current.weather ?? '',
        level: level,
        timeSlot: timeSlot,
      );

      Logger.log('\n╔════════════════════════════════════════╗');
      Logger.log('║   ✅ AI建议生成成功！              ║');
      Logger.log('╚════════════════════════════════════════╝\n');

      return CommuteAdviceModel(
        id: _generateId(),
        timestamp: DateTime.now(),
        adviceType: 'ai_smart',
        title: titleAndIcon['title']!,
        content: combinedContent,
        icon: titleAndIcon['icon']!,
        isRead: false,
        timeSlot: timeSlot,
        level: level,
      );
    } catch (e, stackTrace) {
      Logger.log('\n╔════════════════════════════════════════╗');
      Logger.log('║   ❌ AI建议生成失败                ║');
      Logger.log('╚════════════════════════════════════════╝');
      Logger.log('错误: $e');
      Logger.log('堆栈: $stackTrace\n');
      return null;
    }
  }

  /// 根据天气情况生成标题和图标
  static Map<String, String> _generateTitleAndIcon({
    required String weatherType,
    required CommuteAdviceLevel level,
    required CommuteTimeSlot timeSlot,
  }) {
    // 根据天气类型生成标题
    String title = '';
    String icon = '';

    if (weatherType.contains('雨')) {
      title = '雨天出行';
      icon = '🌧️';
    } else if (weatherType.contains('雪')) {
      title = '雪天出行';
      icon = '❄️';
    } else if (weatherType.contains('雾') || weatherType.contains('霾')) {
      title = '低能见度出行';
      icon = '🌫️';
    } else if (weatherType.contains('晴')) {
      title = '晴好天气出行';
      icon = '☀️';
    } else if (weatherType.contains('阴') || weatherType.contains('云')) {
      title = '多云天气出行';
      icon = '☁️';
    } else {
      // 默认
      title = timeSlot == CommuteTimeSlot.morning ? '早高峰出行' : '晚高峰出行';
      icon = timeSlot == CommuteTimeSlot.morning ? '🌅' : '🌆';
    }

    return {'title': title, 'icon': icon};
  }

  /// 确定建议级别
  static CommuteAdviceLevel _determineLevel({
    required String weatherType,
    required String temperature,
    required String airQuality,
    required Set<String> futureWeatherTypes,
  }) {
    // 检查是否有严重天气
    if (weatherType.contains('暴雨') ||
        weatherType.contains('暴雪') ||
        futureWeatherTypes.any((t) => t.contains('暴雨') || t.contains('暴雪'))) {
      return CommuteAdviceLevel.critical;
    }

    // 检查是否有需要警告的天气
    if (weatherType.contains('大雨') ||
        weatherType.contains('大雪') ||
        weatherType.contains('雾') ||
        weatherType.contains('霾') ||
        futureWeatherTypes.any((t) => t.contains('大雨') || t.contains('大雪'))) {
      return CommuteAdviceLevel.warning;
    }

    // 检查温度
    final temp = int.tryParse(temperature) ?? 0;
    if (temp >= 38 || temp <= -8) {
      return CommuteAdviceLevel.warning;
    }

    // 检查空气质量
    final aqi = int.tryParse(airQuality) ?? 0;
    if (aqi >= 150) {
      return CommuteAdviceLevel.warning;
    }

    // 其他情况为提示或建议
    if (weatherType.contains('雨') ||
        weatherType.contains('雪') ||
        temp >= 35 ||
        temp <= 0) {
      return CommuteAdviceLevel.info;
    }

    return CommuteAdviceLevel.normal;
  }

  /// 使用规则引擎生成建议（AI失败时的备用方案）
  static List<CommuteAdviceModel> _generateRuleBasedAdvices({
    required WeatherModel weather,
    required CommuteTimeSlot timeSlot,
    required settings,
    required Set<String> futureWeatherTypes,
  }) {
    final advices = <CommuteAdviceModel>[];
    final current = weather.current?.current;
    final air = weather.current?.air ?? weather.air;
    final hourlyForecast = weather.forecast24h;

    if (current == null) return [];

    final weatherType = current.weather ?? '';

    // 晴天建议（只在非雨雪天提醒，包含未来预报）
    final hasRainOrSnow = futureWeatherTypes.any(
      (t) => t.contains('雨') || t.contains('雪'),
    );

    if (_isSunny(weatherType) && !hasRainOrSnow) {
      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'sunny',
          title: '☀️ 晴天出行提醒',
          content: '今日阳光充足，建议携带防晒用品，如太阳镜、防晒霜等，做好防晒措施。',
          icon: '☀️',
          isRead: false,
          timeSlot: timeSlot,
          level: CommuteAdviceLevel.normal, // 日常建议
        ),
      );
    }

    // 雨天建议（结合当前和预报）
    final willRain =
        _isRainy(weatherType) || futureWeatherTypes.any((t) => _isRainy(t));

    if (willRain) {
      final isCurrentRain = _isRainy(weatherType);
      final maxRainType = _getMaxRainType([weatherType, ...futureWeatherTypes]);
      final rainyAdvice = _getRainyAdvice(maxRainType, isCurrentRain);

      // 根据降雨级别分配提醒级别
      CommuteAdviceLevel rainLevel;
      if (maxRainType.contains('暴雨')) {
        rainLevel = CommuteAdviceLevel.critical; // 暴雨 - 严重
      } else if (maxRainType.contains('大雨')) {
        rainLevel = CommuteAdviceLevel.warning; // 大雨 - 警告
      } else {
        rainLevel = CommuteAdviceLevel.info; // 中雨/小雨 - 提示
      }

      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'rainy',
          title: isCurrentRain ? '🌧️ 雨天出行提醒' : '🌧️ 即将降雨提醒',
          content: rainyAdvice,
          icon: '🌧️',
          isRead: false,
          timeSlot: timeSlot,
          level: rainLevel,
        ),
      );
    }

    // 雪天建议（结合当前和预报）
    final willSnow =
        _isSnowy(weatherType) || futureWeatherTypes.any((t) => _isSnowy(t));

    if (willSnow) {
      final isCurrentSnow = _isSnowy(weatherType);

      // 根据降雪类型分配级别
      CommuteAdviceLevel snowLevel;
      if (weatherType.contains('暴雪') ||
          futureWeatherTypes.any((t) => t.contains('暴雪'))) {
        snowLevel = CommuteAdviceLevel.critical; // 暴雪 - 严重
      } else if (weatherType.contains('大雪') ||
          futureWeatherTypes.any((t) => t.contains('大雪'))) {
        snowLevel = CommuteAdviceLevel.warning; // 大雪 - 警告
      } else {
        snowLevel = CommuteAdviceLevel.info; // 中雪/小雪 - 提示
      }

      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'snowy',
          title: isCurrentSnow ? '❄️ 雪天出行提醒' : '❄️ 即将降雪提醒',
          content: isCurrentSnow
              ? '雪天路滑，建议穿防滑鞋，注意交通安全。路面结冰，尽量选择地铁、公交等公共交通工具，驾车需谨慎慢行。'
              : '预计通勤时段内将有降雪，请提前准备防滑鞋，预留充足出行时间。路面可能结冰，建议选择公共交通，驾车需格外小心。',
          icon: '❄️',
          isRead: false,
          timeSlot: timeSlot,
          level: snowLevel,
        ),
      );
    }

    // 2. 根据风力生成建议
    if (_isWindy(current)) {
      // 根据风力大小分配级别
      final windPower = current.windpower ?? '';
      final powerMatch = RegExp(r'(\d+)').firstMatch(windPower);
      final power = int.tryParse(powerMatch?.group(1) ?? '0') ?? 0;

      CommuteAdviceLevel windLevel;
      if (power >= 8) {
        windLevel = CommuteAdviceLevel.warning; // 8级以上大风 - 警告
      } else {
        windLevel = CommuteAdviceLevel.info; // 6-7级 - 提示
      }

      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'windy',
          title: '💨 大风天气提醒',
          content: '今日风力较大，请注意高空坠物，避免在广告牌、大树、临时搭建物下停留。骑车出行需小心，建议选择公共交通。',
          icon: '💨',
          isRead: false,
          timeSlot: timeSlot,
          level: windLevel,
        ),
      );
    }

    // 3. 根据空气质量生成建议（从设置读取阈值）
    if (settings.enableAirQualityAlerts &&
        air != null &&
        _isAirQualityPoor(air, settings.airQualityThreshold)) {
      final aqiLevel = air.levelIndex ?? '未知';
      final aqiValue = int.tryParse(air.AQI ?? '0') ?? 0;

      // 根据AQI值分配级别
      CommuteAdviceLevel airLevel;
      if (aqiValue >= 200) {
        airLevel = CommuteAdviceLevel.critical; // 重度污染以上 - 严重
      } else if (aqiValue >= 150) {
        airLevel = CommuteAdviceLevel.warning; // 中度污染 - 警告
      } else {
        airLevel = CommuteAdviceLevel.info; // 轻度污染 - 提示
      }

      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'air_quality',
          title: '😷 空气质量提醒',
          content: '当前空气质量为「$aqiLevel」，建议佩戴口罩，减少户外运动和停留时间。尽量选择地铁等封闭交通工具，关闭车窗。',
          icon: '😷',
          isRead: false,
          timeSlot: timeSlot,
          level: airLevel,
        ),
      );
    }

    // 4. 根据能见度生成建议（仅在非雨雪天且为雾霾等天气时提醒，避免重复）
    if (!_isRainy(weatherType) &&
        !_isSnowy(weatherType) &&
        _isLowVisibility(weatherType, current)) {
      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'visibility',
          title: '🌫️ 低能见度提醒',
          content: '当前能见度较低，驾驶车辆请打开雾灯，保持安全车距，谨慎驾驶，降低车速。行人和骑车出行也需注意交通安全。',
          icon: '🌫️',
          isRead: false,
          timeSlot: timeSlot,
          level: CommuteAdviceLevel.warning, // 低能见度 - 警告
        ),
      );
    }

    // 5. 根据温度生成建议（结合当前和预报，从设置读取阈值）
    if (settings.enableTemperatureAlerts && current.temperature != null) {
      final currentTemp = int.tryParse(current.temperature!) ?? 0;

      // 分析通勤时段的温度趋势
      final tempInfo = _analyzeTemperatureTrend(
        currentTemp: currentTemp,
        hourlyForecast: hourlyForecast,
        timeSlot: timeSlot,
        settings: settings,
      );

      final maxTemp = tempInfo['maxTemp'] as int;
      final minTemp = tempInfo['minTemp'] as int;

      // 高温提醒
      if (maxTemp >= settings.highTemperatureThreshold) {
        final isCurrent = currentTemp >= settings.highTemperatureThreshold;

        // 根据温度高低分配级别
        CommuteAdviceLevel highTempLevel;
        if (maxTemp >= 40) {
          highTempLevel = CommuteAdviceLevel.critical; // 40℃以上 - 严重
        } else if (maxTemp >= 37) {
          highTempLevel = CommuteAdviceLevel.warning; // 37-39℃ - 警告
        } else {
          highTempLevel = CommuteAdviceLevel.info; // 35-36℃ - 提示
        }

        advices.add(
          CommuteAdviceModel(
            id: _generateId(),
            timestamp: DateTime.now(),
            adviceType: 'high_temp',
            title: isCurrent ? '🌡️ 高温出行提醒' : '🌡️ 气温升高提醒',
            content: isCurrent
                ? '当前气温高达${currentTemp}℃，请注意防暑降温，多喝水，避免长时间户外暴晒。通勤途中尽量选择有空调的交通工具。'
                : '预计通勤时段气温将升至${maxTemp}℃，请注意防暑降温，携带水杯多喝水。建议选择有空调的交通工具。',
            icon: '🌡️',
            isRead: false,
            timeSlot: timeSlot,
            level: highTempLevel,
          ),
        );
      }

      // 低温提醒
      if (minTemp <= settings.lowTemperatureThreshold) {
        final isCurrent = currentTemp <= settings.lowTemperatureThreshold;

        // 根据温度低温分配级别
        CommuteAdviceLevel lowTempLevel;
        if (minTemp <= -10) {
          lowTempLevel = CommuteAdviceLevel.critical; // -10℃以下 - 严重
        } else if (minTemp <= -5) {
          lowTempLevel = CommuteAdviceLevel.warning; // -5~-10℃ - 警告
        } else {
          lowTempLevel = CommuteAdviceLevel.info; // 0℃左右 - 提示
        }

        advices.add(
          CommuteAdviceModel(
            id: _generateId(),
            timestamp: DateTime.now(),
            adviceType: 'low_temp',
            title: isCurrent ? '🧊 低温出行提醒' : '🧊 气温降低提醒',
            content: isCurrent
                ? '当前气温低至${currentTemp}℃，请注意保暖，多穿衣物。路面可能结冰，驾驶和步行都需注意防滑安全。'
                : '预计通勤时段气温将降至${minTemp}℃，请注意保暖，多添衣物。路面可能结冰，注意防滑安全。',
            icon: '🧊',
            isRead: false,
            timeSlot: timeSlot,
            level: lowTempLevel,
          ),
        );
      }
    }

    return advices;
  }

  /// 分析通勤时段的温度趋势
  static Map<String, int> _analyzeTemperatureTrend({
    required int currentTemp,
    required List<HourlyWeather>? hourlyForecast,
    required CommuteTimeSlot timeSlot,
    required settings,
  }) {
    int maxTemp = currentTemp;
    int minTemp = currentTemp;

    if (hourlyForecast == null || hourlyForecast.isEmpty) {
      return {'maxTemp': maxTemp, 'minTemp': minTemp};
    }

    final commuteTime = settings.commuteTime;
    final now = DateTime.now();
    int startHour, endHour;

    if (timeSlot == CommuteTimeSlot.morning) {
      startHour = commuteTime.morningStart.hour;
      endHour = commuteTime.morningEnd.hour;
    } else {
      startHour = commuteTime.eveningStart.hour;
      endHour = commuteTime.eveningEnd.hour;
    }

    // 分析通勤时段内的温度
    for (var hourly in hourlyForecast) {
      try {
        final forecastTime = DateTime.parse(hourly.forecasttime ?? '');

        // 只分析今天通勤时段的温度
        if (forecastTime.day != now.day) continue;

        final hour = forecastTime.hour;
        if (hour >= startHour && hour <= endHour) {
          final temp = int.tryParse(hourly.temperature ?? '0') ?? 0;
          if (temp > maxTemp) maxTemp = temp;
          if (temp < minTemp) minTemp = temp;
        }
      } catch (e) {
        continue;
      }
    }

    return {'maxTemp': maxTemp, 'minTemp': minTemp};
  }

  /// 判断是否为晴天
  static bool _isSunny(String weatherType) {
    return weatherType.contains('晴') && !weatherType.contains('转');
  }

  /// 判断是否为雨天
  static bool _isRainy(String weatherType) {
    return weatherType.contains('雨') && !weatherType.contains('雪');
  }

  /// 判断是否为雪天
  static bool _isSnowy(String weatherType) {
    return weatherType.contains('雪') || weatherType.contains('雨夹雪');
  }

  /// 判断是否大风
  static bool _isWindy(CurrentWeather current) {
    final windPower = current.windpower ?? '';
    // 提取风力数字，如果大于等于6级认为是大风
    final powerMatch = RegExp(r'(\d+)').firstMatch(windPower);
    if (powerMatch != null) {
      final power = int.tryParse(powerMatch.group(1) ?? '0') ?? 0;
      return power >= 6;
    }
    return false;
  }

  /// 判断空气质量是否差（使用用户设置的阈值）
  static bool _isAirQualityPoor(AirQuality air, int threshold) {
    final aqi = air.AQI;
    if (aqi == null) return false;

    // 使用用户设置的阈值
    try {
      final aqiValue = int.parse(aqi);
      return aqiValue >= threshold;
    } catch (e) {
      return false;
    }
  }

  /// 判断是否低能见度
  static bool _isLowVisibility(String weatherType, CurrentWeather current) {
    // 雾、霾、扬沙、浮尘等天气认为是低能见度
    if (weatherType.contains('雾') ||
        weatherType.contains('霾') ||
        weatherType.contains('扬沙') ||
        weatherType.contains('浮尘')) {
      return true;
    }

    // 大雨、暴雨也会影响能见度
    if (weatherType.contains('大雨') || weatherType.contains('暴雨')) {
      return true;
    }

    return false;
  }

  /// 分析通勤时段的天气趋势
  static Map<String, dynamic> _analyzeCommuteWeather({
    required CurrentWeather current,
    required List<HourlyWeather>? hourlyForecast,
    required CommuteTimeSlot timeSlot,
    required settings,
  }) {
    final futureWeatherTypes = <String>{};
    final commuteTime = settings.commuteTime;

    if (hourlyForecast == null || hourlyForecast.isEmpty) {
      return {'futureWeatherTypes': futureWeatherTypes};
    }

    // 获取通勤时段的小时范围
    final now = DateTime.now();
    int startHour, endHour;

    if (timeSlot == CommuteTimeSlot.morning) {
      startHour = commuteTime.morningStart.hour;
      endHour = commuteTime.morningEnd.hour;
    } else {
      startHour = commuteTime.eveningStart.hour;
      endHour = commuteTime.eveningEnd.hour;
    }

    // 分析通勤时段内的天气
    for (var hourly in hourlyForecast) {
      try {
        final forecastTime = DateTime.parse(hourly.forecasttime ?? '');

        // 只分析今天通勤时段的天气
        if (forecastTime.day != now.day) continue;

        final hour = forecastTime.hour;
        if (hour >= startHour && hour <= endHour) {
          final weather = hourly.weather ?? '';
          if (weather.isNotEmpty) {
            futureWeatherTypes.add(weather);
          }
        }
      } catch (e) {
        // 解析失败，跳过
        continue;
      }
    }

    return {'futureWeatherTypes': futureWeatherTypes};
  }

  /// 获取最严重的降雨类型
  static String _getMaxRainType(List<String> weatherTypes) {
    final rainLevels = ['暴雨', '大雨', '中雨', '小雨', '阵雨', '雷阵雨'];

    for (var level in rainLevels) {
      if (weatherTypes.any((t) => t.contains(level))) {
        return level;
      }
    }

    // 如果包含"雨"字但没有匹配到具体级别
    if (weatherTypes.any((t) => t.contains('雨'))) {
      return '雨';
    }

    return '';
  }

  /// 获取雨天建议（根据雨量级别和是否当前下雨）
  static String _getRainyAdvice(String maxRainType, bool isCurrentRain) {
    String advice = '';

    if (maxRainType.contains('暴雨')) {
      advice = isCurrentRain
          ? '今日有暴雨，请务必携带雨具。路面积水严重，强烈建议选择地铁、公交等公共交通工具，避免涉水行驶。注意安全！'
          : '预计通勤时段将有暴雨，请务必携带雨具，提前出门。强烈建议选择地铁、公交等公共交通工具，避免路面积水涉水行驶。';
    } else if (maxRainType.contains('大雨')) {
      advice = isCurrentRain
          ? '今日有大雨，请携带雨伞、雨衣等雨具。路面湿滑，建议选择地铁、公交等交通工具，驾车需谨慎慢行。'
          : '预计通勤时段将有大雨，请提前准备雨伞、雨衣。建议选择地铁、公交等交通工具，如需驾车请谨慎慢行。';
    } else if (maxRainType.contains('中雨')) {
      advice = isCurrentRain
          ? '今日有中雨，请携带雨伞。建议选择合适的交通工具，如地铁、公交等，注意防滑。'
          : '预计通勤时段将有中雨，请携带雨伞。建议选择合适的交通工具，如地铁、公交等，注意防滑。';
    } else {
      advice = isCurrentRain
          ? '今日有降雨，请携带雨具，如雨伞、雨衣等，注意出行安全。'
          : '预计通勤时段将有降雨，请提前准备雨具，如雨伞、雨衣等，注意出行安全。';
    }

    return advice;
  }

  /// 判断时段是否已结束（用于自动清理）
  static bool isTimeSlotEnded(CommuteTimeSlot timeSlot) {
    final now = DateTime.now();
    
    // 从天气提醒设置中读取通勤时间配置
    final settings = WeatherAlertService.instance.settings;
    final commuteTime = settings.commuteTime;
    
    final currentMinutes = now.hour * 60 + now.minute;

    switch (timeSlot) {
      case CommuteTimeSlot.morning:
        // 早高峰结束：当前时间 >= 早高峰结束时间
        final morningEndMinutes =
            commuteTime.morningEnd.hour * 60 + commuteTime.morningEnd.minute;
        return currentMinutes >= morningEndMinutes;
      case CommuteTimeSlot.evening:
        // 晚高峰结束：当前时间 >= 晚高峰结束时间，或者当前时间 < 晚高峰开始时间（跨天情况）
        final eveningStartMinutes =
            commuteTime.eveningStart.hour * 60 + commuteTime.eveningStart.minute;
        final eveningEndMinutes =
            commuteTime.eveningEnd.hour * 60 + commuteTime.eveningEnd.minute;
        
        // 如果晚高峰结束时间 < 开始时间（跨天），需要特殊处理
        if (eveningEndMinutes < eveningStartMinutes) {
          // 跨天情况：当前时间 >= 结束时间 或 当前时间 < 开始时间
          return currentMinutes >= eveningEndMinutes || currentMinutes < eveningStartMinutes;
        } else {
          // 正常情况：当前时间 >= 结束时间
          return currentMinutes >= eveningEndMinutes;
        }
    }
  }
}
