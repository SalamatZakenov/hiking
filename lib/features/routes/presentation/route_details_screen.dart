// lib/features/routes/presentation/route_details_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../providers/route_provider.dart';
import '../data/models/route_model.dart';
import '../../../core/theme/app_theme.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String routeId;

  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final Dio _dio = Dio();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  String _weatherText = '...';
  IconData _weatherIcon = Icons.cloud_outlined;
  bool _isWeatherFetched = false;

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final response = await _dio.get('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      if (response.statusCode == 200) {
        final current = response.data['current_weather'];
        if (mounted) {
          setState(() {
            _weatherText = '${current['temperature'].round()}°C';
            _weatherIcon = _getWeatherIcon(current['weathercode']);
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _weatherText = '--');
    }
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.cloud_queue_rounded;
    if (code <= 67) return Icons.water_drop_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    return Icons.cloud_rounded;
  }

  void _openGallery(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => RouteGalleryViewer(images: images, initialIndex: initialIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);

    RouteModel? route;
    try {
      route = routeProvider.routes.firstWhere((r) => r.id.toString() == widget.routeId);
    } catch (e) {
      route = null;
    }

    if (route != null && !_isWeatherFetched) {
      _isWeatherFetched = true;
      _fetchWeather(route.latitude, route.longitude);
    }

    if (route == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // --- ИСПРАВЛЕННАЯ ЛОГИКА ---
    // Если картинок нет, оставляем массив пустым, чтобы не передавать пустую строку в Image.network
    final displayImages = route.allImages.isNotEmpty
        ? route.allImages
        : (route.imageUrl.isNotEmpty ? [route.imageUrl] : <String>[]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- КАРУСЕЛЬ ФОТОГРАФИЙ ---
                  Stack(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: displayImages.isEmpty
                        // Если массив пустой, показываем заглушку напрямую (без Image.network)
                            ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                          ),
                          child: const Center(child: Icon(Icons.terrain_rounded, size: 80, color: Colors.white10)),
                        )
                        // Если картинки есть, строим карусель
                            : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemCount: displayImages.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _openGallery(context, displayImages, index),
                              child: Hero(
                                tag: 'photo_${route!.id}_$index',
                                child: Image.network(
                                  displayImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFF2C2C2E),
                                    child: const Center(child: Icon(Icons.terrain_rounded, size: 80, color: Colors.white10)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        top: 0, left: 0, right: 0, height: 120,
                        child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]))),
                      ),

                      if (displayImages.length > 1)
                        Positioned(
                          bottom: 20, left: 0, right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(displayImages.length, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 8,
                                width: _currentImageIndex == index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),

                  // Контент
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: AppTheme.bgDark),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildBadge(route.category.toUpperCase(), Colors.blueAccent),
                            const SizedBox(width: 8),
                            _buildBadge(route.difficulty.toUpperCase(), _getDifficultyColor(route.difficulty)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(route.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppTheme.cardSlate, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(route.location, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500))),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            _buildStatCard(Icons.route_rounded, route.calculatedDistance != null ? '${route.calculatedDistance!.toStringAsFixed(1)} km' : '? km', 'Distance'),
                            const SizedBox(width: 16),
                            _buildStatCard(Icons.height_rounded, '${route.elevation.toInt()} m', 'Elevation'),
                            const SizedBox(width: 16),
                            _buildStatCard(_weatherIcon, _weatherText, 'Weather'),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        Text(route.description, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5)),
                        const SizedBox(height: 40),

                        // Карта
                        GestureDetector(
                          onTap: () => context.push('/map', extra: '${route!.name}||${route.latitude},${route.longitude}'),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Route Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Icon(Icons.open_in_full_rounded, color: Colors.white54, size: 20),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 180, width: double.infinity,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: IgnorePointer(
                                    child: FlutterMap(
                                      options: MapOptions(initialCenter: LatLng(route.latitude, route.longitude), initialZoom: 13.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                                      children: [
                                        TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', retinaMode: true),
                                        MarkerLayer(markers: [Marker(point: LatLng(route.latitude, route.longitude), width: 40, height: 40, child: const Icon(Icons.location_on, color: Color(0xFFFF453A), size: 40))]),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassIconButton(Icons.arrow_back_ios_new_rounded, () => context.canPop() ? context.pop() : context.go('/routes')),
                  _buildGlassIconButton(Icons.favorite_border_rounded, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String diff) {
    if (diff.toUpperCase() == 'HARD') return const Color(0xFFFF5252);
    if (diff.toUpperCase() == 'MEDIUM') return const Color(0xFFFF9F0A);
    return const Color(0xFF4CAF50);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
    );
  }

  Widget _buildStatCard(IconData icon, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.cardSlate, size: 24),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class RouteGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const RouteGalleryViewer({super.key, required this.images, required this.initialIndex});

  @override
  State<RouteGalleryViewer> createState() => _RouteGalleryViewerState();
}

class _RouteGalleryViewerState extends State<RouteGalleryViewer> {
  late PageController _galleryController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _galleryController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
        title: Text('${_currentIndex + 1} / ${widget.images.length}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _galleryController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5, maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white24)),
              ),
            ),
          );
        },
      ),
    );
  }
}