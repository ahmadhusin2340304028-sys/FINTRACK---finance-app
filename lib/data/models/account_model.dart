class AccountModel {
  final String id;
  final String userId;
  final String name;
  final String type; // Tunai, E-Wallet, Bank
  final double balance;
  final String? color;
  final String? icon;
  final bool isDefault;
  final DateTime createdAt;

  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0,
    this.color,
    this.icon,
    this.isDefault = false,
    required this.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'color': color,
      'icon': icon,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeIcon {
    switch (type) {
      case 'E-Wallet':
        return '📱';
      case 'Bank':
        return '🏦';
      default:
        return '💵';
    }
  }
}
