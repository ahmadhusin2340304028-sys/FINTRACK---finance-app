import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final UserRepository _userRepository = UserRepository();
  static const _uuid = Uuid();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final exists = await _userRepository.emailExists(email);
    if (exists) {
      throw Exception('Email sudah terdaftar');
    }

    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      password: _hashPassword(password),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userRepository.createUser(user);
    await _saveSession(user.id);
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final user = await _userRepository.getUserByEmail(email);
    if (user == null) {
      throw Exception('Email tidak ditemukan');
    }
    if (user.password != _hashPassword(password)) {
      throw Exception('Password salah');
    }
    await _saveSession(user.id);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefCurrentUser);
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCurrentUser, userId);
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefCurrentUser);
  }

  Future<UserModel?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;
    return await _userRepository.getUserById(userId);
  }

  Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    if (userId == null) return false;
    final user = await _userRepository.getUserById(userId);
    return user != null;
  }

  Future<void> updateProfile(UserModel user) async {
    await _userRepository.updateUser(user);
  }

  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = await _userRepository.getUserById(userId);
    if (user == null) throw Exception('User tidak ditemukan');
    if (user.password != _hashPassword(oldPassword)) {
      throw Exception('Password lama salah');
    }
    await _userRepository.updateUser(
      user.copyWith(password: _hashPassword(newPassword)),
    );
  }
}
