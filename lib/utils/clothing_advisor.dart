/// 穿衣建议工具类
/// 
/// 根据温度和天气情况提供穿衣建议
class ClothingAdvisor {
  /// 获取穿衣建议
  static String getSuggestion(String temperature, String? weather) {
    try {
      final temp = int.parse(temperature);
      final hasRain = weather?.contains('雨') ?? false;
      final hasSnow = weather?.contains('雪') ?? false;

      String suggestion = _getTemperatureSuggestion(temp);

      if (hasRain) {
        suggestion += '，记得带伞☂️';
      } else if (hasSnow) {
        suggestion += '，注意防滑保暖❄️';
      }

      return suggestion;
    } catch (e) {
      return '根据天气情况适当增减衣物';
    }
  }

  /// 根据温度获取基础建议
  static String _getTemperatureSuggestion(int temp) {
    if (temp >= 30) {
      return '天气炎热，建议穿短袖、短裤等清凉透气的衣服';
    } else if (temp >= 25) {
      return '天气温暖，适合穿短袖、薄长裤等夏季服装';
    } else if (temp >= 20) {
      return '天气舒适，建议穿长袖衬衫、薄外套等';
    } else if (temp >= 15) {
      return '天气微凉，建议穿夹克、薄毛衣等';
    } else if (temp >= 10) {
      return '天气较冷，建议穿厚外套、毛衣等保暖衣物';
    } else if (temp >= 0) {
      return '天气寒冷，建议穿棉衣、羽绒服等厚实保暖的衣服';
    } else {
      return '天气严寒，建议穿加厚羽绒服、保暖内衣等防寒衣物';
    }
  }

  /// 获取穿衣等级（1-8级）
  static int getClothingLevel(String temperature) {
    try {
      final temp = int.parse(temperature);
      
      if (temp >= 30) return 1;  // 极热
      if (temp >= 25) return 2;  // 热
      if (temp >= 20) return 3;  // 温暖
      if (temp >= 15) return 4;  // 舒适
      if (temp >= 10) return 5;  // 微凉
      if (temp >= 5) return 6;   // 冷
      if (temp >= 0) return 7;   // 寒冷
      return 8;                   // 严寒
    } catch (e) {
      return 4; // 默认舒适
    }
  }

  /// 获取穿衣图标
  static String getClothingIcon(int level) {
    const icons = [
      '👕', // 极热
      '👔', // 热
      '👕', // 温暖
      '🧥', // 舒适
      '🧥', // 微凉
      '🧣', // 冷
      '🧥', // 寒冷
      '🧥', // 严寒
    ];
    return icons[level - 1];
  }
}
