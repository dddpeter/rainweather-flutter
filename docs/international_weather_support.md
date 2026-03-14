# 国际城市天气支持实施文档

## 概述

成功为RainWeather应用添加了国际城市天气查询功能，使其能够支持全球任意城市的天气查询。

## 技术方案

### 使用的免费API

1. **Open-Meteo API**（主要）
   - 完全免费，无需API密钥
   - 无调用次数限制
   - 基于经纬度查询，支持全球任意地点
   - 数据来源：NOAA GFS、DWD ICON、ECMWF IFS等顶级气象模型

2. **OpenStreetMap Nominatim API**（地理编码）
   - 免费，无需API密钥
   - 将城市名称转换为经纬度坐标
   - 每分钟60次查询限制（对单个应用足够）

### 实现的组件

#### 1. GeocodingService（扩展）
文件：`lib/services/geocoding_service.dart`

新增方法：
- `geocode(String cityName)` - 正向地理编码，将城市名称转换为LocationModel
- 支持缓存机制（1小时过期）
- 使用OpenStreetMap Nominatim API

#### 2. OpenMeteoService（新建）
文件：`lib/services/open_meteo_service.dart`

功能：
- 封装Open-Meteo API调用
- 支持当前天气、24小时预报、15日预报
- 实现请求去重和缓存（30分钟）
- 支持批量查询和预加载

#### 3. WeatherAdapter（新建）
文件：`lib/services/weather_adapter.dart`

功能：
- 将Open-Meteo响应数据转换为WeatherModel
- WMO天气代码到中文天气描述映射
- 数据字段适配和格式化

#### 4. CityTypeDetector（新建）
文件：`lib/utils/city_type_detector.dart`

功能：
- 判断城市类型（国内/国外）
- 支持快速判断和精确判断
- 已知国外城市列表

#### 5. WeatherService（修改）
文件：`lib/services/weather_service.dart`

修改内容：
- 添加GeocodingService和OpenMeteoService依赖
- 集成多数据源支持
- 修改getWeatherDataForLocation方法，支持国外城市

#### 6. CityWeatherProvider（修改）
文件：`lib/providers/city_weather_provider.dart`

修改内容：
- 添加GeocodingService依赖
- 修改loadCityWeather方法，支持国外城市查询
- 使用地理编码服务获取城市坐标

## 数据流程

### 国内城市流程
```
用户输入"北京"
  ↓
CityDataService.findCityIdByName("北京")
  ↓
找到城市ID: 101010100
  ↓
WeatherService.getWeatherData("101010100")
  ↓
使用原有API（weatherol.cn）
  ↓
返回WeatherModel
```

### 国外城市流程
```
用户输入"London"
  ↓
GeocodingService.geocode("London")
  ↓
获取坐标: (51.5074, -0.1278)
  ↓
OpenMeteoService.getWeather(lat, lon)
  ↓
获取Open-MeteoResponse
  ↓
WeatherAdapter.convertToWeatherModel()
  ↓
转换为WeatherModel
  ↓
返回WeatherModel
```

## 缓存策略

1. **地理编码缓存**
   - 缓存时间：1小时
   - 存储：城市名称 -> LocationModel

2. **天气数据缓存**
   - 国内城市：30分钟
   - 国外城市：30分钟
   - 存储：请求键 -> WeatherModel

3. **请求去重**
   - 相同请求在30秒内只执行一次
   - 使用RequestDeduplicator管理

## API特性对比

| 特性 | Open-Meteo | 原有API |
|------|------------|---------|
| 覆盖范围 | 全球 | 仅中国 |
| 费用 | 完全免费 | 未知 |
| API密钥 | 无需 | 需要 |
| 调用限制 | 无限制 | 未知 |
| 数据源 | 顶级气象模型 | 未知 |
| 响应时间 | 200-500ms | 未知 |

## 使用示例

### 在UI中使用
```dart
// 查询国内城市（自动识别）
await cityWeatherProvider.loadCityWeather('北京');

// 查询国外城市（自动识别）
await cityWeatherProvider.loadCityWeather('London');
await cityWeatherProvider.loadCityWeather('Tokyo');
await cityWeatherProvider.loadCityWeather('Paris');
```

### 直接使用服务
```dart
final weatherService = WeatherService.getInstance();

// 通过城市名称获取（自动判断国内/国外）
final weather = await weatherService.getWeatherDataByName('London');

// 通过坐标获取
final location = LocationModel(
  lat: 51.5074,
  lng: -0.1278,
  district: 'London',
  // ...其他字段
);
final weather = await weatherService.getWeatherDataForLocation(location);
```

## 已知限制

1. **Open-Meteo限制**
   - 无服务质量保证
   - 高并发时可能返回429状态
   - 响应时间可能较慢

2. **地理编码限制**
   - OpenStreetMap Nominatim每分钟60次查询限制
   - 部分城市名称可能解析失败

3. **数据完整性**
   - 国外城市不显示农历
   - 国外城市不提供日出日落数据（需要额外查询）
   - 部分数据字段（如气压、能见度）Open-Meteo不提供

## 后续优化建议

1. **增加备用数据源**
   - OpenWeatherMap（免费1000次/天）
   - WeatherAPI.com（免费1000次/月）

2. **优化缓存策略**
   - 实现LRU缓存
   - 预加载常用城市
   - 后台静默更新

3. **增强错误处理**
   - 实现自动重试机制
   - 提供降级方案
   - 更友好的错误提示

4. **性能优化**
   - 实现并发控制
   - 添加请求优先级
   - 优化数据转换

## 文件清单

新建文件：
- `lib/models/open_meteo_models.dart` - Open-Meteo数据模型
- `lib/services/open_meteo_service.dart` - Open-Meteo API服务
- `lib/services/weather_adapter.dart` - 数据适配器
- `lib/utils/city_type_detector.dart` - 城市类型检测器

修改文件：
- `lib/services/geocoding_service.dart` - 扩展地理编码服务
- `lib/services/weather_service.dart` - 集成多数据源
- `lib/providers/city_weather_provider.dart` - 支持国外城市查询

## 测试建议

1. **单元测试**
   - 测试WeatherAdapter数据转换
   - 测试CityTypeDetector类型判断
   - 测试缓存机制

2. **集成测试**
   - 测试国内城市查询
   - 测试国外城市查询
   - 测试边界情况
   - 测试错误处理

3. **手动测试**
   - 测试常用国外城市：London、Tokyo、Paris、New York
   - 测试特殊城市名称：中文、英文、拼写错误
   - 测试网络异常情况

## 总结

成功实现了国际城市天气支持功能，主要特点：
- ✅ 完全免费，无成本
- ✅ 自动判断国内/国外城市
- ✅ 统一的数据接口
- ✅ 完善的缓存机制
- ✅ 向后兼容
- ✅ 用户体验无感知

用户可以直接输入国外城市名称（如"London"、"Tokyo"、"Paris"），系统会自动识别并使用Open-Meteo API获取天气数据。

## 主要城市支持

### 默认主要城市列表
应用默认显示以下主要城市：

**国内城市**：
- 北京、上海、广州、深圳、成都、杭州、武汉、西安、南京

**国际城市**：
- 东京、首尔、新加坡、伦敦、纽约

### 支持的国际城市（city.json）
`assets/data/city.json` 中添加了 14 个常见国际城市：

| 城市 | ID | 备注 |
|------|------|------|
| 东京 | INT_TOKYO | 日本首都 |
| 首尔 | INT_SEOUL | 韩国首都 |
| 新加坡 | INT_SINGAPORE | 东南亚金融中心 |
| 曼谷 | INT_BANGKOK | 泰国首都 |
| 悉尼 | INT_SYDNEY | 澳大利亚最大城市 |
| 墨尔本 | INT_MELBOURNE | 澳大利亚第二大城市 |
| 伦敦 | INT_LONDON | 英国首都 |
| 巴黎 | INT_PARIS | 法国首都 |
| 纽约 | INT_NEWYORK | 美国最大城市 |
| 洛杉矶 | INT_LOSANGELES | 美国西海岸城市 |
| 旧金山 | INT_SANFRANCISCO | 美国科技中心 |
| 温哥华 | INT_VANCOUVER | 加拿大西海岸城市 |
| 多伦多 | INT_TORONTO | 加拿大最大城市 |
| 迪拜 | INT_DUBAI | 阿联酋城市 |

### 国际城市 ID 规则
- 国际城市使用 `INT_` 前缀标识
- `CitiesProvider` 和 `CityWeatherProvider` 会识别此前缀
- 系统自动使用 Open-Meteo API 查询天气数据

## 添加城市弹窗支持

在"主要城市"页面的添加城市弹窗中，已添加以下国际热门城市供用户快速添加：

- 东京（日本）
- 首尔（韩国）
- 新加坡
- 曼谷（泰国）
- 悉尼（澳大利亚）
- 伦敦（英国）
- 巴黎（法国）
- 纽约（美国）

用户也可以通过搜索框输入任意城市名称（如 `London`、`Tokyo`、`Paris`），系统会自动识别并添加。
