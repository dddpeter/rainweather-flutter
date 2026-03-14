import 'app_error.dart';

/// Result 类型
///
/// 用于表示操作结果，可以是成功或失败。
/// 提供函数式错误处理方式，避免异常抛出。
///
/// 使用示例：
/// ```dart
/// Future<Result<WeatherModel>> getWeather(String cityId) async {
///   try {
///     final weather = await _fetchWeather(cityId);
///     return Success(weather);
///   } catch (e) {
///     return Failure(AppErrorFactory.fromException(e));
///   }
/// }
///
/// // 使用
/// final result = await getWeather('101010100');
/// if (result.isSuccess) {
///   print(result.data);
/// } else {
///   print(result.error.message);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// 是否成功
  bool get isSuccess => this is Success<T>;

  /// 是否失败
  bool get isFailure => this is Failure<T>;

  /// 获取数据（成功时）
  T get data => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => throw StateError('Cannot get data from Failure'),
      };

  /// 获取错误（失败时）
  AppError get error => switch (this) {
        Success<T>() => throw StateError('Cannot get error from Success'),
        Failure<T>(:final error) => error,
      };

  /// 获取数据或默认值
  T getOrElse(T defaultValue) => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => defaultValue,
      };

  /// 获取数据或通过函数计算默认值
  T getOrElseDo(T Function() orElse) => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => orElse(),
      };

  /// 获取数据或 null
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// 获取错误或 null
  AppError? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// 转换成功值
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success<T>(:final data) => Success(transform(data)),
        Failure<T>(:final error) => Failure(error),
      };

  /// 异步转换成功值
  Future<Result<R>> asyncMap<R>(
    Future<R> Function(T data) transform,
  ) async => switch (this) {
        Success<T>(:final data) => Success(await transform(data)),
        Failure<T>(:final error) => Failure(error),
      };

  /// 转换错误
  Result<T> mapError(AppError Function(AppError error) transform) =>
      switch (this) {
        Success<T>() => this,
        Failure<T>(:final error) => Failure(transform(error)),
      };

  /// 链式操作
  Result<R> flatMap<R>(Result<R> Function(T data) transform) => switch (this) {
        Success<T>(:final data) => transform(data),
        Failure<T>(:final error) => Failure(error),
      };

  /// 异步链式操作
  Future<Result<R>> asyncFlatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async => switch (this) {
        Success<T>(:final data) => await transform(data),
        Failure<T>(:final error) => Failure(error),
      };

  /// 模式匹配
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) =>
      switch (this) {
        Success<T>(:final data) => success(data),
        Failure<T>(:final error) => failure(error),
      };

  /// 异步模式匹配
  Future<R> asyncWhen<R>({
    required Future<R> Function(T data) success,
    required Future<R> Function(AppError error) failure,
  }) async =>
      switch (this) {
        Success<T>(:final data) => await success(data),
        Failure<T>(:final error) => await failure(error),
      };

  /// 执行副作用
  Result<T> onTap(void Function(T data) action) {
    if (this case Success<T>(:final data)) {
      action(data);
    }
    return this;
  }

  /// 执行错误副作用
  Result<T> onTapError(void Function(AppError error) action) {
    if (this case Failure<T>(:final error)) {
      action(error);
    }
    return this;
  }

  /// 恢复错误
  Result<T> recover(T Function(AppError error) recover) => switch (this) {
        Success<T>() => this,
        Failure<T>(:final error) => Success(recover(error)),
      };

  /// 异步恢复错误
  Future<Result<T>> asyncRecover(
    Future<T> Function(AppError error) recover,
  ) async =>
      switch (this) {
        Success<T>() => this,
        Failure<T>(:final error) => Success(await recover(error)),
      };
}

/// 成功结果
final class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// 失败结果
final class Failure<T> extends Result<T> {
  @override
  final AppError error;

  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';
}

/// Result 扩展方法
extension ResultExtension<T> on Future<Result<T>> {
  /// 异步 map
  Future<Result<R>> mapAsync<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// 异步 flatMap
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    final result = await this;
    return result.asyncFlatMap(transform);
  }

  /// 异步恢复
  Future<Result<T>> recoverAsync(T Function(AppError error) recover) async {
    final result = await this;
    return result.recover(recover);
  }
}
