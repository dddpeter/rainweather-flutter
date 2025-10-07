/// 城市名称匹配工具类
/// 提供统一的城市名称匹配逻辑，支持行政区划后缀的处理
class CityNameMatcher {
  /// 判断城市名称是否匹配
  /// 支持多种匹配方式：完全匹配、标准化匹配（去除行政区划后缀）
  static bool isCityNameMatch(String cityName1, String cityName2) {
    // 完全匹配
    if (cityName1 == cityName2) {
      return true;
    }

    // 标准化匹配
    final normalized1 = normalizeCityName(cityName1);
    final normalized2 = normalizeCityName(cityName2);

    return normalized1 == normalized2;
  }

  /// 标准化城市名称，去除行政区划后缀
  /// 只去除末尾的后缀，不影响中间的字符
  static String normalizeCityName(String cityName) {
    String normalized = cityName;

    // 特殊处理：如果是两个字且以县、市、区结尾，则不进行替换
    if (normalized.length == 2 &&
        (normalized.endsWith('县') ||
            normalized.endsWith('市') ||
            normalized.endsWith('区'))) {
      return normalized;
    }

    // 按优先级顺序去除末尾的后缀（从长到短，避免误匹配）
    final suffixes = ['特别行政区', '自治区', '自治县', '特区', '省', '市', '区', '县'];

    for (final suffix in suffixes) {
      if (normalized.endsWith(suffix)) {
        final withoutSuffix = normalized.substring(
          0,
          normalized.length - suffix.length,
        );

        // 检查去掉后缀后是否只剩下2个字，如果是且原后缀是县、市、区，则保留原名称
        if (withoutSuffix.length == 2 &&
            (suffix == '县' || suffix == '市' || suffix == '区')) {
          return normalized; // 保留原名称
        }

        normalized = withoutSuffix;
        break; // 找到一个匹配的后缀就停止
      }
    }

    return normalized;
  }

  /// 判断是否是当前定位城市
  /// 支持多种匹配方式：
  /// 1. 完全匹配
  /// 2. 行政区划名称匹配（去除省、市、自治区、区、县等后缀）
  /// 3. 虚拟当前定位城市
  static bool isCurrentLocationCity(
    String cityName,
    String? currentLocationName,
    String cityId,
  ) {
    // 虚拟当前定位城市
    if (cityId == 'virtual_current_location') {
      return true;
    }

    // 如果当前定位名称为空，返回false
    if (currentLocationName == null || currentLocationName.isEmpty) {
      return false;
    }

    // 使用城市名称匹配逻辑
    return isCityNameMatch(cityName, currentLocationName);
  }
}
