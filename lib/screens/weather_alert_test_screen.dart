import 'package:flutter/material.dart';
import '../models/weather_alert_model.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../services/weather_alert_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 当前定位天气提醒测试页面
class WeatherAlertTestScreen extends StatefulWidget {
  const WeatherAlertTestScreen({super.key});

  @override
  State<WeatherAlertTestScreen> createState() => _WeatherAlertTestScreenState();
}

class _WeatherAlertTestScreenState extends State<WeatherAlertTestScreen> {
  final WeatherAlertService _alertService = WeatherAlertService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final LocationService _locationService = LocationService.getInstance();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _alertService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('当前定位天气提醒测试'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAlerts,
            tooltip: '刷新提醒',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllAlerts,
            tooltip: '清空提醒',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTestActions(),
                    AppColors.cardSpacingWidget,
                    _buildCurrentAlerts(),
                    AppColors.cardSpacingWidget,
                    _buildTestScenarios(),
                    AppColors.cardSpacingWidget,
                    _buildAlertStatistics(),
                  ],
                ),
              ),
      ),
    );
  }

  /// 构建测试操作按钮
  Widget _buildTestActions() {
    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '测试操作',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  '暴雨测试(真实定位)',
                  Icons.thunderstorm,
                  Colors.red,
                  () => _testRainstormAlert(),
                ),
                _buildTestButton(
                  '暴雪测试',
                  Icons.ac_unit,
                  Colors.blue,
                  () => _testBlizzardAlert(),
                ),
                _buildTestButton(
                  '沙尘暴测试',
                  Icons.wind_power,
                  Colors.orange,
                  () => _testSandstormAlert(),
                ),
                _buildTestButton(
                  '雾霾测试',
                  Icons.cloud,
                  Colors.grey,
                  () => _testHazeAlert(),
                ),
                _buildTestButton(
                  '冰雹测试',
                  Icons.whatshot,
                  Colors.red,
                  () => _testHailAlert(),
                ),
                _buildTestButton(
                  '通勤场景',
                  Icons.directions_car,
                  Colors.orange,
                  () => _testCommuteScenario(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  /// 构建当前提醒列表
  Widget _buildCurrentAlerts() {
    final alerts = _alertService.alerts;

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: AppColors.warning,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '当前提醒 (${alerts.length}条)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (alerts.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无提醒',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alerts.map((alert) => _buildAlertItem(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(WeatherAlertModel alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAlertColor(alert.level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAlertColor(alert.level).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAlertColor(alert.level).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(alert.levelIcon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      _getAlertLevelText(alert.level),
                      style: TextStyle(
                        color: _getAlertColor(alert.level),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (alert.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '必提醒',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.content,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '城市: ${alert.cityName}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '优先级: ${alert.priority}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建测试场景
  Widget _buildTestScenarios() {
    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '测试场景',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildScenarioItem(
              '一档提醒测试',
              '测试当前定位必须提醒的天气条件',
              Icons.priority_high,
              Colors.red,
              () => _testRequiredAlerts(),
            ),
            const SizedBox(height: 8),
            _buildScenarioItem(
              '二档提醒测试',
              '测试当前定位场景相关的提醒条件',
              Icons.access_time,
              Colors.orange,
              () => _testScenarioAlerts(),
            ),
            const SizedBox(height: 8),
            _buildScenarioItem(
              '空气质量测试',
              '测试当前定位空气质量提醒功能',
              Icons.air,
              Colors.blue,
              () => _testAirQualityAlert(),
            ),
            const SizedBox(height: 8),
            _buildScenarioItem(
              '通勤时间测试',
              '测试通勤时间检测功能',
              Icons.directions_car,
              Colors.green,
              () => _testCommuteTimeDetection(),
            ),
            const SizedBox(height: 16),
            // 通知测试区域
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: AppColors.warning,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '通知栏测试',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildScenarioItem(
              '发送测试通知',
              '直接发送一个测试通知到通知栏',
              Icons.notifications_active,
              Colors.purple,
              () => _testNotification(),
            ),
            const SizedBox(height: 8),
            _buildScenarioItem(
              '重要提醒通知',
              '测试红色预警通知样式',
              Icons.warning,
              Colors.red,
              () => _testImportantNotification(),
            ),
            const SizedBox(height: 8),
            _buildScenarioItem(
              '批量通知测试',
              '测试多个提醒的批量通知',
              Icons.notification_important,
              Colors.orange,
              () => _testBatchNotifications(),
            ),
            const SizedBox(height: 8),
            _buildScenarioItem(
              '通知权限检查',
              '检查当前通知权限状态',
              Icons.security,
              Colors.blue,
              () => _checkNotificationPermission(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建提醒统计
  Widget _buildAlertStatistics() {
    final alerts = _alertService.alerts;
    final requiredCount = alerts.where((a) => a.isRequired).length;
    final scenarioCount = alerts.where((a) => a.isScenarioBased).length;
    final redCount = alerts
        .where((a) => a.level == WeatherAlertLevel.red)
        .length;
    final yellowCount = alerts
        .where((a) => a.level == WeatherAlertLevel.yellow)
        .length;

    return Card(
      elevation: AppColors.cardElevation,
      shadowColor: AppColors.cardShadowColor,
      color: AppColors.materialCardColor,
      surfaceTintColor: Colors.transparent,
      shape: AppColors.cardShape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '提醒统计',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('总计', '${alerts.length}', Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('一档', '$requiredCount', Colors.red),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('二档', '$scenarioCount', Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatCard('红色', '$redCount', Colors.red)),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('黄色', '$yellowCount', Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    '其他',
                    '${alerts.length - redCount - yellowCount}',
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 测试方法
  Future<void> _testRainstormAlert() async {
    setState(() => _isLoading = true);

    try {
      // 通过定位服务获取真实当前位置
      final currentLocation = await _locationService.getCurrentLocation();

      if (currentLocation != null) {
        final mockWeather = _createMockWeather('暴雨');

        await _alertService.analyzeWeather(mockWeather, currentLocation);
        _showTestResult('暴雨测试完成（针对真实当前位置：${currentLocation.district}）');
      } else {
        _showTestResult('获取位置失败，无法进行暴雨测试');
      }
    } catch (e) {
      _showTestResult('暴雨测试失败：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBlizzardAlert() async {
    final mockWeather = _createMockWeather('暴雪');
    final mockLocation = _createMockLocation('哈尔滨市');

    setState(() => _isLoading = true);
    await _alertService.analyzeWeather(mockWeather, mockLocation);
    setState(() => _isLoading = false);

    _showTestResult('暴雪测试完成');
  }

  Future<void> _testSandstormAlert() async {
    final mockWeather = _createMockWeather('沙尘暴');
    final mockLocation = _createMockLocation('呼和浩特市');

    setState(() => _isLoading = true);
    await _alertService.analyzeWeather(mockWeather, mockLocation);
    setState(() => _isLoading = false);

    _showTestResult('沙尘暴测试完成');
  }

  Future<void> _testHazeAlert() async {
    final mockWeather = _createMockWeather('重度霾');
    final mockLocation = _createMockLocation('石家庄市');

    setState(() => _isLoading = true);
    await _alertService.analyzeWeather(mockWeather, mockLocation);
    setState(() => _isLoading = false);

    _showTestResult('雾霾测试完成');
  }

  Future<void> _testHailAlert() async {
    final mockWeather = _createMockWeather('冰雹');
    final mockLocation = _createMockLocation('重庆市');

    setState(() => _isLoading = true);
    await _alertService.analyzeWeather(mockWeather, mockLocation);
    setState(() => _isLoading = false);

    _showTestResult('冰雹测试完成');
  }

  Future<void> _testCommuteScenario() async {
    final mockWeather = _createMockWeather('大雨');
    final mockLocation = _createMockLocation('上海市');

    setState(() => _isLoading = true);
    await _alertService.analyzeWeather(mockWeather, mockLocation);
    setState(() => _isLoading = false);

    _showTestResult('通勤场景测试完成');
  }

  Future<void> _testRequiredAlerts() async {
    final weathers = ['暴雨', '暴雪', '沙尘暴', '冰雹', '重度霾', '冻雨'];
    final mockLocation = _createMockLocation('当前位置');

    setState(() => _isLoading = true);
    for (final weather in weathers) {
      final mockWeather = _createMockWeather(weather);
      await _alertService.analyzeWeather(mockWeather, mockLocation);
    }
    setState(() => _isLoading = false);

    _showTestResult('一档提醒测试完成');
  }

  Future<void> _testScenarioAlerts() async {
    final weathers = ['大雨', '雷阵雨', '雾', '浓雾', '雨夹雪', '浮尘'];
    final mockLocation = _createMockLocation('当前位置');

    setState(() => _isLoading = true);
    for (final weather in weathers) {
      final mockWeather = _createMockWeather(weather);
      await _alertService.analyzeWeather(mockWeather, mockLocation);
    }
    setState(() => _isLoading = false);

    _showTestResult('二档提醒测试完成');
  }

  Future<void> _testAirQualityAlert() async {
    final mockWeather = _createMockWeather('晴');
    final mockLocation = _createMockLocation('当前位置');

    setState(() => _isLoading = true);
    await _alertService.analyzeWeather(mockWeather, mockLocation);
    setState(() => _isLoading = false);

    _showTestResult('空气质量测试完成');
  }

  Future<void> _testCommuteTimeDetection() async {
    final mockWeather = _createMockWeather('小雨');
    final mockLocation = _createMockLocation('当前位置');

    setState(() => _isLoading = true);
    await _alertService.analyzeWeather(mockWeather, mockLocation);
    setState(() => _isLoading = false);

    _showTestResult('通勤时间检测测试完成');
  }

  Future<void> _refreshAlerts() async {
    setState(() {});
    _showTestResult('提醒列表已刷新');
  }

  Future<void> _clearAllAlerts() async {
    await _alertService.clearAllAlerts();
    setState(() {});
    _showTestResult('所有提醒已清空');
  }

  WeatherModel _createMockWeather(String weatherType) {
    return WeatherModel(
      current: CurrentWeatherData(
        current: CurrentWeather(
          weather: weatherType,
          temperature: '25',
          feelstemperature: '28',
          humidity: '60',
          winddir: '东南风',
          windpower: '3级',
          visibility: '10',
          airpressure: '1013',
        ),
        air: AirQuality(AQI: '120', levelIndex: '轻度污染'),
      ),
      forecast24h: [
        HourlyWeather(
          weather: weatherType,
          temperature: '25',
          forecasttime: '现在',
        ),
      ],
      forecast15d: [
        DailyWeather(
          weather_am: weatherType,
          weather_pm: weatherType,
          temperature_am: '25',
          temperature_pm: '28',
        ),
      ],
    );
  }

  LocationModel _createMockLocation(String cityName) {
    return LocationModel(
      address: cityName,
      country: '中国',
      province: '测试省',
      city: cityName,
      district: cityName,
      street: '测试街道',
      adcode: '110000',
      town: '测试镇',
      lat: 39.9042,
      lng: 116.4074,
    );
  }

  void _showTestResult(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getAlertColor(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return Colors.red;
      case WeatherAlertLevel.yellow:
        return Colors.orange;
      case WeatherAlertLevel.blue:
        return Colors.blue;
      case WeatherAlertLevel.info:
        return Colors.green;
    }
  }

  String _getAlertLevelText(WeatherAlertLevel level) {
    switch (level) {
      case WeatherAlertLevel.red:
        return '红色预警';
      case WeatherAlertLevel.yellow:
        return '黄色预警';
      case WeatherAlertLevel.blue:
        return '蓝色预警';
      case WeatherAlertLevel.info:
        return '信息提醒';
    }
  }

  // 通知测试方法
  Future<void> _testNotification() async {
    final testAlert = WeatherAlertModel(
      id: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
      title: '测试通知',
      content: '这是一个测试通知，用于验证通知功能是否正常工作。',
      level: WeatherAlertLevel.yellow,
      type: WeatherAlertType.other,
      isRequired: false,
      isScenarioBased: true,
      scenario: '测试场景',
      threshold: '0',
      weatherTerm: '测试天气',
      reason: '通知功能测试',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      cityName: '当前位置',
      priority: 5,
    );

    await _notificationService.sendWeatherAlertNotification(testAlert);
    _showTestResult('测试通知已发送到通知栏');
  }

  Future<void> _testImportantNotification() async {
    final importantAlert = WeatherAlertModel(
      id: 'test_important_notification_${DateTime.now().millisecondsSinceEpoch}',
      title: '⚠️ 重要天气预警',
      content: '这是一条重要的天气预警测试通知，应该以红色高优先级显示。',
      level: WeatherAlertLevel.red,
      type: WeatherAlertType.rain,
      isRequired: true,
      isScenarioBased: false,
      scenario: '',
      threshold: '0',
      weatherTerm: '暴雨',
      reason: '重要提醒测试',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      cityName: '当前位置',
      priority: 1,
    );

    await _notificationService.sendWeatherAlertNotification(importantAlert);
    _showTestResult('重要提醒通知已发送到通知栏');
  }

  Future<void> _testBatchNotifications() async {
    final alerts = <WeatherAlertModel>[];

    // 创建多个测试提醒
    for (int i = 1; i <= 3; i++) {
      alerts.add(
        WeatherAlertModel(
          id: 'batch_test_${i}_${DateTime.now().millisecondsSinceEpoch}',
          title: '批量测试通知 $i',
          content: '这是第 $i 个批量测试通知，用于测试多个提醒的通知处理。',
          level: i == 1 ? WeatherAlertLevel.red : WeatherAlertLevel.yellow,
          type: i == 1 ? WeatherAlertType.rain : WeatherAlertType.other,
          isRequired: i == 1,
          isScenarioBased: i != 1,
          scenario: i != 1 ? '场景测试' : '',
          threshold: '0',
          weatherTerm: i == 1 ? '暴雨' : '小雨',
          reason: '批量通知测试',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          cityName: '当前位置',
          priority: i,
        ),
      );
    }

    await _notificationService.sendWeatherAlertNotifications(alerts);
    _showTestResult('批量通知测试完成，共发送 ${alerts.length} 个通知');
  }

  Future<void> _checkNotificationPermission() async {
    final hasPermission = await _notificationService.isPermissionGranted();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                hasPermission ? Icons.check_circle : Icons.warning,
                color: hasPermission ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text('通知权限状态'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPermission ? '✅ 通知权限已授予' : '❌ 通知权限未授予',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: hasPermission ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasPermission
                    ? '您的设备已授予通知权限，可以正常接收天气提醒通知。'
                    : '您的设备未授予通知权限，无法接收天气提醒通知。请到设置页面开启权限。',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (!hasPermission) ...[
                const SizedBox(height: 16),
                Text(
                  '通知设置状态：',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('• 通知开关: ${_notificationService.isEnabled ? "开启" : "关闭"}'),
                Text(
                  '• 声音开关: ${_notificationService.soundEnabled ? "开启" : "关闭"}',
                ),
                Text(
                  '• 震动开关: ${_notificationService.vibrationEnabled ? "开启" : "关闭"}',
                ),
                Text(
                  '• 仅重要提醒: ${_notificationService.onlyImportantAlerts ? "开启" : "关闭"}',
                ),
              ],
            ],
          ),
          actions: [
            if (!hasPermission)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final granted = await _notificationService
                      .requestPermissions();
                  if (granted) {
                    _showTestResult('通知权限已授予');
                    setState(() {}); // 刷新UI
                  } else {
                    _showTestResult('通知权限被拒绝');
                  }
                },
                child: const Text('请求权限'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
