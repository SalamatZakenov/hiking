import 'package:latlong2/latlong.dart';

class RouteModel {
  final String id;
  final String name;
  final String location;
  final String description;
  final double elevation;
  final String difficulty;
  final String category;
  final double latitude;
  final double longitude;
  final String? gpxUrl;
  final List<String> imageUrls;
  final double rating;
  final double? calculatedDistance;
  final List<LatLng>? cachedGpxPoints;

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
    this.gpxUrl,
    required this.imageUrls,
    this.rating = 5.0,
    this.calculatedDistance,
    this.cachedGpxPoints,
  });

  // --- АДАПТЕРЫ ДЛЯ СТАРОГО КОДА КАРТЫ (map_screen.dart) ---
  LatLng get trailhead => LatLng(latitude, longitude);
  List<LatLng> get trackPoints => cachedGpxPoints ?? [];
  double get distanceKm => calculatedDistance ?? 0.0;
  List<WaypointData> get waypoints => [];

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] != null) {
      for (var img in json['images']) {
        if (img['imageUrl'] != null) {
          parsedImages.add(img['imageUrl']);
        }
      }
    }

    return RouteModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Route',
      location: json['location'] ?? 'Unknown Location',
      description: json['description'] ?? '',
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
      difficulty: json['difficulty'] ?? 'MEDIUM',
      category: json['category'] ?? 'OTHER',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      gpxUrl: json['gpxUrl'],
      imageUrls: parsedImages,
      calculatedDistance: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  RouteModel copyWith({
    double? calculatedDistance,
    List<LatLng>? cachedGpxPoints,
  }) {
    return RouteModel(
      id: id,
      name: name,
      location: location,
      description: description,
      elevation: elevation,
      difficulty: difficulty,
      category: category,
      latitude: latitude,
      longitude: longitude,
      gpxUrl: gpxUrl,
      imageUrls: imageUrls,
      rating: rating,
      calculatedDistance: calculatedDistance ?? this.calculatedDistance,
      cachedGpxPoints: cachedGpxPoints ?? this.cachedGpxPoints,
    );
  }
}

// Обновленная заглушка: добавлено поле imageUrl
class WaypointData {
  final LatLng location;
  final String name;
  final String description;
  final String imageUrl; // Добавлено это поле

  WaypointData({
    required this.location,
    required this.name,
    required this.description,
    this.imageUrl = 'https://via.placeholder.com/300x180?text=No+Image', // Дефолтная картинка
  });
}