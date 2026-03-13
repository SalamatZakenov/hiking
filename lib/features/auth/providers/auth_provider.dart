import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// Простая модель пользователя
class User {
  final String username;
  final String email;
  User({required this.username, required this.email});
}

class AuthProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://ec2-51-20-123-149.eu-north-1.compute.amazonaws.com:8080/api/',
    connectTimeout: const Duration(seconds: 10),
  ));

  User? _user; // Храним данные вошедшего пользователя
  bool _isLoading = false;

  // Геттеры, которые требовали ошибки:
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null; // Если пользователь не null — он авторизован

  // Метод РЕГИСТРАЦИИ
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post('auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Register Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Метод ВХОДА (Login) — его тоже требовала ошибка
// Метод ВХОДА (Login)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post('auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        // 1. Получаем токен (теперь мы знаем, что это просто строка)
        final String token = response.data.toString();
        print('✅ Успешный логин! Получен токен: $token');

        // ВАЖНО: Тут в будущем мы должны сохранить токен в память телефона!

        // 2. Делаем временное имя из email (берем всё, что до @)
        final String tempUsername = email.split('@')[0];

        // 3. Авторизуем пользователя
        _user = User(username: tempUsername, email: email);

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Login Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}