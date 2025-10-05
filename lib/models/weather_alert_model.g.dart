// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_alert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherAlertModel _$WeatherAlertModelFromJson(Map<String, dynamic> json) =>
    WeatherAlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      level: $enumDecode(_$WeatherAlertLevelEnumMap, json['level']),
      type: $enumDecode(_$WeatherAlertTypeEnumMap, json['type']),
      isRequired: json['isRequired'] as bool,
      isScenarioBased: json['isScenarioBased'] as bool,
      scenario: json['scenario'] as String?,
      threshold: json['threshold'] as String,
      weatherTerm: json['weatherTerm'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isShown: json['isShown'] as bool? ?? false,
      cityName: json['cityName'] as String,
      priority: (json['priority'] as num).toInt(),
    );

Map<String, dynamic> _$WeatherAlertModelToJson(WeatherAlertModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'level': _$WeatherAlertLevelEnumMap[instance.level]!,
      'type': _$WeatherAlertTypeEnumMap[instance.type]!,
      'isRequired': instance.isRequired,
      'isScenarioBased': instance.isScenarioBased,
      'scenario': instance.scenario,
      'threshold': instance.threshold,
      'weatherTerm': instance.weatherTerm,
      'reason': instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isRead': instance.isRead,
      'isShown': instance.isShown,
      'cityName': instance.cityName,
      'priority': instance.priority,
    };

const _$WeatherAlertLevelEnumMap = {
  WeatherAlertLevel.red: 'red',
  WeatherAlertLevel.yellow: 'yellow',
  WeatherAlertLevel.blue: 'blue',
  WeatherAlertLevel.info: 'info',
};

const _$WeatherAlertTypeEnumMap = {
  WeatherAlertType.rain: 'rain',
  WeatherAlertType.snow: 'snow',
  WeatherAlertType.wind: 'wind',
  WeatherAlertType.fog: 'fog',
  WeatherAlertType.dust: 'dust',
  WeatherAlertType.hail: 'hail',
  WeatherAlertType.temperature: 'temperature',
  WeatherAlertType.visibility: 'visibility',
  WeatherAlertType.airQuality: 'air_quality',
  WeatherAlertType.other: 'other',
};

WeatherAlertRule _$WeatherAlertRuleFromJson(Map<String, dynamic> json) =>
    WeatherAlertRule(
      weatherTerm: json['weatherTerm'] as String,
      level: $enumDecode(_$WeatherAlertLevelEnumMap, json['level']),
      isRequired: json['isRequired'] as bool,
      isScenarioBased: json['isScenarioBased'] as bool,
      threshold: json['threshold'] as String,
      reason: json['reason'] as String,
      scenario: json['scenario'] as String?,
      type: $enumDecode(_$WeatherAlertTypeEnumMap, json['type']),
      priority: (json['priority'] as num).toInt(),
    );

Map<String, dynamic> _$WeatherAlertRuleToJson(WeatherAlertRule instance) =>
    <String, dynamic>{
      'weatherTerm': instance.weatherTerm,
      'level': _$WeatherAlertLevelEnumMap[instance.level]!,
      'isRequired': instance.isRequired,
      'isScenarioBased': instance.isScenarioBased,
      'threshold': instance.threshold,
      'reason': instance.reason,
      'scenario': instance.scenario,
      'type': _$WeatherAlertTypeEnumMap[instance.type]!,
      'priority': instance.priority,
    };

WeatherAlertSettings _$WeatherAlertSettingsFromJson(
  Map<String, dynamic> json,
) => WeatherAlertSettings(
  enableRequiredAlerts: json['enableRequiredAlerts'] as bool? ?? true,
  enableScenarioAlerts: json['enableScenarioAlerts'] as bool? ?? true,
  enableCommuteAlerts: json['enableCommuteAlerts'] as bool? ?? true,
  commuteTime: json['commuteTime'] == null
      ? null
      : CommuteTimeSettings.fromJson(
          json['commuteTime'] as Map<String, dynamic>,
        ),
  enableAirQualityAlerts: json['enableAirQualityAlerts'] as bool? ?? true,
  airQualityThreshold: (json['airQualityThreshold'] as num?)?.toInt() ?? 150,
  enableTemperatureAlerts: json['enableTemperatureAlerts'] as bool? ?? true,
  highTemperatureThreshold:
      (json['highTemperatureThreshold'] as num?)?.toInt() ?? 35,
  lowTemperatureThreshold:
      (json['lowTemperatureThreshold'] as num?)?.toInt() ?? 0,
  enableAlertSound: json['enableAlertSound'] as bool? ?? true,
  enableAlertVibration: json['enableAlertVibration'] as bool? ?? true,
);

Map<String, dynamic> _$WeatherAlertSettingsToJson(
  WeatherAlertSettings instance,
) => <String, dynamic>{
  'enableRequiredAlerts': instance.enableRequiredAlerts,
  'enableScenarioAlerts': instance.enableScenarioAlerts,
  'enableCommuteAlerts': instance.enableCommuteAlerts,
  'commuteTime': instance.commuteTime,
  'enableAirQualityAlerts': instance.enableAirQualityAlerts,
  'airQualityThreshold': instance.airQualityThreshold,
  'enableTemperatureAlerts': instance.enableTemperatureAlerts,
  'highTemperatureThreshold': instance.highTemperatureThreshold,
  'lowTemperatureThreshold': instance.lowTemperatureThreshold,
  'enableAlertSound': instance.enableAlertSound,
  'enableAlertVibration': instance.enableAlertVibration,
};

CommuteTimeSettings _$CommuteTimeSettingsFromJson(
  Map<String, dynamic> json,
) => CommuteTimeSettings(
  morningStart: json['morningStart'] == null
      ? null
      : CustomTimeOfDay.fromJson(json['morningStart'] as Map<String, dynamic>),
  morningEnd: json['morningEnd'] == null
      ? null
      : CustomTimeOfDay.fromJson(json['morningEnd'] as Map<String, dynamic>),
  eveningStart: json['eveningStart'] == null
      ? null
      : CustomTimeOfDay.fromJson(json['eveningStart'] as Map<String, dynamic>),
  eveningEnd: json['eveningEnd'] == null
      ? null
      : CustomTimeOfDay.fromJson(json['eveningEnd'] as Map<String, dynamic>),
  workDays: (json['workDays'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$CommuteTimeSettingsToJson(
  CommuteTimeSettings instance,
) => <String, dynamic>{
  'morningStart': instance.morningStart,
  'morningEnd': instance.morningEnd,
  'eveningStart': instance.eveningStart,
  'eveningEnd': instance.eveningEnd,
  'workDays': instance.workDays,
};

CustomTimeOfDay _$CustomTimeOfDayFromJson(Map<String, dynamic> json) =>
    CustomTimeOfDay(
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
    );

Map<String, dynamic> _$CustomTimeOfDayToJson(CustomTimeOfDay instance) =>
    <String, dynamic>{'hour': instance.hour, 'minute': instance.minute};
