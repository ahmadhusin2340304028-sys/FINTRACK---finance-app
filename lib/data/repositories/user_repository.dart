import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<String> createUser(UserModel user) async {
    final db = await _db;
    await db.insert(
      AppConstants.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return user.id;
  }

  Future<void> updateUser(UserModel user) async {
    final db = await _db;
    await db.update(
      AppConstants.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updateMonthlyAllowance(String userId, double amount) async {
    final db = await _db;
    await db.update(
      AppConstants.tableUsers,
      {
        'monthly_allowance': amount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> emailExists(String email) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<void> deleteUser(String id) async {
    final db = await _db;
    await db.delete(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
