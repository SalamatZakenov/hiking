// lib/features/routes/data/models/route_model.dart

class RouteModel {
  final int id;
  final String name;
  final String location;
  final String difficulty;
  final double distance;
  final String category;
  final double latitude;
  final double longitude;
  final String imageUrl;

  RouteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.difficulty,
    required this.distance,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown Route',
      location: json['location'] ?? 'Unknown Location',
      difficulty: json['difficulty'] ?? 'UNKNOWN',
      // Переводим в double, потому что бэк может прислать как 12.5, так и просто 12
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'HIKING',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}