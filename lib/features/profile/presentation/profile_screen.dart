import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../community/presentation/comments_sheet.dart';

import 'track_detail_screen.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tracking/data/models/local_track.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final tracks = tracker.savedTracks;
    final int totalHikes = tracks.length;
    final double totalDistance = tracks.fold(0.0, (sum, track) => sum + track.distanceKm);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context, authProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100, height: 100, alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                color: const Color(0xFF32D74B).withOpacity(0.2),
              ),
              child: Text(
                (authProvider.user?.username ?? 'S').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF32D74B)),
              ),
            ),
            const SizedBox(height: 16),
            Text(authProvider.user?.username ?? 'Salamat Zakenov', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(authProvider.user?.email ?? 'salamat@zakenov.com', style: const TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(totalHikes.toString(), 'Activities'),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                        _buildStatItem('${totalDistance.toStringAsFixed(1)} km', 'Distance'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("You haven't recorded any activities yet.", style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  return _buildFeedPost(context, tracks[index]);
                },
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedPost(BuildContext context, LocalTrack track) {
    final dateStr = "${track.date.day.toString().padLeft(2, '0')}.${track.date.month.toString().padLeft(2, '0')}.${track.date.year}";
    final String realUserName = track.username.isNotEmpty ? track.username : 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)), bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: const Color(0xFF32D74B).withOpacity(0.2),
                    child: Text(realUserName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF32D74B), fontWeight: FontWeight.bold))
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(realUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$dateStr • ${track.activityType}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(track.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          _PostCarousel(track: track),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Provider.of<TrackingProvider>(context, listen: false).toggleLike(track.id),
                  child: Icon(
                      track.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: track.likedByMe ? Colors.redAccent : Colors.white, size: 28),
                ),
                const SizedBox(width: 8),
                Text('${track.likeCount}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsSheet(trackId: track.id),
                    );
                  },
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 8),
                Text('${track.commentCount}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const Spacer(),
                if (track.imageUrls.isNotEmpty)
                  const Icon(Icons.photo_library_outlined, color: Colors.white54, size: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }
}

class _PostCarousel extends StatefulWidget {
  final LocalTrack track;
  const _PostCarousel({required this.track});
  @override
  State<_PostCarousel> createState() => _PostCarouselState();
}

class _PostCarouselState extends State<_PostCarousel> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrackDetailScreen(track: widget.track))),
          child: _FeedMapWidget(track: widget.track)
      ),
      ...widget.track.imageUrls.map((url) => Image.network(url, fit: BoxFit.cover))
    ];

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView(
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: pages,
          ),
          if (pages.length > 1)
            Positioned(
              bottom: 10, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == i ? 12 : 6, height: 6,
                  decoration: BoxDecoration(color: _currentIndex == i ? const Color(0xFF32D74B) : Colors.white54, borderRadius: BorderRadius.circular(3)),
                )),
              ),
            )
        ],
      ),
    );
  }
}

class _FeedMapWidget extends StatefulWidget {
  final LocalTrack track;
  const _FeedMapWidget({required this.track});
  @override
  State<_FeedMapWidget> createState() => _FeedMapWidgetState();
}

class _FeedMapWidgetState extends State<_FeedMapWidget> {
  List<LatLng> _points = [];

  @override
  void initState() {
    super.initState();
    _loadGpxData();
  }

  Future<void> _loadGpxData() async {
    try {
      String xmlString = "";
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
        final RegExp regExp = RegExp(r'<trkpt lat="([^"]+)" lon="([^"]+)".*?>');
        final matches = regExp.allMatches(xmlString);
        if (mounted) {
          setState(() {
            _points = matches.map((m) => LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!))).toList();
          });
        }
      }
    } catch (e) {
      print('Ошибка загрузки GPX в профиле: $e');
    }
  }

  Widget _buildMapMarker(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Icon(icon, color: Colors.white, size: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) return Container(color: Colors.white.withOpacity(0.05), child: const Center(child: CircularProgressIndicator(color: Color(0xFF32D74B))));

    LatLngBounds? bounds;
    if (_points.length > 1) bounds = LatLngBounds.fromPoints(_points);

    return AbsorbPointer(
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: bounds != null ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(15), maxZoom: 17.0) : null,
          initialCenter: bounds == null && _points.isNotEmpty ? _points.first : const LatLng(43.2220, 76.8512),
        ),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.salamat.hiking_app'),
          if (_points.isNotEmpty)
            PolylineLayer(polylines: [Polyline(points: _points, color: const Color(0xFF007AFF), strokeWidth: 5.0, strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round)]),
          if (_points.isNotEmpty)
            MarkerLayer(markers: [
              Marker(point: _points.first, width: 30, height: 30, child: _buildMapMarker(const Color(0xFF32D74B), Icons.play_arrow_rounded)),
              Marker(point: _points.last, width: 30, height: 30, child: _buildMapMarker(Colors.redAccent, Icons.flag_rounded)),
            ]),
        ],
      ),
    );
  }
}