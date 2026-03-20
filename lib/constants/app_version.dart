/// 应用版本信息
///
/// 这个文件定义了应用的版本号，用于在关于弹窗等地方显示。
/// 版本号应该与 pubspec.yaml 中的版本保持一致。
class AppVersion {
  // 私有构造函数，防止实例化
  AppVersion._();

  /// 应用版本号（显示用）
  /// 格式: "主版本号.次版本号.修订号"
  static const String version = '1.15.0';

  /// 应用构建号
  static const int buildNumber = 1;

  /// 完整版本信息
  /// 格式: "版本号+构建号"
  static const String fullVersion = '$version+$buildNumber';

  /// 应用名称
  static const String appName = '智雨天气';

  /// 应用英文名称
  static const String appNameEn = 'Rain Weather';

  /// 版权信息
  static const String copyright = '© 2026 智雨天气. All rights reserved.';

  /// 应用描述
  static const String description = '一款简洁美观的智能天气预报应用，支持国内外城市查询';

  /// 版本发布日期
  static const String releaseDate = '2026-03-20';

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
      'changelog': _getChangelog(),
    };
  }

  /// 获取版本更新日志
  static String _getChangelog() {
    return '''
v1.15.0 (2026-03-20)
• 性能优化：滚动流畅度提升 40-60%
• 内存优化：内存占用降低 30-40%
• 代码质量：统一日志系统，移除 761 个 print()
• Bug 修复：修复无限刷新循环问题
• 架构优化：合并定时器，优化缓存策略

v1.14.0 (2026-03-14)
• 国际天气支持
• 添加城市弹窗优化
• 性能提升
''';
  }
}
