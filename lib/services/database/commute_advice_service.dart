import 'package:sqflite/sqflite.dart';
import '../../models/commute_advice_model.dart';
import 'database_core.dart';

/// CommuteAdviceService - 通勤建议管理服务
///
/// 职责：
/// - 通勤建议的保存、查询、删除
/// - 已读状态管理
/// - 过期数据清理
class CommuteAdviceService {
  final DatabaseCore _core;

  CommuteAdviceService(this._core);

  /// 保存通勤建议
  Future<void> saveCommuteAdvice(CommuteAdviceModel advice) async {
    final db = await _core.database;
    try {
      await db.insert(
        'commute_advices',
        advice.toMap()..['createdAt'] = DateTime.now().millisecondsSinceEpoch,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ 通勤建议已保存: ${advice.title}');
    } catch (e) {
      print('❌ 保存通勤建议失败: $e');
    }
  }

  /// 批量保存通勤建议
  Future<void> saveCommuteAdvices(List<CommuteAdviceModel> advices) async {
    final db = await _core.database;
    final batch = db.batch();

    try {
      for (var advice in advices) {
        batch.insert(
          'commute_advices',
          advice.toMap()..['createdAt'] = DateTime.now().millisecondsSinceEpoch,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      print('✅ 批量保存通勤建议成功: ${advices.length}条');
    } catch (e) {
      print('❌ 批量保存通勤建议失败: $e');
    }
  }

  /// 获取所有通勤建议
  Future<List<CommuteAdviceModel>> getAllCommuteAdvices() async {
    final db = await _core.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'commute_advices',
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => CommuteAdviceModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ 获取通勤建议失败: $e');
      return [];
    }
  }

  /// 获取未读的通勤建议
  Future<List<CommuteAdviceModel>> getUnreadCommuteAdvices() async {
    final db = await _core.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'commute_advices',
        where: 'isRead = ?',
        whereArgs: [0],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => CommuteAdviceModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ 获取未读通勤建议失败: $e');
      return [];
    }
  }

  /// 获取今日的通勤建议
  Future<List<CommuteAdviceModel>> getTodayCommuteAdvices() async {
    final db = await _core.database;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startTimestamp = startOfDay.millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'commute_advices',
        where: 'createdAt >= ?',
        whereArgs: [startTimestamp],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => CommuteAdviceModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ 获取今日通勤建议失败: $e');
      return [];
    }
  }

  /// 标记建议为已读
  Future<void> markCommuteAdviceAsRead(String adviceId) async {
    final db = await _core.database;
    try {
      await db.update(
        'commute_advices',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [adviceId],
      );
      print('✅ 通勤建议已标记为已读: $adviceId');
    } catch (e) {
      print('❌ 标记通勤建议失败: $e');
    }
  }

  /// 批量标记建议为已读
  Future<void> markAllCommuteAdvicesAsRead() async {
    final db = await _core.database;
    try {
      await db.update(
        'commute_advices',
        {'isRead': 1},
        where: 'isRead = ?',
        whereArgs: [0],
      );
      print('✅ 所有通勤建议已标记为已读');
    } catch (e) {
      print('❌ 批量标记通勤建议失败: $e');
    }
  }

  /// 删除指定的通勤建议
  Future<void> deleteCommuteAdvice(String adviceId) async {
    final db = await _core.database;
    try {
      await db.delete(
        'commute_advices',
        where: 'id = ?',
        whereArgs: [adviceId],
      );
      print('✅ 通勤建议已删除: $adviceId');
    } catch (e) {
      print('❌ 删除通勤建议失败: $e');
    }
  }

  /// 清理过期的通勤建议（保留15天内的）
  Future<int> cleanExpiredCommuteAdvices() async {
    final db = await _core.database;
    try {
      final now = DateTime.now();
      final fifteenDaysAgo = now.subtract(const Duration(days: 15));
      final timestamp = fifteenDaysAgo.millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        'commute_advices',
        where: 'createdAt < ?',
        whereArgs: [timestamp],
      );

      if (deletedCount > 0) {
        print('✅ 清理过期通勤建议: $deletedCount条');
      }
      return deletedCount;
    } catch (e) {
      print('❌ 清理过期通勤建议失败: $e');
      return 0;
    }
  }

  /// 清理当前时段结束的通勤建议
  Future<int> cleanEndedTimeSlotAdvices(String timeSlot) async {
    final db = await _core.database;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startTimestamp = today.millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        'commute_advices',
        where: 'timeSlot = ? AND createdAt >= ?',
        whereArgs: [timeSlot, startTimestamp],
      );

      if (deletedCount > 0) {
        print('✅ 清理$timeSlot时段的通勤建议: $deletedCount条');
      }
      return deletedCount;
    } catch (e) {
      print('❌ 清理时段通勤建议失败: $e');
      return 0;
    }
  }

  /// 清理重复的通勤建议（保留每种类型+时段的最新一条）
  Future<int> cleanDuplicateCommuteAdvices() async {
    final db = await _core.database;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startTimestamp = today.millisecondsSinceEpoch;

      final List<Map<String, dynamic>> allAdvices = await db.query(
        'commute_advices',
        where: 'createdAt >= ?',
        whereArgs: [startTimestamp],
        orderBy: 'createdAt DESC',
      );

      if (allAdvices.isEmpty) return 0;

      final Map<String, List<String>> typeGroups = {};
      for (var advice in allAdvices) {
        final key = '${advice['adviceType']}_${advice['timeSlot']}';
        typeGroups.putIfAbsent(key, () => []);
        typeGroups[key]!.add(advice['id'] as String);
      }

      int deletedCount = 0;
      for (var group in typeGroups.values) {
        if (group.length > 1) {
          for (int i = 1; i < group.length; i++) {
            await db.delete(
              'commute_advices',
              where: 'id = ?',
              whereArgs: [group[i]],
            );
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        print('✅ 清理重复通勤建议: $deletedCount条');
      }
      return deletedCount;
    } catch (e) {
      print('❌ 清理重复通勤建议失败: $e');
      return 0;
    }
  }
}
