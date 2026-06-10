import '../database/database_helper.dart';
import '../models/debt_model.dart';
import '../../core/constants/app_constants.dart';

class DebtRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String> createDebt(DebtModel debt) async {
    final db = await _dbHelper.database;
    await db.insert(AppConstants.tableDebts, debt.toMap());
    return debt.id;
  }

  Future<List<DebtModel>> getDebts(
    String userId, {
    String? type,
    String? status,
  }) async {
    final db = await _dbHelper.database;
    final conditions = ['user_id = ?'];
    final args = <dynamic>[userId];

    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }
    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }

    final results = await db.query(
      AppConstants.tableDebts,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return results.map((e) => DebtModel.fromMap(e)).toList();
  }

  Future<DebtModel?> getDebtById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      AppConstants.tableDebts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DebtModel.fromMap(results.first);
  }

  Future<void> updateDebt(DebtModel debt) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableDebts,
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> markAsPaid(String id) async {
    final db = await _dbHelper.database;
    final debt = await getDebtById(id);
    if (debt == null) return;
    await db.update(
      AppConstants.tableDebts,
      {
        'status': AppConstants.statusPaid,
        'paid_amount': debt.amount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDebt(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tableDebts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DebtModel>> getDueSoonDebts(String userId) async {
    final db = await _dbHelper.database;
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String();
    final results = await db.query(
      AppConstants.tableDebts,
      where: 'user_id = ? AND status = ? AND due_date <= ?',
      whereArgs: [userId, AppConstants.statusUnpaid, tomorrow],
      orderBy: 'due_date ASC',
    );
    return results.map((e) => DebtModel.fromMap(e)).toList();
  }

  Future<Map<String, double>> getSummary(String userId) async {
    final db = await _dbHelper.database;

    final owedResult = await db.rawQuery(
      '''SELECT COALESCE(SUM(amount - paid_amount), 0) as total 
         FROM ${AppConstants.tableDebts} 
         WHERE user_id = ? AND type = ? AND status = ?''',
      [userId, AppConstants.debtTypeOwed, AppConstants.statusUnpaid],
    );

    final receivableResult = await db.rawQuery(
      '''SELECT COALESCE(SUM(amount - paid_amount), 0) as total 
         FROM ${AppConstants.tableDebts} 
         WHERE user_id = ? AND type = ? AND status = ?''',
      [userId, AppConstants.debtTypeReceivable, AppConstants.statusUnpaid],
    );

    return {
      'owed': (owedResult.first['total'] as num?)?.toDouble() ?? 0,
      'receivable': (receivableResult.first['total'] as num?)?.toDouble() ?? 0,
    };
  }
}
