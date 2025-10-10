import 'package:flutter/material.dart';

/// 通勤建议级别枚举
enum CommuteAdviceLevel {
  critical, // 严重/红色 - 暴雨、暴雪等危险天气
  warning, // 警告/黄色 - 大雨、大雪、大风等需注意
  info, // 提示/蓝色 - 一般提醒
  normal, // 普通/绿色 - 日常建议
}

/// 通勤建议模型
class CommuteAdviceModel {
  final String id; // 唯一标识
  final DateTime timestamp; // 创建时间
  final String
  adviceType; // 建议类型：sunny/rainy/snowy/windy/air_quality/visibility/high_temp/low_temp
  final String title; // 标题
  final String content; // 建议内容
  final String icon; // 图标
  final bool isRead; // 是否已读
  final CommuteTimeSlot timeSlot; // 时段：morning/evening
  final CommuteAdviceLevel level; // 提醒级别

  CommuteAdviceModel({
    required this.id,
    required this.timestamp,
    required this.adviceType,
    required this.title,
    required this.content,
    required this.icon,
    required this.isRead,
    required this.timeSlot,
    required this.level,
  });

  /// 从Map创建
  factory CommuteAdviceModel.fromMap(Map<String, dynamic> map) {
    return CommuteAdviceModel(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      adviceType: map['adviceType'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      icon: map['icon'] as String,
      isRead: (map['isRead'] as int) == 1,
      timeSlot: CommuteTimeSlot.values.firstWhere(
        (e) => e.toString() == 'CommuteTimeSlot.${map['timeSlot']}',
        orElse: () => CommuteTimeSlot.morning,
      ),
      level: CommuteAdviceLevel.values.firstWhere(
        (e) => e.toString() == 'CommuteAdviceLevel.${map['level']}',
        orElse: () => CommuteAdviceLevel.normal,
      ),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'adviceType': adviceType,
      'title': title,
      'content': content,
      'icon': icon,
      'isRead': isRead ? 1 : 0,
      'timeSlot': timeSlot.toString().split('.').last,
      'level': level.toString().split('.').last,
    };
  }

  /// 复制并修改
  CommuteAdviceModel copyWith({
    String? id,
    DateTime? timestamp,
    String? adviceType,
    String? title,
    String? content,
    String? icon,
    bool? isRead,
    CommuteTimeSlot? timeSlot,
    CommuteAdviceLevel? level,
  }) {
    return CommuteAdviceModel(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      adviceType: adviceType ?? this.adviceType,
      title: title ?? this.title,
      content: content ?? this.content,
      icon: icon ?? this.icon,
      isRead: isRead ?? this.isRead,
      timeSlot: timeSlot ?? this.timeSlot,
      level: level ?? this.level,
    );
  }

  /// 获取级别对应的颜色
  Color getLevelColor() {
    switch (level) {
      case CommuteAdviceLevel.critical:
        return const Color(0xFFD32F2F); // 红色
      case CommuteAdviceLevel.warning:
        return const Color(0xFFF57C00); // 橙色
      case CommuteAdviceLevel.info:
        return const Color(0xFF64DD17); // 绿色（与详细信息卡片第二列一致）
      case CommuteAdviceLevel.normal:
        return const Color(0xFF388E3C); // 深绿色
    }
  }

  /// 获取级别对应的背景色
  Color getLevelBackgroundColor() {
    return getLevelColor();
  }

  /// 获取级别名称
  String getLevelName() {
    switch (level) {
      case CommuteAdviceLevel.critical:
        return '严重';
      case CommuteAdviceLevel.warning:
        return '警告';
      case CommuteAdviceLevel.info:
        return '提示';
      case CommuteAdviceLevel.normal:
        return '建议';
    }
  }

  /// 获取优先级（数字越小优先级越高）
  int get priority {
    switch (level) {
      case CommuteAdviceLevel.critical:
        return 1;
      case CommuteAdviceLevel.warning:
        return 2;
      case CommuteAdviceLevel.info:
        return 3;
      case CommuteAdviceLevel.normal:
        return 4;
    }
  }
}

/// 通勤时段枚举
enum CommuteTimeSlot {
  morning, // 早高峰 6:00-10:00
  evening, // 晚高峰 17:00-20:00
}

/// 通勤时段扩展
extension CommuteTimeSlotExtension on CommuteTimeSlot {
  /// 获取时段名称
  String get name {
    switch (this) {
      case CommuteTimeSlot.morning:
        return '早高峰';
      case CommuteTimeSlot.evening:
        return '晚高峰';
    }
  }

  /// 获取时段时间范围
  String get timeRange {
    switch (this) {
      case CommuteTimeSlot.morning:
        return '6:00-10:00';
      case CommuteTimeSlot.evening:
        return '17:00-20:00';
    }
  }
}
