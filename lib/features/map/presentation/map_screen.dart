// lib/features/map/presentation/map_screen.dart
import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isTracking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Map')),
      body: Stack(
        children: [
          // 1. Placeholder Карты.
          // В будущем здесь будет: FlutterMap(options: MapOptions(...))
          // с тайлами (TileLayer), поддерживающими локальное кэширование (MBTiles).
          Container(
            color: const Color(0xFF2A2A2A),
            child: const Center(
              child: Text(
                'Map Placeholder\n(Ready for offline vector tiles)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          // 2. Индикатор текущей позиции (монтируется поверх карты)
          const Center(
            child: Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
          ),

          // 3. UI управления трекингом
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isTracking = !_isTracking;
                  // Здесь будет вызов GPS сервиса:
                  // locator.startTracking()
                });
              },
              backgroundColor: _isTracking ? Colors.redAccent : Colors.green,
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? 'Остановить трекинг' : 'Начать трекинг'),
            ),
          ),
        ],
      ),
    );
  }
}