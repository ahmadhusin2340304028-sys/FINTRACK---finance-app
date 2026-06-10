import '../database/database_helper.dart';
import '../models/budget_model.dart';
import '../../core/constants/app_constants.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String> createBudget(BudgetModel budget) async {
    final db = await _dbHelper.database;
    await db.insert(AppConstants.tableBudgets, budget.toMap());
    return budget.id;
  }

  Future<List<BudgetModel>> getBudgets(String userId, {String? period}) async {
    final db = await _dbHelper.database;
    final where = period != null
        ? 'user_id = ? AND period = ?'
        : 'user_id = ?';
    final args = period != null ? [userId, period] : [userId];

    final results = await db.query(
      AppConstants.tableBudgets,
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return results.map((e) => BudgetModel.fromMap(e)).toList();
  }

  Future<BudgetModel?> getBudgetById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      AppConstants.tableBudgets,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return BudgetModel.fromMap(results.first);
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableBudgets,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> updateBudgetUsed(String budgetId, double used) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableBudgets,
      {'used': used, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [budgetId],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tableBudgets,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<BudgetModel>> getActiveBudgets(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final results = await db.query(
      AppConstants.tableBudgets,
      where: 'user_id = ? AND start_date <= ? AND end_date >= ?',
      whereArgs: [userId, now, now],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => BudgetModel.fromMap(e)).toList();
  }
}
