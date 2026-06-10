class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String? avatar;
  final double monthlyAllowance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.avatar,
    this.monthlyAllowance = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      avatar: map['avatar'] as String?,
      monthlyAllowance: (map['monthly_allowance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'avatar': avatar,
      'monthly_allowance': monthlyAllowance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? avatar,
    double? monthlyAllowance,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      avatar: avatar ?? this.avatar,
      monthlyAllowance: monthlyAllowance ?? this.monthlyAllowance,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Computed properties
  double get dailyBudget {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return monthlyAllowance / daysInMonth;
  }

  double get weeklyBudget => dailyBudget * 7;
}
