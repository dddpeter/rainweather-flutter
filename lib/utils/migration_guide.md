# 错误处理和日志系统迁移指南

本指南帮助开发者将现有的print语句和错误处理迁移到新的统一系统。

## 迁移步骤

### 1. 替换print语句为Logger调用

#### 原代码
```dart
print('获取天气数据成功');
print('错误: $error');
```

#### 迁移后
```dart
Logger.s('获取天气数据成功', tag: 'WeatherService');
Logger.e('获取天气数据失败', tag: 'WeatherService', error: error);
```

### 2. 使用ErrorHandler处理异常

#### 原代码
```dart
try {
  await riskyOperation();
} catch (e) {
  print('操作失败: $e');
  // 可能有一些简单的错误处理
}
```

#### 迁移后
```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  Logger.e('操作失败', tag: 'MyComponent', error: e, stackTrace: stackTrace);
  ErrorHandler.handleError(
    e,
    stackTrace: stackTrace,
    context: 'MyComponent.RiskyOperation',
    type: AppErrorType.network, // 根据实际情况选择错误类型
    onRetry: () => riskyOperation(), // 可选的重试逻辑
  );
}
```

### 3. 使用安全执行方法

#### 原代码
```dart
try {
  final result = await riskyOperation();
  return result;
} catch (e) {
  print('操作失败: $e');
  return defaultValue;
}
```

#### 迁移后
```dart
return await ErrorHandler.safeExecute(
  () async => riskyOperation(),
  operationName: 'MyComponent.SafeOperation',
  defaultValue: defaultValue,
  showError: true,
);
```

### 4. 使用用户友好的错误提示

#### 原代码
```dart
if (error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('发生错误: $error')),
  );
}
```

#### 迁移后
```dart
if (error != null) {
  ErrorToast.show(
    context: context,
    message: '网络连接失败',
    errorType: AppErrorType.network,
  );
  
  // 或者使用对话框
  ErrorDialog.showNetworkError(
    context: context,
    message: '无法连接到服务器',
    onRetry: () => retryOperation(),
  );
}
```

## 常见迁移模式

### 网络请求

#### 原代码
```dart
try {
  final response = await http.get(url);
  if (response.statusCode == 200) {
    print('请求成功');
    return response.body;
  } else {
    print('请求失败: ${response.statusCode}');
    return null;
  }
} catch (e) {
  print('网络错误: $e');
  return null;
}
```

#### 迁移后
```dart
return await ErrorHandler.safeExecute<http.Response?>(
  () async {
    Logger.net('发送网络请求: $url', tag: 'NetworkService');
    final response = await http.get(url).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      Logger.net('请求成功', tag: 'NetworkService');
      return response;
    } else {
      Logger.w('请求失败: ${response.statusCode}', tag: 'NetworkService');
      throw Exception('HTTP ${response.statusCode}');
    }
  },
  operationName: 'NetworkService.GetData',
  defaultValue: null,
);
```

### 定位服务

#### 原代码
```dart
try {
  final position = await Geolocator.getCurrentPosition();
  print('定位成功: ${position.latitude}, ${position.longitude}');
  return position;
} catch (e) {
  print('定位失败: $e');
  return null;
}
```

#### 迁移后
```dart
try {
  Logger.loc('开始定位', tag: 'LocationService');
  final position = await Geolocator.getCurrentPosition();
  Logger.loc('定位成功: ${position.latitude}, ${position.longitude}', tag: 'LocationService');
  return position;
} catch (e) {
  Logger.e('定位失败', tag: 'LocationService', error: e);
  ErrorHandler.handleError(
    e,
    context: 'LocationService.GetCurrentPosition',
    type: AppErrorType.location,
    onRetry: () async {
      Logger.loc('重试定位', tag: 'LocationService');
      return await getCurrentPosition();
    },
  );
  return null;
}
```

### 数据库操作

#### 原代码
```dart
try {
  final result = await database.query('table');
  print('查询成功: ${result.length}条记录');
  return result;
} catch (e) {
  print('数据库错误: $e');
  return [];
}
```

#### 迁移后
```dart
return await ErrorHandler.safeExecute<List<Map<String, dynamic>>>(
  () async {
    Logger.cache('查询数据库表: table', tag: 'DatabaseService');
    final result = await database.query('table');
    Logger.cache('查询成功: ${result.length}条记录', tag: 'DatabaseService');
    return result;
  },
  operationName: 'DatabaseService.Query',
  defaultValue: [],
  type: AppErrorType.database,
);
```

## 批量迁移脚本

对于大型项目，可以考虑使用以下正则表达式进行批量替换：

### 替换print语句

1. 简单print语句：
   ```
   查找: print\('([^']+)'\);
   替换: Logger.d('$1', tag: 'ComponentName');
   ```

2. 错误print语句：
   ```
   查找: print\('错误: \$([^']+)'\);
   替换: Logger.e('操作失败', tag: 'ComponentName', error: $1);
   ```

### 添加错误处理

1. 简单try-catch：
   ```
   查找: } catch \(e\) \{\s*print\('([^']+)'\);\s*}
   替换: } catch (e, stackTrace) {
       Logger.e('$1', tag: 'ComponentName', error: e, stackTrace: stackTrace);
       ErrorHandler.handleError(e, context: 'ComponentName.Operation');
     }
   ```

## 验证迁移

迁移完成后，请验证以下内容：

1. 所有print语句已替换为Logger调用
2. 所有异常都通过ErrorHandler处理
3. 错误类型分类正确
4. 用户界面使用ErrorDialog或ErrorToast显示错误
5. 关键操作使用ErrorHandler.safeExecute包装

## 注意事项

1. **保留原始错误信息**：确保在Logger.e中记录完整的错误信息和堆栈跟踪
2. **选择合适的错误类型**：根据实际情况选择AppErrorType，不要全部使用unknown
3. **提供上下文信息**：在ErrorHandler.handleError中提供有意义的context参数
4. **考虑重试逻辑**：对于网络和定位错误，通常应该提供重试选项
5. **性能监控**：对关键操作添加性能计时

## 迁移检查清单

- [ ] 所有print语句已替换为Logger调用
- [ ] 所有异常都通过ErrorHandler处理
- [ ] 错误类型分类正确
- [ ] 用户界面使用ErrorDialog或ErrorToast
- [ ] 关键操作使用ErrorHandler.safeExecute
- [ ] 添加了适当的性能监控
- [ ] 所有Logger调用都包含tag参数
- [ ] 错误处理提供了有意义的上下文信息
