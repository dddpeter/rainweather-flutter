/// 农历信息模型
class LunarInfo {
  // 农历日期
  final String lunarDate; // 例如：正月初一
  final String lunarYear; // 例如：甲辰年
  final String lunarMonth; // 例如：正月
  final String lunarDay; // 例如：初一

  // 生肖
  final String yearAnimal; // 例如：龙

  // 24节气
  final String? solarTerm; // 例如：立春、春分等
  final String? nextSolarTerm; // 下一个节气
  final int? daysToNextSolarTerm; // 距离下一个节气的天数

  // 传统节日
  final List<String> festivals; // 传统节日列表

  // 宜忌
  final List<String> goodThings; // 宜
  final List<String> badThings; // 忌

  // 干支
  final String yearGanZhi; // 年柱
  final String monthGanZhi; // 月柱
  final String dayGanZhi; // 日柱

  // 星座
  final String constellation; // 星座

  // 星宿
  final String starName; // 星宿名称（如：斗木獬）
  final String starLuck; // 星宿吉凶

  // 彭祖百忌
  final String pengZuBaiji;

  // 吉神方位
  final String xiShenDirection; // 喜神方位
  final String fuShenDirection; // 福神方位
  final String caiShenDirection; // 财神方位

  // 冲煞
  final String chongSha; // 冲煞

  // 建除十二值星
  final String jianChu; // 建、除、满、平、定、执、破、危、成、收、开、闭

  // 黄道吉日
  final bool isHuangDaoDay; // 是否黄道吉日

  LunarInfo({
    required this.lunarDate,
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.yearAnimal,
    this.solarTerm,
    this.nextSolarTerm,
    this.daysToNextSolarTerm,
    required this.festivals,
    required this.goodThings,
    required this.badThings,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.constellation,
    required this.starName,
    required this.starLuck,
    required this.pengZuBaiji,
    required this.xiShenDirection,
    required this.fuShenDirection,
    required this.caiShenDirection,
    required this.chongSha,
    required this.jianChu,
    required this.isHuangDaoDay,
  });

  /// 获取农历日期完整显示
  String getFullLunarDate() {
    return '$lunarYear($yearAnimal年) ${lunarMonth}月$lunarDay';
  }

  /// 获取节气节日显示文本
  String? getFestivalText() {
    if (solarTerm != null) {
      return solarTerm;
    }
    if (festivals.isNotEmpty) {
      return festivals.first;
    }
    return null;
  }

  /// 是否有特殊日子（节气或节日）
  bool hasSpecialDay() {
    return solarTerm != null || festivals.isNotEmpty;
  }

  /// 获取宜忌简要信息（前3个）
  String getGoodThingsBrief() {
    if (goodThings.isEmpty) return '无';
    return goodThings.take(3).join(' ');
  }

  String getBadThingsBrief() {
    if (badThings.isEmpty) return '无';
    return badThings.take(3).join(' ');
  }
}

/// 24节气信息
class SolarTermInfo {
  final String name; // 节气名称
  final DateTime date; // 节气日期
  final String description; // 节气描述
  final String emoji; // 节气表情符号

  SolarTermInfo({
    required this.name,
    required this.date,
    required this.description,
    required this.emoji,
  });

  /// 距离现在还有多少天
  int daysFromNow() {
    final now = DateTime.now();
    return date.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// 是否是今天
  bool isToday() {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// 传统节日信息
class FestivalInfo {
  final String name; // 节日名称
  final DateTime date; // 节日日期
  final String description; // 节日描述
  final String emoji; // 节日表情符号
  final bool isLunarFestival; // 是否农历节日

  FestivalInfo({
    required this.name,
    required this.date,
    required this.description,
    required this.emoji,
    this.isLunarFestival = false,
  });

  /// 距离现在还有多少天
  int daysFromNow() {
    final now = DateTime.now();
    return date.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// 是否是今天
  bool isToday() {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
