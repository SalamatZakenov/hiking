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
  String _selectedType = 'Hiking';
  final List<String> _activityTypes = ['Walking', 'Running', 'Hiking'];

  final List<String> _attachedPhotos = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Morning $_selectedType';
  }

  void _addMockPhoto() {
    final mockImages = [
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&fit=crop',
      'https://images.unsplash.com/photo-1551632811-561732d1e306?w=600&fit=crop',
      'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600&fit=crop',
    ];
    setState(() {
      _attachedPhotos.add(mockImages[_attachedPhotos.length % mockImages.length]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context, listen: false);
    final points = tracker.routePoints;

    LatLngBounds? bounds;
    if (points.length > 1) {
      bounds = LatLngBounds.fromPoints(points);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Save Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: bounds != null ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20), maxZoom: 17.0) : null,
                    initialCenter: bounds == null && points.isNotEmpty ? points.first : const LatLng(43.2220, 76.8512),
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.salamat.hiking_app',
                    ),

                    if (points.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points, color: const Color(0xFF007AFF), strokeWidth: 6.0,
                            strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      ),

                    if (points.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(point: points.first, child: const Icon(Icons.location_on, color: Color(0xFF00E5FF), size: 30)), // Изменен цвет
                          Marker(point: points.last, child: const Icon(Icons.flag_circle, color: Colors.red, size: 30)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('Distance', '${tracker.totalDistanceKm.toStringAsFixed(2)} km'),
                      _buildStatBox('Time', tracker.formattedTime),
                    ],
                  ),
                  const SizedBox(height: 30),

                  const Text('Activity Name', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text('Activity Type', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _activityTypes.map((type) {
                      final isSelected = _selectedType == type;
                      return GestureDetector(
                        onTap: () => setState(() { _selectedType = type; _nameController.text = 'Morning $type'; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.1), // Изменен цвет
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(type, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      GestureDetector(
                        onTap: _addMockPhoto,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.add_a_photo_rounded, color: Colors.white54, size: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _attachedPhotos.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(_attachedPhotos[index], width: 80, height: 80, fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), // Изменен цвет
                      onPressed: () async {
                        await tracker.saveCurrentTrack(name: _nameController.text.trim(), type: _selectedType, imageUrls: _attachedPhotos);
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Save Activity', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: TextButton(
                      style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      onPressed: () async {
                        await tracker.discardCurrentTrack();
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Discard Activity', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
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