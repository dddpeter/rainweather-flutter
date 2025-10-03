# 雨天气 Flutter

从原始Android项目重构的Flutter天气应用程序。该应用提供实时天气信息，包括定位服务、天气预报和美观的UI组件。

> **English Documentation**: [README_EN.md](README_EN.md) | **中文文档**: 本文件

## 功能特性

### 核心功能
- **实时天气数据**：从weatherol.cn API获取当前天气状况
- **定位服务**：使用GPS自动检测用户位置
- **天气预报**：24小时逐时预报和15天每日预报
- **温度图表**：显示温度趋势的交互式图表
- **空气质量**：显示空气质量指数(AQI)和颜色编码等级
- **主要城市**：快速访问中国主要城市的天气

### UI/UX特性
- **深色主题**：现代深色主题配蓝色强调色
- **响应式设计**：适配不同屏幕尺寸
- **下拉刷新**：通过下拉手势轻松刷新数据
- **加载状态**：流畅的加载指示器和错误处理
- **天气图标**：不同天气条件的自定义图标
- **渐变背景**：基于天气条件的动态背景

### 技术特性
- **状态管理**：使用Provider模式进行响应式UI更新
- **本地缓存**：SQLite数据库用于离线数据存储
- **后台更新**：定期刷新天气数据
- **错误处理**：全面的错误处理和回退状态
- **JSON序列化**：自动模型序列化/反序列化

## 项目结构

```
lib/
├── constants/          # 应用常量和配置
├── models/            # 带有JSON序列化的数据模型
├── providers/         # 使用Provider的状态管理
├── screens/           # 主要UI屏幕
├── services/          # 业务逻辑和API服务
├── widgets/           # 可重用的UI组件
└── utils/             # 工具函数
```

## 依赖项

### 核心依赖
- **provider**: 状态管理
- **dio**: API请求的HTTP客户端
- **geolocator**: 定位服务
- **sqflite**: 本地数据库存储
- **fl_chart**: 交互式图表

### UI依赖
- **cached_network_image**: 图片缓存
- **flutter_svg**: SVG支持
- **lottie**: 动画支持

### 开发依赖
- **json_serializable**: JSON模型生成
- **build_runner**: 代码生成

## 开始使用

### 前置条件
- Flutter SDK (3.9.2或更高版本)
- Dart SDK
- Android Studio / VS Code
- Android设备或模拟器

### 安装

1. **克隆仓库**
   ```bash
   git clone <repository-url>
   cd rainweather_flutter
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **生成代码**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **运行应用**
   ```bash
   flutter run
   ```

### 配置

应用使用以下API端点：
- **天气API**: `https://www.weatherol.cn/api/home/getCurrAnd15dAnd24h?cityid=`
- **城市数据**: 本地`city.json`文件，包含城市映射

## 架构

### 状态管理
应用使用Provider模式进行状态管理：

- **WeatherProvider**: 管理天气数据、位置和UI状态
- **响应式更新**: 数据变化时UI自动更新
- **错误处理**: 集中式错误状态管理

### 数据流
1. **定位服务**: 获取当前GPS位置
2. **天气服务**: 从API获取天气数据
3. **数据库服务**: 本地缓存数据
4. **Provider**: 管理状态并通知UI
5. **UI**: 响应式显示数据

### 服务
- **LocationService**: GPS定位检测和权限处理
- **WeatherService**: API通信和数据解析
- **DatabaseService**: 本地存储和缓存

## API集成

应用与weatherol.cn天气API集成：

### 端点
- **当前天气**: `/getCurrAnd15dAnd24h?cityid={cityId}`
- **响应格式**: 包含当前、24小时预报和15天预报数据的JSON

### 数据模型
- **WeatherModel**: 完整的天气数据结构
- **CurrentWeather**: 当前天气状况
- **HourlyWeather**: 24小时预报
- **DailyWeather**: 15天预报
- **AirQuality**: 空气质量信息

## 权限

### Android权限
- `ACCESS_FINE_LOCATION`: GPS定位访问
- `ACCESS_COARSE_LOCATION`: 网络定位访问
- `ACCESS_BACKGROUND_LOCATION`: 后台定位更新
- `INTERNET`: API调用的网络访问
- `WAKE_LOCK`: 后台任务执行

## 开发

### 代码生成
模型更改后运行代码生成：
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 测试
```bash
flutter test
```

### 构建
```bash
# 调试构建
flutter build apk --debug

# 发布构建
flutter build apk --release
```

## 从Android迁移

这个Flutter应用是对原始Android天气应用的完全重构，具有以下改进：

### 增强功能
- **现代UI**: Material Design 3深色主题
- **更好的状态管理**: Provider模式vs手动状态处理
- **改进的错误处理**: 全面的错误状态和回退
- **跨平台**: 同时支持Android和iOS
- **更好的性能**: Flutter的高效渲染引擎

### 保留功能
- **相同API**: 使用相同的天气API端点
- **相同数据结构**: 与现有数据保持兼容
- **相同功能**: 所有原始功能都保留并增强
- **相同城市支持**: 支持所有原始中国城市

## 页面功能

### 今日天气
- 当前天气状况显示
- 温度、湿度、风力等详细信息
- 空气质量指数
- 日出日落时间
- 体感温度

### 24小时预报
- 逐小时天气变化
- 温度趋势图表
- 天气图标和描述
- 风力风向信息

### 15日预报
- 15天天气预报
- 温度趋势图表
- 上午/下午天气对比
- 日出日落时间

### 主要城市
- 中国主要城市天气
- 快速切换城市
- 城市天气对比

## 贡献

1. Fork仓库
2. 创建功能分支
3. 进行更改
4. 如适用，添加测试
5. 提交拉取请求

## 许可证

本项目采用MIT许可证 - 详见LICENSE文件。

## 致谢

- 原始Android天气应用提供灵感和API集成
- weatherol.cn提供天气数据API
- Flutter团队提供优秀的框架
- 开源社区提供各种包
