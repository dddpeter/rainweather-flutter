import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';
import 'base_weather_screen.dart';

/// 示例：使用 BaseWeatherScreen 的简化屏幕实现
///
/// 这个示例展示了如何使用新的基类和 Mixin 来简化屏幕代码
class ExampleWeatherScreen extends BaseWeatherScreen {
  const ExampleWeatherScreen({super.key});

  @override
  State<ExampleWeatherScreen> createState() => _ExampleWeatherScreenState();
}

class _ExampleWeatherScreenState extends BaseWeatherScreenState<ExampleWeatherScreen> {
  @override
  void onScreenInit() {
    super.onScreenInit();
    // 屏幕初始化逻辑
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().initializeWeather();
    });
  }

  @override
  void onAppLifecycleChanged(AppLifecycleState state) {
    super.onAppLifecycleChanged(state);
    // 应用生命周期变化处理
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshData();
    }
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    return buildGradientBackground(
      child: buildSafeArea(
        child: Consumer<WeatherProvider>(
          builder: (context, weatherProvider, _) {
            // 处理加载状态
            if (weatherProvider.isLoading && weatherProvider.currentWeather == null) {
              return buildLoadingIndicator(color: AppColors.textPrimary);
            }

            // 处理错误状态
            if (weatherProvider.error != null) {
              return buildErrorView(
                message: weatherProvider.error!,
                onRetry: () => _refreshData(),
              );
            }

            // 处理空数据状态
            if (weatherProvider.currentWeather == null) {
              return buildEmptyView(message: '暂无天气数据');
            }

            // 构建正常内容
            return buildRefreshIndicator(
              onRefresh: () => _refreshData(),
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.backgroundSecondary,
              child: buildSingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(weatherProvider),
                    cardSpacing,
                    _buildContent(weatherProvider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await withRefreshing(
      () => context.read<WeatherProvider>().refreshWeatherData(),
    );
  }

  Widget _buildHeader(WeatherProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        '天气信息',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent(WeatherProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        '温度: ${provider.currentWeather?.current?.current?.temperature ?? '--'}℃',
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

/// 示例：使用 BaseStatefulWeatherScreen 的实现
///
/// 展示如何使用带状态选择器的基类来避免不必要的重建
class ExampleStatefulWeatherScreen extends BaseWeatherScreen {
  const ExampleStatefulWeatherScreen({super.key});

  @override
  State<ExampleStatefulWeatherScreen> createState() =>
      _ExampleStatefulWeatherScreenState();
}

/// 屏幕数据类
class _ScreenData {
  final bool isLoading;
  final String? error;
  final WeatherModel? weather;
  final String? location;

  const _ScreenData({
    required this.isLoading,
    this.error,
    this.weather,
    this.location,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ScreenData &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.location == location;
  }

  @override
  int get hashCode =>
      isLoading.hashCode ^ error.hashCode ^ location.hashCode;
}

class _ExampleStatefulWeatherScreenState
    extends BaseStatefulWeatherScreen<ExampleStatefulWeatherScreen, _ScreenData> {
  @override
  void onScreenInit() {
    super.onScreenInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().initializeWeather();
    });
  }

  @override
  _ScreenData selectData(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    return _ScreenData(
      isLoading: provider.isLoading && provider.currentWeather == null,
      error: provider.error,
      weather: provider.currentWeather,
      location: provider.currentLocation?.district,
    );
  }

  @override
  Widget buildWithData(BuildContext context, _ScreenData data) {
    return buildGradientBackground(
      child: buildSafeArea(
        child: Builder(
          builder: (context) {
            // 加载状态
            if (data.isLoading) {
              return buildLoadingIndicator(color: AppColors.textPrimary);
            }

            // 错误状态
            if (data.error != null) {
              return buildErrorView(
                message: data.error!,
                onRetry: () => _handleRetry(),
              );
            }

            // 空数据状态
            if (data.weather == null) {
              return buildEmptyView();
            }

            // 正常内容
            return buildRefreshIndicator(
              onRefresh: _handleRefresh,
              child: buildSingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(data),
                    cardSpacing,
                    _buildWeatherContent(data),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await handleRefresh(
      () => context.read<WeatherProvider>().refreshWeatherData(),
    );
  }

  Future<void> _handleRetry() async {
    await withLoading(
      () => context.read<WeatherProvider>().forceRefreshWithLocation(),
      showError: true,
      onError: () {
        showErrorMessage('刷新失败，请稍后重试');
      },
    );
  }

  Widget _buildHeader(_ScreenData data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        data.location ?? '未知地区',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWeatherContent(_ScreenData data) {
    final current = data.weather?.current?.current;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${current?.temperature ?? '--'}℃',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            current?.weather ?? '未知',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// 使用指南：
///
/// 1. 继承 BaseWeatherScreen:
///    ```dart
///    class MyScreen extends BaseWeatherScreen { ... }
///    ```
///
/// 2. 状态类继承 BaseWeatherScreenState:
///    ```dart
///    class _MyScreenState extends BaseWeatherScreenState<MyScreen> {
///      @override
///      Widget buildScreenContent(BuildContext context) {
///        // 构建屏幕内容
///      }
///    }
///    ```
///
/// 3. 可用的功能（自动获得）:
///    - ErrorHandlerMixin: 错误处理
///      * showErrorDialog()
///      * handleResultError()
///      * handleException()
///      * executeWithErrorHandling()
///
///    - LoadingStateMixin: 加载状态管理
///      * showLoading() / hideLoading()
///      * withLoading() / withRefreshing()
///      * buildLoadingIndicator()
///      * buildErrorView()
///      * buildEmptyView()
///
///    - RefreshHandlerMixin: 刷新控制
///      * handleRefresh()
///      * buildRefreshIndicator()
///      * triggerHapticFeedback()
///
///    - WidgetsBindingObserver: 生命周期管理
///      * onScreenInit()
///      * onScreenDispose()
///      * onAppLifecycleChanged()
///
/// 4. 便捷方法:
///    - buildGradientBackground()
///    - buildSafeArea()
///    - buildSingleChildScrollView()
///    - showSnackBar()
///    - showSuccessMessage()
///    - showErrorMessage()
///    - showWarningMessage()
///
/// 5. 使用带状态选择器的基类（避免不必要的重建）:
///    ```dart
///    class _MyScreenState
///        extends BaseStatefulWeatherScreen<MyScreen, MyData> {
///      @override
///      MyData selectData(BuildContext context) {
///        // 从Provider选择数据
///      }
///
///      @override
///      Widget buildWithData(BuildContext context, MyData data) {
///        // 使用数据构建UI
///      }
///    }
///    ```
