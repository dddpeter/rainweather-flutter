class CityModel {
  final String id;
  final String name;
  final bool isMainCity;
  final DateTime createdAt;
  final int sortOrder;

  CityModel({
    required this.id,
    required this.name,
    this.isMainCity = false,
    required this.createdAt,
    this.sortOrder = 9999,
  });

  /// 从JSON创建城市模型
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isMainCity: json['isMainCity'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      sortOrder: json['sortOrder'] as int? ?? 9999,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isMainCity': isMainCity,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'sortOrder': sortOrder,
    };
  }

  /// 从数据库行创建城市模型
  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: map['id'] as String,
      name: map['name'] as String,
      isMainCity: (map['isMainCity'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      sortOrder: map['sortOrder'] as int? ?? 9999,
    );
  }

  /// 转换为数据库行
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isMainCity': isMainCity ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'sortOrder': sortOrder,
    };
  }

  /// 复制并修改属性
  CityModel copyWith({
    String? id,
    String? name,
    bool? isMainCity,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return CityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isMainCity: isMainCity ?? this.isMainCity,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'CityModel(id: $id, name: $name, isMainCity: $isMainCity, createdAt: $createdAt, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityModel &&
        other.id == id &&
        other.name == name &&
        other.isMainCity == isMainCity &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        isMainCity.hashCode ^
        sortOrder.hashCode;
  }
}
