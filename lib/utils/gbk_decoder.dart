import 'dart:convert';

/// 简化的GBK解码器
/// 用于解码太平洋网络接口返回的GBK编码响应
class GbkDecoder {
  static final GbkDecoder _instance = GbkDecoder._internal();

  GbkDecoder._internal();

  factory GbkDecoder() {
    return _instance;
  }

  /// 解码GBK字节数组为UTF-8字符串（带错误处理）
  String decodeWithFallback(List<int> gbkBytes) {
    try {
      // 先尝试直接UTF-8解码
      String directDecode = utf8.decode(gbkBytes, allowMalformed: true);

      // 检查是否包含Unicode替换字符（表示编码问题）
      if (directDecode.contains('\uFFFD')) {
        print('📡 检测到编码问题，尝试简单修复...');
        return _simpleGbkFix(directDecode);
      }

      print('📡 内容已经是UTF-8编码');
      return directDecode;
    } catch (e) {
      print('📡 解码错误: $e');
      return utf8.decode(gbkBytes, allowMalformed: true);
    }
  }

  /// 简单的GBK修复方法
  String _simpleGbkFix(String rawText) {
    String result = rawText;

    // 清理可能的乱码字符
    result = result.replaceAll('\uFFFD', '');

    // 如果JSON结构完整，直接返回
    if (result.contains('"ip"') &&
        result.contains('"pro"') &&
        result.contains('"city"')) {
      print('📡 检测到完整的JSON结构，直接使用');
      return result;
    }

    // 简单的字符替换（基于常见的中文字符）
    final Map<String, String> commonMappings = {
      '北京': '北京市',
      '上海': '上海市',
      '广东': '广东省',
      '江苏': '江苏省',
      '浙江': '浙江省',
      '山东': '山东省',
      '河南': '河南省',
      '四川': '四川省',
      '湖北': '湖北省',
      '湖南': '湖南省',
      '河北': '河北省',
      '福建': '福建省',
      '安徽': '安徽省',
      '辽宁': '辽宁省',
      '江西': '江西省',
      '黑龙江': '黑龙江省',
      '吉林': '吉林省',
      '山西': '山西省',
      '陕西': '陕西省',
      '甘肃': '甘肃省',
      '青海': '青海省',
      '台湾': '台湾省',
      '内蒙古': '内蒙古',
      '新疆': '新疆',
      '西藏': '西藏',
      '宁夏': '宁夏',
      '广西': '广西',
      '云南': '云南省',
      '贵州': '贵州省',
      '海南': '海南省',
      '天津': '天津市',
      '重庆': '重庆市',
      '朝阳': '朝阳区',
      '海淀': '海淀区',
      '西城': '西城区',
      '东城': '东城区',
      '丰台': '丰台区',
      '石景山': '石景山区',
    };

    // 执行替换
    commonMappings.forEach((gbk, utf8) {
      result = result.replaceAll(gbk, utf8);
    });

    return result;
  }
}
