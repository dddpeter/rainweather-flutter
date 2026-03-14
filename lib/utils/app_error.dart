/// 应用统一错误处理类型
///
/// 提供一致的错误处理机制，支持：
/// - 类型化的错误分类
/// - 错误代码和消息
/// - 错误链追踪
///
/// 使用示例：
/// ```dart
/// throw NetworkError('请求失败', code: 'NET_001');
/// ```
sealed class AppError implements Exception {
  /// 错误消息
  final String message;

  /// 错误代码
  final String? code;

  /// 原始错误
  final Object? originalError;

  const AppError(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$runtimeType: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }
}

/// 网络错误
class NetworkError extends AppError {
  const NetworkError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 定位错误
class LocationError extends AppError {
  const LocationError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 缓存错误
class CacheError extends AppError {
  const CacheError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 数据库错误
class DatabaseError extends AppError {
  const DatabaseError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 权限错误
class PermissionError extends AppError {
  const PermissionError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 验证错误
class ValidationError extends AppError {
  const ValidationError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 配置错误
class ConfigError extends AppError {
  const ConfigError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 未知错误
class UnknownError extends AppError {
  const UnknownError(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 错误工厂方法
///
/// 从原始错误创建对应的 AppError
class AppErrorFactory {
  AppErrorFactory._();

  /// 从异常创建 AppError
  static AppError fromException(Object error) {
    if (error is AppError) {
      return error;
    }

    // 根据错误类型创建对应的 AppError
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('http') ||
        errorString.contains('connection')) {
      return NetworkError(
        '网络请求失败',
        originalError: error,
      );
    }

    if (errorString.contains('location') ||
        errorString.contains('permission') ||
        errorString.contains('gps')) {
      return LocationError(
        '定位失败',
        originalError: error,
      );
    }

    if (errorString.contains('database') ||
        errorString.contains('sqlite') ||
        errorString.contains('sql')) {
      return DatabaseError(
        '数据库操作失败',
        originalError: error,
      );
    }

    return UnknownError(
      '发生未知错误',
      originalError: error,
    );
  }
}
