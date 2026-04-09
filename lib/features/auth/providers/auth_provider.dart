// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Простая модель пользователя
class User {
  final String username;
  final String email;
  User({required this.username, required this.email});
}

class AuthProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://shyn-api.site',
    connectTimeout: const Duration(seconds: 10),
  ));

  User? _user; // Храним данные вошедшего пользователя
  bool _isLoading = false;

  // Геттеры
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null; // Если пользователь не null — он авторизован

  // --- НОВЫЙ МЕТОД: Проверка сохраненной сессии при старте ---
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('user_email');
    final username = prefs.getString('user_name');

    // Если в памяти есть токен и данные пользователя, восстанавливаем сессию
    if (token != null && email != null && username != null) {
      _user = User(username: username, email: email);
      print('✅ Сессия восстановлена для: $email');
    } else {
      _user = null;
    }
    notifyListeners();
  }

  // --- НОВЫЙ МЕТОД: Выход из аккаунта ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');

    _user = null;
    notifyListeners();
  }

  // Метод РЕГИСТРАЦИИ
  Future<bool> register({
    required String username,
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

  // Метод ЛОГИНА
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
          '/api/auth/login',
          data: {
            'email': email,
            'password': password,
          });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        print('✅ Успешный логин! Получен токен: $token');

        final String tempUsername = email.split('@')[0];
        _user = User(username: tempUsername, email: email);

        // --- СОХРАНЯЕМ В ПАМЯТЬ ТЕЛЕФОНА ---
        final prefs = await SharedPreferences.getInstance();
        if (token != null) await prefs.setString('auth_token', token.toString());
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', tempUsername);

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

  // Метод: Вход через Google / Facebook
  Future<void> loginWithOAuthToken(String token) async {
    print('✅ Успешный вход через OAuth! Токен: $token');

    try {
      // 1. Расшифровываем токен
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      print('👉 Данные внутри токена: $decodedToken');

      // 2. Вытаскиваем email
      String realEmail = decodedToken['sub'] ?? 'google@user.com';

      // 3. Вытаскиваем имя (пока берем кусок почты до собачки @)
      String realName = decodedToken['name'] ?? realEmail.split('@')[0];

      // 4. Сохраняем реальные данные в провайдер
      _user = User(username: realName, email: realEmail);

      // --- СОХРАНЯЕМ В ПАМЯТЬ ТЕЛЕФОНА ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_email', realEmail);
      await prefs.setString('user_name', realName);

    } catch (e) {
      print('❌ Ошибка при разборе OAuth токена: $e');
    }
    notifyListeners();
  }
}