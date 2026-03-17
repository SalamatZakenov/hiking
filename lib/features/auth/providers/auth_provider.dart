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
    baseUrl: 'http://ec2-13-49-175-155.eu-north-1.compute.amazonaws.com',
    connectTimeout: const Duration(seconds: 10),
  ));

  User? _user; // Храним данные вошедшего пользователя
  bool _isLoading = false;

  // Геттеры
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null; // Если пользователь не null — он авторизован

  // Метод РЕГИСТРАЦИИ
  Future<bool> register({
    required String username, // 1. ИСПРАВИЛИ name НА username
    required String email,
    required String password
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
          '/api/auth/register',
          data: {
            'username': username,
            'email': email,
            'password': password,
          });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Register Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Метод ВХОДА (Login)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
// Добавили / перед api
      final response = await _dio.post(
          '/api/auth/login',
          data: {
            'email': email,
            'password': password,
          });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 1. Получаем токен
        final String token = response.data.toString();
        print('✅ Успешный логин! Получен токен: $token');

        // 2. Делаем временное имя из email (берем всё, что до @)
        final String tempUsername = email.split('@')[0];

        // 3. Авторизуем пользователя
        _user = User(username: tempUsername, email: email);

        return true;
      }
      return false;

    } on DioException catch (e) {
      print('❌ Ошибка сети при логине: ${e.message}');
      if (e.response != null) {
        print('👉 Сервер жалуется на: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      print('❌ Какая-то другая ошибка: $e');
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