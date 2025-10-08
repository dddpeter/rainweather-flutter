import 'package:lunar/lunar.dart';
import '../models/lunar_model.dart';

/// 农历服务类
/// 封装 lunar-flutter 库的功能，提供24节气、传统节日等信息
class LunarService {
  static final LunarService _instance = LunarService._internal();

  factory LunarService.getInstance() {
    return _instance;
  }

  LunarService._internal();

  /// 获取指定日期的农历信息
  LunarInfo getLunarInfo(DateTime date) {
    // 先创建Solar对象，再转换为Lunar
    final solar = Solar.fromDate(date);
    final lunar = solar.getLunar();

    // 获取节气（当天是否有节气）
    final solarTerm = lunar.getJieQi();
    final nextSolarTerm = _getNextSolarTerm(date);

    // 获取传统节日
    final festivals = _getFestivals(lunar, solar);

    // 获取宜忌
    final goodThings = _getGoodThings(lunar);
    final badThings = _getBadThings(lunar);

    // 获取星宿信息
    final xiu = lunar.getXiu();
    final xiuLuck = lunar.getXiuLuck();

    // 获取吉神方位
    final xiShen = lunar.getDayPositionXi();
    final fuShen = lunar.getDayPositionFu();
    final caiShen = lunar.getDayPositionCai();

    // 获取冲煞
    final chong = lunar.getDayChongDesc();
    final sha = lunar.getDaySha();

    // 获取建除十二值星
    final zhiXing = lunar.getZhiXing();

    // 判断是否黄道吉日
    final isHuangDao = _isHuangDaoDay(lunar);

    return LunarInfo(
      lunarDate: lunar.toString(),
      lunarYear: '${lunar.getYearInGanZhi()}年',
      lunarMonth: lunar.getMonthInChinese(),
      lunarDay: lunar.getDayInChinese(),
      yearAnimal: lunar.getYearShengXiao(),
      solarTerm: solarTerm.isEmpty ? null : solarTerm,
      nextSolarTerm: nextSolarTerm?.name,
      daysToNextSolarTerm: nextSolarTerm?.daysFromNow(),
      festivals: festivals,
      goodThings: goodThings,
      badThings: badThings,
      yearGanZhi: lunar.getYearInGanZhi(),
      monthGanZhi: lunar.getMonthInGanZhi(),
      dayGanZhi: lunar.getDayInGanZhi(),
      constellation: solar.getXingZuo(),
      starName: xiu,
      starLuck: xiuLuck,
      pengZuBaiji: '${lunar.getPengZuGan()} ${lunar.getPengZuZhi()}',
      xiShenDirection: xiShen,
      fuShenDirection: fuShen,
      caiShenDirection: caiShen,
      chongSha: '$chong $sha',
      jianChu: zhiXing,
      isHuangDaoDay: isHuangDao,
    );
  }

  /// 获取下一个节气信息
  SolarTermInfo? _getNextSolarTerm(DateTime date) {
    try {
      final solar = Solar.fromDate(date);
      final lunar = solar.getLunar();
      final nextJieQi = lunar.getNextJie(false);

      final jieQiName = nextJieQi.getName();
      final jieQiSolar = nextJieQi.getSolar();
      final jieQiDate = DateTime(
        jieQiSolar.getYear(),
        jieQiSolar.getMonth(),
        jieQiSolar.getDay(),
      );

      return SolarTermInfo(
        name: jieQiName,
        date: jieQiDate,
        description: getSolarTermDescription(jieQiName),
        emoji: getSolarTermEmoji(jieQiName),
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取传统节日
  List<String> _getFestivals(Lunar lunar, Solar solar) {
    final festivals = <String>[];

    // 农历节日
    final lunarFestivals = lunar.getFestivals();
    festivals.addAll(lunarFestivals);

    // 公历节日
    final solarFestivals = solar.getFestivals();
    festivals.addAll(solarFestivals);

    // 其他节日（如母亲节、父亲节等）
    final otherFestivals = lunar.getOtherFestivals();
    festivals.addAll(otherFestivals);

    return festivals;
  }

  /// 获取宜做的事
  List<String> _getGoodThings(Lunar lunar) {
    try {
      final yiList = lunar.getDayYi();
      return yiList;
    } catch (e) {
      return [];
    }
  }

  /// 获取忌做的事
  List<String> _getBadThings(Lunar lunar) {
    try {
      final jiList = lunar.getDayJi();
      return jiList;
    } catch (e) {
      return [];
    }
  }

  /// 判断是否黄道吉日
  bool _isHuangDaoDay(Lunar lunar) {
    try {
      // 根据十二建星判断
      final zhiXing = lunar.getZhiXing();
      // 建、满、平、定、成、开为黄道吉日
      const huangDaoStars = ['建', '满', '平', '定', '成', '开'];
      return huangDaoStars.contains(zhiXing);
    } catch (e) {
      return false;
    }
  }

  /// 获取一年的所有节气
  List<SolarTermInfo> getYearSolarTerms(int year) {
    final solarTerms = <SolarTermInfo>[];

    // 遍历一年的每一天，找出所有节气
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        try {
          final date = DateTime(year, month, day);
          final solar = Solar.fromDate(date);
          final lunar = solar.getLunar();
          final jieQi = lunar.getJieQi();

          if (jieQi.isNotEmpty) {
            // 检查是否已经添加过这个节气
            final exists = solarTerms.any((st) => st.name == jieQi);
            if (!exists) {
              solarTerms.add(
                SolarTermInfo(
                  name: jieQi,
                  date: date,
                  description: getSolarTermDescription(jieQi),
                  emoji: getSolarTermEmoji(jieQi),
                ),
              );
            }
          }
        } catch (e) {
          // 忽略错误，继续下一天
        }
      }
    }

    // 按日期排序
    solarTerms.sort((a, b) => a.date.compareTo(b.date));
    return solarTerms;
  }

  /// 获取即将到来的节气（未来N天内）
  List<SolarTermInfo> getUpcomingSolarTerms({int days = 30}) {
    final now = DateTime.now();
    final upcomingTerms = <SolarTermInfo>[];

    for (int i = 0; i <= days; i++) {
      try {
        final date = now.add(Duration(days: i));
        final solar = Solar.fromDate(date);
        final lunar = solar.getLunar();
        final jieQi = lunar.getJieQi();

        if (jieQi.isNotEmpty) {
          // 检查是否已经添加过这个节气
          final exists = upcomingTerms.any((st) => st.name == jieQi);
          if (!exists) {
            upcomingTerms.add(
              SolarTermInfo(
                name: jieQi,
                date: date,
                description: getSolarTermDescription(jieQi),
                emoji: getSolarTermEmoji(jieQi),
              ),
            );
          }
        }
      } catch (e) {
        // 忽略错误
      }
    }

    return upcomingTerms;
  }

  /// 获取节气描述
  String getSolarTermDescription(String solarTerm) {
    const descriptions = {
      '立春': '春季开始，万物复苏。有迎春、咬春习俗',
      '雨水': '降雨增多，适宜耕作。雨水节气利于农事',
      '惊蛰': '春雷惊醒昆虫。有打小人、吃梨习俗',
      '春分': '昼夜等长，春意盎然。有立蛋游戏',
      '清明': '扫墓祭祖，踏青插柳。缅怀先人',
      '谷雨': '雨生百谷，播种时节。有走谷雨、品谷雨茶习俗',
      '立夏': '夏季开始，万物繁茂。预示夏天来临',
      '小满': '作物籽粒饱满。有祭车神、抢水习俗',
      '芒种': '麦收稻种。有送花神、煮梅习俗',
      '夏至': '白昼最长，暑热将至。有祭神、吃面习俗',
      '小暑': '初热时期。有食新米、吃饺子习俗',
      '大暑': '最热时期。有饮伏茶、晒伏姜习俗',
      '立秋': '秋季开始，暑去凉来。有贴秋膘、啃秋习俗',
      '处暑': '暑气至此而止。有庆赞中元活动',
      '白露': '露水凝结，天气转凉。有祭禹王、吃龙眼习俗',
      '秋分': '昼夜等长，秋高气爽。有赏月、吃月饼习俗',
      '寒露': '露水寒冷，深秋时节。有赏红叶、吃芝麻习俗',
      '霜降': '初霜出现，天气渐冷。有赏菊、吃柿子习俗',
      '立冬': '冬季开始，收藏万物。有补冬、吃饺子习俗',
      '小雪': '开始降雪。有腌菜、吃糍粑习俗',
      '大雪': '降雪增多，天寒地冻。有观赏封河、吃红枣糕习俗',
      '冬至': '白昼最短，数九寒天。有吃饺子、汤圆习俗',
      '小寒': '天气严寒，尚未大冷。有食补、锻炼习俗',
      '大寒': '最冷时期。有除旧布新、腌制年肴习俗',
    };
    return descriptions[solarTerm] ?? '';
  }

  /// 获取节气表情符号
  String getSolarTermEmoji(String solarTerm) {
    const emojis = {
      '立春': '🌱',
      '雨水': '🌧️',
      '惊蛰': '⚡',
      '春分': '🌸',
      '清明': '🌿',
      '谷雨': '🌾',
      '立夏': '🌻',
      '小满': '🌾',
      '芒种': '🌾',
      '夏至': '☀️',
      '小暑': '🌡️',
      '大暑': '🔥',
      '立秋': '🍂',
      '处暑': '🍃',
      '白露': '💧',
      '秋分': '🍁',
      '寒露': '❄️',
      '霜降': '🌫️',
      '立冬': '🧊',
      '小雪': '🌨️',
      '大雪': '❄️',
      '冬至': '⛄',
      '小寒': '🥶',
      '大寒': '🧊',
    };
    return emojis[solarTerm] ?? '📅';
  }

  /// 获取传统节日表情符号
  String getFestivalEmoji(String festival) {
    const emojis = {
      '春节': '🧧',
      '元宵节': '🏮',
      '龙抬头': '🐉',
      '中和节': '🐉',
      '寒食节': '🔥',
      '清明节': '🌿',
      '上巳节': '🌸',
      '端午节': '🐉',
      '七夕节': '💑',
      '中元节': '🕯️',
      '中秋节': '🌕',
      '重阳节': '🏔️',
      '寒衣节': '👘',
      '下元节': '🕯️',
      '腊八节': '🥣',
      '灶王节': '🔥',
      '小年': '🎊',
      '除夕': '🎆',
      '元旦': '🎉',
      '情人节': '💝',
      '妇女节': '👩',
      '植树节': '🌳',
      '劳动节': '⚒️',
      '青年节': '🎓',
      '儿童节': '🎈',
      '建党节': '🎗️',
      '建军节': '🎖️',
      '教师节': '👨‍🏫',
      '国庆节': '🇨🇳',
      '圣诞节': '🎄',
    };
    return emojis[festival] ?? '🎊';
  }

  /// 将八卦方位转换为通俗方位
  String convertDirectionToCommon(String direction) {
    // 八卦方位对照表
    const directionMap = {
      '震': '正东',
      '巽': '东南',
      '离': '正南',
      '坤': '西南',
      '兑': '正西',
      '乾': '西北',
      '坎': '正北',
      '艮': '东北',
    };

    // 替换所有八卦名称为通俗方位
    String result = direction;
    directionMap.forEach((bagua, common) {
      // 匹配 "震(正东)" 或 "震" 格式
      result = result.replaceAll('$bagua(正东)', common);
      result = result.replaceAll('$bagua(东南)', common);
      result = result.replaceAll('$bagua(正南)', common);
      result = result.replaceAll('$bagua(西南)', common);
      result = result.replaceAll('$bagua(正西)', common);
      result = result.replaceAll('$bagua(西北)', common);
      result = result.replaceAll('$bagua(正北)', common);
      result = result.replaceAll('$bagua(东北)', common);
      result = result.replaceAll(bagua, common);
    });

    return result;
  }

  /// 获取传统节日描述
  String getFestivalDescription(String festival) {
    const descriptions = {
      '春节': '农历新年，有贴春联、放鞭炮、吃年夜饭习俗',
      '元宵节': '正月十五，有赏花灯、吃汤圆、猜灯谜习俗',
      '龙抬头': '二月初二，有理发、祭龙、吃龙鳞饼习俗',
      '中和节': '二月初二，有熏虫、吃龙鳞饼习俗',
      '寒食节': '清明前一天，禁火吃冷食，缅怀介子推',
      '清明节': '扫墓踏青，祭祖插柳，缅怀先人',
      '上巳节': '三月初三，有踏青、临水祓禊习俗',
      '端午节': '五月初五，有赛龙舟、吃粽子、挂艾草习俗',
      '七夕节': '七月初七，有乞巧、穿针、许愿习俗',
      '中元节': '七月十五，有祭祀先祖、放河灯习俗',
      '中秋节': '八月十五，有赏月、吃月饼、团圆习俗',
      '重阳节': '九月初九，有登高、插茱萸、赏菊习俗',
      '寒衣节': '十月初一，有祭祖、焚纸衣习俗',
      '下元节': '十月十五，有修斋设醮、祈福习俗',
      '冬至节': '冬至日，有吃饺子、汤圆习俗',
      '腊八节': '腊月初八，有喝腊八粥、腌腊八蒜习俗',
      '灶王节': '腊月廿三或廿四，有祭灶神、吃灶糖习俗',
      '小年': '腊月廿三或廿四，有扫尘、祭灶习俗',
      '除夕': '腊月三十，有守岁、吃年夜饭、贴春联习俗',
      '元旦': '公历新年，辞旧迎新',
      '情人节': '2月14日，有送礼物、约会习俗',
      '妇女节': '3月8日，庆祝女性节日',
      '植树节': '3月12日，有植树造林活动',
      '劳动节': '5月1日，庆祝劳动者节日',
      '青年节': '5月4日，纪念五四运动',
      '儿童节': '6月1日，庆祝儿童节日',
      '建党节': '7月1日，纪念中国共产党成立',
      '建军节': '8月1日，纪念中国人民解放军建军',
      '教师节': '9月10日，感谢教师',
      '国庆节': '10月1日，庆祝中华人民共和国成立',
      '圣诞节': '12月25日，西方传统节日',
    };
    return descriptions[festival] ?? '';
  }
}
