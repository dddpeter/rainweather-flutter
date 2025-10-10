import '../models/commute_advice_model.dart';
import '../models/weather_model.dart';
import 'weather_alert_service.dart';

/// 通勤建议服务
class CommuteAdviceService {
  static final CommuteAdviceService _instance =
      CommuteAdviceService._internal();
  factory CommuteAdviceService() => _instance;
  CommuteAdviceService._internal();

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

    // 检查是否启用通勤提醒
    if (!settings.enableCommuteAlerts) {
      return false;
    }

    // 使用用户配置的通勤时间判断
    return settings.commuteTime.isCommuteTime(now);
  }

  /// 获取当前通勤时段（从用户设置读取）
  static CommuteTimeSlot? getCurrentCommuteTimeSlot() {
    final now = DateTime.now();

    // 从天气提醒设置中读取通勤时间配置
    final settings = WeatherAlertService.instance.settings;

    // 检查是否启用通勤提醒
    if (!settings.enableCommuteAlerts) {
      return null;
    }

    final commuteTime = settings.commuteTime;
    final weekday = now.weekday;

    // 检查是否为工作日
    if (!commuteTime.workDays.contains(weekday)) {
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

  /// 根据天气数据生成通勤建议（基于当前天气+24小时预报）
  static List<CommuteAdviceModel> generateAdvices(WeatherModel weather) {
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
    final weatherType = current.weather ?? '';
    final futureWeatherTypes =
        commuteWeatherInfo['futureWeatherTypes'] as Set<String>;

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
        ),
      );
    }

    // 雪天建议（结合当前和预报）
    final willSnow =
        _isSnowy(weatherType) || futureWeatherTypes.any((t) => _isSnowy(t));

    if (willSnow) {
      final isCurrentSnow = _isSnowy(weatherType);
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
        ),
      );
    }

    // 2. 根据风力生成建议
    if (_isWindy(current)) {
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
        ),
      );
    }

    // 3. 根据空气质量生成建议（从设置读取阈值）
    if (settings.enableAirQualityAlerts &&
        air != null &&
        _isAirQualityPoor(air, settings.airQualityThreshold)) {
      final aqiLevel = air.levelIndex ?? '未知';
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
          ),
        );
      }

      // 低温提醒
      if (minTemp <= settings.lowTemperatureThreshold) {
        final isCurrent = currentTemp <= settings.lowTemperatureThreshold;
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
    final hour = now.hour;

    switch (timeSlot) {
      case CommuteTimeSlot.morning:
        return hour >= 10; // 10点后早高峰结束
      case CommuteTimeSlot.evening:
        return hour >= 20 || hour < 17; // 20点后或17点前晚高峰结束
    }
  }
}
