class BudgetModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double target;
  final double used;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.target,
    this.used = 0,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remaining => target - used;
  double get percentage => target > 0 ? (used / target).clamp(0.0, 1.0) : 0;
  bool get isOverBudget => used > target;
  bool get isWarning => remaining / target < 0.2 && !isOverBudget;

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      target: (map['target'] as num).toDouble(),
      used: (map['used'] as num?)?.toDouble() ?? 0,
      period: map['period'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'target': target,
      'used': used,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BudgetModel copyWith({
    String? name,
    String? category,
    double? target,
    double? used,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? color,
  }) {
    return BudgetModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      target: target ?? this.target,
      used: used ?? this.used,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
