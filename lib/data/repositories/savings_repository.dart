import '../database/database_helper.dart';
import '../models/savings_model.dart';
import '../../core/constants/app_constants.dart';

class SavingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String> createSavings(SavingsModel savings) async {
    final db = await _dbHelper.database;
    await db.insert(AppConstants.tableSavings, savings.toMap());
    return savings.id;
  }

  Future<List<SavingsModel>> getSavings(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      AppConstants.tableSavings,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => SavingsModel.fromMap(e)).toList();
  }

  Future<SavingsModel?> getSavingsById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      AppConstants.tableSavings,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SavingsModel.fromMap(results.first);
  }

  Future<void> updateSavings(SavingsModel savings) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableSavings,
      savings.toMap(),
      where: 'id = ?',
      whereArgs: [savings.id],
    );
  }

  Future<void> addAmount(String id, double amount) async {
    final db = await _dbHelper.database;
    final savings = await getSavingsById(id);
    if (savings == null) return;

    final newAmount = savings.currentAmount + amount;
    final isCompleted = newAmount >= savings.targetAmount;

    await db.update(
      AppConstants.tableSavings,
      {
        'current_amount': newAmount,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSavings(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tableSavings,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalSavings(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(current_amount), 0) as total FROM ${AppConstants.tableSavings} WHERE user_id = ?',
      [userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
