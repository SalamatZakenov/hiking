// lib/features/routes/providers/route_provider.dart
import 'package:flutter/material.dart';
import '../data/models/route_model.dart';
import '../data/services/route_service.dart';

class RouteProvider with ChangeNotifier {
  final RouteService _service = RouteService();

  List<RouteModel> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<RouteModel> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Говорим экрану: "Покажи крутилку загрузки"

    try {
      _routes = await _service.fetchRoutes();
    } catch (e) {
      _error = 'Не удалось загрузить маршруты. Проверьте интернет.';
    } finally {
      _isLoading = false;
      notifyListeners(); // Говорим экрану: "Обнови список, данные пришли"
    }
  }
}