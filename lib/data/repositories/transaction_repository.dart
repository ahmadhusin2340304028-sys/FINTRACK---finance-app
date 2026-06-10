import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../../core/constants/app_constants.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  Future<String> createTransaction(TransactionModel transaction) async {
    final db = await _db;
    await db.insert(AppConstants.tableTransactions, transaction.toMap());
    return transaction.id;
  }

  Future<List<TransactionModel>> getTransactions(
    String userId, {
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final conditions = ['user_id = ?'];
    final args = <dynamic>[userId];

    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }
    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(note LIKE ? OR category LIKE ?)');
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }

    final results = await db.query(
      AppConstants.tableTransactions,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return TransactionModel.fromMap(results.first);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await _db;
    await db.update(
      AppConstants.tableTransactions,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _db;
    await db.delete(
      AppConstants.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getSummary(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    final conditions = ['user_id = ?'];
    final args = <dynamic>[userId];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    final whereClause = conditions.join(' AND ');

    final incomeResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ${AppConstants.tableTransactions} WHERE $whereClause AND type = ?',
      [...args, AppConstants.typeIncome],
    );
    final expenseResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ${AppConstants.tableTransactions} WHERE $whereClause AND type = ?',
      [...args, AppConstants.typeExpense],
    );

    final income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0;
    final expense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Future<Map<String, double>> getCategoryBreakdown(
    String userId,
    String type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    final conditions = ['user_id = ?', 'type = ?'];
    final args = <dynamic>[userId, type];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    final results = await db.rawQuery(
      '''SELECT category, SUM(amount) as total 
         FROM ${AppConstants.tableTransactions} 
         WHERE ${conditions.join(' AND ')} 
         GROUP BY category 
         ORDER BY total DESC''',
      args,
    );

    return {for (final r in results) r['category'] as String: (r['total'] as num).toDouble()};
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;
    final results = await db.rawQuery(
      '''SELECT DATE(date) as day, type, SUM(amount) as total 
         FROM ${AppConstants.tableTransactions} 
         WHERE user_id = ? AND date >= ? AND date <= ?
         GROUP BY DATE(date), type
         ORDER BY day ASC''',
      [userId, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return results;
  }

  Future<double> getTodayExpense(String userId) async {
    final db = await _db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery(
      '''SELECT COALESCE(SUM(amount), 0) as total 
         FROM ${AppConstants.tableTransactions} 
         WHERE user_id = ? AND type = ? AND date >= ? AND date < ?''',
      [
        userId,
        AppConstants.typeExpense,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
