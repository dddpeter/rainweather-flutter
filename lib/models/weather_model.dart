import 'package:json_annotation/json_annotation.dart';

part 'weather_model.g.dart';

@JsonSerializable()
class WeatherModel {
  final CurrentWeatherData? current;
  final List<HourlyWeather>? forecast24h;
  final List<DailyWeather>? forecast15d;
  final AirQuality? air;
  final String? tips;

  WeatherModel({
    this.current,
    this.forecast24h,
    this.forecast15d,
    this.air,
    this.tips,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherModelToJson(this);
}

@JsonSerializable()
class CurrentWeatherData {
  final List<WeatherAlert>? alerts;
  final CurrentWeather? current;
  final String? nongLi;
  final AirQuality? air;
  final String? tips;

  CurrentWeatherData({
    this.alerts,
    this.current,
    this.nongLi,
    this.air,
    this.tips,
  });

  factory CurrentWeatherData.fromJson(Map<String, dynamic> json) =>
      _$CurrentWeatherDataFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentWeatherDataToJson(this);
}

@JsonSerializable()
class CurrentWeather {
  final String? airpressure;
  final String? weatherPic;
  final String? visibility;
  final String? windpower;
  final String? feelstemperature;
  final String? temperature;
  final String? weather;
  final String? humidity;
  final String? weatherIndex;
  final String? winddir;
  final String? reporttime;

  CurrentWeather({
    this.airpressure,
    this.weatherPic,
    this.visibility,
    this.windpower,
    this.feelstemperature,
    this.temperature,
    this.weather,
    this.humidity,
    this.weatherIndex,
    this.winddir,
    this.reporttime,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) =>
      _$CurrentWeatherFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentWeatherToJson(this);
}

@JsonSerializable()
class HourlyWeather {
  final String? windDirectionDegree;
  final String? weatherPic;
  final String? forecasttime;
  final String? windPower;
  final String? weatherCode;
  final String? temperature;
  final String? weather;
  final String? windDir;

  HourlyWeather({
    this.windDirectionDegree,
    this.weatherPic,
    this.forecasttime,
    this.windPower,
    this.weatherCode,
    this.temperature,
    this.weather,
    this.windDir,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) =>
      _$HourlyWeatherFromJson(json);

  Map<String, dynamic> toJson() => _$HourlyWeatherToJson(this);
}

@JsonSerializable()
class DailyWeather {
  final String? temperature_am;
  final String? weather_pm_pic;
  final String? winddir_am;
  final String? week;
  final String? forecasttime;
  final String? windpower_pm;
  final String? weather_pm;
  final String? reporttime;
  final String? weather_index_pm;
  final String? winddir_pm;
  final String? weather_am;
  final String? sunrise_sunset;
  final String? windpower_am;
  final String? weather_am_pic;
  final String? temperature_pm;
  final String? weather_index_am;

  DailyWeather({
    this.temperature_am,
    this.weather_pm_pic,
    this.winddir_am,
    this.week,
    this.forecasttime,
    this.windpower_pm,
    this.weather_pm,
    this.reporttime,
    this.weather_index_pm,
    this.winddir_pm,
    this.weather_am,
    this.sunrise_sunset,
    this.windpower_am,
    this.weather_am_pic,
    this.temperature_pm,
    this.weather_index_am,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) =>
      _$DailyWeatherFromJson(json);

  Map<String, dynamic> toJson() => _$DailyWeatherToJson(this);
}

@JsonSerializable()
class AirQuality {
  final String? levelIndex;
  final String? AQI;

  AirQuality({this.levelIndex, this.AQI});

  factory AirQuality.fromJson(Map<String, dynamic> json) =>
      _$AirQualityFromJson(json);

  Map<String, dynamic> toJson() => _$AirQualityToJson(this);
}

@JsonSerializable()
class CityInfo {
  final String id;
  final String name;

  CityInfo({required this.id, required this.name});

  factory CityInfo.fromJson(Map<String, dynamic> json) =>
      _$CityInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CityInfoToJson(this);
}

@JsonSerializable()
class WeatherAlert {
  final String? publishTime;
  final String? city;
  final String? level;
  final String? typeNumber;
  final String? alertPic;
  final String? provice;
  final String? levelNumber;
  final String? alertid;
  final String? type;
  final String? content;

  WeatherAlert({
    this.publishTime,
    this.city,
    this.level,
    this.typeNumber,
    this.alertPic,
    this.provice,
    this.levelNumber,
    this.alertid,
    this.type,
    this.content,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) =>
      _$WeatherAlertFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherAlertToJson(this);
}
