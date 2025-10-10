/// 应用版本信息
///
/// 这个文件定义了应用的版本号，用于在关于弹窗等地方显示。
/// 版本号应该与 pubspec.yaml 中的版本保持一致。
class AppVersion {
  // 私有构造函数，防止实例化
  AppVersion._();

  /// 应用版本号（显示用）
  /// 格式: "主版本号.次版本号.修订号"
  static const String version = '1.11.0';

  /// 应用构建号
  static const int buildNumber = 11;

  /// 完整版本信息
  /// 格式: "版本号+构建号"
  static const String fullVersion = '$version+$buildNumber';

  /// 应用名称
  static const String appName = '知雨天气';

  /// 应用英文名称
  static const String appNameEn = 'Rain Weather';

  /// 版权信息
  static const String copyright = '© 2025 知雨天气. All rights reserved.';

  /// 应用描述
  static const String description = '一款简洁美观的智能天气预报应用';

  /// 版本发布日期
  static const String releaseDate = '2025-10-10';

  /// 获取版本信息摘要
  static String getVersionSummary() {
    return '版本 $version (构建 $buildNumber)';
  }

  /// 获取完整的关于信息
  static Map<String, String> getAboutInfo() {
    return {
      'appName': appName,
      'version': version,
      'buildNumber': buildNumber.toString(),
      'fullVersion': fullVersion,
      'description': description,
      'copyright': copyright,
      'releaseDate': releaseDate,
    };
  }
}
