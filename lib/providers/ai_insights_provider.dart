import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/commute_advice_model.dart';
import '../models/weather_model.dart';
import '../services/ai_service.dart';
import '../services/commute_advice_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';

/// AIInsightsProvider - AI 智能摘要 Provider
///
/// 职责：
/// - 管理 AI 生成的每日天气摘要
/// - 管理 AI 生成的15天天气趋势摘要
/// - 管理通勤建议（完整功能）
/// - AI 生成状态管理
/// - 通勤建议定时清理和智能重试
class AIInsightsProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final DatabaseService _databaseService = DatabaseService.getInstance();

  // ===== 通勤建议 Timer（统一定时器） =====
  Timer? _unifiedCommuteTimer;
  int _cleanupCounter = 0; // 用于追踪清理周期（每4次=2分钟）
  bool _isUnifiedTimerActive = false;

  // ===== 天气数据引用（用于通勤建议生成） =====
  WeatherModel? _currentWeather;

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

  /// 设置当前天气数据（用于通勤建议生成）
  void setWeatherData(WeatherModel? weatherData) {
    _currentWeather = weatherData;
  }

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
          .toList() ??
          [];

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

  // ==================== 通勤建议完整功能 ====================

  /// 检查并生成通勤建议
  Future<void> checkAndGenerateCommuteAdvices() async {
    // 防止重复生成
    if (_isGeneratingCommuteAdvice) {
      Logger.d('通勤建议正在生成中，跳过重复调用', tag: 'AIInsightsProvider');
      return;
    }

    // 检查是否在通勤时段
    if (!CommuteAdviceService.isInCommuteTime()) {
      Logger.d('不在通勤时段，加载历史通勤建议', tag: 'AIInsightsProvider');
      await loadCommuteAdvices();
      return;
    }

    // 检查今日当前时段是否已生成过建议
    final currentTimeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();
    if (currentTimeSlot == null) {
      Logger.d('无法获取当前时段，加载历史建议', tag: 'AIInsightsProvider');
      await loadCommuteAdvices();
      return;
    }

    // 检查数据库中是否已有当前时段的建议
    final existingAdvices = await _databaseService.getTodayCommuteAdvices();
    final hasCurrentSlotAdvices =
        existingAdvices.any((a) => a.timeSlot == currentTimeSlot);

    if (hasCurrentSlotAdvices) {
      Logger.d('当前时段已有通勤建议，加载到界面', tag: 'AIInsightsProvider');
      _hasShownCommuteAdviceToday = true;
      await loadCommuteAdvices();
      return;
    }

    // 检查是否有天气数据
    if (_currentWeather == null) {
      Logger.d('无天气数据，无法生成通勤建议，加载历史建议', tag: 'AIInsightsProvider');
      await loadCommuteAdvices();
      return;
    }

    try {
      _isGeneratingCommuteAdvice = true;

      Logger.d('开始生成通勤建议', tag: 'AIInsightsProvider');

      // 生成通勤建议（使用AI或规则引擎）
      final commuteService = CommuteAdviceService();
      final advices = await commuteService.generateAdvices(_currentWeather!);

      if (advices.isEmpty) {
        Logger.d('当前天气条件无需特别提醒', tag: 'AIInsightsProvider');
        _hasShownCommuteAdviceToday = true;
        _isGeneratingCommuteAdvice = false;
        return;
      }

      // 保存到数据库
      await _databaseService.saveCommuteAdvices(advices);
      Logger.d('通勤建议已保存到数据库', tag: 'AIInsightsProvider');

      // 加载通勤建议
      await loadCommuteAdvices(notifyUI: false);
      Logger.d('通勤建议加载完成，当前建议数: ${_commuteAdvices.length}', tag: 'AIInsightsProvider');

      // 标记今日已显示
      _hasShownCommuteAdviceToday = true;
      _isGeneratingCommuteAdvice = false;

      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e('通勤建议生成失败', tag: 'AIInsightsProvider', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AIInsightsProvider.CheckAndGenerateCommuteAdvices',
        type: AppErrorType.unknown,
      );
      // 生成失败时，至少加载历史建议
      await loadCommuteAdvices();
    } finally {
      // 确保状态被重置
      _isGeneratingCommuteAdvice = false;
    }
  }

  /// 加载通勤建议
  Future<void> loadCommuteAdvices({bool notifyUI = true}) async {
    try {
      Logger.d('开始加载通勤建议', tag: 'AIInsightsProvider');

      // 先尝试从内存缓存快速恢复
      if (_commuteAdvices.isNotEmpty) {
        final currentTimeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();

        // 先过滤掉已结束的建议
        final validAdvices = _commuteAdvices.where((advice) {
          final isToday = advice.timestamp.day == DateTime.now().day;
          final isNotExpired = !CommuteAdviceService.isTimeSlotEnded(advice.timeSlot);
          return isToday && isNotExpired;
        }).toList();

        if (validAdvices.length != _commuteAdvices.length) {
          Logger.d('内存缓存中有已结束的建议，已过滤', tag: 'AIInsightsProvider');
          _commuteAdvices = validAdvices;
        }

        final hasValidCache = _commuteAdvices.any((advice) {
          final isToday = advice.timestamp.day == DateTime.now().day;
          final isCurrentSlot = currentTimeSlot == null || advice.timeSlot == currentTimeSlot;
          final isNotExpired = !CommuteAdviceService.isTimeSlotEnded(advice.timeSlot);
          return isToday && (isCurrentSlot || !CommuteAdviceService.isInCommuteTime()) && isNotExpired;
        });

        if (hasValidCache) {
          Logger.d('使用内存缓存通勤建议: ${_commuteAdvices.length}条', tag: 'AIInsightsProvider');
          if (notifyUI) notifyListeners();
          return;
        } else {
          Logger.d('内存缓存已过期，从数据库重新加载', tag: 'AIInsightsProvider');
          _commuteAdvices = [];
        }
      }

      // 先清理数据库中的重复数据
      await _databaseService.cleanDuplicateCommuteAdvices();

      final advices = await _databaseService.getTodayCommuteAdvices();
      Logger.d('数据库中今日建议: ${advices.length}条', tag: 'AIInsightsProvider');

      if (advices.isEmpty) {
        Logger.d('数据库中没有今日通勤建议', tag: 'AIInsightsProvider');
        _commuteAdvices = [];
        if (notifyUI) notifyListeners();
        return;
      }

      // 获取当前通勤时段
      final currentTimeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();

      // 过滤逻辑：
      // 1. 如果当前在通勤时段，只显示当前时段的建议
      // 2. 如果不在通勤时段，只显示未结束的建议
      final filteredAdvices = advices.where((advice) {
        if (currentTimeSlot != null) {
          return advice.timeSlot == currentTimeSlot;
        } else {
          return !CommuteAdviceService.isTimeSlotEnded(advice.timeSlot);
        }
      }).toList();

      Logger.d('过滤后剩余: ${filteredAdvices.length}条', tag: 'AIInsightsProvider');

      // 二次去重：按 adviceType + timeSlot 去重
      final uniqueAdvices = <String, CommuteAdviceModel>{};
      for (var advice in filteredAdvices) {
        final key = '${advice.adviceType}_${advice.timeSlot}';
        if (!uniqueAdvices.containsKey(key) ||
            advice.timestamp.isAfter(uniqueAdvices[key]!.timestamp)) {
          uniqueAdvices[key] = advice;
        }
      }

      _commuteAdvices = uniqueAdvices.values.toList();
      _commuteAdvices.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      Logger.d('加载通勤建议: ${_commuteAdvices.length}条（去重后）', tag: 'AIInsightsProvider');

      // 更新灵动岛显示
      if (_commuteAdvices.isNotEmpty) {
        NotificationService.instance.showCommuteIslandNotification(_commuteAdvices);
        Logger.d('灵动岛已更新（${_commuteAdvices.length}条建议）', tag: 'AIInsightsProvider');
      } else {
        NotificationService.instance.hideCommuteIslandNotification();
        Logger.d('灵动岛已隐藏', tag: 'AIInsightsProvider');
      }

      if (notifyUI) notifyListeners();
    } catch (e, stackTrace) {
      Logger.e('加载通勤建议失败', tag: 'AIInsightsProvider', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AIInsightsProvider.LoadCommuteAdvices',
        type: AppErrorType.cache,
      );
    }
  }

  /// 标记单个通勤建议为已读
  Future<void> markCommuteAdviceAsRead(String adviceId) async {
    try {
      await _databaseService.markCommuteAdviceAsRead(adviceId);
      // 更新本地状态
      final index = _commuteAdvices.indexWhere((a) => a.id == adviceId);
      if (index != -1) {
        _commuteAdvices[index] = _commuteAdvices[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e, stackTrace) {
      Logger.e('标记通勤建议失败', tag: 'AIInsightsProvider', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'AIInsightsProvider.MarkCommuteAdviceAsRead',
        type: AppErrorType.cache,
      );
    }
  }

  /// 标记所有通勤建议为已读
  Future<void> markAllCommuteAdvicesAsRead() async {
    try {
      await _databaseService.markAllCommuteAdvicesAsRead();
      // 更新本地状态
      _commuteAdvices = _commuteAdvices.map((a) => a.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      Logger.e('批量标记通勤建议失败', tag: 'AIInsightsProvider', error: e);
    }
  }

  /// 启动通勤建议清理定时器（统一定时器）
  void startCommuteCleanupTimer() {
    stopCommuteCleanupTimer();

    // 每30秒执行一次检查，每4次（2分钟）执行清理
    _unifiedCommuteTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // 始终检查是否需要重新生成
      _checkAndRegenerateCommuteIfNeeded();

      // 每4次迭代执行一次清理（2分钟）
      _cleanupCounter++;
      if (_cleanupCounter >= 4) {
        _cleanupCounter = 0;
        _checkAndCleanupCommuteAdvices();
        checkAndGenerateCommuteAdvices();
      }
    });

    _isUnifiedTimerActive = true;
    Logger.d('通勤建议统一定时器已启动（30秒检查，2分钟清理）', tag: 'AIInsightsProvider');
  }

  /// 停止通勤建议清理定时器
  void stopCommuteCleanupTimer() {
    _unifiedCommuteTimer?.cancel();
    _unifiedCommuteTimer = null;
    _isUnifiedTimerActive = false;
    _cleanupCounter = 0;
  }

  /// 启动天气数据变化监听器（已合并到统一定时器）
  void startWeatherDataWatcher() {
    if (_isUnifiedTimerActive) {
      Logger.d('统一定时器已在运行中', tag: 'AIInsightsProvider');
      return;
    }
    // 统一定时器由 startCommuteCleanupTimer 管理
    startCommuteCleanupTimer();
  }

  /// 停止天气数据变化监听器（已合并到统一定时器）
  void stopWeatherDataWatcher() {
    stopCommuteCleanupTimer();
  }

  /// 检查并智能重新生成通勤建议
  void _checkAndRegenerateCommuteIfNeeded() {
    // 检查是否在通勤时段
    if (!CommuteAdviceService.isInCommuteTime()) {
      return; // 不在通勤时段，跳过
    }

    // 检查天气数据是否可用
    if (_currentWeather == null ||
        _currentWeather!.current?.current == null ||
        _currentWeather!.forecast24h == null ||
        _currentWeather!.forecast24h!.isEmpty) {
      return; // 天气数据不可用，跳过
    }

    // 检查通勤建议是否为空或已过期
    bool shouldRegenerate = false;

    if (_commuteAdvices.isEmpty) {
      shouldRegenerate = true;
      Logger.d('监听器检测到通勤建议为空，尝试重新生成', tag: 'AIInsightsProvider');
    } else {
      // 检查是否有已结束时段的建议需要清理
      final currentTimeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();
      if (currentTimeSlot != null) {
        final hasExpiredAdvices = _commuteAdvices.any((advice) {
          return advice.timeSlot != currentTimeSlot;
        });

        if (hasExpiredAdvices) {
          shouldRegenerate = true;
          Logger.d('监听器检测到有过期建议，尝试重新生成', tag: 'AIInsightsProvider');
        }
      }
    }

    if (shouldRegenerate) {
      Logger.d('监听器触发通勤建议重新生成', tag: 'AIInsightsProvider');
      checkAndGenerateCommuteAdvices();
    }
  }

  /// 检查并清理通勤建议
  Future<void> _checkAndCleanupCommuteAdvices() async {
    try {
      // 1. 清理15天前的旧记录
      await _databaseService.cleanExpiredCommuteAdvices();

      // 2. 检查当前时段是否结束，清理当前时段的建议
      final timeSlot = CommuteAdviceService.getCurrentCommuteTimeSlot();
      if (timeSlot != null) {
        // 还在通勤时段，不清理
        return;
      }

      // 不在通勤时段，检查是否需要清理
      if (_commuteAdvices.isNotEmpty) {
        // 收集所有已结束时段的建议
        final endedTimeSlots = <String>{};
        for (final advice in _commuteAdvices) {
          if (CommuteAdviceService.isTimeSlotEnded(advice.timeSlot)) {
            endedTimeSlots.add(advice.timeSlot.toString().split('.').last);
          }
        }

        // 清理所有已结束时段的建议
        if (endedTimeSlots.isNotEmpty) {
          int totalDeleted = 0;
          for (final timeSlotStr in endedTimeSlots) {
            final deletedCount = await _databaseService.cleanEndedTimeSlotAdvices(timeSlotStr);
            totalDeleted += deletedCount;
            Logger.d('清理$timeSlotStr时段的通勤建议: $deletedCount条', tag: 'AIInsightsProvider');
          }

          if (totalDeleted > 0) {
            // 清空内存缓存，强制从数据库重新加载
            _commuteAdvices = [];

            // 重新加载建议
            await loadCommuteAdvices(notifyUI: true);

            // 重置今日显示标记
            _hasShownCommuteAdviceToday = false;

            Logger.d('通勤时段结束，已清理$totalDeleted条建议', tag: 'AIInsightsProvider');
          }
        }
      }
    } catch (e) {
      Logger.e('清理通勤建议失败', tag: 'AIInsightsProvider', error: e);
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
    stopCommuteCleanupTimer();
    stopWeatherDataWatcher();
    _dailySummary = null;
    _forecast15dSummary = null;
    _commuteAdvices.clear();
    super.dispose();
  }
}
