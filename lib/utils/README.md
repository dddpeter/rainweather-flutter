# 错误处理和日志系统使用指南

本项目集成了统一的错误处理和日志记录系统，包括以下三个核心组件：

1. **Logger** - 统一日志管理工具
2. **ErrorHandler** - 统一错误处理工具类
3. **GlobalExceptionHandler** - 全局异常处理器

## Logger 使用指南

Logger 提供了多种日志级别，方便在开发和调试过程中记录信息。

### 基本用法

```dart
import '../utils/logger.dart';

// 调试级别日志（仅在Debug模式下显示）
Logger.d('这是调试信息', tag: 'MyComponent');

// 信息级别日志
Logger.i('这是信息日志', tag: 'MyComponent');

// 警告级别日志
Logger.w('这是警告日志', tag: 'MyComponent');

// 错误级别日志（始终显示）
Logger.e('这是错误日志', tag: 'MyComponent', error: exception, stackTrace: stackTrace);

// 成功级别日志
Logger.s('操作成功', tag: 'MyComponent');
```

### 专用日志类型

```dart
// 网络请求日志
Logger.net('网络请求: GET /api/weather');

// 定位相关日志
Logger.loc('定位成功: 纬度39.9, 经度116.4');

// AI相关日志
Logger.ai('AI响应生成成功');

// 缓存相关日志
Logger.cache('缓存命中: weather_data_beijing');

// 性能相关日志
Logger.perf('数据加载完成: 120ms');

// 用户操作日志
Logger.user('用户点击刷新按钮');
```

### 分隔线和性能计时

```dart
// 添加分隔线
Logger.separator('操作开始');
Logger.separator(); // 无标题分隔线

// 性能计时
Logger.startPerf('数据加载');
// ... 执行操作
Logger.endPerf('数据加载'); // 输出耗时
```

## ErrorHandler 使用指南

ErrorHandler 提供了统一的错误处理机制，包括错误分类、重试策略和用户友好提示。

### 基本用法

```dart
import '../utils/error_handler.dart';

try {
  // 可能失败的操作
  await riskyOperation();
} catch (e, stackTrace) {
  ErrorHandler.handleError(
    e,
    stackTrace: stackTrace,
    context: 'MyComponent.RiskyOperation',
    type: AppErrorType.network,
    onRetry: () => riskyOperation(), // 可选的重试回调
  );
}
```

### 安全执行操作

```dart
// 安全执行异步操作
final result = await ErrorHandler.safeExecute(
  () async => riskyOperation(),
  operationName: 'MyComponent.SafeOperation',
  defaultValue: '默认值',
  showError: true,
);

// 安全执行同步操作
final result = ErrorHandler.safeExecuteSync(
  () => riskySyncOperation(),
  operationName: 'MyComponent.SafeSyncOperation',
  defaultValue: '默认值',
);
```

### 错误类型

ErrorHandler 支持以下错误类型：

- `AppErrorType.network` - 网络错误
- `AppErrorType.location` - 定位错误
- `AppErrorType.dataParsing` - 数据解析错误
- `AppErrorType.cache` - 缓存错误
- `AppErrorType.permission` - 权限错误
- `AppErrorType.unknown` - 未知错误

### 获取用户友好的错误消息

```dart
final message = ErrorHandler.getUserFriendlyMessage(AppErrorType.network, e);
// 返回: "网络连接异常，请检查网络设置后重试"
```

### 检查错误是否可重试

```dart
if (ErrorHandler.isRetryableError(e)) {
  // 显示重试按钮
  final delay = ErrorHandler.getRetryDelay(attemptCount);
  // 延迟重试
}
```

## GlobalExceptionHandler 使用指南

GlobalExceptionHandler 会自动捕获应用中未被处理的异常，防止应用崩溃。

### 初始化

在 `main.dart` 中初始化：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化全局异常处理器
  GlobalExceptionHandler().initialize();
  
  runApp(MyApp());
}
```

## 错误提示UI

项目提供了两种用户友好的错误提示UI：

### ErrorDialog - 错误对话框

```dart
import '../widgets/error_dialog.dart';

// 显示网络错误对话框
ErrorDialog.showNetworkError(
  context: context,
  message: '无法连接到服务器',
  onRetry: () {
    // 重试逻辑
  },
);

// 显示定位错误对话框
ErrorDialog.showLocationError(
  context: context,
  message: '定位失败，请检查定位权限',
  onRetry: () {
    // 重新定位
  },
);

// 显示权限错误对话框
ErrorDialog.showPermissionError(
  context: context,
  message: '需要定位权限才能使用此功能',
);
```

### ErrorToast - 错误提示

```dart
// 显示错误Toast
ErrorToast.show(
  context: context,
  message: '操作失败',
  errorType: AppErrorType.network,
);
```

## 最佳实践

1. **使用Logger替代print语句**
   - 所有日志都应通过Logger记录，便于统一管理和过滤
   - 使用tag参数标识日志来源，便于调试

2. **使用ErrorHandler处理异常**
   - 所有异常都应通过ErrorHandler处理，提供统一的错误处理策略
   - 为错误提供上下文信息，便于定位问题

3. **使用用户友好的错误提示**
   - 使用ErrorDialog和ErrorToast显示错误，提供一致的用户体验
   - 为可重试的错误提供重试选项

4. **性能监控**
   - 使用Logger.startPerf和Logger.endPerf监控关键操作的性能
   - 记录网络请求、数据库操作等耗时操作

5. **错误分类**
   - 根据错误类型选择合适的AppErrorType
   - 为不同类型的错误提供不同的处理策略

## 示例代码

完整的使用示例请参考 `error_handling_example.dart` 文件。
