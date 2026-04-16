import 'dart:convert';

class LocalTrack {
  final String id;
  final String username; // Кто выложил
  final String name;
  final String activityType; // WALKING, RUNNING, HIKING
  final double distanceKm;
  final int durationSeconds;
  final String gpxFilePath; // Тут теперь может лежать ссылка https://...
  final DateTime date;
  final List<String> imageUrls;

  // Новые социальные фичи
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  LocalTrack({
    required this.id,
    this.username = 'User',
    required this.name,
    required this.activityType,
    required this.distanceKm,
    required this.durationSeconds,
    required this.gpxFilePath,
    required this.date,
    this.imageUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  factory LocalTrack.fromMap(Map<String, dynamic> map) {
    return LocalTrack(
      id: map['id'].toString(),
      username: map['username'] ?? 'User',
      name: map['name'] ?? 'Unnamed Route',
      // Бэкенд возвращает HIKING, а у нас в UI было Hiking (с большой буквы). Делаем красиво:
      activityType: map['activityType'] ?? 'HIKING',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['durationSec'] ?? 0,
      gpxFilePath: map['gpxUrl'] ?? '', // Бэкенд возвращает gpxUrl
      date: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      likedByMe: map['likedByMe'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'activityType': activityType,
      'distanceKm': distanceKm,
      'durationSec': durationSeconds, // Сохраняем как durationSec
      'gpxUrl': gpxFilePath, // Сохраняем как gpxUrl
      'createdAt': date.toIso8601String(),
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedByMe': likedByMe,
    };
  }

  String toJson() => json.encode(toMap());
  factory LocalTrack.fromJson(String source) => LocalTrack.fromMap(json.decode(source));
}