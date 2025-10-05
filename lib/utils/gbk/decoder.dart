import 'dart:convert';
import 'convert.dart';

/// GBK解码工具类
/// 用于解码太平洋网络接口返回的GBK编码响应
class GbkDecoder {
  static final GbkDecoder _instance = GbkDecoder._internal();

  GbkDecoder._internal();

  factory GbkDecoder() {
    return _instance;
  }

  /// 解码GBK字节数组为UTF-8字符串
  String decode(List<int> gbkBytes) {
    try {
      // 使用gbk解码器
      return gbk.decode(gbkBytes);
    } catch (e) {
      print('GBK解码错误: $e');
      // 如果GBK解码失败，尝试UTF-8解码
      return utf8.decode(gbkBytes, allowMalformed: true);
    }
  }

  /// 解码GBK字节数组为UTF-8字符串（带错误处理）
  String decodeWithFallback(List<int> gbkBytes) {
    try {
      // 先尝试GBK解码
      String gbkResult = gbk.decode(gbkBytes);

      // 检查是否包含乱码字符
      if (gbkResult.contains('\uFFFD')) {
        print('GBK解码包含乱码，尝试UTF-8解码');
        return utf8.decode(gbkBytes, allowMalformed: true);
      }

      return gbkResult;
    } catch (e) {
      print('GBK解码失败，使用UTF-8解码: $e');
      return utf8.decode(gbkBytes, allowMalformed: true);
    }
  }
}
