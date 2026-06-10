class SavingsModel {
  final String id;
  final String userId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? icon;
  final String? color;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsModel({
    required this.id,
    required this.userId,
    required this.goalName,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.icon,
    this.color,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get percentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining => targetAmount - currentAmount;
  bool get isAchieved => currentAmount >= targetAmount;

  int? get daysRemaining {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  double? get dailySavingsNeeded {
    if (deadline == null || daysRemaining == null || daysRemaining! <= 0) {
      return null;
    }
    return remaining / daysRemaining!;
  }

  factory SavingsModel.fromMap(Map<String, dynamic> map) {
    return SavingsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      goalName: map['goal_name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'icon': icon,
      'color': color,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SavingsModel copyWith({
    String? goalName,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
    String? color,
    bool? isCompleted,
  }) {
    return SavingsModel(
      id: id,
      userId: userId,
      goalName: goalName ?? this.goalName,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
