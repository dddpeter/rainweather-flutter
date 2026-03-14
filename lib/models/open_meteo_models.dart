/// Open-Meteo API 响应数据模型

/// Open-Meteo 当前天气数据
class OpenMeteoCurrentWeather {
  final double temperature;
  final double windspeed;
  final int winddirection;
  final int weathercode;
  final int isDay;
  final DateTime? time;

  OpenMeteoCurrentWeather({
    required this.temperature,
    required this.windspeed,
    required this.winddirection,
    required this.weathercode,
    required this.isDay,
    this.time,
  });

  factory OpenMeteoCurrentWeather.fromJson(Map<String, dynamic> json) {
    return OpenMeteoCurrentWeather(
      temperature: (json['temperature'] as num).toDouble(),
      windspeed: (json['windspeed'] as num).toDouble(),
      winddirection: json['winddirection'] as int? ?? 0,
      weathercode: json['weathercode'] as int? ?? 0,
      isDay: json['is_day'] as int? ?? 1,
      time: json['time'] != null ? DateTime.parse(json['time'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'windspeed': windspeed,
      'winddirection': winddirection,
      'weathercode': weathercode,
      'is_day': isDay,
      'time': time?.toIso8601String(),
    };
  }
}

/// Open-Meteo 每日天气数据
class OpenMeteoDailyWeather {
  final List<DateTime> time;
  final List<double> temperature2mMax;
  final List<double> temperature2mMin;
  final List<double> precipitationSum;
  final List<int> weathercode;
  final List<double> windspeed10mMax;
  final List<int> windDirection10mDominant; // 主导风向（度）

  OpenMeteoDailyWeather({
    required this.time,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationSum,
    required this.weathercode,
    required this.windspeed10mMax,
    this.windDirection10mDominant = const [], // 默认为空列表
  });

  factory OpenMeteoDailyWeather.fromJson(Map<String, dynamic> json) {
    List<DateTime> parseTimeList(List<dynamic> timeList) {
      return timeList.map((t) => DateTime.parse(t as String)).toList();
    }

    List<double> parseDoubleList(List<dynamic> list) {
      return list.map((v) => (v as num).toDouble()).toList();
    }

    List<int> parseIntList(List<dynamic> list) {
      return list.map((v) => v as int).toList();
    }

    return OpenMeteoDailyWeather(
      time: parseTimeList(json['time'] as List<dynamic>? ?? []),
      temperature2mMax: parseDoubleList(json['temperature_2m_max'] as List<dynamic>? ?? []),
      temperature2mMin: parseDoubleList(json['temperature_2m_min'] as List<dynamic>? ?? []),
      precipitationSum: parseDoubleList(json['precipitation_sum'] as List<dynamic>? ?? []),
      weathercode: parseIntList(json['weathercode'] as List<dynamic>? ?? []),
      windspeed10mMax: parseDoubleList(json['windspeed_10m_max'] as List<dynamic>? ?? []),
      windDirection10mDominant: parseIntList(json['wind_direction_10m_dominant'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.map((t) => t.toIso8601String()).toList(),
      'temperature_2m_max': temperature2mMax,
      'temperature_2m_min': temperature2mMin,
      'precipitation_sum': precipitationSum,
      'weathercode': weathercode,
      'windspeed_10m_max': windspeed10mMax,
      'wind_direction_10m_dominant': windDirection10mDominant,
    };
  }

  int get dayCount => time.length;

  DailyWeatherData getDayData(int index) {
    if (index < 0 || index >= dayCount) {
      throw RangeError('Index $index out of range (0-${dayCount - 1})');
    }
    return DailyWeatherData(
      date: time[index],
      tempMax: temperature2mMax[index],
      tempMin: temperature2mMin[index],
      precipitation: precipitationSum[index],
      weatherCode: weathercode[index],
      windSpeed: windspeed10mMax[index],
      windDirection: index < windDirection10mDominant.length ? windDirection10mDominant[index] : 0,
    );
  }
}

/// 每日天气数据
class DailyWeatherData {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;
  final int windDirection; // 风向（度）

  DailyWeatherData({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
    this.windDirection = 0, // 默认值为0
  });
}

/// Open-Meteo 小时天气数据
class OpenMeteoHourlyWeather {
  final List<DateTime> time;
  final List<double> temperature2m;
  final List<double> relativehumidity2m;
  final List<int> weathercode;
  final List<double> windspeed10m;
  final List<double> pressureMsl; // 海平面气压（hPa）
  final List<double> visibility; // 能见度（米）

  OpenMeteoHourlyWeather({
    required this.time,
    required this.temperature2m,
    required this.relativehumidity2m,
    required this.weathercode,
    required this.windspeed10m,
    this.pressureMsl = const [], // 默认为空列表
    this.visibility = const [], // 默认为空列表
  });

  factory OpenMeteoHourlyWeather.fromJson(Map<String, dynamic> json) {
    List<DateTime> parseTimeList(List<dynamic> timeList) {
      return timeList.map((t) => DateTime.parse(t as String)).toList();
    }

    List<double> parseDoubleList(List<dynamic> list) {
      return list.map((v) => (v as num).toDouble()).toList();
    }

    List<int> parseIntList(List<dynamic> list) {
      return list.map((v) => v as int).toList();
    }

    return OpenMeteoHourlyWeather(
      time: parseTimeList(json['time'] as List<dynamic>? ?? []),
      temperature2m: parseDoubleList(json['temperature_2m'] as List<dynamic>? ?? []),
      relativehumidity2m: parseDoubleList(json['relativehumidity_2m'] as List<dynamic>? ?? []),
      weathercode: parseIntList(json['weathercode'] as List<dynamic>? ?? []),
      windspeed10m: parseDoubleList(json['windspeed_10m'] as List<dynamic>? ?? []),
      pressureMsl: parseDoubleList(json['pressure_msl'] as List<dynamic>? ?? []),
      visibility: parseDoubleList(json['visibility'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.map((t) => t.toIso8601String()).toList(),
      'temperature_2m': temperature2m,
      'relativehumidity_2m': relativehumidity2m,
      'weathercode': weathercode,
      'windspeed_10m': windspeed10m,
      'pressure_msl': pressureMsl,
      'visibility': visibility,
    };
  }

  int get hourCount => time.length;

  HourlyWeatherData getHourData(int index) {
    if (index < 0 || index >= hourCount) {
      throw RangeError('Index $index out of range (0-${hourCount - 1})');
    }
    return HourlyWeatherData(
      time: time[index],
      temperature: temperature2m[index],
      humidity: relativehumidity2m[index],
      weatherCode: weathercode[index],
      windSpeed: windspeed10m[index],
      pressure: index < pressureMsl.length ? pressureMsl[index] : 0,
      visibility: index < visibility.length ? visibility[index] : 0,
    );
  }
}

/// 小时天气数据
class HourlyWeatherData {
  final DateTime time;
  final double temperature;
  final double humidity;
  final int weatherCode;
  final double windSpeed;
  final double pressure; // 气压（hPa）
  final double visibility; // 能见度（米）

  HourlyWeatherData({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.windSpeed,
    this.pressure = 0, // 默认值为0
    this.visibility = 0, // 默认值为0
  });
}

/// Open-Meteo API 完整响应
class OpenMeteoResponse {
  final double latitude;
  final double longitude;
  final double? elevation;
  final String? timezone;
  final OpenMeteoCurrentWeather? currentWeather;
  final OpenMeteoDailyWeather? daily;
  final OpenMeteoHourlyWeather? hourly;

  OpenMeteoResponse({
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.timezone,
    this.currentWeather,
    this.daily,
    this.hourly,
  });

  factory OpenMeteoResponse.fromJson(Map<String, dynamic> json) {
    return OpenMeteoResponse(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevation: json['elevation'] != null ? (json['elevation'] as num).toDouble() : null,
      timezone: json['timezone'] as String?,
      currentWeather: json['current_weather'] != null
          ? OpenMeteoCurrentWeather.fromJson(json['current_weather'] as Map<String, dynamic>)
          : null,
      daily: json['daily'] != null
          ? OpenMeteoDailyWeather.fromJson(json['daily'] as Map<String, dynamic>)
          : null,
      hourly: json['hourly'] != null
          ? OpenMeteoHourlyWeather.fromJson(json['hourly'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'timezone': timezone,
      'current_weather': currentWeather?.toJson(),
      'daily': daily?.toJson(),
      'hourly': hourly?.toJson(),
    };
  }
}
