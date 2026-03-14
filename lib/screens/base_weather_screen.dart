import 'package:flutter/material.dart';
import '../mixins/error_handler_mixin.dart';
import '../mixins/loading_state_mixin.dart';
import '../mixins/refresh_handler_mixin.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// 天气屏幕基类
///
/// 提供天气相关屏幕的通用功能：
/// - 主题管理
/// - 错误处理
/// - 加载状态管理
/// - 刷新控制
/// - 生命周期管理
abstract class BaseWeatherScreen extends StatefulWidget {
  const BaseWeatherScreen({super.key});
}

/// 天气屏幕状态基类
///
/// 所有天气屏幕状态应继承此类，自动获得：
/// - ErrorHandlerMixin：错误处理能力
/// - LoadingStateMixin：加载状态管理
/// - RefreshHandlerMixin：刷新控制
/// - WidgetsBindingObserver：生命周期观察
abstract class BaseWeatherScreenState<S extends BaseWeatherScreen>
    extends State<S>
    with
        ErrorHandlerMixin<S>,
        LoadingStateMixin<S>,
        RefreshHandlerMixin<S>,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onScreenInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    onScreenDispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    onAppLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持AutomaticKeepAlive
    return buildWithTheme(context);
  }

  /// 使用主题包装构建内容
  Widget buildWithTheme(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // 确保AppColors使用最新的主题
        AppColors.setThemeProvider(themeProvider);

        return buildScreenContent(context);
      },
    );
  }

  /// 构建屏幕内容（子类实现）
  @protected
  Widget buildScreenContent(BuildContext context);

  /// 屏幕初始化回调（子类可选重写）
  @protected
  void onScreenInit() {}

  /// 屏幕销毁回调（子类可选重写）
  @protected
  void onScreenDispose() {}

  /// 应用生命周期变化回调（子类可选重写）
  @protected
  void onAppLifecycleChanged(AppLifecycleState state) {}

  /// 构建渐变背景容器
  @protected
  Widget buildGradientBackground({
    required Widget child,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.screenBackgroundGradient,
      ),
      child: child,
    );
  }

  /// 构建安全区域内容
  @protected
  Widget buildSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: child,
    );
  }

  /// 构建单子滚动视图
  @protected
  Widget buildSingleChildScrollView({
    required Widget child,
    ScrollPhysics? physics,
  }) {
    return SingleChildScrollView(
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      child: child,
    );
  }

  /// 构建标准卡片间距
  @protected
  Widget get cardSpacing => const SizedBox(height: 12);

  /// 显示SnackBar消息
  @protected
  void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// 显示成功消息
  @protected
  void showSuccessMessage(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.green,
    );
  }

  /// 显示错误消息
  @protected
  void showErrorMessage(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.red,
    );
  }

  /// 显示警告消息
  @protected
  void showWarningMessage(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.orange,
    );
  }
}

/// 带状态数据选择器的天气屏幕基类
///
/// 提供更精确的状态控制，避免不必要的重建
abstract class BaseStatefulWeatherScreen<S extends BaseWeatherScreen, T>
    extends BaseWeatherScreenState<S> {
  /// 从Provider选择数据（子类实现）
  @protected
  T selectData(BuildContext context);

  /// 判断数据是否相等（子类可选重写）
  @protected
  bool dataEquals(T? a, T? b) {
    return a == b;
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        AppColors.setThemeProvider(themeProvider);
        final data = selectData(context);
        return buildWithData(context, data);
      },
    );
  }

  /// 使用数据构建内容（子类实现）
  @protected
  Widget buildWithData(BuildContext context, T data);
}
