import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../tracking/data/models/local_track.dart';
import 'package:dio/dio.dart'; // <-- ОБЯЗАТЕЛЬНО ДОБАВЬ

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

  Future<void> _loadGpxData() async {
    try {
      String xmlString = "";

      // Проверяем: это ссылка из интернета или локальный файл?
      if (widget.track.gpxFilePath.startsWith('http')) {
        final response = await Dio().get(widget.track.gpxFilePath);
        xmlString = response.data.toString();
      } else {
        final file = File(widget.track.gpxFilePath);
        if (await file.exists()) {
          xmlString = await file.readAsString();
        }
      }

      if (xmlString.isNotEmpty) {
        // Регулярка стала чуть безопаснее (убрал > на конце)
        final RegExp regExp = RegExp(r'<trkpt lat="([^"]+)" lon="([^"]+)"');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    LatLngBounds? bounds;
    if (_points.length > 1) {
      bounds = LatLngBounds.fromPoints(_points);
    }

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
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ИНТЕРАКТИВНАЯ КАРТА ---
            SizedBox(
              height: 350, // Сделали карту большой
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: bounds != null ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(30), maxZoom: 17.0) : null,
                    initialCenter: bounds == null && _points.isNotEmpty ? _points.first : const LatLng(43.2220, 76.8512),
                    initialZoom: 15.0,
                    // ТУТ КАРТУ МОЖНО ДВИГАТЬ И ПРИБЛИЖАТЬ!
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.salamat.hiking_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _points, color: const Color(0xFF007AFF), strokeWidth: 6.0,
                          strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    ),
                    if (_points.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _points, color: const Color(0xFF007AFF), strokeWidth: 6.0,
                            strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      ),
                    if (_points.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(point: _points.first, child: const Icon(Icons.location_on, color: Color(0xFF32D74B), size: 35)),
                          Marker(point: _points.last, child: const Icon(Icons.flag_circle, color: Colors.redAccent, size: 35)),
                        ],
                      ),

                  ],
                ),
              ),
            ),

            // --- СТАТИСТИКА ---
            Padding(
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
                          Text(widget.track.activityType, style: const TextStyle(color: Color(0xFF32D74B), fontSize: 16, fontWeight: FontWeight.bold)),                          const SizedBox(height: 4),
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

            // --- ГАЛЕРЕЯ ФОТОГРАФИЙ (Показывается, если есть фото) ---
            if (widget.track.imageUrls.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text('Photos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.track.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          widget.track.imageUrls[index],
                          width: 150,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ]
          ],
        ),
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