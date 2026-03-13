import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Модель данных пользователя
class User {
  final String username;
  final String email;
  User({required this.username, required this.email});
}

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  User? _user;
  User? get user => _user;

  final _storage = const FlutterSecureStorage();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8080/api/auth', // Для iOS симулятора
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {'email': email, 'password': password});
      if (response.statusCode == 200) {
        final token = response.data.toString();
        await _storage.write(key: 'jwt_token', value: token);

        // Создаем локальный объект пользователя
        _user = User(username: email.split('@')[0], email: email);

        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/register', data: {
        'username': name,
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        _user = User(username: name, email: email);
        await login(email, password);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}