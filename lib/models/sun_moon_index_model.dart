import 'package:json_annotation/json_annotation.dart';

part 'sun_moon_index_model.g.dart';

@JsonSerializable()
class SunMoonIndexResponse {
  final int code;
  final SunMoonIndexData? data;
  final String message;
  final dynamic pageNum;

  SunMoonIndexResponse({
    required this.code,
    this.data,
    required this.message,
    this.pageNum,
  });

  factory SunMoonIndexResponse.fromJson(Map<String, dynamic> json) =>
      _$SunMoonIndexResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SunMoonIndexResponseToJson(this);
}

@JsonSerializable()
class SunMoonIndexData {
  final SunAndMoon? sunAndMoon;
  final List<LifeIndex>? index;

  SunMoonIndexData({
    this.sunAndMoon,
    this.index,
  });

  factory SunMoonIndexData.fromJson(Map<String, dynamic> json) =>
      _$SunMoonIndexDataFromJson(json);

  Map<String, dynamic> toJson() => _$SunMoonIndexDataToJson(this);
}

@JsonSerializable()
class SunAndMoon {
  final Moon? moon;
  final Sun? sun;

  SunAndMoon({
    this.moon,
    this.sun,
  });

  factory SunAndMoon.fromJson(Map<String, dynamic> json) =>
      _$SunAndMoonFromJson(json);

  Map<String, dynamic> toJson() => _$SunAndMoonToJson(this);
}

@JsonSerializable()
class Sun {
  final String? sunrise;
  final String? sunset;

  Sun({
    this.sunrise,
    this.sunset,
  });

  factory Sun.fromJson(Map<String, dynamic> json) => _$SunFromJson(json);

  Map<String, dynamic> toJson() => _$SunToJson(this);
}

@JsonSerializable()
class Moon {
  final String? moonrise;
  final String? moonset;
  final String? moonage;

  Moon({
    this.moonrise,
    this.moonset,
    this.moonage,
  });

  factory Moon.fromJson(Map<String, dynamic> json) => _$MoonFromJson(json);

  Map<String, dynamic> toJson() => _$MoonToJson(this);
}

@JsonSerializable()
class LifeIndex {
  @JsonKey(name: 'index_level')
  final String? indexLevel;
  
  @JsonKey(name: 'index_content')
  final String? indexContent;
  
  @JsonKey(name: 'index_type_ch')
  final String? indexTypeCh;

  LifeIndex({
    this.indexLevel,
    this.indexContent,
    this.indexTypeCh,
  });

  factory LifeIndex.fromJson(Map<String, dynamic> json) =>
      _$LifeIndexFromJson(json);

  Map<String, dynamic> toJson() => _$LifeIndexToJson(this);
}
