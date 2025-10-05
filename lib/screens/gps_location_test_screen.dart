import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/location_service.dart';

/// GPS定位验证测试屏幕
class GpsLocationTestScreen extends StatefulWidget {
  const GpsLocationTestScreen({super.key});

  @override
  State<GpsLocationTestScreen> createState() => _GpsLocationTestScreenState();
}

class _GpsLocationTestScreenState extends State<GpsLocationTestScreen> {
  Map<String, dynamic>? _testResult;
  bool _isTesting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('GPS定位验证'),
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 测试按钮
            ElevatedButton(
              onPressed: _isTesting ? null : _runGpsValidation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isTesting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('正在验证GPS定位...'),
                      ],
                    )
                  : const Text('开始验证GPS定位'),
            ),

            const SizedBox(height: 24),

            // 结果显示
            if (_testResult != null) ...[
              Text(
                '验证结果',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResultCard(
                        '权限检查',
                        _testResult!['permission_check'] ? '✅ 通过' : '❌ 失败',
                        _testResult!['permission_check']
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildResultCard(
                        '位置服务',
                        _testResult!['service_enabled'] ? '✅ 开启' : '❌ 关闭',
                        _testResult!['service_enabled']
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(height: 12),
                      if (_testResult!['gps_position'] != null) ...[
                        _buildResultCard(
                          'GPS位置',
                          '✅ 获取成功',
                          Colors.green,
                          _buildGpsPositionDetails(
                            _testResult!['gps_position'],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_testResult!['reverse_geocoding'] != null) ...[
                        _buildResultCard(
                          '反向地理编码',
                          '✅ 成功',
                          Colors.green,
                          _buildGeocodingDetails(
                            _testResult!['reverse_geocoding'],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_testResult!['final_location'] != null) ...[
                        _buildResultCard(
                          '最终位置',
                          '✅ 定位成功',
                          Colors.green,
                          _buildLocationDetails(_testResult!['final_location']),
                        ),
                        const SizedBox(height: 12),
                        if (_testResult!['location_method'] != null) ...[
                          _buildResultCard(
                            '定位方式',
                            '📍 ${_testResult!['location_method']}',
                            Colors.blue,
                            _buildLocationMethodDetails(
                              _testResult!['location_method'],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                      if (_testResult!['errors'].isNotEmpty) ...[
                        _buildResultCard(
                          '错误信息',
                          '❌ 发现问题',
                          Colors.red,
                          _buildErrorDetails(_testResult!['errors']),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButtons(),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    String status,
    Color statusColor, [
    Widget? details,
  ]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (details != null) ...[const SizedBox(height: 12), details],
        ],
      ),
    );
  }

  Widget _buildGpsPositionDetails(Map<String, dynamic> position) {
    // 安全地处理 accuracy 字段，可能是数字或字符串
    String accuracyText = '';
    if (position['accuracy'] != null) {
      if (position['accuracy'] is num) {
        accuracyText = '${(position['accuracy'] as num).toStringAsFixed(1)} 米';
      } else {
        accuracyText = position['accuracy'].toString();
      }
    } else {
      accuracyText = '未知';
    }

    // 安全地处理纬度和经度字段
    String latitudeText = '';
    String longitudeText = '';

    if (position['latitude'] != null && position['latitude'] is num) {
      latitudeText = (position['latitude'] as num).toStringAsFixed(6);
    } else {
      latitudeText = position['latitude']?.toString() ?? '未知';
    }

    if (position['longitude'] != null && position['longitude'] is num) {
      longitudeText = (position['longitude'] as num).toStringAsFixed(6);
    } else {
      longitudeText = position['longitude']?.toString() ?? '未知';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('纬度: $latitudeText'),
        Text('经度: $longitudeText'),
        Text('精度: $accuracyText'),
        Text('时间: ${position['timestamp'] ?? '未知'}'),
      ],
    );
  }

  Widget _buildGeocodingDetails(Map<String, dynamic> geocoding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('地址: ${geocoding['address']}'),
        Text('区域: ${geocoding['district']}'),
        Text('城市: ${geocoding['city']}'),
        Text('省份: ${geocoding['province']}'),
      ],
    );
  }

  Widget _buildLocationDetails(dynamic location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('完整地址: ${location.address}'),
        Text('国家: ${location.country}'),
        Text('省份: ${location.province}'),
        Text('城市: ${location.city}'),
        Text('区县: ${location.district}'),
        Text('街道: ${location.street.isNotEmpty ? location.street : '未知'}'),
        Text('行政代码: ${location.adcode}'),
      ],
    );
  }

  Widget _buildLocationMethodDetails(String method) {
    String description;
    String accuracy;
    IconData icon;

    switch (method) {
      case 'GPS定位':
        description = '使用GPS卫星信号定位';
        accuracy = '精度较高，通常在10-50米';
        icon = Icons.satellite;
        break;
      case 'IP定位':
        description = '使用网络IP地址定位';
        accuracy = '精度较低，通常在1-10公里。当GPS定位成功但位置信息为"未知"时，系统会自动使用IP定位作为备用方案';
        icon = Icons.wifi;
        break;
      default:
        description = '未知定位方式';
        accuracy = '精度未知';
        icon = Icons.location_on;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(description),
          ],
        ),
        const SizedBox(height: 4),
        Text('精度: $accuracy'),
      ],
    );
  }

  Widget _buildErrorDetails(List<String> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: errors.map((error) => Text('• $error')).toList(),
    );
  }

  Widget _buildActionButtons() {
    List<String> errors = List<String>.from(_testResult!['errors']);
    bool hasLocationServiceError = errors.any(
      (error) => error.contains('位置服务未开启'),
    );
    bool hasPermissionError = errors.any(
      (error) => error.contains('权限') || error.contains('Permission'),
    );
    bool hasTimeoutError = errors.any(
      (error) => error.contains('超时') || error.contains('timeout'),
    );

    if (!hasLocationServiceError && !hasPermissionError && !hasTimeoutError) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '解决方案',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (hasTimeoutError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'GPS定位超时提示',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '建议到室外开阔地带重试，GPS信号在室内可能较弱',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasLocationServiceError) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openLocationSettings,
                icon: const Icon(Icons.location_on),
                label: const Text('开启位置服务'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasPermissionError) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('开启定位权限'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _runGpsValidation,
              icon: const Icon(Icons.refresh),
              label: const Text('重新验证'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runGpsValidation() async {
    if (!mounted) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
      _error = null;
    });

    try {
      final locationService = LocationService.getInstance();
      final result = await locationService.validateGpsLocation();

      if (!mounted) return;

      setState(() {
        _testResult = result;
        _isTesting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = '验证过程出错: $e';
        _isTesting = false;
      });
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      final locationService = LocationService.getInstance();
      await locationService.openLocationSettings();

      // 显示提示信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请开启位置服务后返回应用'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开位置设置: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openAppSettings() async {
    try {
      final locationService = LocationService.getInstance();
      await locationService.openAppSettings();

      // 显示提示信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请开启定位权限后返回应用'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开应用设置: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
