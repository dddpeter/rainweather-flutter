/// 通勤建议模型
class CommuteAdviceModel {
  final String id; // 唯一标识
  final DateTime timestamp; // 创建时间
  final String
  adviceType; // 建议类型：sunny/rainy/snowy/windy/air_quality/visibility
  final String title; // 标题
  final String content; // 建议内容
  final String icon; // 图标
  final bool isRead; // 是否已读
  final CommuteTimeSlot timeSlot; // 时段：morning/evening

  CommuteAdviceModel({
    required this.id,
    required this.timestamp,
    required this.adviceType,
    required this.title,
    required this.content,
    required this.icon,
    required this.isRead,
    required this.timeSlot,
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
    );
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
