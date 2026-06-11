// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String username;
  final String email;
  User({required this.username, required this.email});
}

class AuthProvider extends ChangeNotifier {

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('user_email');
    final username = prefs.getString('user_name');

    if (token != null && email != null && username != null) {
      _user = User(username: username, email: email);
      print('✅ Сессия восстановлена для: $email');
    } else {
      print('ℹ️ Сессия не найдена. Нужен логин.');
    }
    notifyListeners();
  }

  // --- ЗАГЛУШКА ЛОГИНА (Всегда пускает) ---
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    // Имитируем запрос на сервер
    await Future.delayed(const Duration(seconds: 1));

    String tempEmail = username;
    String tempUsername = username.contains('@') ? username.split('@')[0] : username;
    if (tempUsername.isEmpty) tempUsername = "Explorer";

    _user = User(username: tempUsername, email: tempEmail);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', "fake_jwt_token_12345");
    await prefs.setString('user_email', tempEmail);
    await prefs.setString('user_name', tempUsername);

    _isLoading = false;
    notifyListeners();
    return true; // Всегда возвращает успех
  }

  // --- ЗАГЛУШКА РЕГИСТРАЦИИ ---
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _user = User(username: username, email: email);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', "fake_jwt_token_12345");
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', username);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> loginWithOAuthToken(String token) async {
    _user = User(username: "Google User", email: "google@example.com");
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    notifyListeners();
  }
}