import '../../core/constants/app_constants.dart';

class DebtModel {
  final String id;
  final String userId;
  final String type; // 'owed' = hutang, 'receivable' = piutang
  final String personName;
  final double amount;
  final double paidAmount;
  final String status;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.personName,
    required this.amount,
    this.paidAmount = 0,
    this.status = AppConstants.statusUnpaid,
    this.dueDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOwed => type == AppConstants.debtTypeOwed;
  bool get isReceivable => type == AppConstants.debtTypeReceivable;
  bool get isPaid => status == AppConstants.statusPaid;
  bool get isUnpaid => status == AppConstants.statusUnpaid;
  double get remaining => amount - paidAmount;
  double get percentage => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0;

  bool get isOverdue {
    if (dueDate == null || isPaid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueSoon {
    if (dueDate == null || isPaid) return false;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 1;
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      personName: map['person_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? AppConstants.statusUnpaid,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'person_name': personName,
      'amount': amount,
      'paid_amount': paidAmount,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DebtModel copyWith({
    String? personName,
    double? amount,
    double? paidAmount,
    String? status,
    DateTime? dueDate,
    String? note,
  }) {
    return DebtModel(
      id: id,
      userId: userId,
      type: type,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
