import 'dart:convert';
import 'package:flutter/services.dart';
import 'city_name_matcher.dart';

/// 城市类型枚举
enum CityType {
  /// 国内城市
  domestic,
  
  /// 国外城市
  foreign,
  
  /// 未知类型
  unknown,
}

/// 城市类型检测器
/// 
/// 用于判断一个城市是国内城市还是国外城市
class CityTypeDetector {
  static CityTypeDetector? _instance;
  Set<String>? _domesticCities;

  CityTypeDetector._();

  static CityTypeDetector getInstance() {
    _instance ??= CityTypeDetector._();
    return _instance!;
  }

  /// 加载国内城市数据
  Future<void> loadDomesticCities() async {
    if (_domesticCities != null) return; // 已加载

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/city.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _domesticCities = jsonList
          .map((json) => json['name'] as String)
          .toSet();

      print('CityTypeDetector: 已加载 ${_domesticCities!.length} 个国内城市');
    } catch (e) {
      print('CityTypeDetector: 加载国内城市数据失败: $e');
      _domesticCities = <String>{};
    }
  }

  /// 判断城市类型
  /// 
  /// [cityName] 城市名称
  /// 
  /// 返回 CityType 枚举值
  Future<CityType> detectCityType(String cityName) async {
    // 确保城市数据已加载
    await loadDomesticCities();

    if (cityName.isEmpty) {
      return CityType.unknown;
    }

    // 标准化城市名称
    final normalizedName = CityNameMatcher.normalizeCityName(cityName.trim());

    // 检查是否为国内城市
    if (_isDomesticCity(normalizedName)) {
      return CityType.domestic;
    }

    // 检查是否为国外城市（通过英文名称判断）
    if (_isForeignCity(cityName)) {
      return CityType.foreign;
    }

    // 无法确定
    return CityType.unknown;
  }

  /// 判断是否为国内城市
  bool _isDomesticCity(String cityName) {
    if (_domesticCities == null || _domesticCities!.isEmpty) {
      return false;
    }

    // 精确匹配
    if (_domesticCities!.contains(cityName)) {
      return true;
    }

    // 模糊匹配
    for (final domesticCity in _domesticCities!) {
      final normalizedDomestic = CityNameMatcher.normalizeCityName(domesticCity);
      if (normalizedDomestic == cityName ||
          domesticCity.contains(cityName) ||
          cityName.contains(domesticCity)) {
        return true;
      }
    }

    return false;
  }

  /// 判断是否为国外城市
  bool _isForeignCity(String cityName) {
    // 简单判断：如果包含非中文字符，很可能是国外城市
    final hasNonChinese = cityName.contains(RegExp(r'[a-zA-Z]'));
    
    if (hasNonChinese) {
      return true;
    }

    // 已知国外城市列表（可以扩展）
    final knownForeignCities = {
      'Tokyo',
      'London',
      'New York',
      'Paris',
      'Berlin',
      'Sydney',
      'Toronto',
      'Dubai',
      'Singapore',
      'Seoul',
      'Bangkok',
      '曼谷',
      '东京',
      '伦敦',
      '纽约',
      '巴黎',
      '柏林',
      '悉尼',
      '多伦多',
      '迪拜',
      '新加坡',
      '首尔',
    };

    final normalized = cityName.toLowerCase();
    for (final foreignCity in knownForeignCities) {
      if (foreignCity.toLowerCase().contains(normalized) ||
          normalized.contains(foreignCity.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// 获取城市类型描述
  String getCityTypeDescription(CityType type) {
    switch (type) {
      case CityType.domestic:
        return '国内城市';
      case CityType.foreign:
        return '国外城市';
      case CityType.unknown:
        return '未知城市';
    }
  }

  /// 快速判断（不加载完整数据）
  /// 
  /// 基于简单的启发式规则快速判断
  CityType quickDetect(String cityName) {
    if (cityName.isEmpty) {
      return CityType.unknown;
    }

    // 如果包含英文字母，很可能是国外城市
    if (cityName.contains(RegExp(r'[a-zA-Z]'))) {
      return CityType.foreign;
    }

    // 如果纯中文，可能是国内城市
    if (cityName.contains(RegExp(r'^[\u4e00-\u9fa5]+$'))) {
      return CityType.domestic;
    }

    return CityType.unknown;
  }

  /// 清空缓存
  void clearCache() {
    _domesticCities = null;
  }
}
