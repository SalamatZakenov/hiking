// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Хранилище для токена
  final _storage = const FlutterSecureStorage();

  // Настройка HTTP-клиента
  // ВАЖНО: 10.0.2.2 используется для Android эмулятора, чтобы достучаться до localhost компьютера.
  // Для iOS симулятора используй 127.0.0.1. Порт 8080 - стандарт для Spring Boot.
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8080/api/auth', // Базовый путь из контроллера
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Логин: соответствует @PostMapping("/login")
  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'email': email, // Уточни у бэкендера: тут email или username?
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Бэкенд возвращает просто String (судя по public String login(...))
        final String token = response.data.toString();

        await _storage.write(key: 'jwt_token', value: token);
        _isAuthenticated = true;
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('Ошибка авторизации: ${e.response?.data ?? e.message}');
      rethrow; // Пробрасываем ошибку в UI (на будущее)
    }
  }

  /// Регистрация: соответствует @PostMapping("/register")
  Future<void> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'username': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Регистрация прошла успешно. Сервер вернул UserResponse.
        // Так как OTP пока нет на бэкенде, мы можем сразу автоматически залогинить юзера
        await login(email, password);
      }
    } on DioException catch (e) {
      debugPrint('Ошибка регистрации: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Выход из аккаунта
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Проверка, есть ли токен (вызывать при старте приложения)
  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }
}