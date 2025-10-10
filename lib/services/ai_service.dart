import 'dart:convert';
import 'package:http/http.dart' as http;

/// 智谱AI服务 - 用于智能通勤建议生成
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _apiKey =
      '22af66926af540978a59d67bf6806fe0.vyrFy5UXn9meHyND';
  static const String _apiUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String _model = 'glm-4-flash';

  /// 调用智谱AI生成智能建议
  Future<String?> generateSmartAdvice(String prompt) async {
    print('\n========================================');
    print('🤖 AI服务：开始调用智谱AI');
    print('========================================');
    print('📡 API地址: $_apiUrl');
    print('🔑 API密钥: ${_apiKey.substring(0, 10)}...');
    print('🤖 使用模型: $_model');
    print('----------------------------------------');
    print('📝 Prompt内容:');
    print(prompt);
    print('----------------------------------------\n');

    try {
      final requestBody = {
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      };

      print('📤 发送请求...');
      print('请求体: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': _apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ AI请求超时（15秒）');
              throw Exception('AI请求超时');
            },
          );

      print('📥 收到响应');
      print('状态码: ${response.statusCode}');
      print('响应体长度: ${response.body.length} 字节');

      if (response.statusCode == 200) {
        print('✅ HTTP请求成功');

        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        print('📊 解析JSON成功');
        print('完整响应: ${jsonEncode(jsonData)}');

        final choices = jsonData['choices'] as List?;
        print('Choices数量: ${choices?.length ?? 0}');

        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;

          if (content != null && content.isNotEmpty) {
            print('\n========================================');
            print('✅ AI响应成功');
            print('========================================');
            print('💬 完整内容:');
            print(content);
            print('========================================\n');
            return content;
          } else {
            print('⚠️ content为空');
          }
        } else {
          print('⚠️ choices为空或不存在');
        }

        print('⚠️ AI响应格式异常');
        return null;
      } else {
        print('\n========================================');
        print('❌ AI请求失败');
        print('========================================');
        print('状态码: ${response.statusCode}');
        print('响应头: ${response.headers}');
        print('响应体: ${response.body}');
        print('========================================\n');
        return null;
      }
    } catch (e, stackTrace) {
      print('\n========================================');
      print('❌ AI服务异常');
      print('========================================');
      print('错误类型: ${e.runtimeType}');
      print('错误信息: $e');
      print('堆栈跟踪:');
      print(stackTrace);
      print('========================================\n');
      return null;
    }
  }

  /// 构建通勤建议的Prompt
  String buildCommutePrompt({
    required String weatherType,
    required String temperature,
    required String windPower,
    required String airQuality,
    required String timeSlot,
    required List<String> futureWeather,
  }) {
    final futureWeatherStr = futureWeather.isEmpty
        ? '无预报数据'
        : futureWeather.join('、');

    final greeting = timeSlot == 'morning' ? '早安' : '晚安';
    final timeLabel = timeSlot == 'morning' ? '早高峰' : '晚高峰';

    return '''【角色】
你是「通勤天气管家」——一位专注于用天气数据守护上下班安全、舒适、效率的私人助理。

【当前时段】$timeLabel 通勤

【天气数据】
- 天气现象：$weatherType
- 气温：$temperature℃
- 风力：$windPower
- 空气质量：$airQuality
- 未来趋势：$futureWeatherStr

【输出格式】
一句话${greeting}问候 + 分段清单（使用 Emoji） + 交通工具推荐指数 + 暖心彩蛋

【分段清单要点】（根据天气情况选择2-4个最重要的）
🌂 防雨建议：⚠️只有下雨（小雨/中雨/大雨/暴雨）时才建议带伞，雾/霾/阴天不需要
👟 鞋履&防滑：根据路面状况建议
☀️ 防晒/防寒：根据温度和天气
🫧 空气/呼吸：根据空气质量
🚦 交通安全：根据天气和风力

🚇 交通指数（用星级表示，最多5星）：
地铁 ⭐ 公交 ⭐ 骑行 ⭐ 自驾 ⭐

💡 彩蛋：一句暖心提示或天气趣闻

【语言风格】
- 亲切、口语化、Emoji 点缀
- 每条建议≤20 字
- 先给结论再给理由
- 拒绝冗余和官方用语

【示例参考】
🌞 早安！今天$timeLabel 通勤如下——

🌂 防雨：降水概率低，放心省伞。
👟 鞋履：路面干燥，常规鞋即可。
☀️ 防晒：紫外线强，露肤请涂防晒。
🫧 空气：AQI优，畅快呼吸。

🚇 交通指数：地铁⭐⭐⭐⭐⭐ 骑行⭐⭐⭐⭐

💡 今天是个好天气，保持好心情！

请直接输出完整的通勤建议，不要额外说明。''';
  }

  /// 解析AI返回的建议文本
  List<String> parseAdviceText(String text) {
    // 去掉多余的连续空行，保留有意义的换行
    final cleanedText = _removeExtraEmptyLines(text);

    // 对于新版通勤提醒（包含问候、清单、推荐、彩蛋），作为一个整体返回
    if (cleanedText.contains('🌞') ||
        cleanedText.contains('🌙') ||
        cleanedText.contains('早安') ||
        cleanedText.contains('晚安') ||
        cleanedText.contains('🚇') ||
        cleanedText.contains('💡')) {
      return [cleanedText];
    }

    // 兼容旧版格式：按行拆分
    final lines = cleanedText.split('\n');
    final advices = <String>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 移除"建议1："、"建议2："等前缀
      final cleanedLine = trimmed
          .replaceFirst(RegExp(r'^建议\d+[：:]\s*'), '')
          .replaceFirst(RegExp(r'^[\d+\.\-\*]\s*'), '');

      if (cleanedLine.isNotEmpty) {
        advices.add(cleanedLine);
      }
    }

    return advices;
  }

  /// 去掉多余的连续空行（保留单个换行）
  String _removeExtraEmptyLines(String text) {
    // 1. 去掉首尾空白
    final trimmed = text.trim();

    // 2. 将连续的多个空行替换为单个换行
    final cleaned = trimmed.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 3. 去掉每行末尾的空白字符
    final lines = cleaned.split('\n');
    final processedLines = lines.map((line) => line.trimRight()).toList();

    return processedLines.join('\n');
  }

  /// 构建天气预警的Prompt（用于增强提醒内容）
  String buildWeatherAlertPrompt({
    required String weatherTerm,
    required String cityName,
    required String timeInfo,
    required String alertLevel,
    required bool isRequired,
  }) {
    final urgencyText = isRequired ? '这是必须提醒的危险天气' : '这需要提醒用户注意';

    return '''你是一个专业的气象预警助手，请为以下天气情况生成简洁实用的提醒内容。

【城市】$cityName
【天气】$weatherTerm
【时间】$timeInfo
【级别】$alertLevel
【重要性】$urgencyText

【要求】
1. 生成一条50字以内的提醒内容
2. 重点说明：天气影响、注意事项、实用建议
3. 语气根据级别调整（严重天气用紧急语气，一般天气用温和提醒）
4. 不要使用"您好"等寒暄语
5. 直接输出提醒内容，不要标题和额外说明

请直接输出提醒内容：''';
  }

  /// 构建天气总结的Prompt（用于生成智能天气摘要）
  String buildWeatherSummaryPrompt({
    required String currentWeather,
    required String temperature,
    required String airQuality,
    required List<String> upcomingWeather,
    String? humidity,
    String? windPower,
  }) {
    final upcomingText = upcomingWeather.isEmpty
        ? '暂无'
        : upcomingWeather.take(3).join('→');

    return '''请根据天气情况生成一段智能天气建议。

【当前天气】
- 天气状况：$currentWeather
- 温度：$temperature℃
- 空气质量：$airQuality
${humidity != null ? '- 湿度：$humidity%' : ''}
${windPower != null ? '- 风力：$windPower' : ''}

【未来趋势】接下来几小时：$upcomingText

【要求】
1. 70-90字之间
2. 必须包含以下实用建议：
   - 是否需要带伞（根据天气和未来趋势判断）
   - 穿衣建议（根据温度和天气）
   - 其他重要提醒（如空气质量、防晒等）
3. 语气自然友好，像朋友的关心
4. 建议要具体实用，不要空洞
5. 直接输出内容，不要标题

输出：''';
  }

  /// 构建15日天气总结的Prompt
  String buildForecast15dSummaryPrompt({
    required List<Map<String, dynamic>> dailyForecasts,
    required String cityName,
  }) {
    // 提取关键天气信息
    final weatherTypes = <String>{};
    final tempRanges = <String>[];

    for (var i = 0; i < dailyForecasts.length && i < 15; i++) {
      final day = dailyForecasts[i];
      weatherTypes.add(day['weather'] ?? '');
      if (day['tempMax'] != null && day['tempMin'] != null) {
        tempRanges.add('${day['tempMax']}~${day['tempMin']}℃');
      }
    }

    return '''你是一个专业的气象分析师，请用一段话总结未来15天的天气趋势和建议。

【城市】$cityName
【天气类型】${weatherTypes.join('、')}
【温度范围】${tempRanges.take(5).join('、')}等

【要求】
1. 80-120字之间
2. 重点说明：主要天气特征、温度变化趋势、需要注意的天气
3. 提供1-2条实用的生活建议（如穿衣、出行、活动安排等）
4. 语气专业友好，像天气预报员在解说
5. 直接输出内容，不要标题

请直接输出总结内容：''';
  }

  /// 解析天气提醒文本
  String? parseAlertText(String text) {
    // 去掉多余的连续空行
    final cleaned = _removeExtraEmptyLines(text);
    if (cleaned.isEmpty) return null;

    // 移除可能的标点符号
    return cleaned.replaceFirst(RegExp(r'^[：:]\s*'), '');
  }
}
