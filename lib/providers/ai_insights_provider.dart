import 'package:flutter/foundation.dart';
import '../models/commute_advice_model.dart';
import '../models/weather_model.dart';
import '../models/sun_moon_index_model.dart';
import '../services/ai_service.dart';
import '../utils/logger.dart';

/// AIInsightsProvider - AI 智能摘要 Provider
///
/// 职责：
/// - 管理 AI 生成的每日天气摘要
/// - 管理 AI 生成的15天天气趋势摘要
/// - 管理通勤建议
/// - AI 生成状态管理
class AIInsightsProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

  // ===== AI 摘要数据 =====
  String? _dailySummary;
  String? _forecast15dSummary;

  // ===== 通勤建议 =====
  List<CommuteAdviceModel> _commuteAdvices = [];
  bool _hasShownCommuteAdviceToday = false;

  // ===== 生成状态标志 =====
  bool _isGeneratingSummary = false;
  bool _isGenerating15dSummary = false;
  bool _isGeneratingCommuteAdvice = false;

  // ===== Getters =====
  String? get dailySummary => _dailySummary;
  String? get forecast15dSummary => _forecast15dSummary;
  List<CommuteAdviceModel> get commuteAdvices => List.unmodifiable(_commuteAdvices);
  bool get hasUnreadCommuteAdvices => _commuteAdvices.any((a) => !a.isRead);
  bool get hasShownCommuteAdviceToday => _hasShownCommuteAdviceToday;

  bool get isGeneratingSummary => _isGeneratingSummary;
  bool get isGenerating15dSummary => _isGenerating15dSummary;
  bool get isGeneratingCommuteAdvice => _isGeneratingCommuteAdvice;

  /// 生成每日天气摘要
  ///
  /// 总是返回非空字符串。AI 生成失败时返回默认摘要。
  Future<String> generateDailySummary(WeatherModel? weatherData) async {
    if (weatherData == null || _isGeneratingSummary) {
      return _dailySummary ?? _getDefaultDailySummary(weatherData);
    }

    _isGeneratingSummary = true;
    notifyListeners();

    try {
      Logger.d('开始生成每日天气摘要', tag: 'AIInsightsProvider');

      final current = weatherData.current?.current;
      final air = weatherData.current?.air ?? weatherData.air;

      if (current == null) {
        return _getDefaultDailySummary(weatherData);
      }

      // 构建未来天气趋势列表
      final upcomingWeather = weatherData.forecast24h
          ?.take(5)
          .map((h) => h.weather ?? '')
          .where((w) => w.isNotEmpty)
          .toList() ?? [];

      // 使用优化的prompt方法
      final prompt = _aiService.buildWeatherSummaryPrompt(
        currentWeather: current.weather ?? '未知',
        temperature: current.temperature ?? '--',
        airQuality: air?.levelIndex ?? '未知',
        upcomingWeather: upcomingWeather,
        humidity: current.humidity,
        windPower: current.windpower,
      );

      final summary = await _aiService.generateSmartAdvice(prompt);

      if (summary != null && summary.isNotEmpty) {
        _dailySummary = summary;
        Logger.d('每日摘要生成成功', tag: 'AIInsightsProvider');
        notifyListeners();
        return summary;
      }

      // AI 生成失败，返回默认摘要
      final defaultSummary = _getDefaultDailySummary(weatherData);
      _dailySummary = defaultSummary;
      return defaultSummary;
    } catch (e) {
      Logger.e('生成每日摘要失败', tag: 'AIInsightsProvider', error: e);
      // 返回默认摘要
      final defaultSummary = _getDefaultDailySummary(weatherData);
      _dailySummary = defaultSummary;
      return defaultSummary;
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  /// 生成15天天气趋势摘要
  ///
  /// 总是返回非空字符串。AI 生成失败时返回默认摘要。
  Future<String> generate15dSummary(List<DailyWeather>? forecast15d) async {
    if (forecast15d == null || forecast15d.isEmpty || _isGenerating15dSummary) {
      return _forecast15dSummary ?? '未来15天天气预报数据加载中...';
    }

    _isGenerating15dSummary = true;
    notifyListeners();

    try {
      Logger.d('开始生成15天天气趋势摘要', tag: 'AIInsightsProvider');

      // 构建每日预报数据
      final dailyForecasts = forecast15d.take(15).map((day) {
        return {
          'weather': day.weather_am ?? day.weather_pm ?? '未知',
          'tempMax': day.temperature_am,
          'tempMin': day.temperature_pm,
        };
      }).toList();

      // 使用优化的prompt方法
      final prompt = _aiService.buildForecast15dSummaryPrompt(
        dailyForecasts: dailyForecasts,
        cityName: '当前位置',
      );

      final summary = await _aiService.generateSmartAdvice(prompt);

      if (summary != null && summary.isNotEmpty) {
        _forecast15dSummary = summary;
        Logger.d('15天摘要生成成功', tag: 'AIInsightsProvider');
        notifyListeners();
        return summary;
      }

      // AI 生成失败，返回默认摘要
      final defaultSummary = _getDefault15dSummary(forecast15d);
      _forecast15dSummary = defaultSummary;
      return defaultSummary;
    } catch (e) {
      Logger.e('生成15天摘要失败', tag: 'AIInsightsProvider', error: e);
      // 返回默认摘要
      final defaultSummary = _getDefault15dSummary(forecast15d);
      _forecast15dSummary = defaultSummary;
      return defaultSummary;
    } finally {
      _isGenerating15dSummary = false;
      notifyListeners();
    }
  }

  /// 生成默认每日摘要
  String _getDefaultDailySummary(WeatherModel? weatherData) {
    if (weatherData == null) {
      return '天气数据加载中，请稍候...';
    }

    final current = weatherData.current?.current;
    if (current == null) {
      return '天气数据加载中，请稍候...';
    }

    final weather = current.weather ?? '晴';
    final temp = current.temperature ?? '--';
    final summary = '$weather，温度$temp℃';

    // 简单建议
    if (weather.contains('雨')) {
      return '$summary，建议携带雨具。';
    } else if (int.tryParse(temp) != null && (int.tryParse(temp) ?? 20) <= 10) {
      return '$summary，天气较冷，注意保暖。';
    } else if (int.tryParse(temp) != null && (int.tryParse(temp) ?? 20) >= 30) {
      return '$summary，天气炎热，注意防暑。';
    }

    return summary;
  }

  /// 生成默认15天摘要
  String _getDefault15dSummary(List<DailyWeather> forecast15d) {
    if (forecast15d.isEmpty) {
      return '暂无15天天气预报数据';
    }

    // 统计主要天气类型
    final weatherTypes = <String, int>{};
    for (final day in forecast15d) {
      // 优先使用白天天气，如果没有则使用下午天气
      final weather = day.weather_am ?? day.weather_pm ?? '未知';
      weatherTypes[weather] = (weatherTypes[weather] ?? 0) + 1;
    }

    // 找出最常见的天气
    final mostCommon = weatherTypes.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return '未来15天以$mostCommon天气为主';
  }

  /// 生成通勤建议
  Future<List<CommuteAdviceModel>> generateCommuteAdvice(
    WeatherModel? weatherData,
    SunMoonIndexData? sunMoonData,
  ) async {
    if (weatherData == null || _isGeneratingCommuteAdvice) {
      return _commuteAdvices;
    }

    _isGeneratingCommuteAdvice = true;
    notifyListeners();

    try {
      Logger.d('开始生成通勤建议', tag: 'AIInsightsProvider');

      // 使用 AIService 的 generateSmartAdvice 方法生成通勤建议
      final prompt = '请根据以下天气数据生成通勤建议，返回JSON数组格式：${weatherData.toString()}';
      final result = await _aiService.generateSmartAdvice(prompt);

      // 解析结果并创建 CommuteAdviceModel 列表
      // 这里暂时返回空列表，实际实现需要解析 AI 返回的结果
      if (result != null && result.isNotEmpty) {
        // TODO: 解析 AI 返回的结果
        _commuteAdvices = [];
        _hasShownCommuteAdviceToday = false;
        Logger.d('通勤建议生成成功: ${result.length} 条', tag: 'AIInsightsProvider');
        notifyListeners();
        return _commuteAdvices;
      }

      return [];
    } catch (e) {
      Logger.e('生成通勤建议失败', tag: 'AIInsightsProvider', error: e);
      return [];
    } finally {
      _isGeneratingCommuteAdvice = false;
      notifyListeners();
    }
  }

  /// 标记通勤建议为已读
  void markCommuteAdvicesAsRead() {
    bool changed = false;
    final newAdvices = <CommuteAdviceModel>[];
    
    for (final advice in _commuteAdvices) {
      if (!advice.isRead) {
        newAdvices.add(advice.copyWith(isRead: true));
        changed = true;
      } else {
        newAdvices.add(advice);
      }
    }

    if (changed) {
      _commuteAdvices = newAdvices;
      _hasShownCommuteAdviceToday = true;
      notifyListeners();
    }
  }

  /// 清除通勤建议
  void clearCommuteAdvices() {
    if (_commuteAdvices.isNotEmpty) {
      _commuteAdvices.clear();
      notifyListeners();
    }
  }

  /// 重置每日显示标志（新的一天调用）
  void resetDailyFlags() {
    if (_hasShownCommuteAdviceToday) {
      _hasShownCommuteAdviceToday = false;
      notifyListeners();
    }
  }

  /// 设置摘要数据（用于从缓存加载）
  void setSummaries({
    String? dailySummary,
    String? forecast15dSummary,
  }) {
    bool changed = false;

    if (dailySummary != null && dailySummary != _dailySummary) {
      _dailySummary = dailySummary;
      changed = true;
    }

    if (forecast15dSummary != null && forecast15dSummary != _forecast15dSummary) {
      _forecast15dSummary = forecast15dSummary;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// 清除所有 AI 数据
  void clearAll() {
    _dailySummary = null;
    _forecast15dSummary = null;
    _commuteAdvices.clear();
    _hasShownCommuteAdviceToday = false;
    notifyListeners();
  }

  /// 释放资源
  @override
  void dispose() {
    _dailySummary = null;
    _forecast15dSummary = null;
    _commuteAdvices.clear();
    super.dispose();
  }
}
