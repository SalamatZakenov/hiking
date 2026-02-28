// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Имитация логина (в реальности тут DTO и репозиторий)
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Имитация сети
    if (email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners(); // GoRouter услышит это и сделает redirect на /map
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}