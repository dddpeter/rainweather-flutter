# 多主题支持使用指南

## ✅ 已完成的功能

### 1. 主题方案架构
- **蓝色主题**（当前默认）- 完整实现
- **绿色主题** - 完整实现
- **紫色主题** - 待实现
- **橙色主题** - 待实现

### 2. 核心文件

#### `lib/constants/app_themes.dart`
- 定义所有主题方案
- 每个主题包含 `lightColors` 和 `darkColors`
- 提供了主题预览颜色和图标

#### `lib/providers/theme_provider.dart`
- 添加了 `AppThemeScheme _themeScheme` 字段
- 新增 `setThemeScheme()` 方法用于切换主题
- 自动保存和加载主题选择

### 3. 使用方法

#### 切换主题方案（在设置页面）
```dart
// 在任何使用 ThemeProvider 的地方
final themeProvider = context.read<ThemeProvider>();

// 切换到蓝色主题
themeProvider.setThemeScheme(AppThemeScheme.blue);

// 切换到绿色主题
themeProvider.setThemeScheme(AppThemeScheme.green);
```

#### 读取当前主题
```dart
final currentScheme = context.read<ThemeProvider>().themeScheme;
final schemeInfo = AppThemes.getScheme(currentScheme);
print('当前主题: ${schemeInfo.name}');
```

#### 创建主题选择UI
```dart
GridView.builder(
  itemCount: AppThemes.allSchemes.length,
  itemBuilder: (context, index) {
    final scheme = AppThemes.allSchemes[index];
    return ThemeColorSchemeTile(
      scheme: scheme,
      onTap: () {
        context.read<ThemeProvider>().setThemeScheme(
          AppThemeScheme.values[index],
        );
      },
    );
  },
)
```

### 4. 主题配置结构

每个主题包含：
- **name**: 主题名称（如"蓝色主题"）
- **icon**: 预览图标
- **previewColor**: 预览颜色
- **lightColors**: 亮色模式配色
- **darkColors**: 暗色模式配色

### 5. 添加新主题

#### 步骤1：在 `app_themes.dart` 定义主题
```dart
static const ThemeColorScheme orange = ThemeColorScheme(
  name: '橙色主题',
  icon: Icons.wb_sunny,
  previewColor: Color(0xFFFF9800),
  lightColors: {
    'primary': Color(0xFFFF6F00),
    'accent': Color(0xFFFFB74D),
    'background': Color(0xFFFFF3E0),
    // ... 其他颜色
  },
  darkColors: {
    'primary': Color(0xFFFFB74D),
    'accent': Color(0xFFFFCC80),
    'background': Color(0xFF3E2723),
    // ... 其他颜色
  },
);
```

#### 步骤2：更新 `getScheme` 方法
```dart
case AppThemeScheme.orange:
  return orange;
```

#### 步骤3：添加到 `allSchemes` 列表
```dart
static List<ThemeColorScheme> get allSchemes => [
  blue,
  green,
  purple,
  orange, // 添加新主题
];
```

### 6. 主题配色规范

每个颜色键应该包含以下常用颜色：
- `primary` - 主色调
- `primaryDark` - 深主色
- `accent` - 强调色
- `background` - 背景色
- `textPrimary` - 主要文字
- `textSecondary` - 次要文字
- `textTertiary` - 辅助文字
- `cardBackground` - 卡片背景
- `cardBorder` - 卡片边框
- `error` - 错误色
- `success` - 成功色
- `warning` - 警告色
- `sunrise`, `sunset`, `moon` - 特殊效果颜色

完整的颜色列表请参考 `AppThemes.blue` 的实现。

## 🎨 主题切换UI示例

可以创建一个主题选择页面：

```dart
class ThemeSelectorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Scaffold(
      appBar: AppBar(title: Text('选择主题')),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: AppThemes.allSchemes.length,
        itemBuilder: (context, index) {
          final scheme = AppThemes.allSchemes[index];
          final isSelected = themeProvider.themeScheme == 
              AppThemeScheme.values[index];
          
          return GestureDetector(
            onTap: () {
              themeProvider.setThemeScheme(AppThemeScheme.values[index]);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: scheme.previewColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(
                  color: Colors.white,
                  width: 3,
                ) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    scheme.icon,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    scheme.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

## 📝 注意事项

1. **主题持久化**：选择会自动保存到 SharedPreferences
2. **即时生效**：切换主题后立即应用，无需重启App
3. **兼容性**：现有的 `AppColors.textPrimary` 等代码无需修改
4. **可扩展**：可以轻松添加更多主题方案

## 🚀 下一步

可以实现的增强功能：
1. 主题预览功能
2. 自定义主题颜色
3. 主题切换动画
4. 更多预设主题（紫色、橙色、红色、青色等）
