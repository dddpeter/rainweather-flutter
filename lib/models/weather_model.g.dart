// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherModel _$WeatherModelFromJson(Map<String, dynamic> json) => WeatherModel(
  current: json['current'] == null
      ? null
      : CurrentWeatherData.fromJson(json['current'] as Map<String, dynamic>),
  forecast24h: (json['forecast24h'] as List<dynamic>?)
      ?.map((e) => HourlyWeather.fromJson(e as Map<String, dynamic>))
      .toList(),
  forecast15d: (json['forecast15d'] as List<dynamic>?)
      ?.map((e) => DailyWeather.fromJson(e as Map<String, dynamic>))
      .toList(),
  air: json['air'] == null
      ? null
      : AirQuality.fromJson(json['air'] as Map<String, dynamic>),
  tips: json['tips'] as String?,
);

Map<String, dynamic> _$WeatherModelToJson(WeatherModel instance) =>
    <String, dynamic>{
      'current': instance.current,
      'forecast24h': instance.forecast24h,
      'forecast15d': instance.forecast15d,
      'air': instance.air,
      'tips': instance.tips,
    };

CurrentWeatherData _$CurrentWeatherDataFromJson(Map<String, dynamic> json) =>
    CurrentWeatherData(
      alerts: json['alerts'] as List<dynamic>?,
      current: json['current'] == null
          ? null
          : CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
      nongLi: json['nongLi'] as String?,
      air: json['air'] == null
          ? null
          : AirQuality.fromJson(json['air'] as Map<String, dynamic>),
      tips: json['tips'] as String?,
    );

Map<String, dynamic> _$CurrentWeatherDataToJson(CurrentWeatherData instance) =>
    <String, dynamic>{
      'alerts': instance.alerts,
      'current': instance.current,
      'nongLi': instance.nongLi,
      'air': instance.air,
      'tips': instance.tips,
    };

CurrentWeather _$CurrentWeatherFromJson(Map<String, dynamic> json) =>
    CurrentWeather(
      airpressure: json['airpressure'] as String?,
      weatherPic: json['weatherPic'] as String?,
      visibility: json['visibility'] as String?,
      windpower: json['windpower'] as String?,
      feelstemperature: json['feelstemperature'] as String?,
      temperature: json['temperature'] as String?,
      weather: json['weather'] as String?,
      humidity: json['humidity'] as String?,
      weatherIndex: json['weatherIndex'] as String?,
      winddir: json['winddir'] as String?,
      reporttime: json['reporttime'] as String?,
    );

Map<String, dynamic> _$CurrentWeatherToJson(CurrentWeather instance) =>
    <String, dynamic>{
      'airpressure': instance.airpressure,
      'weatherPic': instance.weatherPic,
      'visibility': instance.visibility,
      'windpower': instance.windpower,
      'feelstemperature': instance.feelstemperature,
      'temperature': instance.temperature,
      'weather': instance.weather,
      'humidity': instance.humidity,
      'weatherIndex': instance.weatherIndex,
      'winddir': instance.winddir,
      'reporttime': instance.reporttime,
    };

HourlyWeather _$HourlyWeatherFromJson(Map<String, dynamic> json) =>
    HourlyWeather(
      windDirectionDegree: json['windDirectionDegree'] as String?,
      weatherPic: json['weatherPic'] as String?,
      forecasttime: json['forecasttime'] as String?,
      windPower: json['windPower'] as String?,
      weatherCode: json['weatherCode'] as String?,
      temperature: json['temperature'] as String?,
      weather: json['weather'] as String?,
      windDir: json['windDir'] as String?,
    );

Map<String, dynamic> _$HourlyWeatherToJson(HourlyWeather instance) =>
    <String, dynamic>{
      'windDirectionDegree': instance.windDirectionDegree,
      'weatherPic': instance.weatherPic,
      'forecasttime': instance.forecasttime,
      'windPower': instance.windPower,
      'weatherCode': instance.weatherCode,
      'temperature': instance.temperature,
      'weather': instance.weather,
      'windDir': instance.windDir,
    };

DailyWeather _$DailyWeatherFromJson(Map<String, dynamic> json) => DailyWeather(
  temperature_am: json['temperature_am'] as String?,
  weather_pm_pic: json['weather_pm_pic'] as String?,
  winddir_am: json['winddir_am'] as String?,
  week: json['week'] as String?,
  forecasttime: json['forecasttime'] as String?,
  windpower_pm: json['windpower_pm'] as String?,
  weather_pm: json['weather_pm'] as String?,
  reporttime: json['reporttime'] as String?,
  weather_index_pm: json['weather_index_pm'] as String?,
  winddir_pm: json['winddir_pm'] as String?,
  weather_am: json['weather_am'] as String?,
  sunrise_sunset: json['sunrise_sunset'] as String?,
  windpower_am: json['windpower_am'] as String?,
  weather_am_pic: json['weather_am_pic'] as String?,
  temperature_pm: json['temperature_pm'] as String?,
  weather_index_am: json['weather_index_am'] as String?,
);

Map<String, dynamic> _$DailyWeatherToJson(DailyWeather instance) =>
    <String, dynamic>{
      'temperature_am': instance.temperature_am,
      'weather_pm_pic': instance.weather_pm_pic,
      'winddir_am': instance.winddir_am,
      'week': instance.week,
      'forecasttime': instance.forecasttime,
      'windpower_pm': instance.windpower_pm,
      'weather_pm': instance.weather_pm,
      'reporttime': instance.reporttime,
      'weather_index_pm': instance.weather_index_pm,
      'winddir_pm': instance.winddir_pm,
      'weather_am': instance.weather_am,
      'sunrise_sunset': instance.sunrise_sunset,
      'windpower_am': instance.windpower_am,
      'weather_am_pic': instance.weather_am_pic,
      'temperature_pm': instance.temperature_pm,
      'weather_index_am': instance.weather_index_am,
    };

AirQuality _$AirQualityFromJson(Map<String, dynamic> json) => AirQuality(
  levelIndex: json['levelIndex'] as String?,
  AQI: json['AQI'] as String?,
);

Map<String, dynamic> _$AirQualityToJson(AirQuality instance) =>
    <String, dynamic>{'levelIndex': instance.levelIndex, 'AQI': instance.AQI};

CityInfo _$CityInfoFromJson(Map<String, dynamic> json) =>
    CityInfo(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$CityInfoToJson(CityInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};
