// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // <-- Пакет для расшифровки токена

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

  // Метод ВХОДА (Login по паролю)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
          '/api/auth/login',
          data: {
            'email': email,
            'password': password,
          });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String token = response.data.toString();
        print('✅ Успешный логин! Получен токен: $token');

        final String tempUsername = email.split('@')[0];
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

  // --- НОВЫЙ МЕТОД: Вход через Google / Facebook ---
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

      // 4. Сохраняем реальные данные!
      _user = User(username: realName, email: realEmail);

    } catch (e) {
      print('❌ Ошибка расшифровки токена: $e');
      _user = User(username: "Explorer", email: "error@token.com");
    }

    notifyListeners();
  }

  // --- ТОТ САМЫЙ МЕТОД ВЫХОДА (LOGOUT) ---
  void logout() {
    _user = null;
    notifyListeners();
  }

}