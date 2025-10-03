# 主题系统使用指南

## 概述

应用现在支持三种获取主题颜色的方式，推荐优先使用新的基于 `Theme.of(context)` 的方式。

## 使用方式

### 1. 推荐方式（新代码）- 使用扩展方法

```dart
// 使用 context.appTheme 扩展
Text(
  '示例文本',
  style: TextStyle(
    color: context.appTheme.textPrimary,
    fontSize: 16,
  ),
)

Container(
  decoration: BoxDecoration(
    gradient: context.appTheme.primaryGradient,
  ),
)
```

**优点：**
- ✅ 自动适配主题变化
- ✅ 支持动画过渡
- ✅ 无需手动管理监听器
- ✅ 类型安全

### 2. 静态方法（推荐过渡方式）

```dart
// 使用 AppColors.of(context)
Text(
  '示例文本',
  style: TextStyle(
    color: AppColors.of(context).textPrimary,
    fontSize: 16,
  ),
)
```

**优点：**
- ✅ 从旧代码迁移简单
- ✅ 自动适配主题
- ✅ 支持动画

### 3. 兼容方式（旧代码）

```dart
// 使用静态 getter（需要 Consumer 包裹）
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    AppColors.setThemeProvider(themeProvider);
    
    return Text(
      '示例文本',
      style: TextStyle(
        color: AppColors.textPrimary,  // 静态调用
        fontSize: 16,
      ),
    );
  },
)
```

**注意：** 这种方式仅用于兼容旧代码，新代码请使用方式1或2。

## 主题切换动画

主题切换现在支持平滑的颜色过渡动画：

```dart
// 在 main.dart 中已配置
AnimatedTheme(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  ...
)
```

**效果：**
- 🎨 所有颜色变化都有 300ms 的渐变动画
- 🔄 使用 Curves.easeInOut 曲线，更自然
- ⚡ 性能优化，仅重建必要的 Widget

## 可用的主题颜色

### 文字颜色
- `textPrimary` - 主要文字
- `textSecondary` - 次要文字
- `textTertiary` - 辅助文字

### 主题色
- `primaryBlue` - 主蓝色
- `accentBlue` - 强调蓝色
- `accentGreen` - 强调绿色

### 卡片和背景
- `cardBackground` - 卡片背景
- `cardBorder` - 卡片边框
- `glassBackground` - 玻璃效果背景

### 温度颜色
- `highTemp` - 高温色
- `lowTemp` - 低温色

### 日出日落
- `sunrise` - 日出色
- `sunset` - 日落色
- `moon` - 月亮色

### 标签
- `currentTag` - 当前标签文字
- `currentTagBackground` - 当前标签背景
- `currentTagBorder` - 当前标签边框

### 渐变
- `primaryGradient` - 主渐变背景

## 迁移指南

### 从旧方式迁移到新方式

**旧代码：**
```dart
Container(
  color: AppColors.textPrimary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textSecondary),
  ),
)
```

**新代码：**
```dart
Container(
  color: context.appTheme.textPrimary,
  child: Text(
    'Hello',
    style: TextStyle(color: context.appTheme.textSecondary),
  ),
)
```

### 批量替换建议

1. 搜索 `AppColors.textPrimary` 
2. 替换为 `context.appTheme.textPrimary`
3. 确保 widget 有 `BuildContext` 参数

## 性能建议

1. **避免在 build 方法外部使用**
   ```dart
   // ❌ 错误
   final color = context.appTheme.textPrimary;
   
   @override
   Widget build(BuildContext context) {
     return Text('', style: TextStyle(color: color));
   }
   
   // ✅ 正确
   @override
   Widget build(BuildContext context) {
     return Text(
       '',
       style: TextStyle(color: context.appTheme.textPrimary),
     );
   }
   ```

2. **缓存计算结果**
   ```dart
   // 如果需要多次使用
   final theme = context.appTheme;
   return Column(
     children: [
       Text('1', style: TextStyle(color: theme.textPrimary)),
       Text('2', style: TextStyle(color: theme.textPrimary)),
       Text('3', style: TextStyle(color: theme.textPrimary)),
     ],
   );
   ```

## 主题定义位置

- **主题扩展定义**: `lib/constants/theme_extensions.dart`
- **主题配置**: `lib/main.dart` 中的 `_buildLightTheme` 和 `_buildDarkTheme`
- **兼容层**: `lib/constants/app_colors.dart`

## 添加新颜色

1. 在 `theme_extensions.dart` 的 `AppThemeExtension` 类中添加属性
2. 更新 `light()` 和 `dark()` 方法
3. 更新 `copyWith()` 和 `lerp()` 方法
4. 在需要的地方使用 `context.appTheme.yourNewColor`

## 常见问题

**Q: 为什么切换主题时有动画？**
A: 使用了 `AnimatedTheme` widget，它会在主题变化时自动创建颜色插值动画。

**Q: 可以自定义动画时长吗？**
A: 可以，在 `main.dart` 的 `AnimatedTheme` 中修改 `duration` 参数。

**Q: 旧的 AppColors 静态方式还能用吗？**
A: 可以，为了兼容性保留了旧方式，但推荐逐步迁移到新方式。

**Q: 如何禁用主题切换动画？**
A: 将 `AnimatedTheme` 的 `duration` 设置为 `Duration.zero`。

