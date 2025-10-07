# 天气小组件 - 待修复事项

## 需要修复的属性访问

在 `lib/services/weather_widget_service.dart` 中，以下属性访问需要根据实际的 `WeatherModel` 结构进行调整：

### 当前需要修改的地方：

1. **第61-63行**（天气图标和文字）
```dart
// 当前错误：
final weatherIcon = weatherData.current?.current?.icon ?? '';
final weatherText = weatherData.current?.current?.text ?? '未知';

// 应该改为：
final weatherIcon = weatherData.current?.current?.weatherPic ?? '';
final weatherText = weatherData.current?.current?.weather ?? '未知';
```

2. **第67-71行**（空气质量和风力）
```dart
// 当前错误：
final aqi = weatherData.current?.current?.aqi?.toString() ?? '--';
final aqiLevel = _getAqiLevel(weatherData.current?.current?.aqi ?? 0);
final wind = '${weatherData.current?.current?.windDirection ?? ''}'
    '${weatherData.current?.current?.windScale ?? ''}级';

// 应该改为：
final aqi = weatherData.current?.air?.aqi?.toString() ?? '--';
final aqiLevel = _getAqiLevel(int.tryParse(weatherData.current?.air?.aqi ?? '0') ?? 0);
final wind = '${weatherData.current?.current?.winddir ?? ''}'
    '${weatherData.current?.current?.windpower ?? ''}';
```

3. **第148-175行**（5日预报）
```dart
// 当前错误：
date = DateTime.parse(forecast.date ?? '');
weatherIcon: forecast.iconDay ?? '',
tempHigh: '${forecast.tempMax ?? '--'}°',
tempLow: '${forecast.tempMin ?? '--'}°',

// 应该改为：
date = DateTime.parse(forecast.forecasttime ?? '');
weatherIcon: forecast.weather_am_pic ?? '',
tempHigh: '${forecast.temperature_pm ?? '--'}°',
tempLow: '${forecast.temperature_am ?? '--'}°',
```

## WeatherModel 实际结构参考

### CurrentWeather
```dart
class CurrentWeather {
  final String? airpressure;        // 气压
  final String? weatherPic;         // 天气图标 ✓
  final String? visibility;         // 能见度
  final String? windpower;          // 风力 ✓
  final String? feelstemperature;   // 体感温度
  final String? temperature;        // 温度 ✓
  final String? weather;            // 天气状态 ✓
  final String? humidity;           // 湿度
  final String? weatherIndex;       // 天气指数
  final String? winddir;            // 风向 ✓
  final String? reporttime;         // 报告时间
}
```

### AirQuality (在 CurrentWeatherData.air 中)
```dart
class AirQuality {
  final String? aqi;    // 空气质量指数 ✓
  // ... 其他字段
}
```

### DailyWeather
```dart
class DailyWeather {
  final String? temperature_am;      // 上午温度 ✓
  final String? weather_pm_pic;      // 下午天气图标
  final String? winddir_am;          // 上午风向
  final String? week;                // 星期
  final String? forecasttime;        // 预报时间 ✓
  final String? windpower_pm;        // 下午风力
  final String? weather_pm;          // 下午天气 ✓
  final String? weather_am;          // 上午天气 ✓
  final String? weather_am_pic;      // 上午天气图标 ✓
  final String? temperature_pm;      // 下午温度 ✓
  // ... 其他字段
}
```

## 快速修复脚本

可以使用以下命令批量替换：

```bash
# 在 lib/services/weather_widget_service.dart 中
sed -i '' 's/\.icon/\.weatherPic/g' lib/services/weather_widget_service.dart
sed -i '' 's/\.text/\.weather/g' lib/services/weather_widget_service.dart
sed -i '' 's/current?.aqi/air?.aqi/g' lib/services/weather_widget_service.dart
sed -i '' 's/windDirection/winddir/g' lib/services/weather_widget_service.dart
sed -i '' 's/windScale/windpower/g' lib/services/weather_widget_service.dart
sed -i '' 's/\.date/\.forecasttime/g' lib/services/weather_widget_service.dart
sed -i '' 's/\.iconDay/\.weather_am_pic/g' lib/services/weather_widget_service.dart
sed -i '' 's/\.tempMax/\.temperature_pm/g' lib/services/weather_widget_service.dart
sed -i '' 's/\.tempMin/\.temperature_am/g' lib/services/weather_widget_service.dart
```

## 农历工具类修复

在 `lib/utils/lunar_calendar.dart` 的 `getFullInfo` 方法中，删除未使用的变量：

```dart
/// 获取完整的农历信息字符串
static String getFullInfo(DateTime date) {
  // 删除以下三行：
  // int year = date.year;
  // int month = date.month;
  // int day = date.day;
  
  Map<String, dynamic> lunar = solarToLunar(date);
  return '${lunar['yearGanZhi']}年(${lunar['animal']}年) ${lunar['monthStr']}${lunar['dayStr']}';
}
```

## 测试检查清单

修复完成后，请测试以下功能：

- [ ] 农历日期显示正确
- [ ] 当前天气信息显示正确
- [ ] 温度显示正确
- [ ] 空气质量指数显示正确
- [ ] 风力风向显示正确
- [ ] 降雨提醒显示正确
- [ ] 5日天气预报显示完整
- [ ] 应用内预览正常显示

## 下一步工作

1. 修复上述属性访问问题
2. 添加 `home_widget` 依赖
3. 实现 Android 原生 Widget
4. 实现 iOS Widget Extension
5. 集成到 WeatherProvider 中
6. 测试小组件功能

