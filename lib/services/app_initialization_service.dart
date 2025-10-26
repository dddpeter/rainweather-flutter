import 'dart:async';
import '../services/smart_cache_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/baidu_location_service.dart';
import '../services/amap_location_service.dart';
import '../services/tencent_location_service.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';

/// 应用初始化服务
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  /// 初始化所有关键服务
  Future<void> initializeCriticalServices() async {
    // 使用Future.microtask确保在下一帧执行，不阻塞UI
    Future.microtask(() async {
      // 预加载智能缓存到内存
      try {
        Logger.d('预加载智能缓存...');
        await SmartCacheService().preloadCommonData();
        Logger.s('智能缓存预加载完成');
      } catch (e, stackTrace) {
        Logger.e('智能缓存预加载失败', error: e, stackTrace: stackTrace);
        ErrorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'AppInitialization.SmartCachePreload',
          type: AppErrorType.cache,
        );
      }

      // 启动后台缓存清理任务
      _startBackgroundCacheCleaner();

      // 初始化通知服务并请求权限
      await _initializeNotificationService();

      // 初始化定位服务
      await _initializeLocationServices();
    });
  }

  /// 启动后台缓存清理任务
  void _startBackgroundCacheCleaner() {
    Logger.d('启动后台缓存清理任务（每30分钟）');

    // 每30分钟清理一次过期缓存
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      try {
        await SmartCacheService().clearExpiredCache();
      } catch (e) {
        Logger.e('后台缓存清理失败: $e');
      }
    });
  }

  /// 初始化通知服务
  Future<void> _initializeNotificationService() async {
    try {
      Logger.d('初始化通知服务');
      final notificationService = NotificationService.instance;
      await notificationService.initialize();

      // 创建通知渠道（Android）
      await notificationService.createNotificationChannels();

      // 请求通知权限
      final permissionGranted = await notificationService.requestPermissions();
      Logger.i('通知权限请求结果: $permissionGranted');

      if (!permissionGranted) {
        Logger.w('通知权限未授予，部分功能可能无法使用');
      }
    } catch (e, stackTrace) {
      Logger.e('通知服务初始化失败', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AppInitialization.NotificationService',
        type: AppErrorType.permission,
      );
    }
  }

  /// 初始化定位服务
  Future<void> _initializeLocationServices() async {
    // 全局设置腾讯定位服务
    try {
      Logger.d('全局设置腾讯定位服务');
      final tencentLocationService = TencentLocationService.getInstance();
      await tencentLocationService.setGlobalPrivacyAgreement();
      Logger.s('腾讯定位服务设置成功');
    } catch (e, stackTrace) {
      Logger.e('腾讯定位服务设置失败', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AppInitialization.TencentLocationService',
        type: AppErrorType.location,
      );
    }

    // 全局设置百度定位隐私政策同意
    try {
      Logger.d('全局设置百度定位隐私政策同意');
      final baiduLocationService = BaiduLocationService.getInstance();
      await baiduLocationService.setGlobalPrivacyAgreement();
      Logger.s('百度定位隐私政策同意设置成功');
    } catch (e, stackTrace) {
      Logger.e('百度定位隐私政策同意设置失败', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AppInitialization.BaiduLocationService',
        type: AppErrorType.location,
      );
    }

    // 全局设置高德地图API Key
    try {
      Logger.d('全局设置高德地图API Key');
      final amapLocationService = AMapLocationService.getInstance();
      await amapLocationService.setGlobalAPIKey();
      Logger.s('高德地图API Key设置成功');
    } catch (e, stackTrace) {
      Logger.e('高德地图API Key设置失败', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AppInitialization.AmapLocationService',
        type: AppErrorType.location,
      );
    }

    // 请求定位权限（参照demo）
    try {
      Logger.d('请求定位权限');
      final locationService = LocationService.getInstance();
      await locationService.requestLocationPermission();
      Logger.s('定位权限请求完成');
    } catch (e, stackTrace) {
      Logger.e('定位权限请求失败', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AppInitialization.LocationPermission',
        type: AppErrorType.permission,
      );
    }
  }
}
