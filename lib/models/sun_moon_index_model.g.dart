// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sun_moon_index_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SunMoonIndexResponse _$SunMoonIndexResponseFromJson(
  Map<String, dynamic> json,
) => SunMoonIndexResponse(
  code: (json['code'] as num).toInt(),
  data: json['data'] == null
      ? null
      : SunMoonIndexData.fromJson(json['data'] as Map<String, dynamic>),
  message: json['message'] as String,
  pageNum: json['pageNum'],
);

Map<String, dynamic> _$SunMoonIndexResponseToJson(
  SunMoonIndexResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'data': instance.data,
  'message': instance.message,
  'pageNum': instance.pageNum,
};

SunMoonIndexData _$SunMoonIndexDataFromJson(Map<String, dynamic> json) =>
    SunMoonIndexData(
      sunAndMoon: json['sunAndMoon'] == null
          ? null
          : SunAndMoon.fromJson(json['sunAndMoon'] as Map<String, dynamic>),
      index: (json['index'] as List<dynamic>?)
          ?.map((e) => LifeIndex.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SunMoonIndexDataToJson(SunMoonIndexData instance) =>
    <String, dynamic>{
      'sunAndMoon': instance.sunAndMoon,
      'index': instance.index,
    };

SunAndMoon _$SunAndMoonFromJson(Map<String, dynamic> json) => SunAndMoon(
  moon: json['moon'] == null
      ? null
      : Moon.fromJson(json['moon'] as Map<String, dynamic>),
  sun: json['sun'] == null
      ? null
      : Sun.fromJson(json['sun'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SunAndMoonToJson(SunAndMoon instance) =>
    <String, dynamic>{'moon': instance.moon, 'sun': instance.sun};

Sun _$SunFromJson(Map<String, dynamic> json) =>
    Sun(sunrise: json['sunrise'] as String?, sunset: json['sunset'] as String?);

Map<String, dynamic> _$SunToJson(Sun instance) => <String, dynamic>{
  'sunrise': instance.sunrise,
  'sunset': instance.sunset,
};

Moon _$MoonFromJson(Map<String, dynamic> json) => Moon(
  moonrise: json['moonrise'] as String?,
  moonset: json['moonset'] as String?,
  moonage: json['moonage'] as String?,
);

Map<String, dynamic> _$MoonToJson(Moon instance) => <String, dynamic>{
  'moonrise': instance.moonrise,
  'moonset': instance.moonset,
  'moonage': instance.moonage,
};

LifeIndex _$LifeIndexFromJson(Map<String, dynamic> json) => LifeIndex(
  indexLevel: json['index_level'] as String?,
  indexContent: json['index_content'] as String?,
  indexTypeCh: json['index_type_ch'] as String?,
);

Map<String, dynamic> _$LifeIndexToJson(LifeIndex instance) => <String, dynamic>{
  'index_level': instance.indexLevel,
  'index_content': instance.indexContent,
  'index_type_ch': instance.indexTypeCh,
};
