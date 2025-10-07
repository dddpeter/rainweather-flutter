import 'package:flutter/material.dart';
import '../services/baidu_location_service.dart';
import '../services/location_service.dart';
import '../constants/app_colors.dart';

/// 百度定位测试页面
class BaiduLocationTestScreen extends StatefulWidget {
  const BaiduLocationTestScreen({super.key});

  @override
  State<BaiduLocationTestScreen> createState() =>
      _BaiduLocationTestScreenState();
}

class _BaiduLocationTestScreenState extends State<BaiduLocationTestScreen> {
  String _status = '准备测试定位...';
  String _locationInfo = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('百度定位测试'),
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态显示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '测试状态',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 位置信息显示
            if (_locationInfo.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '位置信息',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _locationInfo,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 测试按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _testBaiduLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('正在测试百度定位...'),
                      ],
                    )
                  : const Text('测试百度定位'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _testLocationService,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('正在测试综合定位服务...'),
                      ],
                    )
                  : const Text('测试综合定位服务'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _checkLocationStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('正在检查定位状态...'),
                      ],
                    )
                  : const Text('检查定位状态'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _testSimpleLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('正在简化测试...'),
                      ],
                    )
                  : const Text('简化定位测试'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testBaiduLocation() async {
    setState(() {
      _isLoading = true;
      _status = '正在测试百度定位...';
      _locationInfo = '';
    });

    try {
      final baiduService = BaiduLocationService.getInstance();
      final location = await baiduService.getCurrentLocation();

      if (location != null) {
        setState(() {
          _status = '百度定位成功！';
          _locationInfo =
              '''
省份: ${location.province}
城市: ${location.city}
区县: ${location.district}
街道: ${location.street}
地址: ${location.address}
纬度: ${location.lat}
经度: ${location.lng}
          ''';
        });
      } else {
        setState(() {
          _status = '百度定位失败';
          _locationInfo = '无法获取位置信息';
        });
      }
    } catch (e) {
      setState(() {
        _status = '百度定位错误: $e';
        _locationInfo = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocationService() async {
    setState(() {
      _isLoading = true;
      _status = '正在测试综合定位服务...';
      _locationInfo = '';
    });

    try {
      final locationService = LocationService.getInstance();
      final location = await locationService.getCurrentLocation();

      if (location != null) {
        setState(() {
          _status = '综合定位成功！';
          _locationInfo =
              '''
省份: ${location.province}
城市: ${location.city}
区县: ${location.district}
街道: ${location.street}
地址: ${location.address}
纬度: ${location.lat}
经度: ${location.lng}
是否代理检测: ${location.isProxyDetected ? '是' : '否'}
          ''';
        });
      } else {
        setState(() {
          _status = '综合定位失败';
          _locationInfo = '无法获取位置信息';
        });
      }
    } catch (e) {
      setState(() {
        _status = '综合定位错误: $e';
        _locationInfo = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkLocationStatus() async {
    setState(() {
      _isLoading = true;
      _status = '正在检查定位状态...';
      _locationInfo = '';
    });

    try {
      final baiduService = BaiduLocationService.getInstance();
      final status = await baiduService.getLocationCapabilities();

      setState(() {
        _status = '定位状态检查完成';
        _locationInfo =
            '''
服务可用: ${status['serviceAvailable']}
权限状态: ${status['permission']}
状态描述: ${status['statusDescription']}
建议: ${status['recommendation']}
支持百度定位: ${status['supportsBaiduLocation']}
坐标系: ${status['coordinateType']}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '状态检查错误: $e';
        _locationInfo = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSimpleLocation() async {
    setState(() {
      _isLoading = true;
      _status = '正在简化测试定位...';
      _locationInfo = '';
    });

    try {
      final baiduService = BaiduLocationService.getInstance();

      // 直接调用startLocation进行简单测试
      print('🔧 开始简化定位测试...');
      await baiduService.startLocation();
      print('🔧 定位启动完成');

      setState(() {
        _status = '定位启动成功，等待结果...';
        _locationInfo = '请查看控制台日志获取详细信息';
      });

      // 等待5秒后停止定位
      await Future.delayed(const Duration(seconds: 5));
      await baiduService.stopLocation();

      setState(() {
        _status = '简化测试完成';
        _locationInfo = '请查看控制台日志了解详细过程';
      });
    } catch (e) {
      setState(() {
        _status = '简化测试错误: $e';
        _locationInfo = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
