// lib/features/tracking/data/models/local_track.dart
import 'dart:convert';

class LocalTrack {
  final String id;
  final String name;
  final String type; // <-- НОВОЕ: Тип тренировки (Walking, Running, Hiking)
  final double distanceKm;
  final int durationSeconds;
  final String gpxFilePath;
  final DateTime date;

  LocalTrack({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.durationSeconds,
    required this.gpxFilePath,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'gpxFilePath': gpxFilePath,
      'date': date.toIso8601String(),
    };
  }

  factory LocalTrack.fromMap(Map<String, dynamic> map) {
    return LocalTrack(
      id: map['id'],
      name: map['name'] ?? 'Unnamed Route',
      // Если у нас в памяти остались старые треки без типа, по умолчанию ставим Hiking
      type: map['type'] ?? 'Hiking',
      distanceKm: map['distanceKm'],
      durationSeconds: map['durationSeconds'],
      gpxFilePath: map['gpxFilePath'],
      date: DateTime.parse(map['date']),
    );
  }

  String toJson() => json.encode(toMap());
  factory LocalTrack.fromJson(String source) => LocalTrack.fromMap(json.decode(source));
}