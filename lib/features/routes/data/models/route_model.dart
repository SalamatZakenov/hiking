// lib/features/routes/data/models/route_model.dart
import 'package:flutter/foundation.dart';

class RouteModel {
  final int id;
  final String name;
  final String location;
  final String description;
  final double elevation;
  final String difficulty;
  final String category;
  final double latitude;
  final double longitude;
  final String imageUrl; // Обложка (первая картинка)
  final List<String> allImages; // Все картинки маршрута (на будущее)

  double? calculatedDistance;

  RouteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.elevation,
    required this.difficulty,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.allImages = const [],
    this.calculatedDistance,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    String parsedImageUrl = '';
    List<String> parsedAllImages = [];

    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      // Проходимся по всем картинкам, которые прислал бэкенд
      for (var img in json['images']) {
        // ИЩЕМ ИМЕННО ПО КЛЮЧУ imageUrl !
        final urlString = img['imageUrl']?.toString() ?? '';

        if (urlString.isNotEmpty) {
          // Если ссылка полная, берем как есть. Если относительная - клеим домен.
          if (urlString.startsWith('http')) {
            parsedAllImages.add(urlString);
          } else {
            final cleanPath = urlString.startsWith('/') ? urlString : '/$urlString';
            parsedAllImages.add('https://shyn-api.site$cleanPath');
          }
        }
      }

      // Назначаем первую картинку как главную обложку
      if (parsedAllImages.isNotEmpty) {
        parsedImageUrl = parsedAllImages.first;
      }
    }

    debugPrint('📸 Гора: ${json['name']} | Ссылка: ${parsedImageUrl.isEmpty ? "ПУСТО" : parsedImageUrl}');

    return RouteModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown Route',
      location: json['location'] ?? 'Unknown Location',
      description: json['description'] ?? 'No description available.',
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
      difficulty: json['difficulty'] ?? 'UNKNOWN',
      category: json['category'] ?? 'HIKING',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: parsedImageUrl,
      allImages: parsedAllImages, // Сохраняем массив картинок в модель
    );
  }
}