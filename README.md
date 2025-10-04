# 雨天气 Flutter

一款现代化的天气预报应用，采用 Flutter 开发，提供流畅的用户体验和精美的界面设计。

> **English Documentation**: [README_EN.md](README_EN.md) | **中文文档**: 本文件

## ✨ 功能特性

### 核心功能
- 🌤️ **实时天气数据**：从 weatherol.cn API 获取准确的天气信息
- 📍 **智能定位**：GPS 自动定位和 IP 定位双重保障
- 📊 **多维度预报**：24小时逐时预报 + 15天每日预报
- 📈 **交互式图表**：温度趋势可视化展示
- 🌫️ **空气质量**：实时 AQI 指数和等级显示
- 🏙️ **城市管理**：快速访问和管理多个城市
- 🌅 **日出日落**：精确的日出日落时间和月相信息
- 🌙 **月相显示**：实时月相emoji和月龄信息
- 💡 **生活指数**：穿衣、感冒、运动等生活建议

### 🎨 主题系统（新功能）
- **三种主题模式**：亮色、暗色、跟随系统
- **平滑动画过渡**：300ms 主题切换动画，使用 Curves.easeInOut 曲线
- **主题扩展系统**：基于 Flutter ThemeExtension 的现代化主题架构
- **自动适配**：所有 UI 组件自动适应主题变化
- **颜色插值**：主题切换时所有颜色平滑过渡

### UI/UX 特性
- 🎯 **Material Design 3**：严格遵循 Google Material Design 3 设计规范
- 📱 **响应式布局**：适配不同屏幕尺寸
- 🔄 **下拉刷新**：流畅的刷新交互体验
- 🎭 **动态背景**：基于主题的渐变背景
- ⚡ **流畅动画**：精心设计的加载和过渡动画
- 🌡️ **温度图表**：直观的温度趋势展示
- 💎 **统一卡片设计**：所有卡片使用一致的 Material Design 样式
- 🌈 **丰富天气图标**：45种天气类型，兼容性更好的emoji图标
- 🎨 **视觉层次清晰**：合理的字体大小和间距设计

### 技术特性
- 🔥 **状态管理**：Provider 模式实现响应式 UI
- 💾 **本地缓存**：SQLite 数据库离线数据存储
- 🔐 **权限管理**：完善的权限请求和处理机制
- 🛡️ **错误处理**：全面的错误处理和友好提示
- 📦 **JSON 序列化**：自动模型序列化/反序列化
- 🎨 **主题扩展**：可扩展的自定义主题系统

## 🏗️ 项目结构

```
lib/
├── constants/          # 应用常量和配置
│   ├── app_colors.dart          # 颜色常量（兼容层）
│   ├── theme_extensions.dart   # 主题扩展定义
│   └── app_constants.dart       # 应用常量
├── models/            # 数据模型
│   ├── weather_model.dart       # 天气数据模型
│   └── location_model.dart      # 位置数据模型
├── providers/         # 状态管理
│   ├── weather_provider.dart    # 天气数据状态
│   └── theme_provider.dart      # 主题状态管理
├── screens/           # 主要页面
│   ├── today_screen.dart        # 今日天气页面
│   ├── hourly_screen.dart       # 24小时预报页面
│   ├── forecast15d_screen.dart  # 15日预报页面
│   ├── city_weather_screen.dart # 城市天气页面
│   └── main_cities_screen.dart  # 主要城市页面
├── services/          # 业务逻辑和 API
│   ├── weather_service.dart     # 天气 API 服务
│   ├── location_service.dart    # 定位服务
│   ├── database_service.dart    # 数据库服务
│   └── city_service.dart        # 城市数据服务
└── widgets/           # 可重用组件
    ├── weather_chart.dart       # 7日温度图表
    ├── hourly_chart.dart        # 24小时温度图表
    ├── forecast15d_chart.dart   # 15日温度图表
    ├── hourly_weather_widget.dart  # 24小时预报卡片
    ├── life_index_widget.dart   # 生活指数组件
    └── sun_moon_widget.dart     # 日出日落月相组件
```

## 📦 核心依赖

### 状态管理
- **provider** ^6.1.2 - 状态管理解决方案

### 网络请求
- **dio** ^5.7.0 - HTTP 客户端
- **http** ^1.2.2 - HTTP 请求

### 定位服务
- **geolocator** ^14.0.2 - GPS 定位
- **permission_handler** ^12.0.1 - 权限管理

### 本地存储
- **sqflite** ^2.3.3+1 - 本地数据库
- **shared_preferences** ^2.3.2 - 键值存储

### UI 组件
- **fl_chart** ^0.69.2 - 图表组件
- **cached_network_image** ^3.4.1 - 图片缓存
- **lottie** ^3.1.2 - 动画支持

### 开发工具
- **json_serializable** ^6.9.1 - JSON 序列化
- **build_runner** ^2.4.13 - 代码生成

## 🚀 快速开始

### 环境要求
- Flutter SDK 3.9.2 或更高版本
- Dart SDK 3.9.2 或更高版本
- Android Studio / VS Code
- Android 设备或模拟器（iOS 也支持）

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone <repository-url>
   cd rainweather_flutter
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **生成代码**（如需要）
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **运行应用**
   ```bash
   flutter run
   ```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🎨 主题系统使用

### 三种使用方式

**方式 1：推荐 - 使用扩展方法**
```dart
Text(
  '示例文本',
  style: TextStyle(
    color: context.appTheme.textPrimary,
    fontSize: 16,
  ),
)
```

**方式 2：静态方法**
```dart
Text(
  '示例文本',
  style: TextStyle(
    color: AppColors.of(context).textPrimary,
    fontSize: 16,
  ),
)
```

**方式 3：兼容方式（旧代码）**
```dart
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    AppColors.setThemeProvider(themeProvider);
    return Text(
      '示例文本',
      style: TextStyle(color: AppColors.textPrimary),
    );
  },
)
```

详细使用指南请查看 [THEME_USAGE.md](THEME_USAGE.md)

## 📱 主要页面

### 今日天气
- ✅ 当前天气详细信息展示
- ✅ 温度、湿度、风力、气压等数据
- ✅ 空气质量指数（AQI）
- ✅ 日出日落时间和月相
- ✅ 生活指数建议
- ✅ 24小时天气预览
- ✅ 7日温度趋势图表
- ✅ 底部刷新按钮

### 24小时预报
- ✅ 逐小时天气变化
- ✅ 温度趋势交互式图表
- ✅ 天气图标和描述
- ✅ 风力风向详细信息
- ✅ 温度单位显示（℃）

### 15日预报
- ✅ 15天详细天气预报
- ✅ 最高/最低温度趋势图
- ✅ 上午/下午天气对比
- ✅ 日出日落时间
- ✅ 天气描述

### 主要城市
- ✅ 中国主要城市天气快速查看
- ✅ 城市天气卡片展示
- ✅ 点击查看城市详细天气
- ✅ 支持多个城市管理

### 城市天气详情
- ✅ 单个城市完整天气信息
- ✅ 返回按钮导航
- ✅ 与今日天气相同的详细信息
- ✅ 下拉刷新支持

## 🔧 最近更新

### v1.0.0 (2025-10)

**主题系统重构**
- ✨ 新增三种主题模式（亮色/暗色/跟随系统）
- ✨ 实现主题切换平滑动画（300ms）
- ✨ 引入 ThemeExtension 现代化主题架构
- ✨ 所有 UI 组件支持主题自动适配

**UI/UX 优化**
- 🎨 统一今日天气和城市天气的头部样式
- 🎨 优化 24小时预报区域间距（减少至 1/3）
- 🎨 24小时预报添加天气描述文字
- 🎨 移除 24小时页面刷新按钮
- 🎨 移除城市天气页面的生活建议和刷新按钮
- 🎨 今日天气刷新按钮移至右下角

**数据展示优化**
- 📊 所有图表 Y 轴温度单位改为 ℃
- 📊 图表点描边颜色适配主题
- 📊 生活指数卡片文字颜色适配主题

**技术改进**
- ⚡ 优化主题切换性能
- 🔧 添加主题使用文档（THEME_USAGE.md）
- 🛡️ 改进错误处理和边界情况
- 📦 代码结构优化和清理

## 📡 API 集成

### 天气 API
- **基础 URL**: `https://www.weatherol.cn/api/home/`
- **主要端点**: `/getCurrAnd15dAnd24h?cityid={cityId}`
- **数据格式**: JSON

### 响应数据结构
```json
{
  "current": {
    "current": {},      // 当前天气
    "tips": ""          // 天气提示
  },
  "forecast24h": [],    // 24小时预报
  "forecast15d": [],    // 15日预报
  "sunMoonData": {},    // 日出日落月相
  "lifeIndex": []       // 生活指数
}
```

## 🔐 权限说明

### Android 权限
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS 权限
在 `Info.plist` 中配置：
- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysUsageDescription

## 🧪 开发指南

### 代码生成
```bash
# 生成 JSON 序列化代码
flutter pub run build_runner build --delete-conflicting-outputs

# 监听文件变化自动生成
flutter pub run build_runner watch
```

### 代码分析
```bash
# 分析所有代码
flutter analyze

# 分析特定文件
flutter analyze lib/screens/today_screen.dart
```

### 测试
```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/widget_test.dart
```

## 🏗️ 架构设计

### 状态管理
```
WeatherProvider (顶层)
  ├── currentWeather: WeatherModel?
  ├── currentLocation: LocationModel?
  ├── isLoading: bool
  └── error: String?

ThemeProvider (顶层)
  ├── themeMode: AppThemeMode
  └── notifyListeners()
```

### 数据流
```
定位服务 → WeatherProvider → 天气服务 → API
                ↓
         数据库缓存 ← ← ← ← ← ← ←
                ↓
              UI 更新
```

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 代码规范
- 遵循 Dart 官方代码风格
- 使用有意义的变量和函数名
- 添加必要的注释
- 保持代码整洁和可读性

## 📝 更新日志

### v1.2.0 (最新)
- ✨ **Material Design 3 优化**：全面升级到 Material Design 3 设计规范
- 🌅 **日出日落卡片**：新增日出日落和月出月落信息显示
- 🌙 **月相功能**：实时月相emoji显示和月龄信息
- 💡 **生活指数**：穿衣、感冒、运动等生活建议指数
- 🎨 **UI 优化**：统一卡片样式，优化字体大小和间距
- 🌈 **天气图标**：扩展至45种天气类型，提升兼容性
- 🔧 **代码优化**：修复主题适配问题，提升代码质量

### v1.1.0
- 🎨 **主题系统**：完整的亮色/暗色主题支持
- 📱 **响应式设计**：优化移动端体验
- 🔄 **状态管理**：使用 Provider 模式重构

### v1.0.0
- 🚀 **初始版本**：基础天气功能实现

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [weatherol.cn](https://www.weatherol.cn) - 提供天气数据 API
- [Flutter](https://flutter.dev) - 优秀的跨平台框架
- [Provider](https://pub.dev/packages/provider) - 状态管理解决方案
- [FL Chart](https://pub.dev/packages/fl_chart) - 图表组件库
- 所有开源贡献者

## 📞 联系方式

如有问题或建议，欢迎：
- 提交 Issue
- 发起 Discussion
- 提交 Pull Request

---

**Made with ❤️ using Flutter**
