import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import 'request_deduplicator.dart';
import 'request_cache_service.dart';
import 'network_config_service.dart';

/// 智谱AI服务 - 用于智能通勤建议生成
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final RequestDeduplicator _deduplicator = RequestDeduplicator();
  final RequestCacheService _cacheService = RequestCacheService();
  final NetworkConfigService _networkConfig = NetworkConfigService();

  static const String _apiKey =
      '22af66926af540978a59d67bf6806fe0.vyrFy5UXn9meHyND';
  static const String _apiUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String _model = 'glm-4-flash';

  /// 调用智谱AI生成智能建议（带去重和缓存）
  Future<String?> generateSmartAdvice(String prompt) async {
    final requestKey = RequestKeyGenerator.aiRequest(prompt);

    return await _deduplicator.execute<String?>(requestKey, () async {
      // 先尝试从缓存获取
      final cachedData = await _cacheService.get<String>(
        requestKey,
        (json) => json['content'] as String,
      );

      if (cachedData != null) {
        Logger.d('使用AI缓存数据', tag: 'AIService');
        return cachedData;
      }

      Logger.separator(title: 'AI服务：开始调用智谱AI');
      Logger.d('API地址: $_apiUrl', tag: 'AIService');
      Logger.d('API密钥: ${_apiKey.substring(0, 10)}...', tag: 'AIService');
      Logger.d('使用模型: $_model', tag: 'AIService');
      Logger.d('Prompt内容:', tag: 'AIService');
      Logger.d(prompt, tag: 'AIService');

      try {
        // 根据网络质量调整配置
        final networkQuality = await _networkConfig.getNetworkQuality();
        final baseConfig = _networkConfig.getConfig(RequestType.ai);
        final adjustedConfig = _networkConfig.adjustConfigForNetworkQuality(
          baseConfig,
          networkQuality,
        );

        Logger.d('网络质量: $networkQuality', tag: 'AIService');
        Logger.d('调整后配置: $adjustedConfig', tag: 'AIService');

        final requestBody = {
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        };

        Logger.d('发送请求...', tag: 'AIService');
        Logger.d('请求体: ${jsonEncode(requestBody)}', tag: 'AIService');

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
              adjustedConfig.receiveTimeout,
              onTimeout: () {
                Logger.w(
                  'AI请求超时（${adjustedConfig.receiveTimeout.inSeconds}秒）',
                  tag: 'AIService',
                );
                throw Exception('AI请求超时');
              },
            );

        Logger.d('收到响应', tag: 'AIService');
        Logger.d('状态码: ${response.statusCode}', tag: 'AIService');
        Logger.d('响应体长度: ${response.body.length} 字节', tag: 'AIService');

        if (response.statusCode == 200) {
          Logger.s('HTTP请求成功', tag: 'AIService');

          // 安全的 JSON 解析
          Map<String, dynamic>? jsonData;
          try {
            final decoded = utf8.decode(response.bodyBytes);
            jsonData = jsonDecode(decoded) as Map<String, dynamic>;
            Logger.d('解析JSON成功', tag: 'AIService');
            Logger.d('完整响应: ${jsonEncode(jsonData)}', tag: 'AIService');
          } on FormatException catch (e) {
            Logger.e('JSON格式错误: ${e.message}', tag: 'AIService');
            return null;
          } catch (e) {
            Logger.e('JSON解析失败', tag: 'AIService', error: e);
            return null;
          }

          final choices = jsonData['choices'] as List?;
          Logger.d('Choices数量: ${choices?.length ?? 0}', tag: 'AIService');

          if (choices != null && choices.isNotEmpty) {
            final message = choices[0]['message'] as Map<String, dynamic>?;
            final content = message?['content'] as String?;

            if (content != null && content.isNotEmpty) {
              Logger.separator(title: 'AI响应成功');
              Logger.d('完整内容:', tag: 'AIService');
              Logger.d(content, tag: 'AIService');
              Logger.separator();

              // 缓存AI响应
              await _cacheService.set(
                requestKey,
                content,
                CacheConfig.aiRequest,
                toJson: (data) => {'content': data},
              );

              Logger.d('AI响应已缓存', tag: 'AIService');
              return content;
            } else {
              Logger.w('content为空', tag: 'AIService');
            }
          } else {
            Logger.w('choices为空或不存在', tag: 'AIService');
          }

          Logger.w('AI响应格式异常', tag: 'AIService');
          return null;
        } else {
          Logger.separator(title: 'AI请求失败');
          Logger.e('状态码: ${response.statusCode}', tag: 'AIService');
          Logger.e('响应头: ${response.headers}', tag: 'AIService');
          Logger.e('响应体: ${response.body}', tag: 'AIService');
          Logger.separator();
          return null;
        }
      } catch (e, stackTrace) {
        Logger.e('AI服务异常', tag: 'AIService', error: e, stackTrace: stackTrace);
        ErrorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'AIService.GenerateSmartAdvice',
          type: AppErrorType.network,
        );
        return null;
      }
    });
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

    return '''【角色定义】
你是「通勤天气管家」——专注于为上下班通勤提供防雨和着装建议的私人助理。

【当前时段】$timeLabel 通勤

【天气数据】
- 天气现象：$weatherType
- 气温：$temperature℃
- 风力：$windPower
- 空气质量：$airQuality
- 未来趋势：$futureWeatherStr

【严格输出格式】
⚠️ 请严格按照以下格式输出，不要添加或减少任何空行：

第1行：${greeting == '早安' ? '🌞' : '🌙'} ${greeting}！今天$timeLabel 通勤建议——
第2行：🌂 防雨：[内容]（⚠️只有下雨/雨雪天气时才建议带伞，其他天气如晴天/阴天/雾霾不建议带伞）
第3行：👔 着装：[具体着装]（必须具体，如：长袖衬衫+薄外套、羽绒服+保暖内衣、短袖T恤）

【内容要求】
- 每条建议≤25字
- 亲切、口语化
- 先结论再理由
- 防雨建议：根据实际天气，下雨才说带伞，不下雨就说无需带伞
- 着装建议：根据温度给出具体衣物搭配
- 总字数60-80字

【严格格式示例】（请完全按照此格式，包括空行位置）
🌞 早安！今天早高峰通勤建议——
🌂 防雨：降水概率低，无需带伞。
👔 着装：薄长袖+防晒衫，舒适透气。

⚠️ 严格要求：
1. 只输出防雨和着装两条建议
2. 不要添加其他内容（如鞋履、防晒、空气、交通、彩蛋等）
3. 不要在开头或结尾添加额外空行

请严格按照上述格式输出，直接输出内容，不要其他说明。''';
  }

  /// 解析AI返回的建议文本
  List<String> parseAdviceText(String text) {
    // 保留AI返回的原始数据，只去掉首尾空白
    final cleanedText = text.trim();

    // 对于新版通勤提醒（包含问候、清单、推荐、彩蛋），作为整体返回
    if (cleanedText.contains('🌞') ||
        cleanedText.contains('🌙') ||
        cleanedText.contains('早安') ||
        cleanedText.contains('晚安') ||
        cleanedText.contains('🚇') ||
        cleanedText.contains('💡')) {
      // 直接返回原始文本，不做任何格式化
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
1. 生成一条40-60字的提醒内容
2. 重点说明：
   - 实际影响（如：道路积水、能见度低）
   - 具体建议（如：推迟出行、带伞）
   - 时效性（何时开始、何时结束）
3. 语气根据级别调整：
   - 红色/橙色：使用"立即"、"暂停"等紧急词语
   - 黄色/蓝色：使用"建议"、"注意"等温和提醒
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

【严格格式要求】
1. **字数限制：严格控制在90-120字之间**
2. **格式要求：一段连贯的文字，不分行，不加换行符**
3. 必须包含以下实用建议（按优先级）：
   - 伞具准备（根据当前天气和未来3小时趋势判断是否需要带伞）
   - 穿衣建议（具体到单品，如：薄外套+长袖T恤、羽绒服+毛衣）
   - 重点提醒（如：空气质量差时减少户外活动、大风天注意高空坠物、高温天注意防暑）
4. 语气自然友好，像好朋友在提醒
5. 建议要具体可操作，避免空洞词汇（不要用"适当"、"合理"等模糊词）
6. 直接输出内容，不要标题，不要换行

【优秀示例】
今天${currentWeather}，气温${temperature}℃，空气质量${airQuality}。未来3小时${upcomingWeather.isNotEmpty ? '将有${upcomingWeather[0]}，' : ''}建议携带雨伞以防突降小雨，穿着薄外套+长袖衬衫即可。空气质量优良，适合户外活动。风力较大，外出注意防风保暖。

⚠️ 注意：
- 输出必须是一段连贯的文字，不要分行、分段、换行
- 不要使用"建议您"、"提醒大家"等客套话
- 每句话都要有实际意义，不要废话

请严格按照要求输出：''';
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
1. **字数限制**：90-130字之间
2. **内容结构**（必须包含以下4个部分）：
   - 天气概况（整体趋势：以晴天/雨天/多云为主）
   - 温度趋势（温度上升/下降/稳定，高温XX℃，低温XX℃）
   - 重要天气（是否有降雨、降温、大风等重要天气过程）
   - 生活建议（1-2条具体建议，如：提前准备雨具、注意增减衣物、适合户外活动等）
3. **语气**：专业友好，像天气预报员在解说
4. **格式**：一段连贯的文字，不分段，不换行
5. **要求**：
   - 不要使用"总体来说"、"总的来说"等开头
   - 建议要具体可操作（如：本周多雨，外出记得带伞；周末降温，注意添衣）
   - 直接输出内容，不要标题

【优秀示例】
未来半个月${cityName}以多云天气为主，间有阵雨。温度呈上升趋势，下周初将迎来明显降温，最低气温降至10℃左右，随后逐步回升至25℃上下。15-17日有降水过程，雨量中等。建议：外出携带雨具，温度变化较大，注意及时增减衣物，避免感冒。

请直接输出总结内容：''';
  }

  /// 解析天气提醒文本
  String? parseAlertText(String text) {
    // 保留AI返回的原始数据，只去掉首尾空白
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;

    // 移除可能的标点符号
    return cleaned.replaceFirst(RegExp(r'^[：:]\s*'), '');
  }

  /// 构建智能穿搭顾问Prompt
  String buildOutfitAdvisorPrompt({
    required String currentWeather,
    required String temperature,
    required String feelsLike,
    required String windPower,
    required String humidity,
    List<String>? hourlyWeather,
    String? minTemp,
    String? maxTemp,
  }) {
    final hourlyInfo = hourlyWeather != null && hourlyWeather.isNotEmpty
        ? '未来几小时：${hourlyWeather.take(4).join('→')}'
        : '';

    return '''【穿搭建议】$currentWeather，${temperature}℃（体感${feelsLike}℃），湿度$humidity%，风力$windPower，温度${minTemp ?? '--'}~${maxTemp ?? '--'}℃
$hourlyInfo

【要求】100-130字，简洁实用：
1. 上装+下装（具体单品，如：薄外套+长裤）
2. 配饰（雨具/防晒/保暖等）
3. 特别注意（温差/风雨等）

直接输出内容，不分段：''';
  }

  /// 构建健康管家Prompt
  String buildHealthAdvisorPrompt({
    required String currentWeather,
    required String temperature,
    required String feelsLike,
    required String aqi,
    required String aqiLevel,
    required String humidity,
    required String windPower,
    String userGroup = 'general', // general, elderly, children, allergy
  }) {
    String userGroupDesc = '';
    switch (userGroup) {
      case 'elderly':
        userGroupDesc = '老年人';
        break;
      case 'children':
        userGroupDesc = '儿童';
        break;
      case 'allergy':
        userGroupDesc = '过敏人群';
        break;
      default:
        userGroupDesc = '一般人群';
    }

    return '''【健康建议】$currentWeather，${temperature}℃（体感${feelsLike}℃），AQI $aqi（$aqiLevel），湿度$humidity%
对象：$userGroupDesc

【要求】80-110字，简洁实用：
- 健康风险（1句话）
- 出行建议（1-2句话）
- 防护措施（口罩/防晒/保暖等）

直接输出内容，不分段：''';
  }

  /// 构建异常天气预警Prompt
  String buildExtremeWeatherAlertPrompt({
    required String currentWeather,
    required String temperature,
    required String windPower,
    required String visibility,
    String? alerts, // 官方气象预警
    List<String>? hourlyWeather,
  }) {
    final alertInfo = alerts != null && alerts.isNotEmpty
        ? '官方预警：$alerts'
        : '暂无官方预警';

    final hourlyInfo = hourlyWeather != null && hourlyWeather.isNotEmpty
        ? '未来几小时：${hourlyWeather.take(4).join('→')}'
        : '';

    return '''【天气预警】$currentWeather，${temperature}℃，风力$windPower，能见度${visibility}km
$alertInfo
$hourlyInfo

【要求】60-90字：
1. 风险等级：高危/中危/低危/正常
2. 主要风险（1句话）
3. 安全建议（1-2句话）

判断标准：暴雨暴雪雷暴→高危，大雨大雪7级风→中危
直接输出：''';
  }

  /// 清理AI请求缓存
  Future<void> clearAICache() async {
    await _cacheService.clearAll();
    Logger.d('AI请求缓存已清理', tag: 'AIService');
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  /// 取消所有正在进行的AI请求
  void cancelAllRequests() {
    _deduplicator.cancelAll();
    Logger.d('所有AI请求已取消', tag: 'AIService');
  }

  /// 获取正在进行的请求数量
  int get pendingRequestCount => _deduplicator.pendingRequestCount;
}
