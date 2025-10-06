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
  /// 参考Java代码逻辑，支持更多行政区划后缀
  static String normalizeCityName(String cityName) {
    String normalized = cityName;

    // 第一轮：去除省级和市级后缀
    normalized = normalized
        .replaceAll('省', '')
        .replaceAll('市', '')
        .replaceAll('自治区', '')
        .replaceAll('区', '');

    // 第二轮：去除县级后缀
    normalized = normalized
        .replaceAll('县', '')
        .replaceAll('自治县', '')
        .replaceAll('特区', '')
        .replaceAll('特别行政区', '');

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
