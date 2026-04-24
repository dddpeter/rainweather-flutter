/// 应用版本信息
///
/// 这个文件定义了应用的版本号，用于在关于弹窗等地方显示。
/// 版本号应该与 pubspec.yaml 中的版本保持一致。
class AppVersion {
  // 私有构造函数，防止实例化
  AppVersion._();

  /// 应用版本号（显示用）
  /// 格式: "主版本号.次版本号.修订号"
  static const String version = '1.18.0';

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
  static const String releaseDate = '2026-04-24';

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
v1.18.0 (2026-04-24)
• UI 优化：统一今日/城市天气页面头部布局，温度居中(72字号)+天气动画(右侧64)
• UI 优化：城市名移至AppBar标题栏，滚动时始终可见
• UI 优化：状态行固定高度20px，左对齐AI解读，右对齐告警图标
• UI 优化：卡片移除边框，统一使用纯背景色
• UI 优化：卡片顺序统一为24h天气→空气质量→详细信息→生活指数→日出日落→温度趋势图
• 优化：删除未使用的CityWeatherScreen等4个文件
• 修复：暗色模式背景色随主题方案正确切换
• 修复：AnimatedTheme嵌套问题，主题切换改用MaterialApp内置参数

v1.17.0 (2026-04-24)
• UI 优化：城市名移至AppBar标题栏，滚动时始终可见
• UI 优化：统一今日/城市天气页面卡片顺序
• UI 优化：今日天气头部区域精简，移除城市行，顶部间距优化
• 修复：修复AnimatedTheme嵌套导致的动画无效问题
• 优化：主题切换动画改用MaterialApp内置参数，平滑过渡

v1.16.0 (2026-03-27)
• Bug 修复：修复今日天气页面生活指数不显示问题
• Bug 修复：修复24小时预报温度标签底部溢出问题
• UI 优化：AI解读改为标签样式，支持预取缓存
• UI 优化：今日天气和城市天气页面顶部区域更紧凑
• UI 优化：减少卡片间距和屏幕水平间距
''';
  }
}
