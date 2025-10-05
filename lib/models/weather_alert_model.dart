import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weather_alert_model.g.dart';

/// 天气提醒级别枚举
enum WeatherAlertLevel {
  @JsonValue('red')
  red, // 红色预警/危险 - 必须提醒
  @JsonValue('yellow')
  yellow, // 黄色预警/出行高峰 - 看场景提醒
  @JsonValue('blue')
  blue, // 蓝色预警 - 一般提醒
  @JsonValue('info')
  info, // 信息提醒
}

/// 天气提醒类型枚举
enum WeatherAlertType {
  @JsonValue('rain')
  rain, // 降雨相关
  @JsonValue('snow')
  snow, // 降雪相关
  @JsonValue('wind')
  wind, // 风力相关
  @JsonValue('fog')
  fog, // 雾霾相关
  @JsonValue('dust')
  dust, // 沙尘相关
  @JsonValue('hail')
  hail, // 冰雹相关
  @JsonValue('temperature')
  temperature, // 温度相关
  @JsonValue('visibility')
  visibility, // 能见度相关
  @JsonValue('air_quality')
  airQuality, // 空气质量相关
  @JsonValue('other')
  other, // 其他
}

/// 天气提醒数据模型
@JsonSerializable()
class WeatherAlertModel {
  /// 提醒ID
  final String id;

  /// 提醒标题
  final String title;

  /// 提醒内容
  final String content;

  /// 提醒级别
  final WeatherAlertLevel level;

  /// 提醒类型
  final WeatherAlertType type;

  /// 是否必须提醒（一档）
  final bool isRequired;

  /// 是否场景提醒（二档）
  final bool isScenarioBased;

  /// 触发场景描述（如果是场景提醒）
  final String? scenario;

  /// 建议阈值
  final String threshold;

  /// 天气词条
  final String weatherTerm;

  /// 提醒原因
  final String reason;

  /// 创建时间
  final DateTime createdAt;

  /// 过期时间
  final DateTime? expiresAt;

  /// 是否已读
  final bool isRead;

  /// 是否已显示
  final bool isShown;

  /// 城市名称
  final String cityName;

  /// 优先级（数字越小优先级越高）
  final int priority;

  WeatherAlertModel({
    required this.id,
    required this.title,
    required this.content,
    required this.level,
    required this.type,
    required this.isRequired,
    required this.isScenarioBased,
    this.scenario,
    required this.threshold,
    required this.weatherTerm,
    required this.reason,
    required this.createdAt,
    this.expiresAt,
    this.isRead = false,
    this.isShown = false,
    required this.cityName,
    required this.priority,
  });

  factory WeatherAlertModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherAlertModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherAlertModelToJson(this);

  /// 复制并修改属性
  WeatherAlertModel copyWith({
    String? id,
    String? title,
    String? content,
    WeatherAlertLevel? level,
    WeatherAlertType? type,
    bool? isRequired,
    bool? isScenarioBased,
    String? scenario,
    String? threshold,
    String? weatherTerm,
    String? reason,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isRead,
    bool? isShown,
    String? cityName,
    int? priority,
  }) {
    return WeatherAlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      level: level ?? this.level,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      isScenarioBased: isScenarioBased ?? this.isScenarioBased,
      scenario: scenario ?? this.scenario,
      threshold: threshold ?? this.threshold,
      weatherTerm: weatherTerm ?? this.weatherTerm,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isRead: isRead ?? this.isRead,
      isShown: isShown ?? this.isShown,
      cityName: cityName ?? this.cityName,
      priority: priority ?? this.priority,
    );
  }

  /// 获取提醒级别对应的颜色
  String get levelColor {
    switch (level) {
      case WeatherAlertLevel.red:
        return 'red';
      case WeatherAlertLevel.yellow:
        return 'orange';
      case WeatherAlertLevel.blue:
        return 'blue';
      case WeatherAlertLevel.info:
        return 'green';
    }
  }

  /// 获取提醒级别对应的图标
  String get levelIcon {
    switch (level) {
      case WeatherAlertLevel.red:
        return '🚨';
      case WeatherAlertLevel.yellow:
        return '⚠️';
      case WeatherAlertLevel.blue:
        return 'ℹ️';
      case WeatherAlertLevel.info:
        return '💡';
    }
  }

  /// 判断是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 判断是否需要显示
  bool get shouldShow {
    return !isExpired && !isRead;
  }

  @override
  String toString() {
    return 'WeatherAlertModel(id: $id, title: $title, level: $level, type: $type, isRequired: $isRequired, cityName: $cityName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherAlertModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 天气提醒规则配置
@JsonSerializable()
class WeatherAlertRule {
  /// 天气词条
  final String weatherTerm;

  /// 提醒级别
  final WeatherAlertLevel level;

  /// 是否必须提醒
  final bool isRequired;

  /// 是否场景提醒
  final bool isScenarioBased;

  /// 建议阈值
  final String threshold;

  /// 提醒原因
  final String reason;

  /// 触发场景（场景提醒时使用）
  final String? scenario;

  /// 提醒类型
  final WeatherAlertType type;

  /// 优先级
  final int priority;

  WeatherAlertRule({
    required this.weatherTerm,
    required this.level,
    required this.isRequired,
    required this.isScenarioBased,
    required this.threshold,
    required this.reason,
    this.scenario,
    required this.type,
    required this.priority,
  });

  factory WeatherAlertRule.fromJson(Map<String, dynamic> json) =>
      _$WeatherAlertRuleFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherAlertRuleToJson(this);
}

/// 天气提醒设置
@JsonSerializable()
class WeatherAlertSettings {
  /// 是否启用一档提醒（必须提醒）
  final bool enableRequiredAlerts;

  /// 是否启用二档提醒（场景提醒）
  final bool enableScenarioAlerts;

  /// 是否启用通勤提醒
  final bool enableCommuteAlerts;

  /// 通勤时间设置
  final CommuteTimeSettings commuteTime;

  /// 是否启用空气质量提醒
  final bool enableAirQualityAlerts;

  /// 空气质量阈值
  final int airQualityThreshold;

  /// 是否启用温度提醒
  final bool enableTemperatureAlerts;

  /// 高温阈值
  final int highTemperatureThreshold;

  /// 低温阈值
  final int lowTemperatureThreshold;

  /// 提醒声音设置
  final bool enableAlertSound;

  /// 提醒振动设置
  final bool enableAlertVibration;

  WeatherAlertSettings({
    this.enableRequiredAlerts = true,
    this.enableScenarioAlerts = true,
    this.enableCommuteAlerts = true,
    CommuteTimeSettings? commuteTime,
    this.enableAirQualityAlerts = true,
    this.airQualityThreshold = 150,
    this.enableTemperatureAlerts = true,
    this.highTemperatureThreshold = 35,
    this.lowTemperatureThreshold = 0,
    this.enableAlertSound = true,
    this.enableAlertVibration = true,
  }) : commuteTime = commuteTime ?? CommuteTimeSettings();

  factory WeatherAlertSettings.fromJson(Map<String, dynamic> json) =>
      _$WeatherAlertSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherAlertSettingsToJson(this);

  WeatherAlertSettings copyWith({
    bool? enableRequiredAlerts,
    bool? enableScenarioAlerts,
    bool? enableCommuteAlerts,
    CommuteTimeSettings? commuteTime,
    bool? enableAirQualityAlerts,
    int? airQualityThreshold,
    bool? enableTemperatureAlerts,
    int? highTemperatureThreshold,
    int? lowTemperatureThreshold,
    bool? enableAlertSound,
    bool? enableAlertVibration,
  }) {
    return WeatherAlertSettings(
      enableRequiredAlerts: enableRequiredAlerts ?? this.enableRequiredAlerts,
      enableScenarioAlerts: enableScenarioAlerts ?? this.enableScenarioAlerts,
      enableCommuteAlerts: enableCommuteAlerts ?? this.enableCommuteAlerts,
      commuteTime: commuteTime ?? this.commuteTime,
      enableAirQualityAlerts:
          enableAirQualityAlerts ?? this.enableAirQualityAlerts,
      airQualityThreshold: airQualityThreshold ?? this.airQualityThreshold,
      enableTemperatureAlerts:
          enableTemperatureAlerts ?? this.enableTemperatureAlerts,
      highTemperatureThreshold:
          highTemperatureThreshold ?? this.highTemperatureThreshold,
      lowTemperatureThreshold:
          lowTemperatureThreshold ?? this.lowTemperatureThreshold,
      enableAlertSound: enableAlertSound ?? this.enableAlertSound,
      enableAlertVibration: enableAlertVibration ?? this.enableAlertVibration,
    );
  }
}

/// 通勤时间设置
@JsonSerializable()
class CommuteTimeSettings {
  /// 早晨通勤开始时间
  final CustomTimeOfDay morningStart;

  /// 早晨通勤结束时间
  final CustomTimeOfDay morningEnd;

  /// 晚上通勤开始时间
  final CustomTimeOfDay eveningStart;

  /// 晚上通勤结束时间
  final CustomTimeOfDay eveningEnd;

  /// 工作日设置
  final List<int> workDays; // 1-7 表示周一到周日

  CommuteTimeSettings({
    CustomTimeOfDay? morningStart,
    CustomTimeOfDay? morningEnd,
    CustomTimeOfDay? eveningStart,
    CustomTimeOfDay? eveningEnd,
    List<int>? workDays,
  }) : morningStart = morningStart ?? const CustomTimeOfDay(hour: 7, minute: 0),
       morningEnd = morningEnd ?? const CustomTimeOfDay(hour: 9, minute: 0),
       eveningStart =
           eveningStart ?? const CustomTimeOfDay(hour: 17, minute: 30),
       eveningEnd = eveningEnd ?? const CustomTimeOfDay(hour: 19, minute: 30),
       workDays = workDays ?? [1, 2, 3, 4, 5]; // 默认工作日

  factory CommuteTimeSettings.fromJson(Map<String, dynamic> json) =>
      _$CommuteTimeSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CommuteTimeSettingsToJson(this);

  /// 判断当前时间是否在通勤时间内
  bool isCommuteTime(DateTime now) {
    final weekday = now.weekday;
    if (!workDays.contains(weekday)) return false;

    final currentTime = TimeOfDay.fromDateTime(now);

    // 检查早晨通勤时间
    if (_isTimeInRange(currentTime, morningStart, morningEnd)) {
      return true;
    }

    // 检查晚上通勤时间
    if (_isTimeInRange(currentTime, eveningStart, eveningEnd)) {
      return true;
    }

    return false;
  }

  /// 判断时间是否在指定范围内
  bool _isTimeInRange(
    TimeOfDay current,
    CustomTimeOfDay start,
    CustomTimeOfDay end,
  ) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
}

/// 时间类（用于JSON序列化）
@JsonSerializable()
class CustomTimeOfDay {
  final int hour;
  final int minute;

  const CustomTimeOfDay({required this.hour, required this.minute});

  factory CustomTimeOfDay.fromDateTime(DateTime dateTime) {
    return CustomTimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  factory CustomTimeOfDay.fromTimeOfDay(TimeOfDay timeOfDay) {
    return CustomTimeOfDay(hour: timeOfDay.hour, minute: timeOfDay.minute);
  }

  factory CustomTimeOfDay.fromJson(Map<String, dynamic> json) =>
      _$CustomTimeOfDayFromJson(json);

  Map<String, dynamic> toJson() => _$CustomTimeOfDayToJson(this);

  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
