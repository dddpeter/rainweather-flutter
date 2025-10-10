import '../models/commute_advice_model.dart';
import '../models/weather_model.dart';
import 'weather_alert_service.dart';

/// 通勤建议服务
class CommuteAdviceService {
  static final CommuteAdviceService _instance =
      CommuteAdviceService._internal();
  factory CommuteAdviceService() => _instance;
  CommuteAdviceService._internal();

  /// 生成唯一ID
  static String _generateId() {
    return 'advice_${DateTime.now().millisecondsSinceEpoch}';
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

  /// 根据天气数据生成通勤建议
  static List<CommuteAdviceModel> generateAdvices(WeatherModel weather) {
    final timeSlot = getCurrentCommuteTimeSlot();
    if (timeSlot == null) {
      return []; // 不在通勤时段，不生成建议
    }

    final advices = <CommuteAdviceModel>[];
    final current = weather.current?.current;
    final air = weather.current?.air ?? weather.air;

    if (current == null) {
      return [];
    }

    // 1. 根据天气类型生成建议
    final weatherType = current.weather ?? '';

    // 晴天建议
    if (_isSunny(weatherType)) {
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

    // 雨天建议
    if (_isRainy(weatherType)) {
      final rainyAdvice = _getRainyAdvice(weatherType);
      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'rainy',
          title: '🌧️ 雨天出行提醒',
          content: rainyAdvice,
          icon: '🌧️',
          isRead: false,
          timeSlot: timeSlot,
        ),
      );
    }

    // 雪天建议
    if (_isSnowy(weatherType)) {
      advices.add(
        CommuteAdviceModel(
          id: _generateId(),
          timestamp: DateTime.now(),
          adviceType: 'snowy',
          title: '❄️ 雪天出行提醒',
          content: '雪天路滑，建议穿防滑鞋，注意交通安全。路面结冰，尽量选择地铁、公交等公共交通工具，驾车需谨慎慢行。',
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

    // 3. 根据空气质量生成建议
    if (air != null && _isAirQualityPoor(air)) {
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

    // 4. 根据能见度生成建议
    if (_isLowVisibility(weatherType, current)) {
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

    return advices;
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

  /// 判断空气质量是否差
  static bool _isAirQualityPoor(AirQuality air) {
    final aqi = air.AQI;
    if (aqi == null) return false;

    // AQI大于100认为空气质量差（轻度污染及以上）
    try {
      final aqiValue = int.parse(aqi);
      return aqiValue > 100;
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

  /// 获取雨天建议（根据雨量级别）
  static String _getRainyAdvice(String weatherType) {
    if (weatherType.contains('暴雨')) {
      return '今日有暴雨，请务必携带雨具。路面积水严重，强烈建议选择地铁、公交等公共交通工具，避免涉水行驶。注意安全！';
    } else if (weatherType.contains('大雨')) {
      return '今日有大雨，请携带雨伞、雨衣等雨具。路面湿滑，建议选择地铁、公交等交通工具，驾车需谨慎慢行。';
    } else if (weatherType.contains('中雨')) {
      return '今日有中雨，请携带雨伞。建议选择合适的交通工具，如地铁、公交等，注意防滑。';
    } else {
      return '今日有降雨，请携带雨具，如雨伞、雨衣等，注意出行安全。';
    }
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
