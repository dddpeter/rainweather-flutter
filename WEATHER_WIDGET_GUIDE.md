# 天气小组件设计文档

## 📱 功能概述

天气小组件是一个桌面Widget，可以在手机桌面直接显示天气信息，无需打开应用即可查看天气。

## 🎨 UI设计

### 布局结构

```
┌─────────────────────────────────────────┐
│ 10月07日  周二          农历九月初五  │  ← 第一行
├─────────────────────────────────────────┤
│ 20:30  ☀ 晴                      17°  │  ← 第二行
├─────────────────────────────────────────┤
│ 📍朝阳区 💨良38 🌬️东南2级 💧今日无雨  │  ← 第三行
├─────────────────────────────────────────┤
│ 今天  明天  10/09  10/10  10/11      │  ← 第四行
│  ☀    ☁    🌧    ⛅    ☀           │
│ 20°   18°   15°    16°    19°         │
│ 10°   12°   10°    11°    13°         │
└─────────────────────────────────────────┘
```

### 详细说明

#### 第一行：日期信息
- **左侧**：公历日期（10月07日）
- **中间**：星期几（周二）
- **右侧**：农历日期（农历九月初五）

#### 第二行：核心天气信息
- **左侧**：当前时间（20:30）
- **中间**：天气图标 + 天气状态文字（☀ 晴）
- **右侧**：当前温度（17°）

#### 第三行：详细信息
- **位置**：📍 当前位置（朝阳区）
- **空气**：💨 空气质量指数（良38）
- **风力**：🌬️ 风向风力（东南2级）
- **降雨**：💧 降雨提醒（今日无雨/今日有雨 80% 带伞）

#### 第四行：5日天气预报
每个预报项包含：
- 日期（今天/明天/日期）
- 星期（除今天明天外）
- 天气图标
- 最高温度
- 最低温度

## 🏗️ 技术实现

### 1. 文件结构

```
lib/
├── widgets/
│   ├── weather_widget_config.dart      # 小组件配置
│   └── weather_widget_preview.dart     # 小组件预览（应用内）
├── services/
│   └── weather_widget_service.dart     # 小组件服务
└── utils/
    └── lunar_calendar.dart             # 农历计算工具
```

### 2. 核心类说明

#### WeatherWidgetConfig
- 定义小组件的配置参数
- 尺寸、颜色、字体大小等
- 数据键定义

#### LunarCalendar
- 农历计算工具类
- 支持1900-2100年农历转换
- 提供天干地支、生肖、农历月日

#### WeatherWidgetService
- 小组件数据更新服务
- 格式化天气数据
- 与原生Widget通信

#### WeatherWidgetPreview
- 应用内预览小组件
- 用于调试和展示

### 3. 数据流

```
WeatherProvider (天气数据)
        ↓
WeatherWidgetService (格式化)
        ↓
原生Widget平台 (Android/iOS)
        ↓
桌面显示
```

## 📦 集成步骤

### 1. 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  home_widget: ^0.5.0  # 桌面小组件支持
```

### 2. Android配置

#### 2.1 创建Widget布局

`android/app/src/main/res/layout/weather_widget.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/widget_background">

    <!-- 第一行：日期信息 -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal">
        
        <TextView
            android:id="@+id/text_date"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textSize="14sp"
            android:textColor="#333333" />
        
        <TextView
            android:id="@+id/text_weekday"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="8dp"
            android:textSize="14sp"
            android:textColor="#666666" />
        
        <View
            android:layout_width="0dp"
            android:layout_height="1dp"
            android:layout_weight="1" />
        
        <TextView
            android:id="@+id/text_lunar"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textSize="14sp"
            android:textColor="#999999" />
    </LinearLayout>

    <!-- 第二行：天气信息 -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="12dp"
        android:orientation="horizontal"
        android:gravity="center_vertical">
        
        <TextView
            android:id="@+id/text_time"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textSize="18sp"
            android:textColor="#666666" />
        
        <ImageView
            android:id="@+id/icon_weather"
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:layout_marginStart="16dp" />
        
        <TextView
            android:id="@+id/text_weather"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="8dp"
            android:textSize="16sp"
            android:textColor="#333333" />
        
        <View
            android:layout_width="0dp"
            android:layout_height="1dp"
            android:layout_weight="1" />
        
        <TextView
            android:id="@+id/text_temperature"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textSize="36sp"
            android:textColor="#333333"
            android:textStyle="bold" />
    </LinearLayout>

    <!-- 第三行：详细信息 -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="12dp"
        android:orientation="horizontal">
        
        <TextView
            android:id="@+id/text_location"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textSize="12sp"
            android:textColor="#666666"
            android:drawableStart="@android:drawable/ic_menu_mylocation"
            android:drawablePadding="4dp" />
        
        <TextView
            android:id="@+id/text_aqi"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="16dp"
            android:textSize="12sp"
            android:textColor="#666666" />
        
        <TextView
            android:id="@+id/text_wind"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="16dp"
            android:textSize="12sp"
            android:textColor="#666666" />
        
        <TextView
            android:id="@+id/text_rain"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="16dp"
            android:textSize="12sp"
            android:textColor="#666666" />
    </LinearLayout>

    <!-- 第四行：5日预报 -->
    <LinearLayout
        android:id="@+id/layout_forecast"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:layout_marginTop="12dp"
        android:orientation="horizontal"
        android:gravity="center" />

</LinearLayout>
```

#### 2.2 创建Widget Provider

`android/app/src/main/kotlin/.../WeatherWidgetProvider.kt`:

```kotlin
class WeatherWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.weather_widget)
        
        // 从SharedPreferences读取数据
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val widgetData = prefs.getString("widget_data", "")
        
        if (widgetData != null && widgetData.isNotEmpty()) {
            val json = JSONObject(widgetData)
            
            // 更新UI
            views.setTextViewText(R.id.text_date, json.optString("date"))
            views.setTextViewText(R.id.text_weekday, json.optString("weekday"))
            views.setTextViewText(R.id.text_lunar, json.optString("lunar_date"))
            views.setTextViewText(R.id.text_time, json.optString("time"))
            views.setTextViewText(R.id.text_weather, json.optString("weather_text"))
            views.setTextViewText(R.id.text_temperature, json.optString("temperature"))
            views.setTextViewText(R.id.text_location, json.optString("location"))
            views.setTextViewText(R.id.text_aqi, json.optString("aqi"))
            views.setTextViewText(R.id.text_wind, json.optString("wind"))
            views.setTextViewText(R.id.text_rain, json.optString("rain_alert"))
        }
        
        // 点击打开应用
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.root_layout, pendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
```

#### 2.3 注册Widget

`android/app/src/main/AndroidManifest.xml`:

```xml
<receiver
    android:name=".WeatherWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/weather_widget_info" />
</receiver>
```

### 3. 在应用中集成

在 `WeatherProvider` 中添加小组件更新：

```dart
// lib/providers/weather_provider.dart

import '../services/weather_widget_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherWidgetService _widgetService = WeatherWidgetService.getInstance();
  
  // 在刷新天气数据后更新小组件
  Future<void> refreshWeatherData() async {
    // ... 现有代码 ...
    
    // 更新小组件
    if (_currentWeather != null && _currentLocation != null) {
      await _widgetService.updateWidget(
        weatherData: _currentWeather!,
        location: _currentLocation!,
      );
    }
  }
}
```

### 4. 应用内预览

创建一个设置页面显示小组件预览：

```dart
// lib/screens/widget_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_widget_preview.dart';
import '../services/weather_widget_service.dart';

class WidgetSettingsScreen extends StatelessWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('桌面小组件'),
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          if (provider.currentWeather == null || provider.currentLocation == null) {
            return const Center(child: Text('暂无天气数据'));
          }
          
          // 准备预览数据
          final service = WeatherWidgetService.getInstance();
          final widgetData = service._prepareWidgetData(
            weatherData: provider.currentWeather!,
            location: provider.currentLocation!,
            now: DateTime.now(),
          );
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '小组件预览',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                WeatherWidgetPreview(data: widgetData),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await service.updateWidget(
                      weatherData: provider.currentWeather!,
                      location: provider.currentLocation!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('小组件已更新')),
                    );
                  },
                  child: const Text('立即更新小组件'),
                ),
                const SizedBox(height: 16),
                const Text(
                  '使用说明：\n'
                  '1. 长按桌面空白处\n'
                  '2. 选择"小组件"\n'
                  '3. 找到"知雨天气"小组件\n'
                  '4. 拖拽到桌面',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## 🎯 特色功能

1. **农历显示**：使用自研农历算法，支持1900-2100年
2. **智能降雨提醒**：根据降雨概率智能提示
3. **5日预报**：一目了然未来天气趋势
4. **实时更新**：跟随应用天气数据自动更新

## 📊 数据更新机制

- **自动更新**：应用刷新天气时自动更新小组件
- **后台更新**：可配置定时后台刷新
- **点击刷新**：点击小组件打开应用并刷新

## 🎨 样式定制

可在 `WeatherWidgetConfig` 中自定义：
- 小组件尺寸
- 颜色方案
- 字体大小
- 图标样式

## 🔄 后续优化

1. 支持多种尺寸（2x2, 4x2, 4x4）
2. 支持暗色主题
3. 支持多城市切换
4. 支持自定义背景图
5. 支持透明度调节

