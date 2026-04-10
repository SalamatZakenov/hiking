import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../tracking/data/models/local_track.dart';

class TrackDetailScreen extends StatefulWidget {
  final LocalTrack track;
  const TrackDetailScreen({super.key, required this.track});

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen> {
  List<LatLng> _points = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGpxData();
  }

  // Маленькая магия: читаем наш GPX файл и достаем точки для карты
  Future<void> _loadGpxData() async {
    try {
      final file = File(widget.track.gpxFilePath);
      if (await file.exists()) {
        final xmlString = await file.readAsString();
        // Ищем в тексте широту и долготу
        final RegExp regExp = RegExp(r'<trkpt lat="([^"]+)" lon="([^"]+)">');
        final matches = regExp.allMatches(xmlString);

        for (final match in matches) {
          final lat = double.parse(match.group(1)!);
          final lon = double.parse(match.group(2)!);
          _points.add(LatLng(lat, lon));
        }
      }
    } catch (e) {
      print('Ошибка чтения GPX: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _points.isNotEmpty ? _points[_points.length ~/ 2] : const LatLng(43.2220, 76.8512);
    final dateStr = "${widget.track.date.day.toString().padLeft(2, '0')}.${widget.track.date.month.toString().padLeft(2, '0')}.${widget.track.date.year}";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.track.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF32D74B)))
          : Column(
        children: [
          // --- КАРТА С ПРОЙДЕННЫМ ПУТЕМ ---
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: mapCenter,
                  // Если точек нет, зум отдаляем, если есть - приближаем
                  initialZoom: _points.isEmpty ? 11.0 : 15.0,
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
                      Polyline(points: _points, color: const Color(0xFF007AFF), strokeWidth: 6.0),
                    ],
                  ),
                  // Маркеры начала и конца пути
                  if (_points.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _points.first, // Откуда начал (Зеленая точка)
                          child: const Icon(Icons.location_on, color: Color(0xFF32D74B), size: 35),
                        ),
                        Marker(
                          point: _points.last, // Где закончил (Красный флаг)
                          child: const Icon(Icons.flag_circle, color: Colors.redAccent, size: 35),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // --- ДЕТАЛЬНАЯ СТАТИСТИКА ---
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.track.type, style: const TextStyle(color: Color(0xFF32D74B), fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('Distance', '${widget.track.distanceKm.toStringAsFixed(2)} km'),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                      _buildStatBox('Time', _formatDuration(widget.track.durationSeconds)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      ],
    );
  }
}