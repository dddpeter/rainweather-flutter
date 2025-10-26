import '../providers/weather_provider.dart';
import '../utils/persistent_app_state.dart';

/// 数据类型
enum DataType {
  currentWeather,
  hourlyForecast,
  dailyForecast,
  cityList,
  location,
}

/// 刷新优先级
enum RefreshPriority { high, medium, low }

/// 刷新任务
class RefreshTask {
  final DataType type;
  final RefreshPriority priority;
  final Future<void> Function() task;

  RefreshTask({required this.type, required this.priority, required this.task});
}

/// 智能刷新调度器
class SmartRefreshScheduler {
  static final SmartRefreshScheduler _instance =
      SmartRefreshScheduler._internal();
  factory SmartRefreshScheduler() => _instance;
  SmartRefreshScheduler._internal();

  // 刷新间隔配置（分钟）
  static const Map<DataType, int> _refreshIntervals = {
    DataType.currentWeather: 5, // 当前天气：5分钟
    DataType.hourlyForecast: 15, // 小时预报：15分钟
    DataType.dailyForecast: 60, // 日预报：1小时
    DataType.cityList: 1440, // 城市列表：24小时
    DataType.location: 10, // 定位：10分钟
  };

  /// 判断是否需要刷新
  bool shouldRefresh(DataType dataType, Duration backgroundDuration) {
    final interval = _refreshIntervals[dataType] ?? 60;
    final shouldRefresh = backgroundDuration.inMinutes >= interval;

    if (shouldRefresh) {
      print(
        '🔄 ${_getDataTypeName(dataType)} 需要刷新 (后台 ${backgroundDuration.inMinutes}min >= ${interval}min)',
      );
    }

    return shouldRefresh;
  }

  /// 根据后台时长决定刷新策略
  Future<void> executeSmartRefresh(
    Duration backgroundDuration,
    WeatherProvider weatherProvider,
  ) async {
    print('\n🔄 智能刷新调度器: 后台时长 ${backgroundDuration.inMinutes} 分钟');

    // 收集需要刷新的任务
    final tasks = <RefreshTask>[];

    // 当前天气 - 高优先级
    if (shouldRefresh(DataType.currentWeather, backgroundDuration)) {
      tasks.add(
        RefreshTask(
          type: DataType.currentWeather,
          priority: RefreshPriority.high,
          task: () async {
            print('🔄 刷新当前天气');
            await weatherProvider.refreshWeatherData();
          },
        ),
      );
    }

    // 24小时预报 - 中优先级
    if (shouldRefresh(DataType.hourlyForecast, backgroundDuration)) {
      tasks.add(
        RefreshTask(
          type: DataType.hourlyForecast,
          priority: RefreshPriority.medium,
          task: () async {
            print('🔄 刷新24小时预报');
            await weatherProvider.refresh24HourForecast();
          },
        ),
      );
    }

    // 15日预报 - 中优先级
    if (shouldRefresh(DataType.dailyForecast, backgroundDuration)) {
      tasks.add(
        RefreshTask(
          type: DataType.dailyForecast,
          priority: RefreshPriority.medium,
          task: () async {
            print('🔄 刷新15日预报');
            await weatherProvider.refresh15DayForecast();
          },
        ),
      );
    }

    // 城市列表 - 低优先级
    if (shouldRefresh(DataType.cityList, backgroundDuration)) {
      tasks.add(
        RefreshTask(
          type: DataType.cityList,
          priority: RefreshPriority.low,
          task: () async {
            print('🔄 刷新城市列表');
            await weatherProvider.loadMainCities();
          },
        ),
      );
    }

    // 按优先级执行任务
    await _executeTasks(tasks);

    // 保存刷新时间
    final persistentState = await PersistentAppState.getInstance();
    await persistentState.saveWeatherUpdateTime();

    print('✅ 智能刷新完成，共执行 ${tasks.length} 个任务\n');
  }

  /// 执行刷新任务（按优先级）
  Future<void> _executeTasks(List<RefreshTask> tasks) async {
    if (tasks.isEmpty) {
      print('ℹ️ 没有需要刷新的数据');
      return;
    }

    // 按优先级排序
    tasks.sort(
      (a, b) =>
          _priorityValue(a.priority).compareTo(_priorityValue(b.priority)),
    );

    // 高优先级任务立即执行
    final highPriorityTasks = tasks
        .where((t) => t.priority == RefreshPriority.high)
        .map((t) => t.task())
        .toList();

    if (highPriorityTasks.isNotEmpty) {
      print('🚀 执行 ${highPriorityTasks.length} 个高优先级任务');
      await Future.wait(highPriorityTasks);
    }

    // 中优先级任务依次执行
    final mediumPriorityTasks = tasks
        .where((t) => t.priority == RefreshPriority.medium)
        .toList();

    for (final task in mediumPriorityTasks) {
      try {
        await task.task();
      } catch (e) {
        print('❌ 任务执行失败: $e');
      }
    }

    // 低优先级任务延迟执行
    final lowPriorityTasks = tasks
        .where((t) => t.priority == RefreshPriority.low)
        .toList();

    if (lowPriorityTasks.isNotEmpty) {
      Future.delayed(const Duration(seconds: 3), () async {
        print('🐢 执行 ${lowPriorityTasks.length} 个低优先级任务');
        for (final task in lowPriorityTasks) {
          try {
            await task.task();
          } catch (e) {
            print('❌ 低优先级任务执行失败: $e');
          }
        }
      });
    }
  }

  /// 轻量级刷新（仅刷新当前天气）
  Future<void> lightRefresh(WeatherProvider weatherProvider) async {
    print('🔄 执行轻量级刷新（仅当前天气）');
    try {
      await weatherProvider.refreshWeatherData();
      print('✅ 轻量级刷新完成');
    } catch (e) {
      print('❌ 轻量级刷新失败: $e');
    }
  }

  /// 完整刷新（刷新所有数据）
  Future<void> fullRefresh(WeatherProvider weatherProvider) async {
    print('🔄 执行完整刷新（所有数据）');
    try {
      await Future.wait([
        weatherProvider.forceRefreshWithLocation(),
        weatherProvider.refresh24HourForecast(),
        weatherProvider.refresh15DayForecast(),
        weatherProvider.loadMainCities(),
      ]);

      // 保存刷新时间
      final persistentState = await PersistentAppState.getInstance();
      await persistentState.saveWeatherUpdateTime();

      print('✅ 完整刷新完成');
    } catch (e) {
      print('❌ 完整刷新失败: $e');
    }
  }

  /// 检查是否需要定位更新
  Future<bool> needsLocationUpdate() async {
    try {
      final persistentState = await PersistentAppState.getInstance();
      final lastUpdate = await persistentState.getLastLocationUpdate();

      if (lastUpdate == null) {
        print('📍 需要首次定位');
        return true;
      }

      final timeSinceUpdate = DateTime.now().difference(lastUpdate);
      final needsUpdate =
          timeSinceUpdate.inMinutes >= _refreshIntervals[DataType.location]!;

      if (needsUpdate) {
        print('📍 需要更新定位 (距上次 ${timeSinceUpdate.inMinutes} 分钟)');
      }

      return needsUpdate;
    } catch (e) {
      print('❌ 检查定位更新需求失败: $e');
      return true;
    }
  }

  /// 优先级数值
  int _priorityValue(RefreshPriority priority) {
    switch (priority) {
      case RefreshPriority.high:
        return 1;
      case RefreshPriority.medium:
        return 2;
      case RefreshPriority.low:
        return 3;
    }
  }

  /// 获取数据类型名称
  String _getDataTypeName(DataType type) {
    switch (type) {
      case DataType.currentWeather:
        return '当前天气';
      case DataType.hourlyForecast:
        return '小时预报';
      case DataType.dailyForecast:
        return '日预报';
      case DataType.cityList:
        return '城市列表';
      case DataType.location:
        return '定位信息';
    }
  }
}
