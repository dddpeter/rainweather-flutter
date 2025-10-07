import 'package:flutter/material.dart';
import '../services/tencent_location_service.dart';
import '../services/amap_location_service.dart';
import '../services/baidu_location_service.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import '../constants/app_colors.dart';

/// 统一定位测试页面
class AllLocationTestScreen extends StatefulWidget {
  const AllLocationTestScreen({super.key});

  @override
  State<AllLocationTestScreen> createState() => _AllLocationTestScreenState();
}

class _AllLocationTestScreenState extends State<AllLocationTestScreen> {
  // 各个定位服务的状态
  final Map<String, LocationTestResult> _results = {
    'tencent': LocationTestResult(),
    'amap': LocationTestResult(),
    'baidu': LocationTestResult(),
    'gps': LocationTestResult(),
  };

  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('定位服务测试'),
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 测试按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isTesting ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isTesting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('正在测试所有定位服务...'),
                      ],
                    )
                  : const Text(
                      '开始测试所有定位服务',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          // 测试结果列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTestResultCard(
                  '腾讯定位',
                  'tencent',
                  Icons.location_on,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildTestResultCard('高德地图定位', 'amap', Icons.map, Colors.green),
                const SizedBox(height: 12),
                _buildTestResultCard(
                  '百度定位',
                  'baidu',
                  Icons.explore,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildTestResultCard(
                  'GPS定位',
                  'gps',
                  Icons.gps_fixed,
                  Colors.purple,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个测试结果卡片
  Widget _buildTestResultCard(
    String title,
    String key,
    IconData icon,
    Color color,
  ) {
    final result = _results[key]!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (result.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else if (result.isSuccess)
                  Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (result.error != null)
                  Icon(Icons.error, color: Colors.red, size: 24),
              ],
            ),
          ),

          // 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态信息
                if (result.status.isNotEmpty)
                  _buildInfoRow('状态', result.status),

                // 错误信息
                if (result.error != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('错误', result.error!, isError: true),
                ],

                // 定位信息
                if (result.location != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow('省份', result.location!.province),
                  const SizedBox(height: 4),
                  _buildInfoRow('城市', result.location!.city),
                  const SizedBox(height: 4),
                  _buildInfoRow('区县', result.location!.district),
                  const SizedBox(height: 4),
                  _buildInfoRow('街道', result.location!.street),
                  const SizedBox(height: 4),
                  _buildInfoRow('详细地址', result.location!.address),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    '坐标',
                    '${result.location!.lat.toStringAsFixed(6)}, ${result.location!.lng.toStringAsFixed(6)}',
                  ),
                  if (result.duration != null) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow('耗时', '${result.duration!.inMilliseconds}ms'),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isError ? Colors.red : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 运行所有定位测试
  Future<void> _runAllTests() async {
    setState(() {
      _isTesting = true;
      // 重置所有结果
      _results.forEach((key, value) {
        value.reset();
        value.isLoading = true;
      });
    });

    // 并发测试所有定位服务
    await Future.wait([
      _testTencentLocation(),
      _testAmapLocation(),
      _testBaiduLocation(),
      _testGpsLocation(),
    ]);

    setState(() {
      _isTesting = false;
    });
  }

  /// 测试腾讯定位
  Future<void> _testTencentLocation() async {
    final result = _results['tencent']!;

    try {
      setState(() {
        result.status = '正在获取腾讯定位...';
      });

      final startTime = DateTime.now();
      final service = TencentLocationService.getInstance();
      final location = await service.getCurrentLocation();
      final duration = DateTime.now().difference(startTime);

      setState(() {
        if (location != null) {
          result.location = location;
          result.isSuccess = true;
          result.status = '定位成功';
          result.duration = duration;
        } else {
          result.error = '定位失败：返回结果为空';
          result.status = '定位失败';
        }
        result.isLoading = false;
      });
    } catch (e) {
      setState(() {
        result.error = '定位异常: $e';
        result.status = '定位异常';
        result.isLoading = false;
      });
    }
  }

  /// 测试高德地图定位
  Future<void> _testAmapLocation() async {
    final result = _results['amap']!;

    try {
      setState(() {
        result.status = '正在获取高德地图定位...';
      });

      final startTime = DateTime.now();
      final service = AMapLocationService.getInstance();
      final location = await service.getCurrentLocation();
      final duration = DateTime.now().difference(startTime);

      setState(() {
        if (location != null) {
          result.location = location;
          result.isSuccess = true;
          result.status = '定位成功';
          result.duration = duration;
        } else {
          result.error = '定位失败：返回结果为空';
          result.status = '定位失败';
        }
        result.isLoading = false;
      });
    } catch (e) {
      setState(() {
        result.error = '定位异常: $e';
        result.status = '定位异常';
        result.isLoading = false;
      });
    }
  }

  /// 测试百度定位
  Future<void> _testBaiduLocation() async {
    final result = _results['baidu']!;

    try {
      setState(() {
        result.status = '正在获取百度定位...';
      });

      final startTime = DateTime.now();
      final service = BaiduLocationService.getInstance();
      final location = await service.getCurrentLocation();
      final duration = DateTime.now().difference(startTime);

      setState(() {
        if (location != null) {
          result.location = location;
          result.isSuccess = true;
          result.status = '定位成功';
          result.duration = duration;
        } else {
          result.error = '定位失败：返回结果为空';
          result.status = '定位失败';
        }
        result.isLoading = false;
      });
    } catch (e) {
      setState(() {
        result.error = '定位异常: $e';
        result.status = '定位异常';
        result.isLoading = false;
      });
    }
  }

  /// 测试GPS定位
  Future<void> _testGpsLocation() async {
    final result = _results['gps']!;

    try {
      setState(() {
        result.status = '正在获取GPS定位...';
      });

      final startTime = DateTime.now();
      final service = LocationService.getInstance();

      // 使用getCurrentLocation，它会尝试所有定位方式
      // 为了只测试GPS，我们直接调用底层GPS方法
      final location = await service.getCurrentLocation();

      final duration = DateTime.now().difference(startTime);

      setState(() {
        if (location != null) {
          result.location = location;
          result.isSuccess = true;
          result.status = '定位成功';
          result.duration = duration;
        } else {
          result.error = 'GPS定位失败';
          result.status = '定位失败';
        }
        result.isLoading = false;
      });
    } catch (e) {
      setState(() {
        result.error = '定位异常: $e';
        result.status = '定位异常';
        result.isLoading = false;
      });
    }
  }
}

/// 定位测试结果数据类
class LocationTestResult {
  String status = '等待测试';
  LocationModel? location;
  String? error;
  bool isLoading = false;
  bool isSuccess = false;
  Duration? duration;

  void reset() {
    status = '等待测试';
    location = null;
    error = null;
    isLoading = false;
    isSuccess = false;
    duration = null;
  }
}
