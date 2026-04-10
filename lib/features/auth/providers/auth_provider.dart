// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // <-- ДОБАВИЛИ ДЛЯ ПАРСИНГА JSON

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

  // --- Проверка сохраненной сессии при старте ---
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
      print('ℹ️ Сессия не найдена. Нужен логин.');
    }
    notifyListeners();
  }

  // Метод: Логин (вход)
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          "email": username, // У тебя на бэкенде поле называется email
          "password": password
        },
      );

      if (response.statusCode == 200) {
        // --- УМНЫЙ ПАРСИНГ ОТВЕТА БЭКЕНДА ---
        String? token;

        if (response.data is Map) {
          // Если бэкенд отдал правильный словарь
          token = response.data['token'] ?? response.data['accessToken'];
        } else if (response.data is String) {
          // Если бэкенд отдал строку
          try {
            // Пробуем расшифровать строку как JSON
            final decoded = jsonDecode(response.data);
            token = decoded['token'] ?? decoded['accessToken'];
          } catch (_) {
            // Если это не JSON, возможно бэкенд прислал сам токен голым текстом
            token = response.data;
          }
        }

        if (token == null || token.isEmpty) {
          print('❌ Токен не найден в ответе: ${response.data}');
          return false;
        }

        // Вытаскиваем email из токена (или берем тот, что ввели)
        String tempEmail = username;
        String tempUsername = username.split('@')[0];

        try {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          tempEmail = decodedToken['sub'] ?? tempEmail;
          tempUsername = decodedToken['name'] ?? tempUsername;
        } catch (e) {
          print('⚠️ Не удалось расшифровать JWT токен: $e');
        }

        _user = User(username: tempUsername, email: tempEmail);

        // Сохраняем в память телефона
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_email', tempEmail);
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
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      String realEmail = decodedToken['sub'] ?? 'google@user.com';
      String realName = decodedToken['name'] ?? realEmail.split('@')[0];

      _user = User(username: realName, email: realEmail);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_email', realEmail);
      await prefs.setString('user_name', realName);

      notifyListeners();
    } catch (e) {
      print('❌ Ошибка при обработке OAuth токена: $e');
    }
  }

  // Метод: Регистрация
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: {
          "firstname": username,
          "lastname": username,
          "email": email,
          "password": password,
          "role": "USER"
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // --- УМНЫЙ ПАРСИНГ ОТВЕТА БЭКЕНДА ---
        String? token;

        if (response.data is Map) {
          token = response.data['token'] ?? response.data['accessToken'];
        } else if (response.data is String) {
          try {
            final decoded = jsonDecode(response.data);
            token = decoded['token'] ?? decoded['accessToken'];
          } catch (_) {
            token = response.data;
          }
        }

        if (token == null || token.isEmpty) {
          print('❌ Токен не найден при регистрации: ${response.data}');
          return false;
        }

        _user = User(username: username, email: email);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', username);

        return true;
      }
      return false;

    } on DioException catch (e) {
      print('❌ Ошибка сети при регистрации: ${e.message}');
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

  // Метод: Выход (Logout)
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    print('🚪 Пользователь вышел из системы. Память очищена.');
    notifyListeners();
  }
}