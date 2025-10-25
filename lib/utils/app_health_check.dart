import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';

/// 健康检查报告
class HealthReport {
  bool database = false;
  bool network = false;
  bool location = false;
  bool permissions = false;
  String databaseError = '';
  String networkError = '';
  String locationError = '';
  String permissionsError = '';

  bool get isHealthy => database && network && location && permissions;

  Map<String, dynamic> toJson() => {
    'database': database,
    'network': network,
    'location': location,
    'permissions': permissions,
    'isHealthy': isHealthy,
    'errors': {
      'database': databaseError,
      'network': networkError,
      'location': locationError,
      'permissions': permissionsError,
    },
  };

  @override
  String toString() {
    final status = <String>[];
    if (database) {
      status.add('✅ 数据库');
    } else {
      status.add('❌ 数据库: $databaseError');
    }

    if (network) {
      status.add('✅ 网络');
    } else {
      status.add('❌ 网络: $networkError');
    }

    if (location) {
      status.add('✅ 定位');
    } else {
      status.add('❌ 定位: $locationError');
    }

    if (permissions) {
      status.add('✅ 权限');
    } else {
      status.add('❌ 权限: $permissionsError');
    }

    return status.join('\n');
  }
}

/// 应用健康检查
class AppHealthCheck {
  static final AppHealthCheck _instance = AppHealthCheck._internal();
  factory AppHealthCheck() => _instance;
  AppHealthCheck._internal();

  /// 执行完整健康检查
  Future<HealthReport> performCheck({bool verbose = false}) async {
    if (verbose) print('\n🏥 开始应用健康检查...');

    final report = HealthReport();

    // 并行执行所有检查以提高速度
    await Future.wait([
      _checkDatabase(report, verbose),
      _checkNetwork(report, verbose),
      _checkLocationService(report, verbose),
      _checkPermissions(report, verbose),
    ]);

    if (verbose) {
      print('\n📊 健康检查结果:');
      print(report.toString());
      print('总体状态: ${report.isHealthy ? '✅ 健康' : '⚠️ 存在问题'}\n');
    }

    return report;
  }

  /// 检查数据库
  Future<void> _checkDatabase(HealthReport report, bool verbose) async {
    try {
      if (verbose) print('🔍 检查数据库连接...');

      final dbService = DatabaseService.getInstance();

      // 尝试执行简单查询来验证数据库
      final isInitialized = await dbService.isCitiesTableInitialized();

      if (isInitialized) {
        report.database = true;
        if (verbose) print('✅ 数据库连接正常');
      } else {
        report.database = false;
        report.databaseError = '数据库未初始化';
        if (verbose) print('❌ 数据库未初始化');
      }
    } catch (e) {
      report.database = false;
      report.databaseError = e.toString();
      if (verbose) print('❌ 数据库检查失败: $e');
    }
  }

  /// 检查网络连接
  Future<void> _checkNetwork(HealthReport report, bool verbose) async {
    try {
      if (verbose) print('🔍 检查网络连接...');

      // 简单的网络连接检查：尝试ping常用域名
      try {
        final result = await InternetAddress.lookup(
          'www.baidu.com',
        ).timeout(const Duration(seconds: 3));

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          report.network = true;
          if (verbose) print('✅ 网络连接正常');
        } else {
          report.network = false;
          report.networkError = '无法解析域名';
          if (verbose) print('❌ 无法解析域名');
        }
      } on SocketException catch (e) {
        report.network = false;
        report.networkError = '网络不可达: ${e.message}';
        if (verbose) print('❌ 网络不可达');
      }
    } catch (e) {
      report.network = false;
      report.networkError = e.toString();
      if (verbose) print('❌ 网络检查失败: $e');
    }
  }

  /// 检查定位服务
  Future<void> _checkLocationService(HealthReport report, bool verbose) async {
    try {
      if (verbose) print('🔍 检查定位服务...');

      // 检查定位服务是否启用
      final isEnabled = await Geolocator.isLocationServiceEnabled();

      if (isEnabled) {
        report.location = true;
        if (verbose) print('✅ 定位服务已启用');
      } else {
        report.location = false;
        report.locationError = '定位服务未启用';
        if (verbose) print('❌ 定位服务未启用');
      }
    } catch (e) {
      report.location = false;
      report.locationError = e.toString();
      if (verbose) print('❌ 定位服务检查失败: $e');
    }
  }

  /// 检查权限
  Future<void> _checkPermissions(HealthReport report, bool verbose) async {
    try {
      if (verbose) print('🔍 检查应用权限...');

      final locationService = LocationService.getInstance();

      // 检查定位权限
      final permissionResult = await locationService.checkLocationPermission();
      final hasPermission =
          permissionResult == LocationPermissionResult.granted;

      if (hasPermission) {
        report.permissions = true;
        if (verbose) print('✅ 应用权限正常');
      } else {
        report.permissions = false;
        report.permissionsError = '缺少定位权限: ${permissionResult.name}';
        if (verbose) print('❌ 缺少定位权限: ${permissionResult.name}');
      }
    } catch (e) {
      report.permissions = false;
      report.permissionsError = e.toString();
      if (verbose) print('❌ 权限检查失败: $e');
    }
  }

  /// 修复检测到的问题
  Future<bool> fixIssues(HealthReport report) async {
    print('\n🔧 开始修复检测到的问题...');

    bool allFixed = true;

    // 修复数据库问题
    if (!report.database) {
      allFixed &= await _fixDatabase();
    }

    // 修复定位服务问题
    if (!report.location) {
      allFixed &= await _fixLocationService();
    }

    // 权限问题需要用户授权，只能提示
    if (!report.permissions) {
      print('⚠️ 权限问题需要用户手动授权');
      allFixed = false;
    }

    // 网络问题无法自动修复
    if (!report.network) {
      print('⚠️ 网络连接问题需要用户检查设置');
      allFixed = false;
    }

    if (allFixed) {
      print('✅ 所有问题已修复');
    } else {
      print('⚠️ 部分问题需要用户介入');
    }

    return allFixed;
  }

  /// 修复数据库
  Future<bool> _fixDatabase() async {
    try {
      print('🔧 尝试重新初始化数据库...');
      final dbService = DatabaseService.getInstance();
      await dbService.initDatabase();
      print('✅ 数据库已重新初始化');
      return true;
    } catch (e) {
      print('❌ 数据库修复失败: $e');
      return false;
    }
  }

  /// 修复定位服务
  Future<bool> _fixLocationService() async {
    try {
      print('🔧 尝试重启定位服务...');
      final locationService = LocationService.getInstance();

      // 尝试重新请求权限
      final permissionResult = await locationService
          .requestLocationPermission();
      final hasPermission =
          permissionResult == LocationPermissionResult.granted;

      if (hasPermission) {
        print('✅ 定位服务已恢复');
        return true;
      } else {
        print('⚠️ 定位服务需要用户授权: ${permissionResult.name}');
        return false;
      }
    } catch (e) {
      print('❌ 定位服务修复失败: $e');
      return false;
    }
  }

  /// 快速健康检查（仅检查关键项）
  Future<bool> quickCheck() async {
    try {
      // 只检查网络和数据库
      try {
        await InternetAddress.lookup(
          'www.baidu.com',
        ).timeout(const Duration(seconds: 2));
      } on SocketException {
        print('⚠️ 快速检查: 无网络连接');
        return false;
      }

      final dbService = DatabaseService.getInstance();
      final isDbOk = await dbService.isCitiesTableInitialized();
      if (!isDbOk) {
        print('⚠️ 快速检查: 数据库未初始化');
        return false;
      }

      print('✅ 快速检查: 系统正常');
      return true;
    } catch (e) {
      print('❌ 快速检查失败: $e');
      return false;
    }
  }
}
