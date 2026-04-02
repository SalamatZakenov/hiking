// lib/features/routes/data/services/route_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Для debugPrint
import '../models/route_model.dart';

class RouteService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://shyn-api.site/api/routes';

  Future<List<RouteModel>> fetchRoutes() async {
    try {
      final response = await _dio.get(baseUrl);

      // Выводим в консоль ровно то, что ответил сервер!
      debugPrint('🌍 ОТВЕТ БЭКЕНДА: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load routes. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔥 ОШИБКА В SERVICE: $e');
      throw Exception('Error fetching routes: $e');
    }
  }
}