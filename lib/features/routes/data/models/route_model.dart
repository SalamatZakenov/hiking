// lib/features/routes/data/models/route_model.dart
import 'package:latlong2/latlong.dart';

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
  final List<WaypointData> waypoints;

  final double distanceKm;
  final double elevationGainMeters;
  final String difficulty;
  final String routeCategory;
  final String estimatedTime;
  final String imageUrl;

  final String? gpxUrl;

  // НОВОЕ ПОЛЕ: Настоящая локация из Базы Данных
  final String parsedLocation;

  double? calculatedDistance;
  double? calculatedDurationMinutes;

  // Теперь мы отдаем локацию из БД. Если бэкенд пришлет null, покажем дефолтную.
  String get location => parsedLocation.isNotEmpty ? parsedLocation : 'Заилийский Алатау';

  String get category => routeCategory;
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
    required this.waypoints,
    required this.distanceKm,
    required this.elevationGainMeters,
    required this.difficulty,
    required this.routeCategory,
    required this.estimatedTime,
    required this.imageUrl,
    required this.parsedLocation, // Добавили в конструктор
    this.gpxUrl,
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
    String? routeCategory,
    String? estimatedTime,
    String? imageUrl,
    String? parsedLocation,
    String? gpxUrl,
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
      waypoints: waypoints ?? this.waypoints,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      difficulty: difficulty ?? this.difficulty,
      routeCategory: routeCategory ?? this.routeCategory,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      imageUrl: imageUrl ?? this.imageUrl,
      parsedLocation: parsedLocation ?? this.parsedLocation, // Копируем
      gpxUrl: gpxUrl ?? this.gpxUrl,
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

      waypoints: [],

      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toDouble() ?? (json['elevation'] as num?)?.toDouble() ?? 0.0,
      difficulty: json['difficulty']?.toString() ?? 'UNKNOWN',
      routeCategory: json['category']?.toString() ?? 'PEAK',
      estimatedTime: json['estimatedTime']?.toString() ?? 'N/A',
      imageUrl: parsedImageUrl,

      parsedLocation: json['location']?.toString() ?? '', // <-- ЧИТАЕМ ИЗ БАЗЫ!
      gpxUrl: json['gpxUrl']?.toString(),
    );
  }
}