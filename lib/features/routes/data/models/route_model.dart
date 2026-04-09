// lib/features/routes/data/models/route_model.dart
import 'package:latlong2/latlong.dart';

// 1. НАШ НОВЫЙ КЛАСС ДЛЯ МЕТОК
class WaypointData {
  final LatLng location;
  final String name;
  final String imageUrl;

  WaypointData({required this.location, required this.name, required this.imageUrl});
}

class RouteModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  final LatLng trailhead;
  final List<LatLng> trackPoints;
  final List<WaypointData> waypoints; // 2. НОВОЕ ПОЛЕ ДЛЯ МЕТОК ИЗ GPX

  final double distanceKm;
  final double elevationGainMeters;
  final String difficulty;
  final String estimatedTime;
  final String imageUrl;

  double? calculatedDistance;
  double? calculatedDurationMinutes;

  String get location => 'Алматы, Заилийский Алатау';
  String get category => difficulty;
  double get elevation => elevationGainMeters;
  List<String> get allImages => [imageUrl];

  RouteModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.trailhead,
    required this.trackPoints,
    required this.waypoints, // Добавили в конструктор
    required this.distanceKm,
    required this.elevationGainMeters,
    required this.difficulty,
    required this.estimatedTime,
    required this.imageUrl,
    this.calculatedDistance,
    this.calculatedDurationMinutes,
  });

  RouteModel copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    LatLng? trailhead,
    List<LatLng>? trackPoints,
    List<WaypointData>? waypoints,
    double? distanceKm,
    double? elevationGainMeters,
    String? difficulty,
    String? estimatedTime,
    String? imageUrl,
    double? calculatedDistance,
    double? calculatedDurationMinutes,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      trailhead: trailhead ?? this.trailhead,
      trackPoints: trackPoints ?? this.trackPoints,
      waypoints: waypoints ?? this.waypoints, // Копируем метки
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      imageUrl: imageUrl ?? this.imageUrl,
      calculatedDistance: calculatedDistance ?? this.calculatedDistance,
      calculatedDurationMinutes: calculatedDurationMinutes ?? this.calculatedDurationMinutes,
    );
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    String parsedImageUrl = '';
    if (json['imageUrl'] != null) {
      parsedImageUrl = json['imageUrl'].toString();
    } else if (json['images'] != null && json['images'] is List && json['images'].isNotEmpty) {
      parsedImageUrl = json['images'][0]['imageUrl']?.toString() ?? '';
    }

    return RouteModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,

      trailhead: json['trailhead'] != null
          ? LatLng((json['trailhead']['lat'] as num).toDouble(), (json['trailhead']['lng'] as num).toDouble())
          : LatLng((json['latitude'] as num?)?.toDouble() ?? 0.0, (json['longitude'] as num?)?.toDouble() ?? 0.0),

      trackPoints: json['trackPoints'] != null
          ? (json['trackPoints'] as List).map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())).toList()
          : [],

      waypoints: [], // Изначально пусто, мы заполним это из GPX

      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toDouble() ?? (json['elevation'] as num?)?.toDouble() ?? 0.0,
      difficulty: json['difficulty']?.toString() ?? 'UNKNOWN',
      estimatedTime: json['estimatedTime']?.toString() ?? 'N/A',
      imageUrl: parsedImageUrl,
    );
  }
}