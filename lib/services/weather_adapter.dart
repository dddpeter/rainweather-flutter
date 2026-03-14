import '../models/open_meteo_models.dart';
import '../models/weather_model.dart';
import '../models/sun_moon_index_model.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// 天气适配器
/// 
/// 将Open-Meteo API的响应数据转换为项目使用的WeatherModel格式
class WeatherAdapter {
  /// WMO天气代码映射表
  /// 将Open-Meteo的WMO天气代码转换为中文天气描述
  static const Map<int, String> wmoWeatherCodeMap = {
    0: '晴',
    1: '多云',
    2: '多云',
    3: '阴',
    45: '雾',
    48: '雾',
    51: '毛毛雨',
    53: '毛毛雨',
    55: '毛毛雨',
    61: '小雨',
    63: '中雨',
    65: '大雨',
    66: '冻雨',
    67: '冻雨',
    71: '小雪',
    73: '中雪',
    75: '大雪',
    77: '阵雪',
    80: '阵雨',
    81: '阵雨',
    82: '阵雨',
    85: '阵雪',
    86: '阵雪',
    95: '雷阵雨',
    96: '雷阵雨伴有冰雹',
    99: '强雷阵雨',
  };

  /// 根据WMO天气代码获取中文天气描述
  static String getWeatherDescription(int weatherCode) {
    return wmoWeatherCodeMap[weatherCode] ?? '不清楚';
  }

  /// 根据WMO天气代码获取天气图标
  static String getWeatherIcon(int weatherCode) {
    return AppConstants.weatherIcons[getWeatherDescription(weatherCode)] ?? '❓';
  }

  /// 根据WMO天气代码获取白天天气图片
  static String getDayWeatherImage(int weatherCode) {
    final description = getWeatherDescription(weatherCode);
    return AppConstants.dayWeatherImages[description] ?? 'q.png';
  }

  /// 根据WMO天气代码获取夜晚天气图片
  static String getNightWeatherImage(int weatherCode) {
    final description = getWeatherDescription(weatherCode);
    return AppConstants.nightWeatherImages[description] ??
           AppConstants.dayWeatherImages[description] ??
           'q0.png';
  }

  /// 根据WMO天气代码获取中文天气图片
  static String getChineseWeatherImage(int weatherCode, {bool isNight = false}) {
    final description = getWeatherDescription(weatherCode);
    if (isNight) {
      return AppConstants.chineseNightWeatherImages[description] ??
             AppConstants.chineseWeatherImages[description] ??
             '晴.png';
    } else {
      return AppConstants.chineseWeatherImages[description] ?? '晴.png';
    }
  }

  /// 将Open-Meteo响应转换为WeatherModel
  /// 
  /// [openMeteoResponse] Open-Meteo API响应数据
  /// [cityName] 城市名称
  /// 
  /// 返回 WeatherModel 对象
  static WeatherModel convertToWeatherModel(
    OpenMeteoResponse openMeteoResponse,
    String cityName,
  ) {
    try {
      // 转换当前天气（传递hourly数据以获取湿度、气压、能见度）
      final currentWeatherData = _convertCurrentWeather(
        openMeteoResponse.currentWeather,
        openMeteoResponse.timezone,
        openMeteoResponse.hourly, // 传递hourly数据
      );

      // 转换24小时预报
      final forecast24h = _convertHourlyForecast(
        openMeteoResponse.hourly,
      );

      // 转换15日预报
      final forecast15d = _convertDailyForecast(
        openMeteoResponse.daily,
      );

      return WeatherModel(
        current: currentWeatherData,
        forecast24h: forecast24h,
        forecast15d: forecast15d,
        air: AirQuality(
          AQI: '未知',
          levelIndex: '未知',
        ),
        tips: '数据来源：Open-Meteo',
      );
    } catch (e, stackTrace) {
      Logger.e(
        '转换WeatherModel失败: $cityName',
        tag: 'WeatherAdapter',
        error: e,
        stackTrace: stackTrace,
      );
      // 返回空对象
      return WeatherModel();
    }
  }

  /// 转换当前天气数据
  static CurrentWeatherData? _convertCurrentWeather(
    OpenMeteoCurrentWeather? currentWeather,
    String? timezone,
    OpenMeteoHourlyWeather? hourlyWeather, // 添加hourly参数
  ) {
    if (currentWeather == null) return null;

    final weatherDesc = getWeatherDescription(currentWeather.weathercode);
    final weatherIcon = getWeatherIcon(currentWeather.weathercode);

    // 从hourly数据中提取当前小时的湿度、气压、能见度
    String humidity = '未知';
    String airpressure = '未知';
    String visibility = '未知';

    if (hourlyWeather != null && hourlyWeather.hourCount > 0) {
      // 获取第一个小时的数据（当前小时）
      final currentHourData = hourlyWeather.getHourData(0);
      
      // 湿度（百分比）- 湿度范围 0-100，大于等于0都有效
      if (currentHourData.humidity >= 0) {
        humidity = '${currentHourData.humidity.round()}';
      }
      
      // 气压（hPa）- 正常气压范围 900-1100，大于0都有效
      if (currentHourData.pressure > 0) {
        airpressure = '${currentHourData.pressure.round()} hPa';
      }
      
      // 能见度（米转换为公里）- 能见度可以为0（大雾），但需要检查是否有数据
      // 如果能见度大于等于0，说明有数据（包括0值）
      if (currentHourData.visibility >= 0) {
        final visibilityKm = currentHourData.visibility / 1000.0;
        visibility = '${visibilityKm.toStringAsFixed(1)} km';
      }
    }

    return CurrentWeatherData(
      current: CurrentWeather(
        temperature: currentWeather.temperature.round().toString(),
        weather: weatherDesc,
        humidity: humidity,
        windpower: _convertWindSpeed(currentWeather.windspeed),
        winddir: _convertWindDirection(currentWeather.winddirection),
        airpressure: airpressure,
        visibility: visibility,
        feelstemperature: currentWeather.temperature.round().toString(), // 简化处理
        weatherPic: weatherIcon,
        weatherIndex: _getWeatherIndex(currentWeather.weathercode),
        reporttime: currentWeather.time?.toIso8601String() ?? DateTime.now().toIso8601String(),
      ),
      alerts: [], // Open-Meteo不提供天气预警
      nongLi: null, // 国外城市不显示农历
      air: AirQuality(
        AQI: '未知',
        levelIndex: '未知',
      ),
      tips: '国际天气数据',
    );
  }

  /// 转换24小时预报
  static List<HourlyWeather>? _convertHourlyForecast(
    OpenMeteoHourlyWeather? hourlyWeather,
  ) {
    if (hourlyWeather == null || hourlyWeather.hourCount == 0) return null;

    final result = <HourlyWeather>[];
    final count = hourlyWeather.hourCount > 24 ? 24 : hourlyWeather.hourCount;

    for (int i = 0; i < count; i++) {
      final hourData = hourlyWeather.getHourData(i);
      final weatherDesc = getWeatherDescription(hourData.weatherCode);
      final weatherIcon = getWeatherIcon(hourData.weatherCode);

      result.add(HourlyWeather(
        forecasttime: _formatForecastTime(hourData.time),
        temperature: hourData.temperature.round().toString(),
        weather: weatherDesc,
        weatherCode: hourData.weatherCode.toString(),
        weatherPic: weatherIcon,
        windPower: _convertWindSpeed(hourData.windSpeed),
        windDir: _convertWindDirection(0), // Open-Meteo每小时不包含风向
        windDirectionDegree: '0',
      ));
    }

    return result;
  }

  /// 转换15日预报
  static List<DailyWeather>? _convertDailyForecast(
    OpenMeteoDailyWeather? dailyWeather,
  ) {
    if (dailyWeather == null || dailyWeather.dayCount == 0) return null;

    final result = <DailyWeather>[];
    final count = dailyWeather.dayCount > 15 ? 15 : dailyWeather.dayCount;

    for (int i = 0; i < count; i++) {
      final dayData = dailyWeather.getDayData(i);
      final weatherDesc = getWeatherDescription(dayData.weatherCode);
      final weatherIcon = getWeatherIcon(dayData.weatherCode);

      result.add(DailyWeather(
        forecasttime: _formatForecastDate(dayData.date),
        week: _getWeekday(dayData.date),
        temperature_am: dayData.tempMin.round().toString(),
        temperature_pm: dayData.tempMax.round().toString(),
        weather_am: weatherDesc,
        weather_pm: weatherDesc,
        weather_am_pic: weatherIcon,
        weather_pm_pic: weatherIcon,
        windpower_am: _convertWindSpeed(dayData.windSpeed),
        windpower_pm: _convertWindSpeed(dayData.windSpeed),
        winddir_am: _convertWindDirection(dayData.windDirection),
        winddir_pm: _convertWindDirection(dayData.windDirection),
        weather_index_am: _getWeatherIndex(dayData.weatherCode),
        weather_index_pm: _getWeatherIndex(dayData.weatherCode),
        sunrise_sunset: null, // Open-Meteo需要单独查询日出日落
        reporttime: dayData.date.toIso8601String(),
      ));
    }

    return result;
  }

  /// 转换风速
  /// Open-Meteo使用km/h，转换为中文描述
  static String _convertWindSpeed(double speedKmh) {
    if (speedKmh < 1) return '无风';
    if (speedKmh < 6) return '1级';
    if (speedKmh < 12) return '2级';
    if (speedKmh < 20) return '3级';
    if (speedKmh < 29) return '4级';
    if (speedKmh < 39) return '5级';
    if (speedKmh < 50) return '6级';
    if (speedKmh < 62) return '7级';
    if (speedKmh < 75) return '8级';
    if (speedKmh < 89) return '9级';
    if (speedKmh < 103) return '10级';
    if (speedKmh < 117) return '11级';
    return '12级';
  }

  /// 转换风向
  static String _convertWindDirection(int degree) {
    const directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
    final index = ((degree + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// 获取天气指数
  static String _getWeatherIndex(int weatherCode) {
    if (weatherCode == 0) return '1'; // 晴
    if (weatherCode <= 3) return '2'; // 多云/阴
    if (weatherCode <= 49) return '3'; // 雾
    if (weatherCode <= 69) return '4'; // 雨
    if (weatherCode <= 79) return '5'; // 雪
    return '6'; // 其他
  }

  /// 格式化预报时间（小时）
  static String _formatForecastTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:00';
  }

  /// 格式化预报日期
  static String _formatForecastDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 获取星期
  static String _getWeekday(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  /// 根据天气代码获取建议
  static String getWeatherTips(int weatherCode) {
    final weatherDesc = getWeatherDescription(weatherCode);
    
    if (weatherDesc.contains('晴')) {
      return '天气晴朗，适合户外活动';
    } else if (weatherDesc.contains('多云')) {
      return '多云天气，温度适宜';
    } else if (weatherDesc.contains('阴')) {
      return '阴天，请注意保暖';
    } else if (weatherDesc.contains('雨')) {
      return '有雨，请携带雨具';
    } else if (weatherDesc.contains('雪')) {
      return '有雪，注意路面湿滑';
    } else if (weatherDesc.contains('雾') || weatherDesc.contains('霾')) {
      return '雾霾天气，请佩戴口罩，减少外出';
    }
    
    return '请注意天气变化';
  }

  /// 为国外城市生成生活指数
  /// 
  /// 根据天气数据（温度、天气代码等）生成基本的生活指数建议
  /// 
  /// [temperature] 当前温度（摄氏度）
  /// [weatherCode] WMO天气代码
  /// [humidity] 湿度（百分比，可选）
  /// [windSpeed] 风速（km/h，可选）
  /// 
  /// 返回 SunMoonIndexData 对象，包含生活指数列表
  static SunMoonIndexData generateLifeIndex({
    required double temperature,
    required int weatherCode,
    double? humidity,
    double? windSpeed,
  }) {
    final List<LifeIndex> indices = [];

    // 1. 穿衣指数
    indices.add(_generateClothingIndex(temperature));

    // 2. 感冒指数
    indices.add(_generateColdIndex(temperature, weatherCode, windSpeed));

    // 3. 紫外线强度指数
    indices.add(_generateUVIndex(weatherCode));

    // 4. 洗车指数
    indices.add(_generateCarWashIndex(weatherCode));

    // 5. 运动指数
    indices.add(_generateExerciseIndex(temperature, weatherCode, windSpeed));

    // 6. 化妆指数
    indices.add(_generateMakeupIndex(temperature, humidity));

    return SunMoonIndexData(
      sunAndMoon: null, // 国外城市不提供日出日落数据
      index: indices,
    );
  }

  /// 生成穿衣指数
  static LifeIndex _generateClothingIndex(double temp) {
    String level;
    String content;

    if (temp >= 35) {
      level = '炎热';
      content = '天气炎热，建议穿着短衣、短裙、薄短裤等夏季服装';
    } else if (temp >= 28) {
      level = '热';
      content = '天气较热，建议穿着短衫、短裙、短裤等夏季服装';
    } else if (temp >= 21) {
      level = '舒适';
      content = '温度适中，建议穿着薄型T恤、衬衫等春秋过渡装';
    } else if (temp >= 14) {
      level = '较舒适';
      content = '天气较凉，建议穿着长袖衬衫、薄外套等春秋装';
    } else if (temp >= 7) {
      level = '较冷';
      content = '天气较冷，建议穿着毛衣、厚外套等冬季服装';
    } else if (temp >= -5) {
      level = '冷';
      content = '天气寒冷，建议穿着棉衣、羽绒服等冬季服装';
    } else {
      level = '极冷';
      content = '天气极冷，建议穿着厚羽绒服、棉衣等保暖服装';
    }

    return LifeIndex(
      indexTypeCh: '穿衣指数',
      indexLevel: level,
      indexContent: content,
    );
  }

  /// 生成感冒指数
  static LifeIndex _generateColdIndex(double temp, int weatherCode, double? windSpeed) {
    String level;
    String content;

    // 根据温度和天气状况判断感冒风险
    final isRainy = weatherCode >= 51 && weatherCode <= 67;
    final isSnowy = weatherCode >= 71 && weatherCode <= 86;
    final isWindy = windSpeed != null && windSpeed > 30;

    int riskScore = 0;

    // 温度影响
    if (temp < 5) riskScore += 3;
    else if (temp < 15) riskScore += 2;
    else if (temp < 25) riskScore += 1;

    // 天气影响
    if (isRainy || isSnowy) riskScore += 2;

    // 风力影响
    if (isWindy) riskScore += 1;

    if (riskScore >= 5) {
      level = '极易发';
      content = '天气恶劣，极易感冒，请注意防寒保暖，避免外出';
    } else if (riskScore >= 3) {
      level = '易发';
      content = '天气变化较大，容易感冒，请注意防护';
    } else if (riskScore >= 2) {
      level = '较易发';
      content = '天气略有波动，感冒几率较低，注意适当防护';
    } else {
      level = '少发';
      content = '天气条件良好，感冒几率较低';
    }

    return LifeIndex(
      indexTypeCh: '感冒指数',
      indexLevel: level,
      indexContent: content,
    );
  }

  /// 生成紫外线强度指数
  static LifeIndex _generateUVIndex(int weatherCode) {
    String level;
    String content;

    // 根据天气状况估算紫外线强度
    if (weatherCode == 0) {
      // 晴天
      level = '很强';
      content = '紫外线很强，建议涂抹SPF30+防晒霜，佩戴太阳镜';
    } else if (weatherCode <= 2) {
      // 多云
      level = '强';
      content = '紫外线较强，建议涂抹SPF20+防晒霜';
    } else if (weatherCode == 3) {
      // 阴天
      level = '弱';
      content = '紫外线较弱，无需特殊防护';
    } else {
      // 雨雪等天气
      level = '最弱';
      content = '紫外线很弱，无需防护';
    }

    return LifeIndex(
      indexTypeCh: '紫外线强度指数',
      indexLevel: level,
      indexContent: content,
    );
  }

  /// 生成洗车指数
  static LifeIndex _generateCarWashIndex(int weatherCode) {
    String level;
    String content;

    final isRainy = weatherCode >= 51 && weatherCode <= 82;
    final isSnowy = weatherCode >= 71 && weatherCode <= 86;

    if (isRainy || isSnowy) {
      level = '不宜';
      content = '有雨雪天气，不宜洗车';
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      // 雾
      level = '较不宜';
      content = '有雾天气，较不宜洗车';
    } else if (weatherCode <= 3) {
      // 晴或多云
      level = '适宜';
      content = '天气晴好，适宜洗车';
    } else {
      level = '较适宜';
      content = '天气尚可，可以洗车';
    }

    return LifeIndex(
      indexTypeCh: '洗车指数',
      indexLevel: level,
      indexContent: content,
    );
  }

  /// 生成运动指数
  static LifeIndex _generateExerciseIndex(double temp, int weatherCode, double? windSpeed) {
    String level;
    String content;

    final isRainy = weatherCode >= 51 && weatherCode <= 82;
    final isSnowy = weatherCode >= 71 && weatherCode <= 86;
    final isStormy = weatherCode >= 95;
    final isWindy = windSpeed != null && windSpeed > 40;

    // 综合判断运动适宜度
    int suitabilityScore = 10;

    // 温度影响
    if (temp < -10 || temp > 38) suitabilityScore -= 5;
    else if (temp < 0 || temp > 35) suitabilityScore -= 3;
    else if (temp < 10 || temp > 30) suitabilityScore -= 1;

    // 天气影响
    if (isStormy) suitabilityScore -= 5;
    else if (isRainy || isSnowy) suitabilityScore -= 3;

    // 风力影响
    if (isWindy) suitabilityScore -= 2;

    if (suitabilityScore >= 8) {
      level = '适宜';
      content = '天气良好，适宜户外运动';
    } else if (suitabilityScore >= 6) {
      level = '较适宜';
      content = '天气尚可，可以进行户外运动';
    } else if (suitabilityScore >= 4) {
      level = '较不宜';
      content = '天气不太适合户外运动，建议室内运动';
    } else {
      level = '不宜';
      content = '天气恶劣，不宜户外运动';
    }

    return LifeIndex(
      indexTypeCh: '运动指数',
      indexLevel: level,
      indexContent: content,
    );
  }

  /// 生成化妆指数
  static LifeIndex _generateMakeupIndex(double temp, double? humidity) {
    String level;
    String content;

    // 根据温度和湿度判断
    final isDry = humidity != null && humidity < 40;
    final isHumid = humidity != null && humidity > 70;

    if (temp >= 30) {
      if (isHumid) {
        level = '防脱水';
        content = '高温高湿，建议使用控油护肤品，注意防晒';
      } else {
        level = '防晒';
        content = '高温干燥，建议使用保湿护肤品，加强防晒';
      }
    } else if (temp >= 20) {
      if (isDry) {
        level = '保湿';
        content = '天气干燥，建议使用保湿护肤品';
      } else {
        level = '滋润';
        content = '天气适宜，常规护肤即可';
      }
    } else if (temp >= 10) {
      level = '滋润';
      content = '天气较凉，建议使用滋润型护肤品';
    } else {
      level = '保湿';
      content = '天气寒冷干燥，建议使用滋润保湿护肤品';
    }

    return LifeIndex(
      indexTypeCh: '化妆指数',
      indexLevel: level,
      indexContent: content,
    );
  }
}
