import '../../core/constants/app_constants.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String? accountId;
  final String type;
  final double amount;
  final String category;
  final String? note;
  final String? imagePath;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    this.accountId,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    this.imagePath,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIncome => type == AppConstants.typeIncome;
  bool get isExpense => type == AppConstants.typeExpense;

  String get categoryEmoji =>
      AppConstants.categoryIcons[category] ?? '📌';

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'image_path': imagePath,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? type,
    double? amount,
    String? category,
    String? note,
    String? imagePath,
    DateTime? date,
    String? accountId,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
