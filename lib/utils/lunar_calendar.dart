/// 农历计算工具类
class LunarCalendar {
  // 农历数据：1900-2100年
  static const List<int> _lunarInfo = [
    0x04bd8,
    0x04ae0,
    0x0a570,
    0x054d5,
    0x0d260,
    0x0d950,
    0x16554,
    0x056a0,
    0x09ad0,
    0x055d2,
    0x04ae0,
    0x0a5b6,
    0x0a4d0,
    0x0d250,
    0x1d255,
    0x0b540,
    0x0d6a0,
    0x0ada2,
    0x095b0,
    0x14977,
    0x04970,
    0x0a4b0,
    0x0b4b5,
    0x06a50,
    0x06d40,
    0x1ab54,
    0x02b60,
    0x09570,
    0x052f2,
    0x04970,
    0x06566,
    0x0d4a0,
    0x0ea50,
    0x06e95,
    0x05ad0,
    0x02b60,
    0x186e3,
    0x092e0,
    0x1c8d7,
    0x0c950,
    0x0d4a0,
    0x1d8a6,
    0x0b550,
    0x056a0,
    0x1a5b4,
    0x025d0,
    0x092d0,
    0x0d2b2,
    0x0a950,
    0x0b557,
    0x06ca0,
    0x0b550,
    0x15355,
    0x04da0,
    0x0a5b0,
    0x14573,
    0x052b0,
    0x0a9a8,
    0x0e950,
    0x06aa0,
    0x0aea6,
    0x0ab50,
    0x04b60,
    0x0aae4,
    0x0a570,
    0x05260,
    0x0f263,
    0x0d950,
    0x05b57,
    0x056a0,
    0x096d0,
    0x04dd5,
    0x04ad0,
    0x0a4d0,
    0x0d4d4,
    0x0d250,
    0x0d558,
    0x0b540,
    0x0b6a0,
    0x195a6,
    0x095b0,
    0x049b0,
    0x0a974,
    0x0a4b0,
    0x0b27a,
    0x06a50,
    0x06d40,
    0x0af46,
    0x0ab60,
    0x09570,
    0x04af5,
    0x04970,
    0x064b0,
    0x074a3,
    0x0ea50,
    0x06b58,
    0x055c0,
    0x0ab60,
    0x096d5,
    0x092e0,
    0x0c960,
    0x0d954,
    0x0d4a0,
    0x0da50,
    0x07552,
    0x056a0,
    0x0abb7,
    0x025d0,
    0x092d0,
    0x0cab5,
    0x0a950,
    0x0b4a0,
    0x0baa4,
    0x0ad50,
    0x055d9,
    0x04ba0,
    0x0a5b0,
    0x15176,
    0x052b0,
    0x0a930,
    0x07954,
    0x06aa0,
    0x0ad50,
    0x05b52,
    0x04b60,
    0x0a6e6,
    0x0a4e0,
    0x0d260,
    0x0ea65,
    0x0d530,
    0x05aa0,
    0x076a3,
    0x096d0,
    0x04afb,
    0x04ad0,
    0x0a4d0,
    0x1d0b6,
    0x0d250,
    0x0d520,
    0x0dd45,
    0x0b5a0,
    0x056d0,
    0x055b2,
    0x049b0,
    0x0a577,
    0x0a4b0,
    0x0aa50,
    0x1b255,
    0x06d20,
    0x0ada0,
    0x14b63,
    0x09370,
    0x049f8,
    0x04970,
    0x064b0,
    0x168a6,
    0x0ea50,
    0x06b20,
    0x1a6c4,
    0x0aae0,
    0x0a2e0,
    0x0d2e3,
    0x0c960,
    0x0d557,
    0x0d4a0,
    0x0da50,
    0x05d55,
    0x056a0,
    0x0a6d0,
    0x055d4,
    0x052d0,
    0x0a9b8,
    0x0a950,
    0x0b4a0,
    0x0b6a6,
    0x0ad50,
    0x055a0,
    0x0aba4,
    0x0a5b0,
    0x052b0,
    0x0b273,
    0x06930,
    0x07337,
    0x06aa0,
    0x0ad50,
    0x14b55,
    0x04b60,
    0x0a570,
    0x054e4,
    0x0d160,
    0x0e968,
    0x0d520,
    0x0daa0,
    0x16aa6,
    0x056d0,
    0x04ae0,
    0x0a9d4,
    0x0a2d0,
    0x0d150,
    0x0f252,
  ];

  // 天干
  static const List<String> _gan = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
  ];

  // 地支
  static const List<String> _zhi = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  // 生肖
  static const List<String> _animals = [
    '鼠',
    '牛',
    '虎',
    '兔',
    '龙',
    '蛇',
    '马',
    '羊',
    '猴',
    '鸡',
    '狗',
    '猪',
  ];

  // 农历月份
  static const List<String> _lunarMonths = [
    '正月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '冬月',
    '腊月',
  ];

  // 农历日期
  static const List<String> _lunarDays = [
    '初一',
    '初二',
    '初三',
    '初四',
    '初五',
    '初六',
    '初七',
    '初八',
    '初九',
    '初十',
    '十一',
    '十二',
    '十三',
    '十四',
    '十五',
    '十六',
    '十七',
    '十八',
    '十九',
    '二十',
    '廿一',
    '廿二',
    '廿三',
    '廿四',
    '廿五',
    '廿六',
    '廿七',
    '廿八',
    '廿九',
    '三十',
  ];

  /// 获取农历年份的天数
  static int _lunarYearDays(int year) {
    int sum = 348;
    for (int i = 0x8000; i > 0x8; i >>= 1) {
      sum += (_lunarInfo[year - 1900] & i) != 0 ? 1 : 0;
    }
    return sum + _leapDays(year);
  }

  /// 获取农历年闰月的天数
  static int _leapDays(int year) {
    if (_leapMonth(year) != 0) {
      return (_lunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29;
    }
    return 0;
  }

  /// 获取农历年闰哪个月
  static int _leapMonth(int year) {
    return _lunarInfo[year - 1900] & 0xf;
  }

  /// 获取农历年月的天数
  static int _monthDays(int year, int month) {
    return (_lunarInfo[year - 1900] & (0x10000 >> month)) != 0 ? 30 : 29;
  }

  /// 将公历日期转换为农历
  static Map<String, dynamic> solarToLunar(DateTime date) {
    // int year = date.year;
    // int month = date.month;
    // int day = date.day;

    // 计算与1900年1月31日（农历1900年正月初一）的天数差
    int offset = 0;
    DateTime baseDate = DateTime(1900, 1, 31);
    offset = date.difference(baseDate).inDays;

    int lunarYear = 1900;
    int daysOfYear = 0;

    // 计算农历年份
    while (lunarYear < 2100 && offset > 0) {
      daysOfYear = _lunarYearDays(lunarYear);
      offset -= daysOfYear;
      lunarYear++;
    }

    if (offset < 0) {
      offset += daysOfYear;
      lunarYear--;
    }

    // 农历年份
    int leap = _leapMonth(lunarYear); // 闰哪个月
    bool isLeap = false;

    // 计算农历月份
    int lunarMonth = 1;
    for (lunarMonth = 1; lunarMonth < 13 && offset > 0; lunarMonth++) {
      // 闰月
      if (leap > 0 && lunarMonth == (leap + 1) && !isLeap) {
        --lunarMonth;
        isLeap = true;
        daysOfYear = _leapDays(lunarYear);
      } else {
        daysOfYear = _monthDays(lunarYear, lunarMonth);
      }

      // 解除闰月
      if (isLeap && lunarMonth == (leap + 1)) {
        isLeap = false;
      }

      offset -= daysOfYear;
    }

    if (offset == 0 && leap > 0 && lunarMonth == leap + 1) {
      if (isLeap) {
        isLeap = false;
      } else {
        isLeap = true;
        --lunarMonth;
      }
    }

    if (offset < 0) {
      offset += daysOfYear;
      --lunarMonth;
    }

    int lunarDay = offset + 1;

    return {
      'year': lunarYear,
      'month': lunarMonth,
      'day': lunarDay,
      'isLeap': isLeap,
      'yearGanZhi': _getYearGanZhi(lunarYear),
      'animal': _animals[(lunarYear - 1900) % 12],
      'monthStr': (isLeap ? '闰' : '') + _lunarMonths[lunarMonth - 1],
      'dayStr': _lunarDays[lunarDay - 1],
    };
  }

  /// 获取年份的干支
  static String _getYearGanZhi(int year) {
    int ganIndex = (year - 4) % 10;
    int zhiIndex = (year - 4) % 12;
    return _gan[ganIndex] + _zhi[zhiIndex];
  }

  /// 格式化农历日期
  static String format(DateTime date) {
    Map<String, dynamic> lunar = solarToLunar(date);
    return '${lunar['monthStr']}${lunar['dayStr']}';
  }

  /// 获取完整的农历信息字符串
  static String getFullInfo(DateTime date) {
    Map<String, dynamic> lunar = solarToLunar(date);
    return '${lunar['yearGanZhi']}年(${lunar['animal']}年) ${lunar['monthStr']}${lunar['dayStr']}';
  }
}
