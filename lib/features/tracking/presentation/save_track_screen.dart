import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';

class SaveTrackScreen extends StatefulWidget {
  const SaveTrackScreen({super.key});

  @override
  State<SaveTrackScreen> createState() => _SaveTrackScreenState();
}

class _SaveTrackScreenState extends State<SaveTrackScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Hiking'; // По умолчанию
  final List<String> _activityTypes = ['Walking', 'Running', 'Hiking'];

  @override
  void initState() {
    super.initState();
    // Генерируем дефолтное название
    _nameController.text = 'Morning ${_selectedType}';
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context, listen: false);
    final points = tracker.routePoints;

    // Центрируем карту по последней точке или центру маршрута
    final mapCenter = points.isNotEmpty ? points[points.length ~/ 2] : const LatLng(43.2220, 76.8512);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Save Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            // Если передумал сохранять — возвращаемся и продолжаем (или можно сделать сброс)
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- КАРТА С МАРШРУТОМ ---
            SizedBox(
              height: 250,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 14.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Запрещаем крутить карту, она чисто для красоты
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],

                      userAgentPackageName: 'com.salamat.hiking_app',
                      maxNativeZoom: 17,
                      maxZoom: 22,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          color: Colors.blueAccent,
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),
                    // Добавляем маркеры Старта и Финиша
                    if (points.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: points.first, // Старт
                            child: const Icon(Icons.location_on, color: Colors.green, size: 30),
                          ),
                          Marker(
                            point: points.last, // Финиш
                            child: const Icon(Icons.flag_circle, color: Colors.red, size: 30),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- СТАТИСТИКА ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('Distance', '${tracker.totalDistanceKm.toStringAsFixed(2)} km'),
                      _buildStatBox('Time', tracker.formattedTime),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- НАЗВАНИЕ ---
                  const Text('Activity Name', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- ТИП АКТИВНОСТИ ---
                  const Text('Activity Type', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _activityTypes.map((type) {
                      final isSelected = _selectedType == type;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            _nameController.text = 'Morning $type'; // Автоматически меняем название
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF32D74B) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 50),

                  // --- КНОПКА СОХРАНИТЬ ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF32D74B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        // 1. Сохраняем в провайдер!
                        await tracker.saveCurrentTrack(
                          name: _nameController.text.trim(),
                          type: _selectedType,
                        );

                        // 2. Закрываем экран сохранения и возвращаемся
                        if (mounted) {
                          Navigator.pop(context); // Закрыть экран
                          // Опционально: показать SnackBar об успехе
                        }
                      },
                      child: const Text('Save Activity', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}