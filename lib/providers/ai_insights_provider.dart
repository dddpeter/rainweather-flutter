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
  Future<String?> generateDailySummary(WeatherModel? weatherData) async {
    if (weatherData == null || _isGeneratingSummary) {
      return _dailySummary;
    }

    _isGeneratingSummary = true;
    notifyListeners();

    try {
      Logger.d('开始生成每日天气摘要', tag: 'AIInsightsProvider');

      // 使用 AIService 的 generateSmartAdvice 方法
      final prompt = '请为以下天气数据生成简短的每日摘要：${weatherData.toString()}';
      final summary = await _aiService.generateSmartAdvice(prompt);

      if (summary != null && summary.isNotEmpty) {
        _dailySummary = summary;
        Logger.d('每日摘要生成成功', tag: 'AIInsightsProvider');
        notifyListeners();
        return summary;
      }

      return null;
    } catch (e) {
      Logger.e('生成每日摘要失败', tag: 'AIInsightsProvider', error: e);
      return null;
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  /// 生成15天天气趋势摘要
  Future<String?> generate15dSummary(List<DailyWeather>? forecast15d) async {
    if (forecast15d == null || forecast15d.isEmpty || _isGenerating15dSummary) {
      return _forecast15dSummary;
    }

    _isGenerating15dSummary = true;
    notifyListeners();

    try {
      Logger.d('开始生成15天天气趋势摘要', tag: 'AIInsightsProvider');

      // 使用 AIService 的 generateSmartAdvice 方法
      final prompt = '请为以下15天天气预报生成简短的趋势摘要：${forecast15d.toString()}';
      final summary = await _aiService.generateSmartAdvice(prompt);

      if (summary != null && summary.isNotEmpty) {
        _forecast15dSummary = summary;
        Logger.d('15天摘要生成成功', tag: 'AIInsightsProvider');
        notifyListeners();
        return summary;
      }

      return null;
    } catch (e) {
      Logger.e('生成15天摘要失败', tag: 'AIInsightsProvider', error: e);
      return null;
    } finally {
      _isGenerating15dSummary = false;
      notifyListeners();
    }
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
