import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_alert_model.dart';

/// 通知服务类
/// 负责管理天气提醒的本地通知
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // 通知设置
  bool _isEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _onlyImportantAlerts = false; // 只显示重要提醒

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Web平台不支持通知功能
    if (kIsWeb) {
      print('NotificationService: Web平台不支持通知功能');
      return;
    }

    try {
      // Android 初始化设置
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS/macOS 初始化设置
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // macOS 初始化设置
      const DarwinInitializationSettings initializationSettingsMacOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS,
          );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 加载保存的设置
      await _loadSettings();

      _isInitialized = true;

      if (kDebugMode) {
        print('NotificationService: 初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 初始化失败 - $e');
      }
    }
  }

  /// 检查通知权限
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) {
        // Web平台不支持通知权限
        return false;
      }

      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        final bool? granted = await androidImplementation
            ?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final bool? result = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      } else if (Platform.isMacOS) {
        final bool? result = await _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 请求权限失败 - $e');
      }
      return false;
    }
  }

  /// 检查是否已授予通知权限
  Future<bool> isPermissionGranted() async {
    try {
      if (kIsWeb) {
        // Web平台不支持通知权限
        return false;
      }

      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        final bool? granted = await androidImplementation
            ?.areNotificationsEnabled();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final result = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return result?.isEnabled ?? false;
      } else if (Platform.isMacOS) {
        final result = await _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return result?.isEnabled ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 检查权限失败 - $e');
      }
      return false;
    }
  }

  /// 发送天气提醒通知
  Future<void> sendWeatherAlertNotification(WeatherAlertModel alert) async {
    if (!_isEnabled || !_isInitialized) return;

    // 检查是否只显示重要提醒
    if (_onlyImportantAlerts && !alert.isRequired) return;

    try {
      final notificationId = alert.id.hashCode;
      final channelId = alert.level == WeatherAlertLevel.red
          ? 'weather_alert_red'
          : 'weather_alert_yellow';

      // 创建通知详情
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          alert.level == WeatherAlertLevel.red ? '重要天气提醒' : '天气提醒',
          channelDescription: '天气预警通知',
          importance: alert.level == WeatherAlertLevel.red
              ? Importance.high
              : Importance.defaultImportance,
          priority: alert.level == WeatherAlertLevel.red
              ? Priority.high
              : Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(
            alert.level == WeatherAlertLevel.red ? 0xFFE53E3E : 0xFFF6AD55,
          ),
          playSound: _soundEnabled,
          enableVibration: _vibrationEnabled,
          fullScreenIntent: alert.isRequired, // 重要提醒全屏显示
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(
            alert.content,
            contentTitle: alert.title,
            summaryText: '知雨天气 - ${alert.cityName}',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: _soundEnabled,
          sound: 'default',
          interruptionLevel: alert.isRequired
              ? InterruptionLevel.critical
              : InterruptionLevel.active,
          subtitle: '${alert.cityName} - ${_getWeatherTypeText(alert.type)}',
          threadIdentifier: 'weather_alert_${alert.cityName}',
          categoryIdentifier: 'WEATHER_ALERT',
        ),
      );

      await _notifications.show(
        notificationId,
        alert.title,
        alert.content,
        notificationDetails,
        payload: jsonEncode({
          'alertId': alert.id,
          'type': 'weather_alert',
          'level': alert.level.toString(),
          'isRequired': alert.isRequired,
        }),
      );

      if (kDebugMode) {
        print('NotificationService: 发送通知 - ${alert.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 发送通知失败 - $e');
      }
    }
  }

  /// 批量发送天气提醒通知
  Future<void> sendWeatherAlertNotifications(
    List<WeatherAlertModel> alerts,
  ) async {
    if (!_isEnabled || !_isInitialized || alerts.isEmpty) return;

    // 按优先级排序，优先发送重要提醒
    alerts.sort((a, b) {
      if (a.isRequired && !b.isRequired) return -1;
      if (!a.isRequired && b.isRequired) return 1;
      return b.priority.compareTo(a.priority);
    });

    // 发送通知，限制数量避免通知栏被刷屏
    final maxNotifications = 5;
    final alertsToNotify = alerts.take(maxNotifications).toList();

    for (final alert in alertsToNotify) {
      await sendWeatherAlertNotification(alert);
      // 添加小延迟避免通知发送过快
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (alerts.length > maxNotifications) {
      // 如果提醒太多，发送一个汇总通知
      await _sendSummaryNotification(alerts.length, maxNotifications);
    }
  }

  /// 发送汇总通知
  Future<void> _sendSummaryNotification(
    int totalCount,
    int displayedCount,
  ) async {
    try {
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_alert_summary',
          '天气提醒汇总',
          channelDescription: '天气提醒汇总通知',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4299E1),
          playSound: _soundEnabled,
          enableVibration: _vibrationEnabled,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: _soundEnabled,
        ),
      );

      await _notifications.show(
        'summary_${DateTime.now().millisecondsSinceEpoch}'.hashCode,
        '天气提醒汇总',
        '共有 $totalCount 个天气提醒，已显示前 $displayedCount 个，请打开应用查看详情',
        notificationDetails,
        payload: jsonEncode({
          'type': 'weather_alert_summary',
          'totalCount': totalCount,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 发送汇总通知失败 - $e');
      }
    }
  }

  /// 取消通知
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 取消通知失败 - $e');
      }
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 取消所有通知失败 - $e');
      }
    }
  }

  /// 通知点击处理
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = jsonDecode(payload);
        final type = data['type'] as String?;

        if (kDebugMode) {
          print('NotificationService: 通知被点击 - $type');
        }

        // 这里可以处理通知点击后的导航逻辑
        // 例如跳转到天气提醒详情页面
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 处理通知点击失败 - $e');
      }
    }
  }

  /// 创建通知渠道 (Android)
  Future<void> createNotificationChannels() async {
    if (kIsWeb) {
      // Web平台不支持通知渠道
      return;
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // 重要提醒渠道
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'weather_alert_red',
          '重要天气提醒',
          description: '红色预警和危险天气提醒',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // 普通提醒渠道
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'weather_alert_yellow',
          '天气提醒',
          description: '黄色预警和场景提醒',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
      );

      // 汇总通知渠道
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'weather_alert_summary',
          '天气提醒汇总',
          description: '天气提醒汇总通知',
          importance: Importance.defaultImportance,
          enableVibration: false,
          playSound: false,
        ),
      );
    }
  }

  // 设置相关方法
  bool get isEnabled => _isEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get onlyImportantAlerts => _onlyImportantAlerts;

  /// 设置通知开关
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// 设置声音开关
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
  }

  /// 设置震动开关
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveSettings();
  }

  /// 设置只显示重要提醒
  Future<void> setOnlyImportantAlerts(bool enabled) async {
    _onlyImportantAlerts = enabled;
    await _saveSettings();
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_enabled', _isEnabled);
      await prefs.setBool('notification_sound_enabled', _soundEnabled);
      await prefs.setBool('notification_vibration_enabled', _vibrationEnabled);
      await prefs.setBool('notification_only_important', _onlyImportantAlerts);
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 保存设置失败 - $e');
      }
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('notification_enabled') ?? true;
      _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
      _vibrationEnabled =
          prefs.getBool('notification_vibration_enabled') ?? true;
      _onlyImportantAlerts =
          prefs.getBool('notification_only_important') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: 加载设置失败 - $e');
      }
    }
  }

  /// 获取设置摘要
  String getSettingsSummary() {
    if (!_isEnabled) return '通知已关闭';

    final parts = <String>[];
    if (_soundEnabled) parts.add('声音');
    if (_vibrationEnabled) parts.add('震动');
    if (_onlyImportantAlerts) parts.add('仅重要');

    return parts.isEmpty ? '基础通知' : parts.join('、');
  }

  /// 获取天气类型文本（用于iOS通知副标题）
  String _getWeatherTypeText(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.temperature:
        return '温度提醒';
      case WeatherAlertType.rain:
        return '降雨提醒';
      case WeatherAlertType.snow:
        return '降雪提醒';
      case WeatherAlertType.wind:
        return '大风提醒';
      case WeatherAlertType.fog:
        return '大雾提醒';
      case WeatherAlertType.dust:
        return '沙尘提醒';
      case WeatherAlertType.hail:
        return '冰雹提醒';
      case WeatherAlertType.visibility:
        return '能见度提醒';
      case WeatherAlertType.airQuality:
        return '空气质量';
      case WeatherAlertType.other:
        return '天气提醒';
    }
  }
}
