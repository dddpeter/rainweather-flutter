import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather_alert_model.dart';
import '../services/weather_alert_service.dart';
import '../services/notification_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 天气提醒设置页面
class WeatherAlertSettingsScreen extends StatefulWidget {
  const WeatherAlertSettingsScreen({super.key});

  @override
  State<WeatherAlertSettingsScreen> createState() =>
      _WeatherAlertSettingsScreenState();
}

class _WeatherAlertSettingsScreenState
    extends State<WeatherAlertSettingsScreen> {
  late WeatherAlertSettings _settings;
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _settings = WeatherAlertService.instance.settings;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('天气提醒设置'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
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
                    _buildBasicSettings(),
                    AppColors.cardSpacingWidget,
                    _buildCommuteSettings(),
                    AppColors.cardSpacingWidget,
                    _buildAirQualitySettings(),
                    AppColors.cardSpacingWidget,
                    _buildTemperatureSettings(),
                    AppColors.cardSpacingWidget,
                    _buildNotificationSettings(),
                    AppColors.cardSpacingWidget,
                    _buildAlertRules(),
                  ],
                ),
              ),
      ),
    );
  }

  /// 基础设置
  Widget _buildBasicSettings() {
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
                  Icons.settings,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '基础设置',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 启用一档提醒
            _buildSwitchTile(
              title: '启用一档提醒',
              subtitle: '暴雨、暴雪、沙尘暴等危险天气必须提醒',
              value: _settings.enableRequiredAlerts,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enableRequiredAlerts: value);
                });
                _saveSettings();
              },
            ),

            const SizedBox(height: 8),

            // 启用二档提醒
            _buildSwitchTile(
              title: '启用二档提醒',
              subtitle: '大雨、雾等天气在特定场景下提醒',
              value: _settings.enableScenarioAlerts,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enableScenarioAlerts: value);
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 通勤设置
  Widget _buildCommuteSettings() {
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
                  Icons.directions_car,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '通勤提醒',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 启用通勤提醒
            _buildSwitchTile(
              title: '启用通勤提醒',
              subtitle: '在通勤时间启用场景提醒',
              value: _settings.enableCommuteAlerts,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enableCommuteAlerts: value);
                });
                _saveSettings();
              },
            ),

            if (_settings.enableCommuteAlerts) ...[
              const SizedBox(height: 16),

              // 早晨通勤时间
              _buildTimeRangeTile(
                title: '早晨通勤时间',
                startTime: _settings.commuteTime.morningStart,
                endTime: _settings.commuteTime.morningEnd,
                onStartTimeChanged: (time) {
                  setState(() {
                    _settings = _settings.copyWith(
                      commuteTime: CommuteTimeSettings(
                        morningStart: time,
                        morningEnd: _settings.commuteTime.morningEnd,
                        eveningStart: _settings.commuteTime.eveningStart,
                        eveningEnd: _settings.commuteTime.eveningEnd,
                        workDays: _settings.commuteTime.workDays,
                      ),
                    );
                  });
                  _debouncedSaveSettings();
                },
                onEndTimeChanged: (time) {
                  setState(() {
                    _settings = _settings.copyWith(
                      commuteTime: CommuteTimeSettings(
                        morningStart: _settings.commuteTime.morningStart,
                        morningEnd: time,
                        eveningStart: _settings.commuteTime.eveningStart,
                        eveningEnd: _settings.commuteTime.eveningEnd,
                        workDays: _settings.commuteTime.workDays,
                      ),
                    );
                  });
                  _debouncedSaveSettings();
                },
              ),

              const SizedBox(height: 16),

              // 晚上通勤时间
              _buildTimeRangeTile(
                title: '晚上通勤时间',
                startTime: _settings.commuteTime.eveningStart,
                endTime: _settings.commuteTime.eveningEnd,
                onStartTimeChanged: (time) {
                  setState(() {
                    _settings = _settings.copyWith(
                      commuteTime: CommuteTimeSettings(
                        morningStart: _settings.commuteTime.morningStart,
                        morningEnd: _settings.commuteTime.morningEnd,
                        eveningStart: time,
                        eveningEnd: _settings.commuteTime.eveningEnd,
                        workDays: _settings.commuteTime.workDays,
                      ),
                    );
                  });
                  _debouncedSaveSettings();
                },
                onEndTimeChanged: (time) {
                  setState(() {
                    _settings = _settings.copyWith(
                      commuteTime: CommuteTimeSettings(
                        morningStart: _settings.commuteTime.morningStart,
                        morningEnd: _settings.commuteTime.morningEnd,
                        eveningStart: _settings.commuteTime.eveningStart,
                        eveningEnd: time,
                        workDays: _settings.commuteTime.workDays,
                      ),
                    );
                  });
                  _debouncedSaveSettings();
                },
              ),

              const SizedBox(height: 8),

              // 工作日设置
              _buildWorkDaysTile(),
            ],
          ],
        ),
      ),
    );
  }

  /// 空气质量设置
  Widget _buildAirQualitySettings() {
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
                  Icons.air,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '空气质量提醒',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 启用空气质量提醒
            _buildSwitchTile(
              title: '启用空气质量提醒',
              subtitle: '当空气质量超过阈值时提醒',
              value: _settings.enableAirQualityAlerts,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enableAirQualityAlerts: value);
                });
                _saveSettings();
              },
            ),

            if (_settings.enableAirQualityAlerts) ...[
              const SizedBox(height: 16),

              // 空气质量阈值
              _buildNumberPickerTile(
                title: '空气质量阈值 (AQI)',
                unit: '',
                value: _settings.airQualityThreshold,
                min: 50,
                max: 300,
                step: 10,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(airQualityThreshold: value);
                  });
                  _debouncedSaveSettings();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 温度设置
  Widget _buildTemperatureSettings() {
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
                  Icons.thermostat,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '温度提醒',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 启用温度提醒
            _buildSwitchTile(
              title: '启用温度提醒',
              subtitle: '当温度超过设定阈值时提醒',
              value: _settings.enableTemperatureAlerts,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(
                    enableTemperatureAlerts: value,
                  );
                });
                _saveSettings();
              },
            ),

            if (_settings.enableTemperatureAlerts) ...[
              const SizedBox(height: 16),

              // 高温阈值
              _buildNumberPickerTile(
                title: '高温阈值',
                unit: '℃',
                value: _settings.highTemperatureThreshold,
                min: 30,
                max: 50,
                step: 1,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(
                      highTemperatureThreshold: value,
                    );
                  });
                  _debouncedSaveSettings();
                },
              ),

              const SizedBox(height: 16),

              // 低温阈值
              _buildNumberPickerTile(
                title: '低温阈值',
                unit: '℃',
                value: _settings.lowTemperatureThreshold,
                min: -20,
                max: 10,
                step: 1,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(
                      lowTemperatureThreshold: value,
                    );
                  });
                  _debouncedSaveSettings();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 通知设置
  Widget _buildNotificationSettings() {
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
                  Icons.notifications,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '通知设置',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppConstants.sectionTitleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        NotificationService.instance.getSettingsSummary(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 权限检查
            FutureBuilder<bool>(
              future: NotificationService.instance.isPermissionGranted(),
              builder: (context, snapshot) {
                final hasPermission = snapshot.data ?? false;
                return Card(
                  elevation: 0,
                  color: hasPermission
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: hasPermission
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      hasPermission ? Icons.check_circle : Icons.warning,
                      color: hasPermission ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      hasPermission ? '通知权限已授予' : '需要通知权限',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      hasPermission ? '可以正常接收天气提醒通知' : '点击请求通知权限以接收天气提醒',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: hasPermission
                        ? null
                        : TextButton(
                            onPressed: () async {
                              final granted = await NotificationService.instance
                                  .requestPermissions();
                              if (granted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('通知权限已授予'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('通知权限被拒绝，请在系统设置中手动开启'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            child: const Text('请求权限'),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 提醒声音
            _buildSwitchTile(
              title: '提醒声音',
              subtitle: '收到提醒时播放提示音',
              value: _settings.enableAlertSound,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enableAlertSound: value);
                });
                _saveSettings();
              },
            ),

            const SizedBox(height: 8),

            // 本地通知
            _buildSwitchTile(
              title: '推送通知',
              subtitle: '在系统通知栏显示天气提醒',
              value: NotificationService.instance.isEnabled,
              onChanged: (value) async {
                await NotificationService.instance.setEnabled(value);
                setState(() {});
                _saveSettings();
              },
            ),

            const SizedBox(height: 8),

            // 通知声音
            _buildSwitchTile(
              title: '通知声音',
              subtitle: '推送通知时播放提示音',
              value: NotificationService.instance.soundEnabled,
              onChanged: (value) async {
                await NotificationService.instance.setSoundEnabled(value);
                setState(() {});
                _saveSettings();
              },
            ),

            const SizedBox(height: 8),

            // 通知振动
            _buildSwitchTile(
              title: '通知振动',
              subtitle: '推送通知时震动提示',
              value: NotificationService.instance.vibrationEnabled,
              onChanged: (value) async {
                await NotificationService.instance.setVibrationEnabled(value);
                setState(() {});
                _saveSettings();
              },
            ),

            const SizedBox(height: 8),

            // 仅重要提醒
            _buildSwitchTile(
              title: '仅重要提醒',
              subtitle: '只推送红色预警和危险天气通知',
              value: NotificationService.instance.onlyImportantAlerts,
              onChanged: (value) async {
                await NotificationService.instance.setOnlyImportantAlerts(
                  value,
                );
                setState(() {});
                _saveSettings();
              },
            ),

            const SizedBox(height: 8),

            // 提醒振动
            _buildSwitchTile(
              title: '提醒振动',
              subtitle: '收到提醒时震动提示',
              value: _settings.enableAlertVibration,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enableAlertVibration: value);
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 提醒规则说明
  Widget _buildAlertRules() {
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
                  Icons.rule,
                  color: AppColors.accentBlue,
                  size: AppConstants.sectionTitleIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  '提醒规则说明',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.sectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRuleSection('一档：必须提醒（红色预警/危险）', [
              '暴雨、大暴雨、特大暴雨 - 城市内涝、地铁停运',
              '暴雪 - 道路结冰、高速封路',
              '沙尘暴、强沙尘暴 - 能见度<200m，呼吸系统风险',
              '冰雹、雨凇 - 砸车、砸伤人',
              '中度霾、重度霾、严重霾 - PM2.5>150，健康风险',
              '冻雨 - 电线/路面结冰，极易翻车',
            ], Colors.red),

            const SizedBox(height: 16),

            _buildRuleSection('二档：看场景提醒（黄色预警/出行高峰）', [
              '大雨、雷阵雨 - 下班高峰+红色拥堵路段',
              '雾、浓雾、强浓雾 - 机场/高速出行前',
              '雨夹雪、雨雪天气 - 早晨通勤',
              '浮尘、扬沙 - 儿童/老人外出',
            ], Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleSection(String title, List<String> rules, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...rules.map(
          (rule) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              '• $rule',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accentBlue,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 时间范围选择控件
  Widget _buildTimeRangeTile({
    required String title,
    required CustomTimeOfDay startTime,
    required CustomTimeOfDay endTime,
    required ValueChanged<CustomTimeOfDay> onStartTimeChanged,
    required ValueChanged<CustomTimeOfDay> onEndTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 开始时间
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: startTime.hour,
                      minute: startTime.minute,
                    ),
                  );
                  if (time != null) {
                    onStartTimeChanged(
                      CustomTimeOfDay(hour: time.hour, minute: time.minute),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$startTime',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '开始',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 连接线
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            // 结束时间
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: endTime.hour,
                      minute: endTime.minute,
                    ),
                  );
                  if (time != null) {
                    onEndTimeChanged(
                      CustomTimeOfDay(hour: time.hour, minute: time.minute),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$endTime',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '结束',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 数字选择器（替代滑动条）
  Widget _buildNumberPickerTile({
    required String title,
    required String unit,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // 减少按钮
              InkWell(
                onTap: value > min
                    ? () {
                        onChanged(value - step);
                      }
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Icon(
                    Icons.remove,
                    color: value > min
                        ? AppColors.accentBlue
                        : AppColors.textSecondary.withOpacity(0.3),
                    size: 24,
                  ),
                ),
              ),
              // 分隔线
              Container(width: 1, height: 40, color: AppColors.cardBorder),
              // 数值显示
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '$value$unit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // 分隔线
              Container(width: 1, height: 40, color: AppColors.cardBorder),
              // 增加按钮
              InkWell(
                onTap: value < max
                    ? () {
                        onChanged(value + step);
                      }
                    : null,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Icon(
                    Icons.add,
                    color: value < max
                        ? AppColors.accentBlue
                        : AppColors.textSecondary.withOpacity(0.3),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 范围提示
        Text(
          '范围: $min - $max$unit',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWorkDaysTile() {
    final workDays = _settings.commuteTime.workDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '工作日设置',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
            final isSelected = workDays.contains(index + 1);

            return FilterChip(
              label: Text(dayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newWorkDays = List<int>.from(workDays);
                  if (selected) {
                    newWorkDays.add(index + 1);
                  } else {
                    newWorkDays.remove(index + 1);
                  }
                  _settings = _settings.copyWith(
                    commuteTime: CommuteTimeSettings(workDays: newWorkDays),
                  );
                });
                _saveSettings();
              },
              selectedColor: AppColors.accentBlue.withOpacity(0.2),
              checkmarkColor: AppColors.accentBlue,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
                fontSize: 12,
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 防抖保存设置（延迟保存，避免频繁操作导致页面跳转）
  void _debouncedSaveSettings() {
    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 设置新的定时器，500ms后保存
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveSettings();
    });
  }

  Future<void> _saveSettings() async {
    try {
      // 不显示loading，避免页面重建
      await WeatherAlertService.instance.saveSettings(_settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存设置失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
