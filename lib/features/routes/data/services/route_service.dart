// lib/features/routes/data/services/route_service.dart
import 'package:dio/dio.dart';
import '../models/route_model.dart';

class RouteService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://shyn-api.site/api/routes';

  Future<List<RouteModel>> fetchRoutes() async {
    try {
      final response = await _dio.get(baseUrl);

      if (response.statusCode == 200) {
        // Ожидаем, что бэкенд возвращает массив (List)
        final List<dynamic> data = response.data;
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load routes');
      }
    } catch (e) {
      throw Exception('Error fetching routes: $e');
    }
  }
}