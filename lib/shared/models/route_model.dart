// lib/shared/models/route_model.dart
class HikingRoute {
  final String id;
  final String name;
  final String imageUrl;
  final double lengthKm;
  final String difficulty;
  final double rating;

  HikingRoute({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.lengthKm,
    required this.difficulty,
    required this.rating,
  });
}