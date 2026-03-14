// lib/shared/models/route_model.dart

class HikingRoute {
  final String id;
  final String name;        // Например: "Пик Фурманова" или "Иле-Алатауский парк"
  final String location;    // Где находится
  final String difficulty;  // Сложность (Easy, Medium, Hard)
  final double lengthKm;    // Расстояние
  final String category;    // НОВОЕ ПОЛЕ: 'peak', 'park', 'trail', 'lake' и т.д.
  // В будущем сюда добавишь imageUrl или координаты для карты

  HikingRoute({
    required this.id,
    required this.name,
    required this.location,
    required this.difficulty,
    required this.lengthKm,
    required this.category,
  });

  // Этот фабричный метод будет парсить JSON с вашего AWS сервера
  factory HikingRoute.fromJson(Map<String, dynamic> json) {
    return HikingRoute(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown',
      location: json['location'] ?? 'Unknown Location',
      difficulty: json['difficulty'] ?? 'Medium',
      // Если с бэка приходит int, конвертируем в double
      lengthKm: (json['distance'] ?? json['lengthKm'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'trail', // По умолчанию просто тропа
    );
  }
}